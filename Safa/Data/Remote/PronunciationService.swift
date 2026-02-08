// MARK: - PronunciationService.swift
// PURPOSE: Speech recognition for Arabic pronunciation checking
// DEPENDENCIES: Speech, AVFoundation

import Foundation
import Speech
import AVFoundation
import Combine

final class PronunciationService: ObservableObject {
    // MARK: - Published State
    @Published private(set) var isRecording = false
    @Published private(set) var isAuthorized = false
    @Published private(set) var transcribedText = ""
    @Published private(set) var error: Error?

    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Init
    init() {
        Task {
            await checkAuthorization()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.isAuthorized = status == .authorized
                }
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func checkAuthorization() async {
        let status = SFSpeechRecognizer.authorizationStatus()
        await MainActor.run {
            isAuthorized = status == .authorized
        }
    }

    // MARK: - Recording

    func startRecording() throws {
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw PronunciationError.recognitionUnavailable
        }
        recognitionRequest.shouldReportPartialResults = true

        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self?.stopRecording()
                }
            }
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        Task { @MainActor in
            isRecording = true
            transcribedText = ""
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        Task { @MainActor in
            isRecording = false
        }
    }

    // MARK: - Pronunciation Checking

    func checkPronunciation(expected: String) async throws -> PronunciationCheckResult {
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted {
                throw PronunciationError.notAuthorized
            }
        }

        // Start recording
        try startRecording()

        // Wait for recording (max 10 seconds)
        try await Task.sleep(nanoseconds: 5_000_000_000)

        // Stop recording
        stopRecording()

        // Calculate score
        let score = calculateSimilarity(expected: expected, actual: transcribedText)

        return PronunciationCheckResult(
            expectedText: expected,
            recognizedText: transcribedText,
            score: score,
            feedback: generateFeedback(score: score)
        )
    }

    // MARK: - Scoring

    private func calculateSimilarity(expected: String, actual: String) -> Int {
        guard !expected.isEmpty && !actual.isEmpty else { return 0 }

        // Normalize strings
        let normalizedExpected = expected.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedActual = actual.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Simple similarity based on Levenshtein distance
        let distance = levenshteinDistance(normalizedExpected, normalizedActual)
        let maxLength = max(normalizedExpected.count, normalizedActual.count)

        guard maxLength > 0 else { return 0 }

        let similarity = 1.0 - (Double(distance) / Double(maxLength))
        return Int(similarity * 100)
    }

    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2Array.count + 1), count: s1Array.count + 1)

        for i in 0...s1Array.count {
            matrix[i][0] = i
        }
        for j in 0...s2Array.count {
            matrix[0][j] = j
        }

        for i in 1...s1Array.count {
            for j in 1...s2Array.count {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }

        return matrix[s1Array.count][s2Array.count]
    }

    private func generateFeedback(score: Int) -> String {
        switch score {
        case 90...100:
            return "Excellent pronunciation! Keep it up!"
        case 75..<90:
            return "Great job! Your pronunciation is very good."
        case 50..<75:
            return "Good attempt. Try listening to the example again."
        case 25..<50:
            return "Keep practicing. Focus on the sounds you're finding difficult."
        default:
            return "Try again. Listen carefully to the example first."
        }
    }
}

// MARK: - Pronunciation Check Result
struct PronunciationCheckResult {
    let expectedText: String
    let recognizedText: String
    let score: Int // 0-100
    let feedback: String

    var isPassing: Bool {
        score >= 70
    }
}

// MARK: - Pronunciation Error
enum PronunciationError: LocalizedError {
    case notAuthorized
    case recognitionUnavailable
    case recordingFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return String(localized: "Microphone permission is required for pronunciation checking.")
        case .recognitionUnavailable:
            return String(localized: "Speech recognition is not available.")
        case .recordingFailed:
            return String(localized: "Failed to start recording.")
        }
    }
}
