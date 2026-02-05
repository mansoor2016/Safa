// MARK: - ProgressDashboardViewModelTests.swift
// PURPOSE: Unit tests for ProgressDashboardViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class ProgressDashboardViewModelTests: XCTestCase {

    var sut: ProgressDashboardViewModel!

    override func setUp() {
        super.setUp()
        sut = ProgressDashboardViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_loadsUserStats() {
        XCTAssertGreaterThan(sut.userStats.totalHasanat, 0)
    }

    func test_initialState_loadsStreaks() {
        XCTAssertFalse(sut.streaks.isEmpty)
    }

    func test_initialState_loadsWeeklyData() {
        XCTAssertEqual(sut.weeklyData.count, 7)
    }

    func test_initialState_loadsMonthlyPrayerData() {
        XCTAssertEqual(sut.monthlyPrayerData.count, 30)
    }

    // MARK: - User Stats Tests

    func test_userStats_hasValidLevel() {
        XCTAssertGreaterThanOrEqual(sut.userStats.currentLevel, 1)
        XCTAssertLessThanOrEqual(sut.userStats.currentLevel, 10)
    }

    func test_userStats_hasUnlockedAchievements() {
        XCTAssertFalse(sut.userStats.unlockedAchievements.isEmpty)
    }

    func test_userStats_hasPrayersLogged() {
        XCTAssertGreaterThan(sut.userStats.totalPrayersLogged, 0)
    }

    func test_userStats_hasAyahsRead() {
        XCTAssertGreaterThan(sut.userStats.totalAyahsRead, 0)
    }

    func test_userStats_hasTasbeehCount() {
        XCTAssertGreaterThan(sut.userStats.totalTasbeehCount, 0)
    }

    func test_userStats_hasLessonsCompleted() {
        XCTAssertGreaterThan(sut.userStats.lessonsCompleted, 0)
    }

    // MARK: - Streaks Tests

    func test_streaks_containsDailyStreak() {
        let dailyStreak = sut.streaks.first { $0.type == .daily }
        XCTAssertNotNil(dailyStreak)
    }

    func test_streaks_containsPrayerStreak() {
        let prayerStreak = sut.streaks.first { $0.type == .prayer }
        XCTAssertNotNil(prayerStreak)
    }

    func test_streaks_containsQuranStreak() {
        let quranStreak = sut.streaks.first { $0.type == .quran }
        XCTAssertNotNil(quranStreak)
    }

    func test_streaks_containsDhikrStreak() {
        let dhikrStreak = sut.streaks.first { $0.type == .dhikr }
        XCTAssertNotNil(dhikrStreak)
    }

    func test_streaks_allHaveValidCurrentCount() {
        for streak in sut.streaks {
            XCTAssertGreaterThanOrEqual(streak.currentCount, 0, "Streak \(streak.type) should have non-negative count")
        }
    }

    func test_streaks_allHaveValidLongestCount() {
        for streak in sut.streaks {
            XCTAssertGreaterThanOrEqual(streak.longestCount, streak.currentCount, "Streak \(streak.type) longest should be >= current")
        }
    }

    func test_streaks_allHaveLastActivityDate() {
        for streak in sut.streaks {
            XCTAssertNotNil(streak.lastActivityDate, "Streak \(streak.type) should have last activity date")
        }
    }

    // MARK: - Weekly Data Tests

    func test_weeklyData_hasSeverDays() {
        XCTAssertEqual(sut.weeklyData.count, 7)
    }

    func test_weeklyData_allHaveValidHasanat() {
        for day in sut.weeklyData {
            XCTAssertGreaterThanOrEqual(day.hasanat, 0, "Daily hasanat should be non-negative")
        }
    }

    func test_weeklyData_allHaveValidActivities() {
        for day in sut.weeklyData {
            XCTAssertGreaterThanOrEqual(day.activities, 0, "Daily activities should be non-negative")
        }
    }

    func test_weeklyData_allHaveValidDates() {
        for day in sut.weeklyData {
            XCTAssertNotNil(day.date)
        }
    }

    func test_weeklyData_allHaveUniqueIds() {
        let ids = sut.weeklyData.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count)
    }

    // MARK: - Monthly Prayer Data Tests

    func test_monthlyPrayerData_hasThirtyDays() {
        XCTAssertEqual(sut.monthlyPrayerData.count, 30)
    }

    func test_monthlyPrayerData_allHaveValidCounts() {
        for day in sut.monthlyPrayerData {
            XCTAssertGreaterThanOrEqual(day.count, 0, "Prayer count should be >= 0")
            XCTAssertLessThanOrEqual(day.count, 5, "Prayer count should be <= 5")
        }
    }

    func test_monthlyPrayerData_allHaveValidDayNumbers() {
        for day in sut.monthlyPrayerData {
            XCTAssertGreaterThanOrEqual(day.day, 1, "Day should be >= 1")
            XCTAssertLessThanOrEqual(day.day, 31, "Day should be <= 31")
        }
    }

    func test_monthlyPrayerData_allHaveUniqueIds() {
        let ids = sut.monthlyPrayerData.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count)
    }

    // MARK: - Level Progress Tests

    func test_levelProgress_isBetweenZeroAndOne() {
        XCTAssertGreaterThanOrEqual(sut.levelProgress, 0)
        XCTAssertLessThanOrEqual(sut.levelProgress, 1)
    }

    func test_levelProgress_calculatesCorrectly() {
        // Set up known values
        sut.userStats = UserStats(
            totalHasanat: 1500,
            currentLevel: 5
        )

        // Level 5 starts at 1000 hasanat, level 6 at 2000 hasanat
        // Progress = (1500 - 1000) / (2000 - 1000) = 500 / 1000 = 0.5
        XCTAssertEqual(sut.levelProgress, 0.5, accuracy: 0.01)
    }

    func test_levelProgress_isZero_atLevelStart() {
        sut.userStats = UserStats(
            totalHasanat: 1000,
            currentLevel: 5
        )
        // Level 5 starts at 1000, so progress should be 0
        XCTAssertEqual(sut.levelProgress, 0, accuracy: 0.01)
    }

    func test_levelProgress_clampsToOne() {
        // Even if hasanat exceeds next level, progress should max at 1.0
        sut.userStats = UserStats(
            totalHasanat: 2500,
            currentLevel: 5
        )
        // Level 6 is at 2000, so this exceeds, should clamp to 1.0
        XCTAssertLessThanOrEqual(sut.levelProgress, 1.0)
    }

    // MARK: - Hasanat To Next Level Tests

    func test_hasanatToNextLevel_calculatesCorrectly() {
        sut.userStats = UserStats(
            totalHasanat: 1500,
            currentLevel: 5
        )
        // Next level (6) is at 2000, so need 500 more
        XCTAssertEqual(sut.hasanatToNextLevel, 500)
    }

    func test_hasanatToNextLevel_isZeroOrPositive() {
        XCTAssertGreaterThanOrEqual(sut.hasanatToNextLevel, 0)
    }

    func test_hasanatToNextLevel_isZero_whenAtOrAboveNextLevel() {
        sut.userStats = UserStats(
            totalHasanat: 2500,
            currentLevel: 5
        )
        // Level 6 is at 2000, we have 2500, so need 0
        XCTAssertEqual(sut.hasanatToNextLevel, 0)
    }

    func test_hasanatToNextLevel_isCorrectAtLevelStart() {
        sut.userStats = UserStats(
            totalHasanat: 1000,
            currentLevel: 5
        )
        // Level 6 is at 2000, we have 1000, so need 1000
        XCTAssertEqual(sut.hasanatToNextLevel, 1000)
    }

    // MARK: - Load Data Tests

    func test_loadData_populatesAllData() {
        // Clear all data
        sut.userStats = UserStats()
        sut.streaks = []
        sut.weeklyData = []
        sut.monthlyPrayerData = []

        // Reload
        sut.loadData()

        // Verify all populated
        XCTAssertGreaterThan(sut.userStats.totalHasanat, 0)
        XCTAssertFalse(sut.streaks.isEmpty)
        XCTAssertFalse(sut.weeklyData.isEmpty)
        XCTAssertFalse(sut.monthlyPrayerData.isEmpty)
    }

    // MARK: - DailyProgress Model Tests

    func test_dailyProgress_isIdentifiable() {
        let progress = ProgressDashboardViewModel.DailyProgress(
            date: Date(),
            hasanat: 50,
            activities: 5
        )
        XCTAssertNotNil(progress.id)
    }

    func test_dailyProgress_storesDate() {
        let testDate = Date()
        let progress = ProgressDashboardViewModel.DailyProgress(
            date: testDate,
            hasanat: 50,
            activities: 5
        )
        XCTAssertEqual(progress.date, testDate)
    }

    func test_dailyProgress_storesHasanat() {
        let progress = ProgressDashboardViewModel.DailyProgress(
            date: Date(),
            hasanat: 100,
            activities: 5
        )
        XCTAssertEqual(progress.hasanat, 100)
    }

    func test_dailyProgress_storesActivities() {
        let progress = ProgressDashboardViewModel.DailyProgress(
            date: Date(),
            hasanat: 50,
            activities: 7
        )
        XCTAssertEqual(progress.activities, 7)
    }

    // MARK: - DayPrayerCount Model Tests

    func test_dayPrayerCount_isIdentifiable() {
        let dayCount = ProgressDashboardViewModel.DayPrayerCount(day: 1, count: 5)
        XCTAssertNotNil(dayCount.id)
    }

    func test_dayPrayerCount_storesDay() {
        let dayCount = ProgressDashboardViewModel.DayPrayerCount(day: 15, count: 3)
        XCTAssertEqual(dayCount.day, 15)
    }

    func test_dayPrayerCount_storesCount() {
        let dayCount = ProgressDashboardViewModel.DayPrayerCount(day: 1, count: 4)
        XCTAssertEqual(dayCount.count, 4)
    }

    // MARK: - Edge Cases

    func test_levelProgress_handlesLevelOne() {
        sut.userStats = UserStats(
            totalHasanat: 50,
            currentLevel: 1
        )
        // Level 1 starts at 0, level 2 at 100
        // Progress = 50 / 100 = 0.5
        XCTAssertEqual(sut.levelProgress, 0.5, accuracy: 0.01)
    }

    func test_levelProgress_handlesMaxLevel() {
        sut.userStats = UserStats(
            totalHasanat: 25000,
            currentLevel: 10
        )
        // Level 10 is max - test that it doesn't crash
        // Note: At max level, the calculation may produce edge case values
        _ = sut.levelProgress
    }

    func test_hasanatToNextLevel_handlesMaxLevel() {
        sut.userStats = UserStats(
            totalHasanat: 25000,
            currentLevel: 10
        )
        // At max level, should still compute
        XCTAssertGreaterThanOrEqual(sut.hasanatToNextLevel, 0)
    }
}
