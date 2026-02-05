// MARK: - LearningRepositoryTests.swift
// PURPOSE: Unit tests for learning repository functionality
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class LearningRepositoryTests: XCTestCase {

    var sut: LearningRepository!
    var mockCoreData: CoreDataStack!

    override func setUp() {
        super.setUp()
        mockCoreData = CoreDataStack.shared
        sut = LearningRepository(coreData: mockCoreData)

        // Clear any existing progress
        UserDefaults.standard.removeObject(forKey: "com.safa.learning.progress")
        UserDefaults.standard.removeObject(forKey: "com.safa.learning.completed")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "com.safa.learning.progress")
        UserDefaults.standard.removeObject(forKey: "com.safa.learning.completed")
        sut = nil
        mockCoreData = nil
        super.tearDown()
    }

    // MARK: - Track Tests

    func testGetTracksReturnsAllTracks() async throws {
        let tracks = try await sut.getTracks()

        XCTAssertFalse(tracks.isEmpty)
        XCTAssertTrue(tracks.count >= 4, "Should have at least 4 learning tracks")
    }

    func testGetTrackByIdReturnsCorrectTrack() async throws {
        let track = try await sut.getTrack(id: "arabic_foundations")

        XCTAssertNotNil(track)
        XCTAssertEqual(track?.id, "arabic_foundations")
    }

    func testGetTrackByIdReturnsNilForInvalidId() async throws {
        let track = try await sut.getTrack(id: "nonexistent")

        XCTAssertNil(track)
    }

    // MARK: - Lesson Tests

    func testGetLessonsForArabicTrack() async throws {
        let lessons = try await sut.getLessons(forTrack: "arabic_foundations")

        XCTAssertFalse(lessons.isEmpty)
        XCTAssertTrue(lessons.allSatisfy { $0.trackId == "arabic_foundations" })
    }

    func testGetLessonsForTajweedTrack() async throws {
        let lessons = try await sut.getLessons(forTrack: "tajweed")

        XCTAssertFalse(lessons.isEmpty)
        XCTAssertTrue(lessons.allSatisfy { $0.trackId == "tajweed" })
    }

    func testGetLessonsForInvalidTrackReturnsEmpty() async throws {
        let lessons = try await sut.getLessons(forTrack: "nonexistent")

        XCTAssertTrue(lessons.isEmpty)
    }

    func testGetLessonByIdReturnsCorrectLesson() async throws {
        let lesson = try await sut.getLesson(trackId: "arabic_foundations", lessonId: "arabic_1")

        XCTAssertNotNil(lesson)
        XCTAssertEqual(lesson?.id, "arabic_1")
        XCTAssertEqual(lesson?.titleEnglish, "Alif - ا")
    }

    func testGetLessonContentReturnsContent() async throws {
        let content = try await sut.getLessonContent(lessonId: "arabic_1")

        XCTAssertNotNil(content)
        XCTAssertEqual(content?.lessonId, "arabic_1")
        XCTAssertFalse(content?.sections.isEmpty ?? true)
    }

    // MARK: - Completion Tests

    func testMarkLessonCompleteUpdatesProgress() async throws {
        let lessonId = "arabic_1"

        try await sut.markLessonComplete(lessonId: lessonId, score: 85)

        let lessons = try await sut.getLessons(forTrack: "arabic_foundations")
        let completedLesson = lessons.first { $0.id == lessonId }

        XCTAssertTrue(completedLesson?.isCompleted ?? false)
    }

    func testMarkLessonCompleteIncrementsProgressCount() async throws {
        let initialProgress = try await sut.getOverallProgress()
        let initialCount = initialProgress.totalLessonsCompleted

        try await sut.markLessonComplete(lessonId: "arabic_1", score: 90)

        let updatedProgress = try await sut.getOverallProgress()
        XCTAssertEqual(updatedProgress.totalLessonsCompleted, initialCount + 1)
    }

    func testMarkSameLessonCompleteTwiceDoesNotDoubleCount() async throws {
        try await sut.markLessonComplete(lessonId: "arabic_1", score: 85)
        let progressAfterFirst = try await sut.getOverallProgress()

        try await sut.markLessonComplete(lessonId: "arabic_1", score: 90)
        let progressAfterSecond = try await sut.getOverallProgress()

        XCTAssertEqual(progressAfterFirst.totalLessonsCompleted, progressAfterSecond.totalLessonsCompleted)
    }

    // MARK: - Progress Tests

    func testGetTrackProgressReturnsCorrectData() async throws {
        try await sut.markLessonComplete(lessonId: "arabic_1", score: 80)
        try await sut.markLessonComplete(lessonId: "arabic_2", score: 90)

        let progress = try await sut.getTrackProgress(trackId: "arabic_foundations")

        XCTAssertEqual(progress.trackId, "arabic_foundations")
        XCTAssertEqual(progress.completedLessons, 2)
        XCTAssertGreaterThan(progress.totalLessons, 0)
    }

    func testGetOverallProgressInitialState() async throws {
        let progress = try await sut.getOverallProgress()

        XCTAssertEqual(progress.totalLessonsCompleted, 0)
        XCTAssertEqual(progress.totalTracksCompleted, 0)
        XCTAssertEqual(progress.pronunciationAttempts, 0)
    }

    // MARK: - Pronunciation Tests

    func testRecordPronunciationAttemptUpdatesCount() async throws {
        let initialProgress = try await sut.getOverallProgress()
        let initialAttempts = initialProgress.pronunciationAttempts

        try await sut.recordPronunciationAttempt(lessonId: "arabic_1", score: 75)

        let updatedProgress = try await sut.getOverallProgress()
        XCTAssertEqual(updatedProgress.pronunciationAttempts, initialAttempts + 1)
    }

    func testRecordPronunciationAttemptUpdatesAverageScore() async throws {
        try await sut.recordPronunciationAttempt(lessonId: "arabic_1", score: 80)
        try await sut.recordPronunciationAttempt(lessonId: "arabic_1", score: 90)

        let progress = try await sut.getOverallProgress()

        XCTAssertNotNil(progress.averagePronunciationScore)
        XCTAssertEqual(progress.averagePronunciationScore!, 85.0, accuracy: 0.1)
    }

    // MARK: - Next Lesson Tests

    func testGetNextLessonReturnsFirstIncomplete() async throws {
        let nextLesson = try await sut.getNextLesson()

        XCTAssertNotNil(nextLesson)
        XCTAssertFalse(nextLesson?.isCompleted ?? true)
    }

    func testGetNextLessonSkipsCompletedLessons() async throws {
        try await sut.markLessonComplete(lessonId: "arabic_1", score: 100)

        let nextLesson = try await sut.getNextLesson()

        XCTAssertNotNil(nextLesson)
        XCTAssertNotEqual(nextLesson?.id, "arabic_1")
    }
}

