// MARK: - AudioPlayerService.swift
// PURPOSE: Audio playback for Quran recitation and dua pronunciations
// DEPENDENCIES: AVFoundation

import Foundation
import AVFoundation
import Combine

final class AudioPlayerService: NSObject, ObservableObject {
    // MARK: - Published State
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var displayLink: CADisplayLink?

    // MARK: - Init
    override init() {
        super.init()
        configureAudioSession()
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            self.error = error
        }
    }

    // MARK: - Playback Controls

    func play(url: URL) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            let data: Data

            if url.isFileURL {
                data = try Data(contentsOf: url)
            } else {
                let (downloadedData, _) = try await URLSession.shared.data(from: url)
                data = downloadedData
            }

            let player = try AVAudioPlayer(data: data)
            player.delegate = self

            await MainActor.run {
                self.audioPlayer = player
                self.duration = player.duration
                self.isLoading = false
            }

            player.play()

            await MainActor.run {
                self.isPlaying = true
                self.startProgressUpdates()
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            throw error
        }
    }

    func playBundled(fileName: String, fileExtension: String = "mp3") throws {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            throw AudioError.fileNotFound
        }

        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self

        audioPlayer = player
        duration = player.duration

        player.play()
        isPlaying = true
        startProgressUpdates()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressUpdates()
    }

    func resume() {
        audioPlayer?.play()
        isPlaying = true
        startProgressUpdates()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        stopProgressUpdates()
    }

    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }

    func seekForward(seconds: TimeInterval = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    func seekBackward(seconds: TimeInterval = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    // MARK: - Progress Updates

    private func startProgressUpdates() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopProgressUpdates() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateProgress() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
    }

    // MARK: - Computed Properties

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var remainingTime: TimeInterval {
        max(duration - currentTime, 0)
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            currentTime = 0
            stopProgressUpdates()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.error = error
            isPlaying = false
            stopProgressUpdates()
        }
    }
}

// MARK: - Audio Error
enum AudioError: LocalizedError {
    case fileNotFound
    case playbackFailed
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Audio file not found."
        case .playbackFailed:
            return "Failed to play audio."
        case .downloadFailed:
            return "Failed to download audio."
        }
    }
}
