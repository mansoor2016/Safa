// MARK: - LearningModelTests.swift
// PURPOSE: Unit tests for Learning domain entities

import XCTest
@testable import Safa

final class LearningModelTests: XCTestCase {

    // MARK: - LearningTrack Tests

    func testLearningTrackCreation() {
        let track = LearningTrack(
            id: "test_track",
            titleEnglish: "Test Track",
            titleArabic: "مسار اختبار",
            description: "A test learning track",
            iconName: "star",
            lessonCount: 10,
            estimatedMinutes: 60
        )

        XCTAssertEqual(track.id, "test_track")
        XCTAssertEqual(track.titleEnglish, "Test Track")
        XCTAssertEqual(track.titleArabic, "مسار اختبار")
        XCTAssertEqual(track.description, "A test learning track")
        XCTAssertEqual(track.iconName, "star")
        XCTAssertEqual(track.lessonCount, 10)
        XCTAssertEqual(track.estimatedMinutes, 60)
    }

    func testStaticArabicFoundationsTrack() {
        let track = LearningTrack.arabicFoundations

        XCTAssertEqual(track.id, "arabic_foundations")
        XCTAssertEqual(track.titleEnglish, "Arabic Foundations")
        XCTAssertEqual(track.lessonCount, 28) // 28 Arabic letters
        XCTAssertEqual(track.estimatedMinutes, 120)
    }

    func testStaticTajweedTrack() {
        let track = LearningTrack.tajweed

        XCTAssertEqual(track.id, "tajweed")
        XCTAssertEqual(track.titleEnglish, "Tajweed Rules")
        XCTAssertEqual(track.lessonCount, 20)
    }

    func testStaticQuranRecitationTrack() {
        let track = LearningTrack.quranRecitation

        XCTAssertEqual(track.id, "quran_recitation")
        XCTAssertEqual(track.lessonCount, 30)
    }

    func testStaticDhikrMasteryTrack() {
        let track = LearningTrack.dhikrMastery

        XCTAssertEqual(track.id, "dhikr_mastery")
        XCTAssertEqual(track.lessonCount, 15)
    }

    func testAllTracksContainsFourTracks() {
        XCTAssertEqual(LearningTrack.allTracks.count, 4)
        XCTAssertTrue(LearningTrack.allTracks.contains { $0.id == "arabic_foundations" })
        XCTAssertTrue(LearningTrack.allTracks.contains { $0.id == "tajweed" })
        XCTAssertTrue(LearningTrack.allTracks.contains { $0.id == "quran_recitation" })
        XCTAssertTrue(LearningTrack.allTracks.contains { $0.id == "dhikr_mastery" })
    }

    // MARK: - Lesson Tests

    func testLessonCreation() {
        let lesson = Lesson(
            id: "lesson1",
            trackId: "arabic_foundations",
            order: 1,
            titleEnglish: "Letter Alif",
            durationMinutes: 5,
            type: .reading
        )

        XCTAssertEqual(lesson.id, "lesson1")
        XCTAssertEqual(lesson.trackId, "arabic_foundations")
        XCTAssertEqual(lesson.order, 1)
        XCTAssertEqual(lesson.titleEnglish, "Letter Alif")
        XCTAssertEqual(lesson.durationMinutes, 5)
        XCTAssertEqual(lesson.type, .reading)
        XCTAssertFalse(lesson.isCompleted)
        XCTAssertNil(lesson.bestScore)
        XCTAssertTrue(lesson.content.isEmpty)
    }

    func testLessonWithAllParameters() {
        let steps = [
            LessonStep(type: .reading, title: "Step 1"),
            LessonStep(type: .listening, arabicText: "أ")
        ]

        let lesson = Lesson(
            id: "lesson2",
            trackId: "arabic_foundations",
            order: 2,
            titleEnglish: "Letter Ba",
            titleArabic: "حرف الباء",
            description: "Learn the letter Ba",
            durationMinutes: 10,
            type: .practice,
            isCompleted: true,
            bestScore: 95,
            content: steps
        )

        XCTAssertEqual(lesson.titleArabic, "حرف الباء")
        XCTAssertEqual(lesson.description, "Learn the letter Ba")
        XCTAssertTrue(lesson.isCompleted)
        XCTAssertEqual(lesson.bestScore, 95)
        XCTAssertEqual(lesson.content.count, 2)
    }

    func testLessonTypes() {
        XCTAssertEqual(Lesson.LessonType.reading.rawValue, "reading")
        XCTAssertEqual(Lesson.LessonType.listening.rawValue, "listening")
        XCTAssertEqual(Lesson.LessonType.quiz.rawValue, "quiz")
        XCTAssertEqual(Lesson.LessonType.practice.rawValue, "practice")
    }

    // MARK: - LessonStep Tests

    func testLessonStepCreation() {
        let step = LessonStep(
            type: .reading,
            title: "Introduction",
            body: "Learn the basics"
        )

        XCTAssertEqual(step.type, .reading)
        XCTAssertEqual(step.title, "Introduction")
        XCTAssertEqual(step.body, "Learn the basics")
    }

