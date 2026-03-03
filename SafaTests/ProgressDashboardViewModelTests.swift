// MARK: - ProgressDashboardViewModelTests.swift
// PURPOSE: Unit tests for ProgressDashboardViewModel — prayer consistency focus
// DEPENDENCIES: XCTest, Safa

import XCTest
import CoreLocation
@testable import Safa

@MainActor
final class ProgressDashboardViewModelTests: XCTestCase {

    private var sut: ProgressDashboardViewModel!
    private var mockUserRepo: MockUserRepository!
    private var userState: UserStateManager!
    private var mockPrayerRepo: ConfigurableMockPrayerRepository!
    private var mockQuranRepo: ConfigurableMockQuranRepository!
    private var mockLearningRepo: ConfigurableMockLearningRepository!
    private var mockLocationService: MockLocationService!
    private var fixedDate: Date!
    private var fixedCalendar: Calendar!

    override func setUp() {
        super.setUp()
        mockUserRepo = MockUserRepository()
        userState = UserStateManager(userRepository: mockUserRepo)
        mockPrayerRepo = ConfigurableMockPrayerRepository()
        mockQuranRepo = ConfigurableMockQuranRepository()
        mockLearningRepo = ConfigurableMockLearningRepository()
        mockLocationService = MockLocationService()

        // Fixed date: Wednesday Feb 19, 2025 at 14:00
        fixedCalendar = Calendar(identifier: .gregorian)
        fixedCalendar.firstWeekday = 2 // Monday start
        fixedCalendar.timeZone = TimeZone(identifier: "UTC")!

        var components = DateComponents()
        components.year = 2025
        components.month = 2
        components.day = 19
        components.hour = 14
        components.minute = 0
        fixedDate = fixedCalendar.date(from: components)!

        sut = makeViewModel()
    }

    override func tearDown() {
        sut = nil
        userState = nil
        mockUserRepo = nil
        mockPrayerRepo = nil
        mockQuranRepo = nil
        mockLearningRepo = nil
        mockLocationService = nil
        fixedDate = nil
        fixedCalendar = nil
        super.tearDown()
    }

    private func makeViewModel(
        now: Date? = nil,
        calendar: Calendar? = nil,
        locationService: MockLocationService? = nil
    ) -> ProgressDashboardViewModel {
        ProgressDashboardViewModel(
            userState: userState,
            prayerRepository: mockPrayerRepo,
            quranRepository: mockQuranRepo,
            learningRepository: mockLearningRepo,
            locationService: locationService ?? mockLocationService,
            preferencesManager: nil,
            now: { now ?? self.fixedDate },
            calendar: calendar ?? fixedCalendar
        )
    }

    // MARK: - Preserved Tests: Load