// MARK: - Learning Track Tests

final class LearningTrackTests: XCTestCase {

    func testAllTracksExist() {
        let tracks = LearningTrack.allTracks

        XCTAssertTrue(tracks.contains { $0.id == "arabic_foundations" })
        XCTAssertTrue(tracks.contains { $0.id == "tajweed" })
    }

    func testTrackHasRequiredFields() {
        for track in LearningTrack.allTracks {
            XCTAssertFalse(track.id.isEmpty)
            XCTAssertFalse(track.titleEnglish.isEmpty)
            XCTAssertFalse(track.descriptionText.isEmpty)
            XCTAssertFalse(track.iconName.isEmpty)
        }
    }

    func testTrackDifficultyLevels() {
        let tracks = LearningTrack.allTracks

        XCTAssertTrue(tracks.contains { $0.difficulty == .beginner })
    }
}

// MARK: - Lesson Tests

final class LessonTests: XCTestCase {

    func testArabicLessonsExist() {
        let lessons = Lesson.arabicFoundationsLessons

        XCTAssertFalse(lessons.isEmpty)
        XCTAssertTrue(lessons.count >= 8)
    }

    func testTajweedLessonsExist() {
        let lessons = Lesson.tajweedLessons

        XCTAssertFalse(lessons.isEmpty)
        XCTAssertTrue(lessons.count >= 5)
    }

    func testLessonsHaveCorrectOrder() {
        let lessons = Lesson.arabicFoundationsLessons

        for (index, lesson) in lessons.enumerated() {
            XCTAssertEqual(lesson.order, index + 1)
        }
    }

    func testLessonsHaveValidTypes() {
        let allLessons = Lesson.arabicFoundationsLessons + Lesson.tajweedLessons

        for lesson in allLessons {
            XCTAssertNotNil(lesson.type)
        }
    }
}

// MARK: - Lesson Content Tests

final class LessonContentTests: XCTestCase {

    func testSampleContentExists() {
        let content = LessonContent.sampleContent

        XCTAssertFalse(content.isEmpty)
    }

    func testArabicOneContent() {
        guard let content = LessonContent.sampleContent["arabic_1"] else {
            XCTFail("Arabic 1 content should exist")
            return
        }

        XCTAssertEqual(content.lessonId, "arabic_1")
        XCTAssertFalse(content.sections.isEmpty)
    }

    func testContentSectionsHaveValidTypes() {
        for (_, content) in LessonContent.sampleContent {
            for section in content.sections {
                XCTAssertFalse(section.id.isEmpty)
            }
        }
    }
}
