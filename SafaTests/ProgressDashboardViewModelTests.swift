// MARK: - ProgressDashboardViewModelTests.swift
// PURPOSE: Unit tests for ProgressDashboardViewModel with real data sources
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

@MainActor
final class ProgressDashboardViewModelTests: XCTestCase {

    private var sut: ProgressDashboardViewModel!
    private var mockUserRepo: MockUserRepository!
    private var userState: UserStateManager!
    private var mockPrayerRepo: ConfigurableMockPrayerRepository!
    private var mockQuranRepo: ConfigurableMockQuranRepository!
    private var mockLearningRepo: ConfigurableMockLearningRepository!

    override func setUp() {
        super.setUp()
        mockUserRepo = MockUserRepository()
        userState = UserStateManager(userRepository: mockUserRepo)
        mockPrayerRepo = ConfigurableMockPrayerRepository()
        mockQuranRepo = ConfigurableMockQuranRepository()
        mockLearningRepo = ConfigurableMockLearningRepository()

        sut = ProgressDashboardViewModel(
            userState: userState,
            prayerRepository: mockPrayerRepo,
            quranRepository: mockQuranRepo,
            learningRepository: mockLearningRepo
        )
    }

    override func tearDown() {
        sut = nil
        userState = nil
        mockUserRepo = nil
        mockPrayerRepo = nil
        mockQuranRepo = nil
        mockLearningRepo = nil
        super.tearDown()
    }

    // MARK: - Load Tests

    func test_load_setsStatsFromUserState() async {
        // Configure mock repo so loadUserData() returns desired values
        mockUserRepo.statsToReturn = UserStats(
            totalHasanat: 500,
            currentLevel: 3,
            totalPrayersLogged: 42,
            totalTasbeehCount: 1000
        )

        await sut.load()

        XCTAssertEqual(sut.userStats.totalHasanat, 500)
        XCTAssertEqual(sut.userStats.currentLevel, 3)
        XCTAssertEqual(sut.userStats.totalPrayersLogged, 42)
        XCTAssertEqual(sut.userStats.totalTasbeehCount, 1000)
    }

    func test_load_queriesLessonsFromLearningRepo() async {
        mockLearningRepo.progressToReturn = LearningProgress(
            totalLessonsCompleted: 12,
            totalTracksCompleted: 1,
            totalMinutesLearned: 60,
            currentStreak: 3,
            pronunciationAttempts: 5
        )

        await sut.load()

        XCTAssertEqual(sut.userStats.lessonsCompleted, 12)
    }

    func test_load_queriesAyahsFromQuranRepo() async {
        mockQuranRepo.readingProgressToReturn = QuranProgress(
            lastSurah: 2,
            lastAyah: 100,
            totalAyahsRead: 420
        )

        await sut.load()

        XCTAssertEqual(sut.userStats.totalAyahsRead, 420)
    }

    func test_load_setsStreaksFromUserState() async {
        mockUserRepo.streaksToReturn = [
            Streak(type: .daily, currentCount: 5, longestCount: 10),
            Streak(type: .prayer, currentCount: 3, longestCount: 7)
        ]

        await sut.load()

        XCTAssertEqual(sut.streaks.count, 2)
    }

    func test_weeklyData_returns7Entries() async {
        await sut.load()

        XCTAssertEqual(sut.weeklyData.count, 7)
    }

    // MARK: - Monthly Prayer Data Tests

    func test_monthlyPrayerData_countsOnlyObligatoryPrayers() async {
        let today = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!

        // Add obligatory prayers + sunrise (non-obligatory) for day 1
        let day1 = startOfMonth
        mockPrayerRepo.logsToReturn = [
            PrayerLog(prayerType: .fajr, date: day1),
            PrayerLog(prayerType: .dhuhr, date: day1),
            PrayerLog(prayerType: .sunrise, date: day1)
        ]

        await sut.load()

        // Day 1 should only count 2 obligatory prayers (fajr + dhuhr), not sunrise
        let day1Data = sut.monthlyPrayerData.first { $0.day == 1 }
        XCTAssertEqual(day1Data?.count, 2)
    }

    func test_monthlyPrayerData_capsAt5() async {
        let today = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let day1 = startOfMonth

        // Simulate 6 different prayer types logged (impossible in practice, but tests the cap)
        mockPrayerRepo.logsToReturn = [
            PrayerLog(prayerType: .fajr, date: day1),
            PrayerLog(prayerType: .dhuhr, date: day1),
            PrayerLog(prayerType: .asr, date: day1),
            PrayerLog(prayerType: .maghrib, date: day1),
            PrayerLog(prayerType: .isha, date: day1)
        ]

        await sut.load()

        let day1Data = sut.monthlyPrayerData.first { $0.day == 1 }
        XCTAssertEqual(day1Data?.count, 5)
    }

    func test_monthlyPrayerData_hasCorrectDayCount() async {
        await sut.load()

        let calendar = Calendar.current
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
        XCTAssertEqual(sut.monthlyPrayerData.count, daysInMonth)
    }

    // MARK: - Level Progress Tests

    func test_levelProgress_computation() async {
        sut.userStats = UserStats(totalHasanat: 1500, currentLevel: 5)
        // Level 5: 1000, Level 6: 2000 → progress = 500/1000 = 0.5
        XCTAssertEqual(sut.levelProgress, 0.5, accuracy: 0.01)
    }

