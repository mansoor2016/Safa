// MARK: - AudioPlayerService+Extensions.swift
// PURPOSE: Extensions for audio playback functionality
// DEPENDENCIES: AVFoundation, MediaPlayer

import AVFoundation
import MediaPlayer

// MARK: - Audio Session Configuration

extension AudioPlayerService {

    /// Configure audio session for background playback
    func configureBackgroundAudio() {
        do {
            let session = AVAudioSession.sharedInstance()

            // Set category for background audio playback
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.allowAirPlay, .allowBluetooth]
            )

            // Activate the session
            try session.setActive(true)

            print("Audio session configured for background playback")
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    /// Deactivate audio session when done
    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}

// MARK: - Now Playing Info

extension AudioPlayerService {

    /// Update Now Playing info for Lock Screen and Control Center
    func updateNowPlayingInfo(
        title: String,
        artist: String = "Quran Recitation",
        albumTitle: String = "Safa",
        duration: TimeInterval,
        currentTime: TimeInterval,
        artworkImage: UIImage? = nil
    ) {
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyAlbumTitle: albumTitle,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        // Add artwork if available
        if let image = artworkImage {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    /// Clear Now Playing info
    func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}

// MARK: - Remote Control Events

extension AudioPlayerService {

    /// Setup remote control event handlers (play/pause from Lock Screen, AirPods, etc.)
    func setupRemoteControls(
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        onSeek: @escaping (TimeInterval) -> Void
    ) {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            onPlay()
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ in
            onPause()
            return .success
        }

        // Next track command
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { _ in
            onNext()
            return .success
        }

        // Previous track command
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { _ in
            onPrevious()
            return .success
        }

        // Seek command
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            onSeek(positionEvent.positionTime)
            return .success
        }

        // Skip forward/backward
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { _ in
            // Skip forward 15 seconds
            return .success
        }

        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { _ in
            // Skip backward 15 seconds
            return .success
        }
    }

    /// Remove remote control handlers
    func removeRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
    }
}

// MARK: - Audio Download Manager

@Observable
final class AudioDownloadManager {

    // MARK: - Properties

    private let fileManager = FileManager.default
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var downloadProgress: [String: Double] = [:]

    var isDownloading: Bool {
        !downloadTasks.isEmpty
    }

    var wifiOnlyEnabled: Bool = true

    // MARK: - Download Directory

    private var downloadDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let audioDirectory = documentsDirectory.appendingPathComponent("Audio", isDirectory: true)

        // Create directory if needed
        if !fileManager.fileExists(atPath: audioDirectory.path) {
            try? fileManager.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        }

        return audioDirectory
    }

    // MARK: - Public Methods

    /// Download an audio file
    func downloadAudio(
        from url: URL,
        identifier: String,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        // Check WiFi setting
        if wifiOnlyEnabled && !isOnWiFi() {
            completion(.failure(DownloadError.wifiRequired))
            return
        }

        // Check if already downloaded
        let localURL = downloadDirectory.appendingPathComponent(identifier + ".mp3")
        if fileManager.fileExists(atPath: localURL.path) {
            completion(.success(localURL))
            return
        }

        // Create download task
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
        let task = session.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self = self else { return }

            self.downloadTasks.removeValue(forKey: identifier)

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let tempURL = tempURL else {
                completion(.failure(DownloadError.downloadFailed))
                return
            }

            // Move to permanent location
            do {
                if self.fileManager.fileExists(atPath: localURL.path) {
                    try self.fileManager.removeItem(at: localURL)
                }
                try self.fileManager.moveItem(at: tempURL, to: localURL)
                completion(.success(localURL))
            } catch {
                completion(.failure(error))
            }
        }

        downloadTasks[identifier] = task
        task.resume()
    }

    /// Cancel a download
    func cancelDownload(identifier: String) {
        downloadTasks[identifier]?.cancel()
        downloadTasks.removeValue(forKey: identifier)
    }

    /// Cancel all downloads
    func cancelAllDownloads() {
        downloadTasks.values.forEach { $0.cancel() }
        downloadTasks.removeAll()
    }

    /// Check if audio is downloaded
    func isDownloaded(identifier: String) -> Bool {
        let localURL = downloadDirectory.appendingPathComponent(identifier + ".mp3")
        return fileManager.fileExists(atPath: localURL.path)
    }

    /// Get local URL for downloaded audio
    func localURL(for identifier: String) -> URL? {
        let localURL = downloadDirectory.appendingPathComponent(identifier + ".mp3")
        return fileManager.fileExists(atPath: localURL.path) ? localURL : nil
    }

    /// Delete downloaded audio
    func deleteDownload(identifier: String) throws {
        let localURL = downloadDirectory.appendingPathComponent(identifier + ".mp3")
        if fileManager.fileExists(atPath: localURL.path) {
            try fileManager.removeItem(at: localURL)
        }
    }

    /// Get total size of downloads
    func getTotalDownloadSize() -> Int64 {
        guard let enumerator = fileManager.enumerator(at: downloadDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            totalSize += Int64(fileSize)
        }

        return totalSize
    }

    /// Delete all downloads
    func deleteAllDownloads() throws {
        let contents = try fileManager.contentsOfDirectory(at: downloadDirectory, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }
    }

    // MARK: - Private Methods

    private func isOnWiFi() -> Bool {
        NetworkMonitor.shared.isOnWiFi
    }

    // MARK: - Errors

    enum DownloadError: Error, LocalizedError {
        case wifiRequired
        case downloadFailed

        var errorDescription: String? {
            switch self {
            case .wifiRequired:
                return String(localized: "WiFi connection required for downloads")
            case .downloadFailed:
                return String(localized: "Download failed")
            }
        }
    }
}

