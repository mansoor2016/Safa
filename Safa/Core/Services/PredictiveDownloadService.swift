// MARK: - PredictiveDownloadService.swift
// PURPOSE: Intelligent audio download prediction based on user reading patterns
// DEPENDENCIES: Foundation, BackgroundTasks

import Foundation
import BackgroundTasks

// MARK: - Download Prediction

struct DownloadPrediction: Identifiable, Codable {
    let id: UUID
    let surahNumber: Int
    let reason: PredictionReason
    let priority: Int
    let createdAt: Date

    init(surahNumber: Int, reason: PredictionReason, priority: Int = 0) {
        self.id = UUID()
        self.surahNumber = surahNumber
        self.reason = reason
        self.priority = priority
        self.createdAt = Date()
    }

    enum PredictionReason: String, Codable {
        case nextSurah = "next_surah"
        case sameJuz = "same_juz"
        case frequentlyRead = "frequently_read"
        case continuation = "continuation"
    }
}

// MARK: - Reading History Entry

struct ReadingHistoryEntry: Codable {
    let surahNumber: Int
    let timestamp: Date
    let duration: TimeInterval
    let completedSurah: Bool
}

// MARK: - Predictive Download Service

@Observable
final class PredictiveDownloadService {
    static let shared = PredictiveDownloadService()

    // MARK: - Properties

    private(set) var downloadQueue: [DownloadPrediction] = []
    private(set) var isProcessingQueue = false
    private(set) var lastPredictionUpdate: Date?

    private let downloadManager = AudioDownloadManager()
    private let userDefaults = UserDefaults.standard

    // Storage Keys
    private let readingHistoryKey = AppConstants.StorageKeys.predictiveReadingHistory
    private let downloadQueueKey = AppConstants.StorageKeys.predictiveDownloadQueue
    private let enabledKey = AppConstants.StorageKeys.predictiveEnabled
    private let wifiOnlyKey = AppConstants.StorageKeys.predictiveWifiOnly

    // Configuration
    var isEnabled: Bool {
        get { userDefaults.bool(forKey: enabledKey) }
        set { userDefaults.set(newValue, forKey: enabledKey) }
    }

    var wifiOnly: Bool {
        get { userDefaults.object(forKey: wifiOnlyKey) as? Bool ?? true }
        set { userDefaults.set(newValue, forKey: wifiOnlyKey) }
    }

    // Constants
    private let maxQueueSize = 10
    private let maxHistoryEntries = 100
    private let frequentlyReadThreshold = 3

    // MARK: - Background Task Identifier

    static let backgroundTaskIdentifier = "com.safa.predictiveDownload"

    // MARK: - Init

    private init() {
        loadDownloadQueue()
    }

    // MARK: - Public Methods

    /// Record that user finished reading/listening to a surah
    func recordSurahCompletion(surahNumber: Int, duration: TimeInterval) {
        guard isEnabled else { return }

        let entry = ReadingHistoryEntry(
            surahNumber: surahNumber,
            timestamp: Date(),
            duration: duration,
            completedSurah: true
        )
        addToReadingHistory(entry)
        updatePredictions(afterReading: surahNumber)
    }

    /// Record that user started reading a surah
    func recordSurahStart(surahNumber: Int) {
        guard isEnabled else { return }

        let entry = ReadingHistoryEntry(
            surahNumber: surahNumber,
            timestamp: Date(),
            duration: 0,
            completedSurah: false
        )
        addToReadingHistory(entry)
    }

    /// Get predictions for downloads
    func getPredictions() -> [DownloadPrediction] {
        return downloadQueue.sorted { $0.priority > $1.priority }
    }

    /// Process the download queue (called in background)
    func processDownloadQueue() async {
        guard isEnabled && !isProcessingQueue else { return }

        // Check WiFi requirement
        if wifiOnly && !isOnWiFi() {
            return
        }

        isProcessingQueue = true
        defer { isProcessingQueue = false }

        let predictions = getPredictions()

        for prediction in predictions {
            // Skip if already downloaded
            let identifier = "surah_\(prediction.surahNumber)"
            if downloadManager.isDownloaded(identifier: identifier) {
                removePrediction(prediction)
                continue
            }

            // Download the surah audio
            await downloadSurahAudio(surahNumber: prediction.surahNumber)
            removePrediction(prediction)

            // Small delay between downloads
            try? await Task.sleep(for: .seconds(1))
        }
    }

    /// Clear all predictions and queue
    func clearPredictions() {
        downloadQueue.removeAll()
        saveDownloadQueue()
    }

