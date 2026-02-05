// MARK: - LearnViewModelTests.swift
// PURPOSE: Unit tests for LearnViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

@MainActor
final class LearnViewModelTests: XCTestCase {

    var sut: LearnViewModel!
    var mockRepository: TestableLearningRepository!
    var mockUserState: UserStateManager!

    override func setUp() {
        super.setUp()
        mockRepository = TestableLearningRepository()
        mockUserState = UserStateManager(userRepository: MockUserRepository())
        sut = LearnViewModel(learningRepository: mockRepository, userState: mockUserState)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        mockUserState = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasEmptyTracks() {
        XCTAssertTrue(sut.tracks.isEmpty)
    }

    func test_initialState_hasEmptyLessonsByTrack() {
        XCTAssertTrue(sut.lessonsByTrack.isEmpty)
    }

    func test_initialState_hasEmptyTrackProgress() {
        XCTAssertTrue(sut.trackProgress.isEmpty)
    }

    func test_initialState_hasZeroOverallProgress() {
        XCTAssertEqual(sut.overallProgress.totalLessonsCompleted, 0)
        XCTAssertEqual(sut.overallProgress.totalTracksCompleted, 0)
    }

    func test_initialState_hasNoNextLesson() {
        XCTAssertNil(sut.nextLesson)
    }

    func test_initialState_hasNoSelectedTrack() {
        XCTAssertNil(sut.selectedTrack)
    }

    func test_initialState_hasNoSelectedLesson() {
        XCTAssertNil(sut.selectedLesson)
    }

    func test_initialState_isNotLoading() {
        XCTAssertFalse(sut.isLoading)
    }

    func test_initialState_hasNoError() {
        XCTAssertNil(sut.error)
    }

    // MARK: - Load Tracks Tests

    func test_loadTracks_populatesTracks() async {
        // Given
        let expectedTracks = [
            LearningTrack(
                id: "arabic",
                titleEnglish: "Arabic Foundations",
                titleArabic: "أساسيات العربية",
                description: "Learn Arabic alphabet",
                iconName: "textformat",
                lessonCount: 10,
                estimatedMinutes: 60
            )
        ]
        mockRepository.tracksToReturn = expectedTracks

        // When
        await sut.loadTracks()

        // Then
        XCTAssertEqual(sut.tracks.count, 1)
        XCTAssertEqual(sut.tracks.first?.titleEnglish, "Arabic Foundations")
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadTracks_doesNotReloadIfAlreadyLoaded() async {
        // Given
        mockRepository.tracksToReturn = [
            LearningTrack(
                id: "arabic",
                titleEnglish: "Arabic",
                titleArabic: nil,
                description: "Test",
                iconName: "a",
                lessonCount: 5,
                estimatedMinutes: 30
            )
        ]
        await sut.loadTracks()
        let callCount = mockRepository.getTracksCallCount

        // When
        await sut.loadTracks()

        // Then
        XCTAssertEqual(mockRepository.getTracksCallCount, callCount)
    }

    func test_loadTracks_loadsOverallProgress() async {
        // Given
        mockRepository.tracksToReturn = []
        mockRepository.overallProgressToReturn = LearningProgress(
            totalLessonsCompleted: 5,
            totalTracksCompleted: 1,
            totalMinutesLearned: 60,
            currentStreak: 3,
            pronunciationAttempts: 10,
            averagePronunciationScore: 85.0
        )

        // When
        await sut.loadTracks()

        // Then
        XCTAssertEqual(sut.overallProgress.totalLessonsCompleted, 5)
        XCTAssertEqual(sut.overallProgress.totalTracksCompleted, 1)
    }

    func test_loadTracks_loadsNextLesson() async {
        // Given
        let nextLesson = Lesson(
            id: "lesson1",
            trackId: "arabic",
            order: 1,
            titleEnglish: "Letter Alif",
            durationMinutes: 5,
            type: .reading
        )
        mockRepository.nextLessonToReturn = nextLesson

        // When
        await sut.loadTracks()

        // Then
        XCTAssertNotNil(sut.nextLesson)
        XCTAssertEqual(sut.nextLesson?.titleEnglish, "Letter Alif")
    }

    func test_loadTracks_failure_setsError() async {
        // Given
        mockRepository.errorToThrow = TestError.loadFailed

        // When
        await sut.loadTracks()

        // Then
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Load Lessons Tests

    func test_loadLessons_populatesLessonsByTrack() async {
        // Given
        let lessons = [
            Lesson(id: "l1", trackId: "arabic", order: 1, titleEnglish: "Lesson 1", durationMinutes: 5, type: .reading),
            Lesson(id: "l2", trackId: "arabic", order: 2, titleEnglish: "Lesson 2", durationMinutes: 5, type: .listening)
        ]
        mockRepository.lessonsToReturn = lessons

        // When
        await sut.loadLessons(for: "arabic")

        // Then
        XCTAssertEqual(sut.lessonsByTrack["arabic"]?.count, 2)
    }

    func test_loadLessons_doesNotReloadIfAlreadyLoaded() async {
        // Given
        mockRepository.lessonsToReturn = [
            Lesson(id: "l1", trackId: "arabic", order: 1, titleEnglish: "Lesson 1", durationMinutes: 5, type: .reading)
        ]
        await sut.loadLessons(for: "arabic")
        let callCount = mockRepository.getLessonsCallCount

        // When
        await sut.loadLessons(for: "arabic")

        // Then
        XCTAssertEqual(mockRepository.getLessonsCallCount, callCount)
    }

    // MARK: - Get Progress Tests

    func test_getProgress_returnsProgressForTrack() async {
        // Given
        mockRepository.tracksToReturn = [
            LearningTrack(id: "arabic", titleEnglish: "Arabic", titleArabic: nil, description: "", iconName: "a", lessonCount: 10, estimatedMinutes: 60)
        ]
        mockRepository.trackProgressToReturn = TrackProgress(trackId: "arabic", completedLessons: 3, totalLessons: 10)
        await sut.loadTracks()

        // When
        let progress = sut.getProgress(for: "arabic")

        // Then
        XCTAssertEqual(progress.completedLessons, 3)
        XCTAssertEqual(progress.totalLessons, 10)
    }

    func test_getProgress_returnsDefaultWhenNotLoaded() {
        // When
        let progress = sut.getProgress(for: "unknown")

        // Then
        XCTAssertEqual(progress.completedLessons, 0)
    }

    // MARK: - Get Lessons Tests

    func test_getLessons_returnsLessonsForTrack() async {
        // Given
        mockRepository.lessonsToReturn = [
            Lesson(id: "l1", trackId: "arabic", order: 1, titleEnglish: "Lesson 1", durationMinutes: 5, type: .reading)
        ]
        await sut.loadLessons(for: "arabic")

        // When
        let lessons = sut.getLessons(for: "arabic")

        // Then
        XCTAssertEqual(lessons.count, 1)
    }

    func test_getLessons_returnsEmptyWhenNotLoaded() {
        // When
        let lessons = sut.getLessons(for: "unknown")

        // Then
        XCTAssertTrue(lessons.isEmpty)
    }

    // MARK: - Start Lesson Tests

    func test_startLesson_setsSelectedLesson() {
        // Given
        let lesson = Lesson(id: "l1", trackId: "arabic", order: 1, titleEnglish: "Test Lesson", durationMinutes: 5, type: .reading)

        // When
        sut.startLesson(lesson)

        // Then
        XCTAssertEqual(sut.selectedLesson?.id, "l1")
    }

    // MARK: - Complete Lesson Tests

    func test_completeLesson_updatesLessonState() async {
        // Given
        let lesson = Lesson(id: "l1", trackId: "arabic", order: 1, titleEnglish: "Test", durationMinutes: 5, type: .reading, isCompleted: false)
        sut.lessonsByTrack["arabic"] = [lesson]
        mockRepository.trackProgressToReturn = TrackProgress(trackId: "arabic", completedLessons: 1, totalLessons: 10)
        mockRepository.overallProgressToReturn = LearningProgress(
            totalLessonsCompleted: 1,
            totalTracksCompleted: 0,
            totalMinutesLearned: 5,
            currentStreak: 1,
            pronunciationAttempts: 0,
            averagePronunciationScore: nil
        )

        // When
        await sut.completeLesson(lesson, score: 85)

        // Then - lesson should be marked complete
        XCTAssertTrue(sut.lessonsByTrack["arabic"]?.first?.isCompleted == true)
        XCTAssertEqual(sut.lessonsByTrack["arabic"]?.first?.bestScore, 85)
    }

    func test_completeLesson_updatesTrackProgress() async {
        // Given
        let lesson = Lesson(id: "l1", trackId: "arabic", order: 1, titleEnglish: "Test", durationMinutes: 5, type: .reading)
        sut.lessonsByTrack["arabic"] = [lesson]
        mockRepository.trackProgressToReturn = TrackProgress(trackId: "arabic", completedLessons: 5, totalLessons: 10)
        mockRepository.overallProgressToReturn = LearningProgress(
            totalLessonsCompleted: 5,
            totalTracksCompleted: 0,
            totalMinutesLearned: 25,
            currentStreak: 1,
            pronunciationAttempts: 0,
            averagePronunciationScore: nil
        )

        // When
        await sut.completeLesson(lesson, score: 90)

        // Then
        XCTAssertEqual(sut.trackProgress["arabic"]?.completedLessons, 5)
    }

    func test_completeLesson_failure_setsError() async {
        // Given
        let lesson = Lesson(id: "l1", trackId: "arabic", order: 1, titleEnglish: "Test", durationMinutes: 5, type: .reading)
        mockRepository.errorToThrow = TestError.completeFailed

        // When
        await sut.completeLesson(lesson, score: 85)

        // Then
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Record Pronunciation Tests

    func test_recordPronunciation_callsRepository() async {
        // Given - no error

        // When
        await sut.recordPronunciation(lessonId: "l1", score: 75)

        // Then
        XCTAssertTrue(mockRepository.recordPronunciationCalled)
    }

    func test_recordPronunciation_failure_setsError() async {
        // Given
        mockRepository.errorToThrow = TestError.recordFailed

        // When
        await sut.recordPronunciation(lessonId: "l1", score: 75)

        // Then
        XCTAssertNotNil(sut.error)
    }
}

// MARK: - Test Error

private enum TestError: Error {
    case loadFailed
    case completeFailed
    case recordFailed
}

// MARK: - Testable Learning Repository

@MainActor
final class TestableLearningRepository: LearningRepositoryProtocol {
    var tracksToReturn: [LearningTrack] = []
    var lessonsToReturn: [Lesson] = []
    var trackProgressToReturn: TrackProgress?
    var overallProgressToReturn: LearningProgress?
    var nextLessonToReturn: Lesson?
    var errorToThrow: Error?

    var getTracksCallCount = 0
    var getLessonsCallCount = 0
    var recordPronunciationCalled = false

    nonisolated func getTracks() async throws -> [LearningTrack] {
        let error = await errorToThrow
        if let error {
            throw error
        }
        await MainActor.run { getTracksCallCount += 1 }
        return await tracksToReturn
    }

    nonisolated func getTrack(id trackId: String) async throws -> LearningTrack? {
        return await tracksToReturn.first { $0.id == trackId }
    }

    nonisolated func getLessons(forTrack trackId: String) async throws -> [Lesson] {
        let error = await errorToThrow
        if let error {
            throw error
        }
        await MainActor.run { getLessonsCallCount += 1 }
        return await lessonsToReturn
    }

    nonisolated func getLesson(trackId: String, lessonId: String) async throws -> Lesson? {
        return await lessonsToReturn.first { $0.id == lessonId }
    }

    nonisolated func getLessonContent(lessonId: String) async throws -> LessonContent? {
        return nil
    }

    nonisolated func markLessonComplete(lessonId: String, score: Int) async throws {
        let error = await errorToThrow
        if let error {
            throw error
        }
    }

    nonisolated func getTrackProgress(trackId: String) async throws -> TrackProgress {
        let progress = await trackProgressToReturn
        return progress ?? TrackProgress(trackId: trackId, completedLessons: 0, totalLessons: 0)
    }

    nonisolated func getOverallProgress() async throws -> LearningProgress {
        let progress = await overallProgressToReturn
        return progress ?? LearningProgress(
            totalLessonsCompleted: 0,
            totalTracksCompleted: 0,
            totalMinutesLearned: 0,
            currentStreak: 0,
            pronunciationAttempts: 0,
            averagePronunciationScore: nil
        )
    }

    nonisolated func recordPronunciationAttempt(lessonId: String, score: Int) async throws {
        let error = await errorToThrow
        if let error {
            throw error
        }
        await MainActor.run { recordPronunciationCalled = true }
    }

    nonisolated func getNextLesson() async throws -> Lesson? {
        return await nextLessonToReturn
    }
}

// MARK: - Mock User Repository

@MainActor
final class MockUserRepository: UserRepositoryProtocol {
    nonisolated func getUserStats() async throws -> UserStats {
        return UserStats()
    }

    nonisolated func updateUserStats(_ stats: UserStats) async throws {}

    nonisolated func addHasanat(_ amount: Int) async throws -> Int {
        return amount
    }

    nonisolated func getStreaks() async throws -> [Streak] {
        return StreakType.allCases.map { Streak(type: $0) }
    }

    nonisolated func getStreak(type: StreakType) async throws -> Streak? {
        return Streak(type: type)
    }

    nonisolated func updateStreak(_ streak: Streak) async throws {}

    nonisolated func recordStreakActivity(type: StreakType) async throws {}

    nonisolated func getAchievements() async throws -> [Achievement] {
        return []
    }

    nonisolated func unlockAchievement(_ achievementId: String) async throws {}

    nonisolated func isAchievementUnlocked(_ achievementId: String) async throws -> Bool {
        return false
    }

    nonisolated func getPreference<T: Codable>(key: String) async throws -> T? {
        return nil
    }

    nonisolated func setPreference<T: Codable>(key: String, value: T) async throws {}

    nonisolated func getPreferences() async -> UserPreferences {
        return UserPreferences()
    }

    nonisolated func updatePreferences(_ preferences: UserPreferences) async throws {}

    nonisolated func getStreakFreezes() async throws -> Int {
        return 0
    }

    nonisolated func useStreakFreeze() async throws {}

    nonisolated func awardStreakFreeze() async throws {}
}
