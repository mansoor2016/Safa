// MARK: - LearningModelTests.swift
// PURPOSE: Unit tests for Learning domain models
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class LearningModelTests: XCTestCase {

    // MARK: - Learning Track Tests

    func testLearningTrackInitialization() {
        let track = LearningTrack(
            id: "arabic_alphabet",
            name: "Arabic Alphabet",
            arabicName: "الحروف العربية",
            description: "Learn Arabic letters",
            iconName: "textformat.abc",
            difficulty: .beginner,
            estimatedHours: 10,
            lessons: []
        )

        XCTAssertEqual(track.id, "arabic_alphabet")
        XCTAssertEqual(track.name, "Arabic Alphabet")
        XCTAssertEqual(track.difficulty, .beginner)
        XCTAssertEqual(track.estimatedHours, 10)
    }

    func testLearningTrackDifficultyLevels() {
        XCTAssertEqual(LearningDifficulty.beginner.rawValue, "beginner")
        XCTAssertEqual(LearningDifficulty.intermediate.rawValue, "intermediate")
        XCTAssertEqual(LearningDifficulty.advanced.rawValue, "advanced")
    }

    func testLearningTrackDifficultyDisplayNames() {
        XCTAssertEqual(LearningDifficulty.beginner.displayName, "Beginner")
        XCTAssertEqual(LearningDifficulty.intermediate.displayName, "Intermediate")
        XCTAssertEqual(LearningDifficulty.advanced.displayName, "Advanced")
    }

    // MARK: - Lesson Tests

    func testLessonInitialization() {
        let lesson = Lesson(
            id: "alif",
            trackId: "arabic_alphabet",
            title: "Alif (ا)",
            description: "The first letter",
            orderIndex: 1,
            content: [],
            isLocked: false,
            isCompleted: false
        )

        XCTAssertEqual(lesson.id, "alif")
        XCTAssertEqual(lesson.trackId, "arabic_alphabet")
        XCTAssertEqual(lesson.orderIndex, 1)
        XCTAssertFalse(lesson.isLocked)
        XCTAssertFalse(lesson.isCompleted)
    }

    func testLessonLockStatus() {
        let unlockedLesson = Lesson(
            id: "1",
            trackId: "test",
            title: "Test",
            description: "Test",
            orderIndex: 1,
            content: [],
            isLocked: false,
            isCompleted: false
        )

        let lockedLesson = Lesson(
            id: "2",
            trackId: "test",
            title: "Test 2",
            description: "Test 2",
            orderIndex: 2,
            content: [],
            isLocked: true,
            isCompleted: false
        )

        XCTAssertFalse(unlockedLesson.isLocked)
        XCTAssertTrue(lockedLesson.isLocked)
    }

    // MARK: - Lesson Step Tests

    func testLessonStepReading() {
        let step = LessonStep(
            id: "step1",
            type: .reading,
            title: "Introduction",
            body: "Learn about this topic",
            arabicText: "عربي",
            transliteration: "transliteration",
            audioFileName: nil,
            imageName: nil,
            options: nil,
            correctAnswer: nil,
            explanation: nil
        )

        XCTAssertEqual(step.type, .reading)
        XCTAssertEqual(step.title, "Introduction")
        XCTAssertNotNil(step.arabicText)
    }

    func testLessonStepListening() {
        let step = LessonStep(
            id: "step2",
            type: .listening,
            title: "Listen",
            body: "Listen to the sound",
            arabicText: "ا",
            transliteration: nil,
            audioFileName: "alif.mp3",
            imageName: nil,
            options: nil,
            correctAnswer: nil,
            explanation: nil
        )

        XCTAssertEqual(step.type, .listening)
        XCTAssertNotNil(step.audioFileName)
    }

    func testLessonStepQuiz() {
        let step = LessonStep(
            id: "step3",
            type: .quiz,
            title: "Quiz",
            body: "Select the correct answer",
            arabicText: nil,
            transliteration: nil,
            audioFileName: nil,
            imageName: nil,
            options: ["A", "B", "C", "D"],
            correctAnswer: "A",
            explanation: "A is correct because..."
        )

        XCTAssertEqual(step.type, .quiz)
        XCTAssertEqual(step.options?.count, 4)
        XCTAssertEqual(step.correctAnswer, "A")
        XCTAssertNotNil(step.explanation)
    }

    func testLessonStepTypes() {
        XCTAssertEqual(LessonStepType.reading.rawValue, "reading")
        XCTAssertEqual(LessonStepType.listening.rawValue, "listening")
        XCTAssertEqual(LessonStepType.pronunciation.rawValue, "pronunciation")
        XCTAssertEqual(LessonStepType.quiz.rawValue, "quiz")
        XCTAssertEqual(LessonStepType.exercise.rawValue, "exercise")
    }

    // MARK: - Learning Progress Tests

    func testLearningProgressInitialization() {
        let progress = LearningProgress(
            lessonId: "alif",
            isCompleted: true,
            score: 85,
            completedAt: Date()
        )

        XCTAssertEqual(progress.lessonId, "alif")
        XCTAssertTrue(progress.isCompleted)
        XCTAssertEqual(progress.score, 85)
    }

    func testLearningProgressScore() {
        let perfectScore = LearningProgress(
            lessonId: "test",
            isCompleted: true,
            score: 100,
            completedAt: Date()
        )

        let passingScore = LearningProgress(
            lessonId: "test2",
            isCompleted: true,
            score: 70,
            completedAt: Date()
        )

        XCTAssertEqual(perfectScore.score, 100)
        XCTAssertEqual(passingScore.score, 70)
    }

    // MARK: - Track Progress Tests

    func testTrackProgressCalculation() {
        let track = LearningTrack(
            id: "test",
            name: "Test Track",
            arabicName: "اختبار",
            description: "Test",
            iconName: "book",
            difficulty: .beginner,
            estimatedHours: 5,
            lessons: [
                Lesson(id: "1", trackId: "test", title: "L1", description: "", orderIndex: 1, content: [], isLocked: false, isCompleted: true),
                Lesson(id: "2", trackId: "test", title: "L2", description: "", orderIndex: 2, content: [], isLocked: false, isCompleted: true),
                Lesson(id: "3", trackId: "test", title: "L3", description: "", orderIndex: 3, content: [], isLocked: false, isCompleted: false),
                Lesson(id: "4", trackId: "test", title: "L4", description: "", orderIndex: 4, content: [], isLocked: true, isCompleted: false)
            ]
        )

        let completedCount = track.lessons.filter { $0.isCompleted }.count
        let totalCount = track.lessons.count
        let progress = Double(completedCount) / Double(totalCount)

        XCTAssertEqual(completedCount, 2)
        XCTAssertEqual(totalCount, 4)
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    // MARK: - Encoding/Decoding Tests

    func testLessonCodable() throws {
        let original = Lesson(
            id: "test",
            trackId: "test_track",
            title: "Test Lesson",
            description: "Description",
            orderIndex: 1,
            content: [],
            isLocked: false,
            isCompleted: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Lesson.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.title, decoded.title)
    }

    func testLearningTrackCodable() throws {
        let original = LearningTrack(
            id: "test",
            name: "Test",
            arabicName: "اختبار",
            description: "Test",
            iconName: "book",
            difficulty: .intermediate,
            estimatedHours: 10,
            lessons: []
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LearningTrack.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.difficulty, decoded.difficulty)
    }
}
