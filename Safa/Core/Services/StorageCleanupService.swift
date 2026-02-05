// MARK: - StorageCleanupService.swift
// PURPOSE: Smart cleanup of unused audio files based on retention period
// DEPENDENCIES: Foundation, BackgroundTasks

import Foundation
import BackgroundTasks

// MARK: - Retention Period

enum RetentionPeriod: String, CaseIterable, Identifiable, Codable {
    case oneMonth = "1_month"
    case threeMonths = "3_months"
    case sixMonths = "6_months"
    case never = "never"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneMonth: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .never: return "Never"
        }
    }

    var days: Int? {
        switch self {
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .never: return nil
        }
    }

    var description: String {
        switch self {
        case .oneMonth: return "Remove audio unused for more than 1 month"
        case .threeMonths: return "Remove audio unused for more than 3 months"
        case .sixMonths: return "Remove audio unused for more than 6 months"
        case .never: return "Never automatically remove audio"
        }
    }
}

// MARK: - Audio File Metadata

struct AudioFileMetadata: Codable, Identifiable {
    let id: String // file identifier
    let fileName: String
    var lastPlayedDate: Date?
    let downloadedDate: Date
    let fileSize: Int64

    var daysSinceLastPlayed: Int? {
        guard let lastPlayed = lastPlayedDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastPlayed, to: Date()).day
    }

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

// MARK: - Cleanup Result

struct CleanupResult {
    let filesRemoved: Int
    let bytesReclaimed: Int64
    let errors: [Error]

    var formattedBytesReclaimed: String {
        ByteCountFormatter.string(fromByteCount: bytesReclaimed, countStyle: .file)
    }
}

// MARK: - Storage Cleanup Service

@Observable
final class StorageCleanupService {
    static let shared = StorageCleanupService()

    // MARK: - Properties

    private(set) var audioFiles: [AudioFileMetadata] = []
    private(set) var totalStorageUsed: Int64 = 0
    private(set) var isScanning = false
    private(set) var lastCleanupDate: Date?
    private(set) var lastCleanupResult: CleanupResult?

    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard

    // Storage Keys
    private let metadataKey = "com.safa.storage.audioMetadata"
    private let retentionPeriodKey = "com.safa.storage.retentionPeriod"
    private let autoCleanupKey = "com.safa.storage.autoCleanup"
    private let lastCleanupKey = "com.safa.storage.lastCleanup"

