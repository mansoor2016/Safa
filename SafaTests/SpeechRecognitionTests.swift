// MARK: - SpeechRecognitionTests.swift
// PURPOSE: Unit tests for speech recognition functionality
// DEPENDENCIES: XCTest, Speech, AVFoundation

import XCTest
import Speech
import AVFoundation
@testable import Safa

final class SpeechRecognitionServiceTests: XCTestCase {

    var sut: SpeechRecognitionService!

    override func setUp() {
        super.setUp()
        sut = SpeechRecognitionService()
    }

    override func tearDown() {
        sut.stopRecording()
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertFalse(sut.isRecording)
        XCTAssertTrue(sut.transcription.isEmpty)
        XCTAssertEqual(sut.confidence, 0.0)
    }

    func testInitialAuthorizationStatus() {
        // Initial status is notDetermined until we check
        XCTAssertEqual(sut.authorizationStatus, .notDetermined)
    }

    // MARK: - Pronunciation Scoring Tests

    func testExactMatchScore() {
        let result = sut.calculatePronunciationScore(
            expected: "بِسْمِ اللَّهِ",
            actual: "بِسْمِ اللَّهِ",
            acceptableVariations: []
        )

        XCTAssertEqual(result.score, 100)
        XCTAssertEqual(result.accuracy, .excellent)
    }

    func testAcceptableVariationScore() {
        let result = sut.calculatePronunciationScore(
            expected: "الله",
            actual: "allah",
            acceptableVariations: ["allah", "Allah"]
        )

        XCTAssertGreaterThanOrEqual(result.score, 95)
        XCTAssertEqual(result.accuracy, .excellent)
    }

    func testPartialMatchScore() {
        let result = sut.calculatePronunciationScore(
            expected: "السلام عليكم",
            actual: "سلام",
            acceptableVariations: []
        )

        // Partial match should have lower score
        XCTAssertLessThan(result.score, 90)
    }

    func testEmptyActualReturnsLowScore() {
        let result = sut.calculatePronunciationScore(
            expected: "بسم الله",
            actual: "",
            acceptableVariations: []
        )

        XCTAssertEqual(result.score, 0)
        XCTAssertEqual(result.accuracy, .needsWork)
    }

    // MARK: - Accuracy Levels Tests

    func testExcellentAccuracyRange() {
        let excellentResult = sut.calculatePronunciationScore(
            expected: "test",
            actual: "test",
            acceptableVariations: []
        )

        XCTAssertEqual(excellentResult.accuracy, .excellent)
    }

    // MARK: - Hasanat Bonus Tests

    func testExcellentAccuracyBonus() {
        let result = PronunciationResult(
            score: 95,
            accuracy: .excellent,
            feedback: "Test",
            matchedText: "test"
        )

        XCTAssertEqual(result.hasanatBonus, 5)
    }

    func testGoodAccuracyBonus() {
        let result = PronunciationResult(
            score: 80,
            accuracy: .good,
            feedback: "Test",
            matchedText: "test"
        )

        XCTAssertEqual(result.hasanatBonus, 3)
    }

    func testFairAccuracyBonus() {
        let result = PronunciationResult(
            score: 60,
            accuracy: .fair,
            feedback: "Test",
            matchedText: "test"
        )

        XCTAssertEqual(result.hasanatBonus, 1)
    }

    func testNeedsWorkAccuracyBonus() {
        let result = PronunciationResult(
            score: 30,
            accuracy: .needsWork,
            feedback: "Test",
            matchedText: "test"
        )

        XCTAssertEqual(result.hasanatBonus, 0)
    }

    // MARK: - Error Tests

    func testSpeechErrorDescriptions() {
        XCTAssertNotNil(SpeechError.notAuthorized.errorDescription)
        XCTAssertNotNil(SpeechError.recognizerNotAvailable.errorDescription)
        XCTAssertNotNil(SpeechError.requestCreationFailed.errorDescription)
        XCTAssertNotNil(SpeechError.recognitionFailed("test").errorDescription)
        XCTAssertNotNil(SpeechError.audioSessionError("test").errorDescription)
    }
}

// MARK: - Pronunciation Accuracy Tests

final class PronunciationAccuracyTests: XCTestCase {

    func testAccuracyRawValues() {
        XCTAssertEqual(PronunciationAccuracy.excellent.rawValue, "Excellent")
        XCTAssertEqual(PronunciationAccuracy.good.rawValue, "Good")
        XCTAssertEqual(PronunciationAccuracy.fair.rawValue, "Fair")
        XCTAssertEqual(PronunciationAccuracy.needsWork.rawValue, "Needs Work")
    }

    func testAccuracyColors() {
        XCTAssertEqual(PronunciationAccuracy.excellent.color, "green")
        XCTAssertEqual(PronunciationAccuracy.good.color, "blue")
        XCTAssertEqual(PronunciationAccuracy.fair.color, "orange")
        XCTAssertEqual(PronunciationAccuracy.needsWork.color, "red")
    }
}

// MARK: - Microphone Permission Service Tests

final class MicrophonePermissionServiceTests: XCTestCase {

    var sut: MicrophonePermissionService!

    override func setUp() {
        super.setUp()
        sut = MicrophonePermissionService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testInitialState() {
        // Initial state depends on actual permission status
        sut.checkPermission()
        // Just verify it doesn't crash
    }

    func testAuthorizationStatusTypes() {
        // Verify we can access all status types
        _ = AVAudioSession.RecordPermission.undetermined
        _ = AVAudioSession.RecordPermission.denied
        _ = AVAudioSession.RecordPermission.granted
    }
}