// MARK: - Playback State

enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case stopped
    case error(String)

    var isActive: Bool {
        switch self {
        case .playing, .paused, .loading:
            return true
        default:
            return false
        }
    }
}

// MARK: - Ayah Playback Manager

@Observable
final class AyahPlaybackManager {

    // MARK: - Properties

    private let audioService: AudioPlayerService
    private let downloadManager = AudioDownloadManager()

    var currentSurah: Int?
    var currentAyah: Int?
    var playbackState: PlaybackState = .idle
    var isContinuousPlayback: Bool = true

    // MARK: - Initialization

    init(audioService: AudioPlayerService = AudioPlayerService()) {
        self.audioService = audioService
        audioService.configureBackgroundAudio()
    }

    // MARK: - Public Methods

    /// Play a specific ayah
    func playAyah(surah: Int, ayah: Int, reciter: String = "mishary") {
        currentSurah = surah
        currentAyah = ayah
        playbackState = .loading

        let identifier = "\(reciter)_\(surah)_\(ayah)"

        // Check if downloaded
        if let localURL = downloadManager.localURL(for: identifier) {
            play(url: localURL, surah: surah, ayah: ayah)
        } else {
            // Stream from remote (simplified)
            let remoteURL = constructAudioURL(surah: surah, ayah: ayah, reciter: reciter)
            play(url: remoteURL, surah: surah, ayah: ayah)
        }
    }

    /// Play entire surah continuously
    func playSurah(surah: Int, startingAyah: Int = 1, reciter: String = "mishary") {
        isContinuousPlayback = true
        playAyah(surah: surah, ayah: startingAyah, reciter: reciter)
    }

    /// Pause playback
    func pause() {
        audioService.pause()
        playbackState = .paused
    }

    /// Resume playback
    func resume() {
        audioService.resume()
        playbackState = .playing
    }

    /// Stop playback
    func stop() {
        audioService.stop()
        playbackState = .stopped
        currentSurah = nil
        currentAyah = nil
    }

    /// Skip to next ayah
    func nextAyah() {
        guard let surah = currentSurah, let ayah = currentAyah else { return }
        playAyah(surah: surah, ayah: ayah + 1)
    }

    /// Go to previous ayah
    func previousAyah() {
        guard let surah = currentSurah, let ayah = currentAyah, ayah > 1 else { return }
        playAyah(surah: surah, ayah: ayah - 1)
    }

    // MARK: - Private Methods

    private func play(url: URL, surah: Int, ayah: Int) {
        Task { @MainActor in
            do {
                try await audioService.play(url: url)
                playbackState = .playing

                // Update now playing info
                audioService.updateNowPlayingInfo(
                    title: "Surah \(surah), Ayah \(ayah)",
                    artist: "Quran Recitation",
                    albumTitle: "Safa",
                    duration: audioService.duration,
                    currentTime: audioService.currentTime
                )
            } catch {
                playbackState = .error(error.localizedDescription)
            }
        }
    }

    private func constructAudioURL(surah: Int, ayah: Int, reciter: String) -> URL {
        // Construct URL for audio (would need actual audio hosting)
        let surahPadded = String(format: "%03d", surah)
        let ayahPadded = String(format: "%03d", ayah)
        return URL(string: "https://cdn.islamic.network/quran/audio/128/ar.\(reciter)/\(surahPadded)\(ayahPadded).mp3")!
    }
}