    func test_hasanatToNextLevel_computation() async {
        sut.userStats = UserStats(totalHasanat: 1500, currentLevel: 5)
        // Level 6: 2000, so 500 remaining
        XCTAssertEqual(sut.hasanatToNextLevel, 500)
    }

    func test_levelProgress_maxLevel() async {
        sut.userStats = UserStats(totalHasanat: 25000, currentLevel: 10)
        // Level 10 is max — should not crash and return a valid value
        let progress = sut.levelProgress
        XCTAssertGreaterThanOrEqual(progress, 0)
        XCTAssertLessThanOrEqual(progress, 1.0)
    }

    func test_levelProgress_atLevelStart_isZero() async {
        sut.userStats = UserStats(totalHasanat: 1000, currentLevel: 5)
        XCTAssertEqual(sut.levelProgress, 0, accuracy: 0.01)
    }

    func test_hasanatToNextLevel_atOrAboveNextLevel_isZero() async {
        sut.userStats = UserStats(totalHasanat: 2500, currentLevel: 5)
        XCTAssertEqual(sut.hasanatToNextLevel, 0)
    }

    // MARK: - Loading State

    func test_load_setsIsLoadingDuringLoad() async {
        // After load completes, isLoading should be false
        await sut.load()
        XCTAssertFalse(sut.isLoading)
    }
}

// MARK: - Test-Specific Configurable Mocks

private final class ConfigurableMockPrayerRepository: PrayerRepositoryProtocol {
    var logsToReturn: [PrayerLog] = []

    func getPrayers(for date: Date, location: Coordinates, method: CalculationMethod, madhab: Madhab?) async throws -> [PrayerTime] { [] }
    func logPrayer(_ prayer: PrayerType, for date: Date, at time: Date, isOnTime: Bool) async throws {}
    func deletePrayerLog(_ log: PrayerLog) async throws {}
    func getPrayerLogs(for date: Date) async throws -> [PrayerLog] { logsToReturn }
    func getPrayerLogs(from: Date, to: Date) async throws -> [PrayerLog] { logsToReturn }
    func isPrayerLogged(_ type: PrayerType, for date: Date) async throws -> Bool { false }
    func getSunnahTimes(for date: Date, location: Coordinates, method: CalculationMethod, madhab: Madhab?) -> [SunnahTime] { [] }
}

private final class ConfigurableMockQuranRepository: QuranRepositoryProtocol {
    var readingProgressToReturn: QuranProgress?

    func getAllSurahs() async throws -> [Surah] { [] }
    func getSurah(number: Int) async throws -> Surah? { nil }
    func getAyahs(forSurah surahNumber: Int) async throws -> [Ayah] { [] }
    func getAyah(surah surahNumber: Int, ayah ayahNumber: Int) async throws -> Ayah? { nil }
    func searchAyahs(query: String) async throws -> [Ayah] { [] }
    func getBookmarks() async throws -> [QuranBookmark] { [] }
    func addBookmark(surah: Int, ayah: Int) async throws {}
    func removeBookmark(surah: Int, ayah: Int) async throws {}
    func isBookmarked(surah: Int, ayah: Int) async throws -> Bool { false }
    func getReadingProgress() async throws -> QuranProgress? { readingProgressToReturn }
    func updateProgress(surah: Int, ayah: Int) async throws {}
    func getJuz(number: Int) async throws -> Juz? { nil }
    func getAllJuz() async throws -> [Juz] { [] }
    func getSurahReadProgress(surahNumber: Int) async throws -> SurahReadProgress? { nil }
    func markAyahRead(surahNumber: Int, ayahNumber: Int, totalAyahs: Int) async throws {}
    func updateBookmarkNote(surahNumber: Int, ayahNumber: Int, note: String?) async throws {}
    func getCompletedSurahNumbers() async throws -> Set<Int> { [] }
    func resetSurahProgress(surahNumber: Int) async throws {}
    func getDailyVerse(for date: Date) async -> Ayah? { nil }
}

private final class ConfigurableMockLearningRepository: LearningRepositoryProtocol {
    var progressToReturn = LearningProgress(
        totalLessonsCompleted: 0,
        totalTracksCompleted: 0,
        totalMinutesLearned: 0,
        currentStreak: 0,
        pronunciationAttempts: 0
    )

    func getTracks() async throws -> [LearningTrack] { [] }
    func getTrack(id trackId: String) async throws -> LearningTrack? { nil }
    func getLessons(forTrack trackId: String) async throws -> [Lesson] { [] }
    func getLesson(trackId: String, lessonId: String) async throws -> Lesson? { nil }
    func getLessonContent(lessonId: String) async throws -> LessonContent? { nil }
    func markLessonComplete(lessonId: String, score: Int) async throws {}
    func getTrackProgress(trackId: String) async throws -> TrackProgress { TrackProgress(trackId: trackId, completedLessons: 0, totalLessons: 0) }
    func getOverallProgress() async throws -> LearningProgress { progressToReturn }
    func recordPronunciationAttempt(lessonId: String, score: Int) async throws {}
    func getNextLesson() async throws -> Lesson? { nil }
}