    func test_load_setsStatsFromUserState() async {
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
            currentStreak: 3
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

    // MARK: - Preserved Tests: Monthly Prayer Data

    func test_monthlyPrayerData_countsOnlyObligatoryPrayers() async {
        let startOfMonth = fixedCalendar.date(from: fixedCalendar.dateComponents([.year, .month], from: fixedDate))!
        let day1 = startOfMonth

        mockPrayerRepo.logsToReturn = [
            PrayerLog(prayerType: .fajr, date: day1),
            PrayerLog(prayerType: .dhuhr, date: day1),
            PrayerLog(prayerType: .sunrise, date: day1)
        ]

        await sut.load()

        let day1Data = sut.monthlyPrayerData.first { $0.day == 1 }
        XCTAssertEqual(day1Data?.count, 2)
    }

    func test_monthlyPrayerData_capsAt5() async {
        let startOfMonth = fixedCalendar.date(from: fixedCalendar.dateComponents([.year, .month], from: fixedDate))!
        let day1 = startOfMonth

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

        let daysInMonth = fixedCalendar.range(of: .day, in: .month, for: fixedDate)?.count ?? 30
        XCTAssertEqual(sut.monthlyPrayerData.count, daysInMonth)
    }

    // MARK: - Preserved Tests: Level Progress

    func test_levelProgress_computation() async {
        sut.userStats = UserStats(totalHasanat: 1500, currentLevel: 5)
        XCTAssertEqual(sut.levelProgress, 0.5, accuracy: 0.01)
    }

    func test_hasanatToNextLevel_computation() async {
        sut.userStats = UserStats(totalHasanat: 1500, currentLevel: 5)
        XCTAssertEqual(sut.hasanatToNextLevel, 500)
    }

    func test_levelProgress_maxLevel() async {
        sut.userStats = UserStats(totalHasanat: 800_000, currentLevel: 20)
        let progress = sut.levelProgress
        XCTAssertEqual(progress, 1.0, "Max level should show full progress ring")
    }

    func test_levelProgress_atLevelStart_isZero() async {
        sut.userStats = UserStats(totalHasanat: 1000, currentLevel: 5)
        XCTAssertEqual(sut.levelProgress, 0, accuracy: 0.01)
    }

    func test_hasanatToNextLevel_atOrAboveNextLevel_isZero() async {
        sut.userStats = UserStats(totalHasanat: 2500, currentLevel: 5)
        XCTAssertEqual(sut.hasanatToNextLevel, 0)
    }

    func test_load_setsIsLoadingDuringLoad() async {
        await sut.load()
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Today Status Tests

    func test_todayStatus_noLocation_allNeutral() async {
        // No coordinates = no schedule
        let noLocationService = MockLocationService()
        noLocationService.coordinatesToReturn = nil
        noLocationService.locationToReturn = nil
        sut = makeViewModel(locationService: noLocationService)

        mockPrayerRepo.logsToReturn = []

        await sut.load()

        // All 5 prayers should be present, none classified as missed
        XCTAssertEqual(sut.todayPrayerStatuses.count, 5)
        let missed = sut.todayPrayerStatuses.filter(\.isMissed)
        XCTAssertEqual(missed.count, 0, "Without location, unlogged prayers should not be classified as missed")
    }

    func test_todayStatus_noLocation_todayScheduleAvailableFalse() async {
        let noLocationService = MockLocationService()
        noLocationService.coordinatesToReturn = nil
        noLocationService.locationToReturn = nil
        sut = makeViewModel(locationService: noLocationService)

        await sut.load()

        XCTAssertFalse(sut.todayScheduleAvailable)
    }

    func test_todayStatus_loggedPrayersShowAsLogged() async {
        let today = fixedCalendar.startOfDay(for: fixedDate)
        mockPrayerRepo.logsToReturn = [
            PrayerLog(prayerType: .fajr, date: today, isOnTime: true),
            PrayerLog(prayerType: .dhuhr, date: today, isOnTime: false)
        ]

        await sut.load()

        let fajr = sut.todayPrayerStatuses.first { $0.prayerType == .fajr }
        let dhuhr = sut.todayPrayerStatuses.first { $0.prayerType == .dhuhr }
        XCTAssertTrue(fajr?.isLogged ?? false)
        XCTAssertTrue(fajr?.isOnTime ?? false)
        XCTAssertTrue(dhuhr?.isLogged ?? false)
        XCTAssertFalse(dhuhr?.isOnTime ?? true)
    }

    // MARK: - Elapsed Opportunities Tests

    func test_elapsedOpportunities_mondayMorning() async {
        // Monday at 08:00 — only 1 elapsed day = 5 opportunities
        var components = DateComponents()
        components.year = 2025
        components.month = 2
        components.day = 17 // Monday
        components.hour = 8
        let monday = fixedCalendar.date(from: components)!
        sut = makeViewModel(now: monday)

        await sut.load()

        let trend = sut.consistencyTrend
        XCTAssertNotNil(trend)
        XCTAssertEqual(trend?.thisWeekOpportunities, 5, "Monday morning should have 5 opportunities (1 day × 5)")
    }

    // MARK: - Consistency Trend Tests

    func test_consistencyTrend_improving() async {
        // Last week: 15/35 logged, this week so far: 12/15 (3 days elapsed)
        let thisWeekStart = startOfWeek(for: fixedDate)
        let lastWeekStart = fixedCalendar.date(byAdding: .day, value: -7, to: thisWeekStart)!

        var logs: [PrayerLog] = []

        // Last week: 3 prayers per day × 5 days = 15 total
        for dayOffset in 0..<5 {
            let date = fixedCalendar.date(byAdding: .day, value: dayOffset, to: lastWeekStart)!
            for prayerType in [PrayerType.fajr, .dhuhr, .asr] {
                logs.append(PrayerLog(prayerType: prayerType, date: date, isOnTime: true))
            }
        }

        // This week: 4 prayers per day × 3 days (Mon-Wed) = 12 total
        for dayOffset in 0..<3 {
            let date = fixedCalendar.date(byAdding: .day, value: dayOffset, to: thisWeekStart)!
            for prayerType in [PrayerType.fajr, .dhuhr, .asr, .maghrib] {
                logs.append(PrayerLog(prayerType: prayerType, date: date, isOnTime: true))
            }
        }

        mockPrayerRepo.logsToReturn = logs
        await sut.load()

        let trend = sut.consistencyTrend
        XCTAssertNotNil(trend)
        XCTAssertTrue(trend!.hasBaseline)
        // This week: 12/15 = 80%, last week: 15/35 ≈ 43%
        XCTAssertGreaterThan(trend!.delta, 0, "This week should show improvement over last week")
    }

    func test_consistencyTrend_firstWeek_noBaseline() async {
        // Only this week's logs, no last-week data
        let thisWeekStart = startOfWeek(for: fixedDate)
        let date = fixedCalendar.date(byAdding: .day, value: 1, to: thisWeekStart)!
        mockPrayerRepo.logsToReturn = [
            PrayerLog(prayerType: .fajr, date: date, isOnTime: true)
        ]

        await sut.load()

        let trend = sut.consistencyTrend
        XCTAssertNotNil(trend)
        XCTAssertFalse(trend!.hasBaseline, "With no last-week data, hasBaseline should be false")
    }

    func test_consistencyTrend_onTimeRate_excludesMakeup() async {
        let thisWeekStart = startOfWeek(for: fixedDate)
        let day1 = thisWeekStart

        mockPrayerRepo.logsToReturn = [
            PrayerLog(prayerType: .fajr, date: day1, isOnTime: true, isMakeup: false),
            PrayerLog(prayerType: .dhuhr, date: day1, isOnTime: true, isMakeup: true), // makeup — should not count as on-time
            PrayerLog(prayerType: .asr, date: day1, isOnTime: true, isMakeup: false)
        ]

        await sut.load()

        let trend = sut.consistencyTrend
        XCTAssertNotNil(trend)
        // 3 logged on Monday, but only 2 on-time (makeup excluded)
        // Elapsed days = Mon-Wed = 3 days = 15 opportunities
        // onTimeRate = 2/15
        XCTAssertEqual(trend!.onTimeRate, 2.0 / Double(trend!.thisWeekOpportunities), accuracy: 0.01)
    }

    // MARK: - Weekly Grid Tests

    func test_weeklyGrid_dedupesByPrayerType() async {
        let thisWeekStart = startOfWeek(for: fixedDate)

        // Two fajr logs for the same day
        mockPrayerRepo.logsToReturn = [
            PrayerLog(prayerType: .fajr, date: thisWeekStart, isOnTime: true),
            PrayerLog(prayerType: .fajr, date: thisWeekStart, isOnTime: false)
        ]

        await sut.load()

        let firstDay = sut.weeklyPrayerGrid.first
        XCTAssertNotNil(firstDay)
        XCTAssertEqual(firstDay!.loggedCount, 1, "Duplicate fajr logs same day should dedup to 1")
    }

    func test_weeklyGrid_has7Days() async {
        await sut.load()

        XCTAssertEqual(sut.weeklyPrayerGrid.count, 7)
    }

    func test_weekBoundary_usesCalendarFirstWeekday() async {
        // Calendar with Monday start
        let firstDay = sut.weeklyPrayerGrid.first
        await sut.load()

        let gridFirstDay = sut.weeklyPrayerGrid.first
        XCTAssertNotNil(gridFirstDay)

        // The first day of the grid should be a Monday (weekday 2 in gregorian)
        let weekday = fixedCalendar.component(.weekday, from: gridFirstDay!.date)
        XCTAssertEqual(weekday, 2, "Grid should start on Monday when calendar.firstWeekday = 2")
    }

    // MARK: - Midnight Boundary Test

    func test_todayStatus_midnightBoundary() async {
        // At 00:01 — should attribute to the correct day
        var components = DateComponents()
        components.year = 2025
        components.month = 2
        components.day = 19
        components.hour = 0
        components.minute = 1
        let midnight = fixedCalendar.date(from: components)!

        let startOfDay = fixedCalendar.startOfDay(for: midnight)
        mockPrayerRepo.logsToReturn = [
            PrayerLog(prayerType: .fajr, date: startOfDay, isOnTime: true)
        ]

        sut = makeViewModel(now: midnight)
        await sut.load()

        let fajr = sut.todayPrayerStatuses.first { $0.prayerType == .fajr }
        XCTAssertTrue(fajr?.isLogged ?? false, "Fajr logged at start of day should show as logged")
    }

    // MARK: - Prayer Streak Tests

    func test_prayerStreak_extractedFromStreaks() async {
        mockUserRepo.streaksToReturn = [
            Streak(type: .daily, currentCount: 10, longestCount: 15),
            Streak(type: .prayer, currentCount: 7, longestCount: 12)
        ]

        await sut.load()

        XCTAssertNotNil(sut.prayerStreak)
        XCTAssertEqual(sut.prayerStreak?.currentCount, 7)
        XCTAssertEqual(sut.prayerStreak?.type, .prayer)
    }

    // MARK: - Helpers

    private func startOfWeek(for date: Date) -> Date {
        let components = fixedCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return fixedCalendar.date(from: components) ?? fixedCalendar.startOfDay(for: date)
    }
}

// MARK: - Test-Specific Configurable Mocks

private final class ConfigurableMockPrayerRepository: PrayerRepositoryProtocol {
    var logsToReturn: [PrayerLog] = []
    var prayerTimesToReturn: [PrayerTime] = []

    func getPrayers(for date: Date, location: Coordinates, method: CalculationMethod, madhab: Madhab?) async throws -> [PrayerTime] { prayerTimesToReturn }
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
        currentStreak: 0
    )

    func getTracks() async throws -> [LearningTrack] { [] }
    func getTrack(id trackId: String) async throws -> LearningTrack? { nil }
    func getLessons(forTrack trackId: String) async throws -> [Lesson] { [] }
    func getLesson(trackId: String, lessonId: String) async throws -> Lesson? { nil }
    func getLessonContent(lessonId: String) async throws -> LessonContent? { nil }
    func markLessonComplete(lessonId: String, score: Int) async throws {}
    func getTrackProgress(trackId: String) async throws -> TrackProgress { TrackProgress(trackId: trackId, completedLessons: 0, totalLessons: 0) }
    func getOverallProgress() async throws -> LearningProgress { progressToReturn }
    func getNextLesson() async throws -> Lesson? { nil }
}