    // MARK: - Background Task Registration

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundTask(task as! BGProcessingTask)
        }
    }

    func scheduleBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("PredictiveDownloadService: Failed to schedule background task: \(error)")
        }
    }

    // MARK: - Prediction Logic

    private func updatePredictions(afterReading surahNumber: Int) {
        var newPredictions: [DownloadPrediction] = []

        // 1. Next Surah Prediction
        if surahNumber < 114 {
            newPredictions.append(DownloadPrediction(
                surahNumber: surahNumber + 1,
                reason: .nextSurah,
                priority: 100
            ))
        }

        // 2. Same Juz Prediction
        let currentJuz = surahNumber.juzNumber
        let sameJuzSurahs = surahsInJuz(currentJuz)
            .filter { $0 != surahNumber && $0 > surahNumber }
            .prefix(3)

        for juzSurah in sameJuzSurahs {
            newPredictions.append(DownloadPrediction(
                surahNumber: juzSurah,
                reason: .sameJuz,
                priority: 50
            ))
        }

        // 3. Frequently Read Prediction
        let frequentlyRead = getMostFrequentlyReadSurahs()
        for (index, surah) in frequentlyRead.prefix(3).enumerated() {
            if !newPredictions.contains(where: { $0.surahNumber == surah }) {
                newPredictions.append(DownloadPrediction(
                    surahNumber: surah,
                    reason: .frequentlyRead,
                    priority: 30 - index
                ))
            }
        }

        // Add to queue, avoiding duplicates
        for prediction in newPredictions {
            addPrediction(prediction)
        }

        lastPredictionUpdate = Date()
        saveDownloadQueue()
    }

    private func addPrediction(_ prediction: DownloadPrediction) {
        // Don't add if already in queue
        guard !downloadQueue.contains(where: { $0.surahNumber == prediction.surahNumber }) else {
            return
        }

        // Don't add if already downloaded
        let identifier = "surah_\(prediction.surahNumber)"
        if downloadManager.isDownloaded(identifier: identifier) {
            return
        }

        downloadQueue.append(prediction)

        // Trim queue if too large
        if downloadQueue.count > maxQueueSize {
            downloadQueue = Array(downloadQueue.sorted { $0.priority > $1.priority }.prefix(maxQueueSize))
        }
    }

    private func removePrediction(_ prediction: DownloadPrediction) {
        downloadQueue.removeAll { $0.id == prediction.id }
        saveDownloadQueue()
    }

    // MARK: - Reading History

    private func getReadingHistory() -> [ReadingHistoryEntry] {
        guard let data = userDefaults.data(forKey: readingHistoryKey),
              let history = try? JSONDecoder().decode([ReadingHistoryEntry].self, from: data) else {
            return []
        }
        return history
    }

    private func addToReadingHistory(_ entry: ReadingHistoryEntry) {
        var history = getReadingHistory()
        history.append(entry)

        // Trim history if too large
        if history.count > maxHistoryEntries {
            history = Array(history.suffix(maxHistoryEntries))
        }

        if let data = try? JSONEncoder().encode(history) {
            userDefaults.set(data, forKey: readingHistoryKey)
        }
    }

    private func getMostFrequentlyReadSurahs() -> [Int] {
        let history = getReadingHistory()
        var surahCounts: [Int: Int] = [:]

        for entry in history {
            surahCounts[entry.surahNumber, default: 0] += 1
        }

        return surahCounts
            .filter { $0.value >= frequentlyReadThreshold }
            .sorted { $0.value > $1.value }
            .map { $0.key }
    }

    // MARK: - Queue Persistence

    private func loadDownloadQueue() {
        guard let data = userDefaults.data(forKey: downloadQueueKey),
              let queue = try? JSONDecoder().decode([DownloadPrediction].self, from: data) else {
            return
        }
        downloadQueue = queue
    }

    private func saveDownloadQueue() {
        if let data = try? JSONEncoder().encode(downloadQueue) {
            userDefaults.set(data, forKey: downloadQueueKey)
        }
    }

    // MARK: - Audio Download

    private func downloadSurahAudio(surahNumber: Int) async {
        let identifier = "surah_\(surahNumber)"
        let surahPadded = String(format: "%03d", surahNumber)

        // Construct download URL (using common reciter)
        guard let url = URL(string: "https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/\(surahPadded).mp3") else {
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            downloadManager.downloadAudio(
                from: url,
                identifier: identifier,
                progress: { _ in }
            ) { result in
                switch result {
                case .success(let localURL):
                    print("PredictiveDownloadService: Downloaded surah \(surahNumber) to \(localURL)")
                case .failure(let error):
                    print("PredictiveDownloadService: Failed to download surah \(surahNumber): \(error)")
                }
                continuation.resume()
            }
        }
    }

    // MARK: - Background Task Handler

    private func handleBackgroundTask(_ task: BGProcessingTask) {
        scheduleBackgroundTask() // Schedule next run

        let queue = Task {
            await processDownloadQueue()
        }

        task.expirationHandler = {
            queue.cancel()
        }

        Task {
            await queue.value
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: - Utility Methods

    private func isOnWiFi() -> Bool {
        NetworkMonitor.shared.isOnWiFi
    }

}

// MARK: - Feature Flag Integration

extension PredictiveDownloadService {
    var isAvailable: Bool {
        FeatureFlags.shared.isEnabled(.predictiveDownload)
    }
}
