// MARK: - StreakUseCaseTests.swift
// PURPOSE: Unit tests for Streak update use case
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class StreakUseCaseTests: XCTestCase {

    var sut: UpdateStreakUseCase!

    override func setUp() {
        super.setUp()
        sut = UpdateStreakUseCase()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialStreakIsZero() {
        let streak = sut.getStreak(for: .daily)

        XCTAssertEqual(streak.currentCount, 0)
        XCTAssertEqual(streak.longestCount, 0)
        XCTAssertNil(streak.lastActivityDate)
    }

    func testAllStreakTypesInitialized() {
        let allStreaks = sut.getAllStreaks()

        XCTAssertEqual(allStreaks.count, StreakType.allCases.count)

        for streakType in StreakType.allCases {
            let streak = sut.getStreak(for: streakType)
            XCTAssertEqual(streak.type, streakType)
        }
    }

    // MARK: - Record Activity Tests

    func testRecordFirstActivity() {
        let result = sut.recordActivity(.prayer(.fajr), at: Date())

        XCTAssertEqual(result.streakType, .prayer)
        XCTAssertEqual(result.previousCount, 0)
        XCTAssertEqual(result.newCount, 1)
        XCTAssertFalse(result.streakBroken)
        XCTAssertTrue(result.countIncreased)
    }

    func testRecordSameActivityTwiceSameDay() {
        let today = Date()

        _ = sut.recordActivity(.prayer(.fajr), at: today)
        let secondResult = sut.recordActivity(.prayer(.dhuhr), at: today)

        // Same day, same streak type - shouldn't increment again
        XCTAssertEqual(secondResult.newCount, 1)
        XCTAssertFalse(secondResult.countIncreased)
    }

    func testRecordConsecutiveDays() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Record yesterday
        _ = sut.recordActivity(.prayer(.fajr), at: yesterday)

        // Record today
        let result = sut.recordActivity(.prayer(.fajr), at: today)

        XCTAssertEqual(result.newCount, 2)
        XCTAssertFalse(result.streakBroken)
        XCTAssertTrue(result.countIncreased)
    }

    func testStreakBrokenAfterMissedDay() {
        let calendar = Calendar.current
        let today = Date()
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!

        // Record three days ago
        _ = sut.recordActivity(.prayer(.fajr), at: threeDaysAgo)

        // Record today (missed yesterday and day before)
        let result = sut.recordActivity(.prayer(.fajr), at: today)

        XCTAssertEqual(result.newCount, 1)
        XCTAssertTrue(result.streakBroken)
    }

    // MARK: - Streak Type Mapping Tests

    func testPrayerActivityMapsToPrayerStreak() {
        let result = sut.recordActivity(.prayer(.fajr), at: Date())
        XCTAssertEqual(result.streakType, .prayer)
    }

    func testQuranActivityMapsToQuranStreak() {
        let result = sut.recordActivity(.quranReading, at: Date())
        XCTAssertEqual(result.streakType, .quran)
    }

    func testDhikrActivityMapsToDhikrStreak() {
        let result = sut.recordActivity(.dhikr, at: Date())
        XCTAssertEqual(result.streakType, .dhikr)
    }

    func testLearningActivityMapsToLearningStreak() {
        let result = sut.recordActivity(.learning, at: Date())
        XCTAssertEqual(result.streakType, .learning)
    }

    func testAnyActivityMapsToDailyStreak() {
        let result = sut.recordActivity(.anyActivity, at: Date())
        XCTAssertEqual(result.streakType, .daily)
    }

    // MARK: - Daily Streak Auto-Update Tests

    func testPrayerActivityAlsoUpdatesDailyStreak() {
        _ = sut.recordActivity(.prayer(.fajr), at: Date())

        let dailyStreak = sut.getStreak(for: .daily)
        XCTAssertEqual(dailyStreak.currentCount, 1, "Prayer should also update daily streak")
    }

    func testQuranActivityAlsoUpdatesDailyStreak() {
        _ = sut.recordActivity(.quranReading, at: Date())

        let dailyStreak = sut.getStreak(for: .daily)
        XCTAssertEqual(dailyStreak.currentCount, 1, "Quran should also update daily streak")
    }

    // MARK: - Longest Count Tests

    func testLongestCountUpdates() {
        let calendar = Calendar.current
        var date = Date()

        // Build a 5-day streak
        for _ in 0..<5 {
            _ = sut.recordActivity(.prayer(.fajr), at: date)
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        let streak = sut.getStreak(for: .prayer)
        XCTAssertEqual(streak.longestCount, 5)
    }

    func testLongestCountPreservedAfterBreak() {
        let calendar = Calendar.current
        var date = Date()

        // Build a 5-day streak
        for _ in 0..<5 {
            _ = sut.recordActivity(.prayer(.fajr), at: date)
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        // Skip 3 days and record again (breaks streak)
        date = calendar.date(byAdding: .day, value: 3, to: date)!
        _ = sut.recordActivity(.prayer(.fajr), at: date)

        let streak = sut.getStreak(for: .prayer)
        XCTAssertEqual(streak.currentCount, 1, "Current should reset")
        XCTAssertEqual(streak.longestCount, 5, "Longest should be preserved")
    }

    func testNewRecordDetected() {
        let calendar = Calendar.current
        var date = Date()

        // Build a 3-day streak
        for _ in 0..<3 {
            _ = sut.recordActivity(.prayer(.fajr), at: date)
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        // Skip days and start new streak
        date = calendar.date(byAdding: .day, value: 5, to: date)!

        // Build a new 5-day streak
        for i in 0..<5 {
            let result = sut.recordActivity(.prayer(.fajr), at: date)
            date = calendar.date(byAdding: .day, value: 1, to: date)!

            if i >= 3 { // Days 4 and 5 are new records
                XCTAssertTrue(result.isNewRecord, "Day \(i+1) should be a new record")
            }
        }
    }

    // MARK: - Milestone Tests

    func testMilestone7Detected() {
        let calendar = Calendar.current
        var date = Date()
        var milestone7Reached = false

        // Build a 7-day streak
        for _ in 0..<7 {
            let result = sut.recordActivity(.prayer(.fajr), at: date)
            if result.milestoneReached == 7 {
                milestone7Reached = true
            }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        XCTAssertTrue(milestone7Reached, "7-day milestone should be detected")
    }

    // MARK: - Check Streaks Tests

    func testCheckStreaksBreaksOldStreak() {
        let calendar = Calendar.current
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!

        // Record 3 days ago
        _ = sut.recordActivity(.prayer(.fajr), at: threeDaysAgo)

        // Verify streak exists
        var streak = sut.getStreak(for: .prayer)
        XCTAssertEqual(streak.currentCount, 1)

        // Check streaks (should break the old one)
        let results = sut.checkAndUpdateStreaks(for: Date())

        XCTAssertTrue(results.contains { $0.streakBroken && $0.streakType == .prayer })

        streak = sut.getStreak(for: .prayer)
        XCTAssertEqual(streak.currentCount, 0, "Streak should be reset to 0")
    }

    // MARK: - Streak Freeze Tests

    func testStreakFreezeNotAvailableInitially() {
        let result = sut.useStreakFreeze(for: .daily)
        XCTAssertFalse(result, "Freeze should not be available initially")
    }

    func testStreakFreezeUsable() {
        // Add freezes
        sut.addStreakFreezes(2)

        XCTAssertEqual(sut.getAvailableFreezes(), 2)

        let result = sut.useStreakFreeze(for: .daily)
        XCTAssertTrue(result)
        XCTAssertEqual(sut.getAvailableFreezes(), 1)
    }
}

// MARK: - Streak Extension Tests

final class StreakExtensionTests: XCTestCase {

    func testStreakIsActiveToday() {
        let streak = Streak(
            type: .daily,
            currentCount: 5,
            longestCount: 10,
            lastActivityDate: Date()
        )

        XCTAssertTrue(streak.isActiveToday)
    }

    func testStreakIsNotActiveTodayWhenYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let streak = Streak(
            type: .daily,
            currentCount: 5,
            longestCount: 10,
            lastActivityDate: yesterday
        )

        XCTAssertFalse(streak.isActiveToday)
    }

    func testStreakAtRiskWhenYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let streak = Streak(
            type: .daily,
            currentCount: 5,
            longestCount: 10,
            lastActivityDate: yesterday
        )

        XCTAssertFalse(streak.isAtRisk, "Yesterday is not at risk yet")
    }

    func testStreakAtRiskWhenTwoDaysAgo() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let streak = Streak(
            type: .daily,
            currentCount: 5,
            longestCount: 10,
            lastActivityDate: twoDaysAgo
        )

        XCTAssertTrue(streak.isAtRisk, "Two days ago means streak is at risk")
    }
}
