// MARK: - SpeechRecognitionService.swift
// PURPOSE: Arabic speech recognition for pronunciation checking
// DEPENDENCIES: Speech, AVFoundation

import Foundation
import Speech
import AVFoundation

// MARK: - Speech Recognition Service

@Observable
final class SpeechRecognitionService {

    // MARK: - Properties

    var isRecording: Bool = false
    var isAuthorized: Bool = false
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var transcription: String = ""
    var confidence: Float = 0.0
    var error: SpeechError?

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Initialization

    init() {
        // Initialize with Arabic (Modern Standard Arabic)
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in
                    self?.authorizationStatus = status
                    self?.isAuthorized = status == .authorized
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }

    func checkAuthorizationStatus() {
        let status = SFSpeechRecognizer.authorizationStatus()
        authorizationStatus = status
        isAuthorized = status == .authorized
    }

    // MARK: - Recording

    func startRecording() throws {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerNotAvailable
        }

        guard isAuthorized else {
            throw SpeechError.notAuthorized
        }

        // Cancel any ongoing task
        stopRecording()

        // Reset state
        transcription = ""
        confidence = 0.0
        error = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.requestCreationFailed
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation

        // Get audio input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install tap to capture audio
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let error = error {
                    self?.error = SpeechError.recognitionFailed(error.localizedDescription)
                    self?.stopRecording()
                    return
                }

                if let result = result {
                    self?.transcription = result.bestTranscription.formattedString

                    // Get confidence from segments
                    let segments = result.bestTranscription.segments
                    if !segments.isEmpty {
                        let totalConfidence = segments.reduce(0) { $0 + $1.confidence }
                        self?.confidence = totalConfidence / Float(segments.count)
                    }

                    if result.isFinal {
                        self?.stopRecording()
                    }
                }
            }
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: - Pronunciation Scoring

    func calculatePronunciationScore(
        expected: String,
        actual: String,
        acceptableVariations: [String] = []
    ) -> PronunciationResult {
        // Normalize strings for comparison
        let normalizedExpected = normalizeArabic(expected)
        let normalizedActual = normalizeArabic(actual)

        // Check exact match
        if normalizedExpected == normalizedActual {
            return PronunciationResult(
                score: 100,
                accuracy: .excellent,
                feedback: "Perfect pronunciation!",
                matchedText: actual
            )
        }

        // Check acceptable variations
        for variation in acceptableVariations {
            let normalizedVariation = normalizeArabic(variation)
            if normalizedVariation == normalizedActual {
                return PronunciationResult(
                    score: 95,
                    accuracy: .excellent,
                    feedback: "Great pronunciation!",
                    matchedText: actual
                )
            }
        }

        // Calculate similarity score
        let similarity = calculateSimilarity(expected: normalizedExpected, actual: normalizedActual)
        let score = Int(similarity * 100)

        let (accuracy, feedback) = evaluateScore(score)

        return PronunciationResult(
            score: score,
            accuracy: accuracy,
            feedback: feedback,
            matchedText: actual
        )
    }

    // MARK: - Private Helpers

    private func normalizeArabic(_ text: String) -> String {
        var normalized = text

        // Remove diacritics (tashkeel)
        let diacritics = CharacterSet(charactersIn: "\u{064B}\u{064C}\u{064D}\u{064E}\u{064F}\u{0650}\u{0651}\u{0652}\u{0653}\u{0654}\u{0655}")
        normalized = normalized.unicodeScalars.filter { !diacritics.contains($0) }.map { String($0) }.joined()

        // Normalize alef variations
        normalized = normalized.replacingOccurrences(of: "إ", with: "ا")
        normalized = normalized.replacingOccurrences(of: "أ", with: "ا")
        normalized = normalized.replacingOccurrences(of: "آ", with: "ا")

        // Normalize ta marbuta
        normalized = normalized.replacingOccurrences(of: "ة", with: "ه")

        // Remove spaces and lowercase
        normalized = normalized.replacingOccurrences(of: " ", with: "")

        return normalized
    }

    private func calculateSimilarity(expected: String, actual: String) -> Double {
        // Levenshtein distance based similarity
        let distance = levenshteinDistance(expected, actual)
        let maxLength = max(expected.count, actual.count)

        guard maxLength > 0 else { return 1.0 }

        return 1.0 - (Double(distance) / Double(maxLength))
    }

    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let m = s1.count
        let n = s2.count

        if m == 0 { return n }
        if n == 0 { return m }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }

        let s1Array = Array(s1)
        let s2Array = Array(s2)

        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return matrix[m][n]
    }

    private func evaluateScore(_ score: Int) -> (PronunciationAccuracy, String) {
        switch score {
        case 90...100:
            return (.excellent, "Excellent! Your pronunciation is very clear.")
        case 75..<90:
            return (.good, "Good job! Minor improvements needed.")
        case 50..<75:
            return (.fair, "Fair attempt. Try speaking more slowly and clearly.")
        default:
            return (.needsWork, "Keep practicing! Listen to the audio example and try again.")
        }
    }
}

// MARK: - Pronunciation Result

struct PronunciationResult {
    let score: Int
    let accuracy: PronunciationAccuracy
    let feedback: String
    let matchedText: String

    var hasanatBonus: Int {
        switch accuracy {
        case .excellent: return 5
        case .good: return 3
        case .fair: return 1
        case .needsWork: return 0
        }
    }
}

enum PronunciationAccuracy: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case needsWork = "Needs Work"

    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "orange"
        case .needsWork: return "red"
        }
    }
}

// MARK: - Speech Errors

enum SpeechError: LocalizedError {
    case notAuthorized
    case recognizerNotAvailable
    case requestCreationFailed
    case recognitionFailed(String)
    case audioSessionError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return String(localized: "Speech recognition is not authorized. Please enable it in Settings.")
        case .recognizerNotAvailable:
            return String(localized: "Speech recognition is not available on this device.")
        case .requestCreationFailed:
            return String(localized: "Failed to create speech recognition request.")
        case .recognitionFailed(let message):
            return String(localized: "Recognition failed: \(message)")
        case .audioSessionError(let message):
            return String(localized: "Audio session error: \(message)")
        }
    }
}

// MARK: - Microphone Permission Helper

@Observable
final class MicrophonePermissionService {

    enum PermissionState { case undetermined, granted, denied }

    var isAuthorized: Bool = false
    var authorizationStatus: PermissionState = .undetermined

    func requestPermission() async -> Bool {
        do {
            let granted = await AVAudioApplication.requestRecordPermission()
            isAuthorized = granted
            authorizationStatus = granted ? .granted : .denied
            return granted
        }
    }

    func checkPermission() {
        let status = AVAudioApplication.shared.recordPermission
        isAuthorized = (status == .granted)
        switch status {
        case .granted: authorizationStatus = .granted
        case .denied: authorizationStatus = .denied
        default: authorizationStatus = .undetermined
        }
    }
}