    // Configuration
    var retentionPeriod: RetentionPeriod {
        get {
            guard let rawValue = userDefaults.string(forKey: retentionPeriodKey),
                  let period = RetentionPeriod(rawValue: rawValue) else {
                return .threeMonths // default
            }
            return period
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: retentionPeriodKey)
        }
    }

    var autoCleanupEnabled: Bool {
        get { userDefaults.bool(forKey: autoCleanupKey) }
        set { userDefaults.set(newValue, forKey: autoCleanupKey) }
    }

    // MARK: - Background Task Identifier

    static let backgroundTaskIdentifier = "com.safa.storageCleanup"

    // MARK: - Audio Directory

    private var audioDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory.appendingPathComponent("Audio", isDirectory: true)
    }

    // MARK: - Init

    private init() {
        loadMetadata()
        loadLastCleanupDate()
    }

    // MARK: - Public Methods

    /// Scan the audio directory for files
    func scanAudioFiles() async {
        isScanning = true
        defer { isScanning = false }

        var files: [AudioFileMetadata] = []
        var totalSize: Int64 = 0

        guard let enumerator = fileManager.enumerator(
            at: audioDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]
        ) else {
            return
        }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .creationDateKey]),
                  let fileSize = resourceValues.fileSize,
                  let creationDate = resourceValues.creationDate else {
                continue
            }

            let identifier = fileURL.deletingPathExtension().lastPathComponent
            let existingMetadata = audioFiles.first { $0.id == identifier }

            let metadata = AudioFileMetadata(
                id: identifier,
                fileName: fileURL.lastPathComponent,
                lastPlayedDate: existingMetadata?.lastPlayedDate,
                downloadedDate: creationDate,
                fileSize: Int64(fileSize)
            )

            files.append(metadata)
            totalSize += Int64(fileSize)
        }

        audioFiles = files.sorted { ($0.lastPlayedDate ?? .distantPast) > ($1.lastPlayedDate ?? .distantPast) }
        totalStorageUsed = totalSize
        saveMetadata()
    }

    /// Record that a file was played
    func recordFilePlayback(identifier: String) {
        if let index = audioFiles.firstIndex(where: { $0.id == identifier }) {
            audioFiles[index].lastPlayedDate = Date()
            saveMetadata()
        } else {
            // File might not be in our list yet, add it
            let fileURL = audioDirectory.appendingPathComponent("\(identifier).mp3")
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .creationDateKey]),
               let fileSize = resourceValues.fileSize,
               let creationDate = resourceValues.creationDate {
                let metadata = AudioFileMetadata(
                    id: identifier,
                    fileName: "\(identifier).mp3",
                    lastPlayedDate: Date(),
                    downloadedDate: creationDate,
                    fileSize: Int64(fileSize)
                )
                audioFiles.append(metadata)
                saveMetadata()
            }
        }
    }

    /// Get files that exceed the retention period
    func getUnusedAudioFiles() -> [AudioFileMetadata] {
        guard let days = retentionPeriod.days else {
            return [] // "Never" retention period
        }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        return audioFiles.filter { file in
            // If never played, use download date
            let referenceDate = file.lastPlayedDate ?? file.downloadedDate
            return referenceDate < cutoffDate
        }
    }

    /// Get storage that would be reclaimed by cleanup
    func getStorageToReclaim() -> Int64 {
        let unusedFiles = getUnusedAudioFiles()
        return unusedFiles.reduce(0) { $0 + $1.fileSize }
    }

    /// Clean up unused files
    func cleanupUnusedFiles() async -> CleanupResult {
        let unusedFiles = getUnusedAudioFiles()
        var filesRemoved = 0
        var bytesReclaimed: Int64 = 0
        var errors: [Error] = []

        for file in unusedFiles {
            let fileURL = audioDirectory.appendingPathComponent(file.fileName)

            do {
                try fileManager.removeItem(at: fileURL)
                filesRemoved += 1
                bytesReclaimed += file.fileSize
                audioFiles.removeAll { $0.id == file.id }
            } catch {
                errors.append(error)
            }
        }

        totalStorageUsed -= bytesReclaimed
        lastCleanupDate = Date()
        saveMetadata()
        saveLastCleanupDate()

        let result = CleanupResult(
            filesRemoved: filesRemoved,
            bytesReclaimed: bytesReclaimed,
            errors: errors
        )
        lastCleanupResult = result

        return result
    }

    /// Delete a specific file
    func deleteFile(identifier: String) throws {
        let fileURL = audioDirectory.appendingPathComponent("\(identifier).mp3")

        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }

        if let file = audioFiles.first(where: { $0.id == identifier }) {
            totalStorageUsed -= file.fileSize
        }
        audioFiles.removeAll { $0.id == identifier }
        saveMetadata()
    }

    /// Delete all audio files
    func deleteAllFiles() async throws {
        let contents = try fileManager.contentsOfDirectory(at: audioDirectory, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }

        audioFiles.removeAll()
        totalStorageUsed = 0
        saveMetadata()
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
        guard autoCleanupEnabled else { return }

        let request = BGProcessingTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        // Schedule for weekly cleanup
        request.earliestBeginDate = Date(timeIntervalSinceNow: 7 * 24 * 60 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("StorageCleanupService: Failed to schedule background task: \(error)")
        }
    }

    // MARK: - Background Task Handler

    private func handleBackgroundTask(_ task: BGProcessingTask) {
        scheduleBackgroundTask() // Schedule next run

        let cleanupTask = Task {
            await scanAudioFiles()
            _ = await cleanupUnusedFiles()
        }

        task.expirationHandler = {
            cleanupTask.cancel()
        }

        Task {
            await cleanupTask.value
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: - Persistence

    private func loadMetadata() {
        guard let data = userDefaults.data(forKey: metadataKey),
              let metadata = try? JSONDecoder().decode([AudioFileMetadata].self, from: data) else {
            return
        }
        audioFiles = metadata
        totalStorageUsed = audioFiles.reduce(0) { $0 + $1.fileSize }
    }

    private func saveMetadata() {
        if let data = try? JSONEncoder().encode(audioFiles) {
            userDefaults.set(data, forKey: metadataKey)
        }
    }

    private func loadLastCleanupDate() {
        lastCleanupDate = userDefaults.object(forKey: lastCleanupKey) as? Date
    }

    private func saveLastCleanupDate() {
        userDefaults.set(lastCleanupDate, forKey: lastCleanupKey)
    }

    // MARK: - Computed Properties

    var formattedTotalStorage: String {
        ByteCountFormatter.string(fromByteCount: totalStorageUsed, countStyle: .file)
    }

    var unusedFilesCount: Int {
        getUnusedAudioFiles().count
    }

    var formattedStorageToReclaim: String {
        ByteCountFormatter.string(fromByteCount: getStorageToReclaim(), countStyle: .file)
    }
}

// MARK: - Feature Flag Integration

extension StorageCleanupService {
    var isAvailable: Bool {
        FeatureFlags.shared.isEnabled(.smartCleanup)
    }
}