    func testLessonStepWithArabicContent() {
        let step = LessonStep(
            type: .listening,
            arabicText: "بِسْمِ اللَّهِ",
            transliteration: "Bismillah",
            audioFileName: "bismillah.mp3"
        )

        XCTAssertEqual(step.arabicText, "بِسْمِ اللَّهِ")
        XCTAssertEqual(step.transliteration, "Bismillah")
        XCTAssertEqual(step.audioFileName, "bismillah.mp3")
    }

    func testLessonStepQuiz() {
        let step = LessonStep(
            type: .quiz,
            options: ["A", "B", "C"],
            correctAnswer: "B",
            explanation: "B is correct because..."
        )

        XCTAssertEqual(step.type, .quiz)
        XCTAssertEqual(step.options, ["A", "B", "C"])
        XCTAssertEqual(step.correctAnswer, "B")
        XCTAssertEqual(step.explanation, "B is correct because...")
    }

    func testLessonStepTypes() {
        XCTAssertEqual(LessonStep.StepType.reading.rawValue, "reading")
        XCTAssertEqual(LessonStep.StepType.listening.rawValue, "listening")
        XCTAssertEqual(LessonStep.StepType.quiz.rawValue, "quiz")
        XCTAssertEqual(LessonStep.StepType.exercise.rawValue, "exercise")
    }

    // MARK: - TrackProgress Tests

    func testTrackProgressCreation() {
        let progress = TrackProgress(
            trackId: "arabic_foundations",
            completedLessons: 5,
            totalLessons: 28
        )

        XCTAssertEqual(progress.trackId, "arabic_foundations")
        XCTAssertEqual(progress.completedLessons, 5)
        XCTAssertEqual(progress.totalLessons, 28)
        XCTAssertNil(progress.averageScore)
        XCTAssertNil(progress.lastLessonId)
        XCTAssertNil(progress.lastActivityDate)
    }

    func testTrackProgressCompletionPercentage() {
        let progress = TrackProgress(
            trackId: "test",
            completedLessons: 10,
            totalLessons: 20
        )

        XCTAssertEqual(progress.completionPercentage, 50.0, accuracy: 0.001)
    }

    func testTrackProgressCompletionPercentageZero() {
        let progress = TrackProgress(
            trackId: "test",
            completedLessons: 0,
            totalLessons: 10
        )

        XCTAssertEqual(progress.completionPercentage, 0.0, accuracy: 0.001)
    }

    func testTrackProgressCompletionPercentageFull() {
        let progress = TrackProgress(
            trackId: "test",
            completedLessons: 10,
            totalLessons: 10
        )

        XCTAssertEqual(progress.completionPercentage, 100.0, accuracy: 0.001)
    }

    func testTrackProgressCompletionPercentageNoLessons() {
        let progress = TrackProgress(
            trackId: "test",
            completedLessons: 0,
            totalLessons: 0
        )

        XCTAssertEqual(progress.completionPercentage, 0.0, accuracy: 0.001)
    }

    func testTrackProgressIsComplete() {
        var progress = TrackProgress(
            trackId: "test",
            completedLessons: 9,
            totalLessons: 10
        )

        XCTAssertFalse(progress.isComplete)

        progress.completedLessons = 10
        XCTAssertTrue(progress.isComplete)

        progress.completedLessons = 15 // More than total
        XCTAssertTrue(progress.isComplete)
    }

    // MARK: - LearningProgress Tests

    func testLearningProgressCreation() {
        let progress = LearningProgress(
            totalLessonsCompleted: 50,
            totalTracksCompleted: 2,
            totalMinutesLearned: 300,
            currentStreak: 7
        )

        XCTAssertEqual(progress.totalLessonsCompleted, 50)
        XCTAssertEqual(progress.totalTracksCompleted, 2)
        XCTAssertEqual(progress.totalMinutesLearned, 300)
        XCTAssertEqual(progress.currentStreak, 7)
    }

    // MARK: - Codable Tests

    func testLearningTrackCodable() throws {
        let track = LearningTrack.arabicFoundations

        let encoder = JSONEncoder()
        let data = try encoder.encode(track)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LearningTrack.self, from: data)

        XCTAssertEqual(decoded.id, track.id)
        XCTAssertEqual(decoded.titleEnglish, track.titleEnglish)
        XCTAssertEqual(decoded.lessonCount, track.lessonCount)
    }

    func testLessonCodable() throws {
        let lesson = Lesson(
            id: "test",
            trackId: "arabic",
            order: 1,
            titleEnglish: "Test Lesson",
            durationMinutes: 5,
            type: .reading
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(lesson)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Lesson.self, from: data)

        XCTAssertEqual(decoded.id, lesson.id)
        XCTAssertEqual(decoded.type, lesson.type)
    }

    func testTrackProgressCodable() throws {
        let progress = TrackProgress(
            trackId: "test",
            completedLessons: 5,
            totalLessons: 10
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(progress)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TrackProgress.self, from: data)

        XCTAssertEqual(decoded.trackId, progress.trackId)
        XCTAssertEqual(decoded.completedLessons, progress.completedLessons)
    }
}
