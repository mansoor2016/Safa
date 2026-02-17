// MARK: - UseCaseTests.swift
// PURPOSE: Unit tests for domain use cases (Hasanat, Streak)

import XCTest
@testable import Safa

// MARK: - CalculateHasanatUseCase Tests

final class CalculateHasanatUseCaseTests: XCTestCase {

    var sut: CalculateHasanatUseCase!

    override func setUp() {
        super.setUp()
        sut = CalculateHasanatUseCase()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Prayer Actions

    func testPrayerLoggedPoints() {
        let points = sut.calculatePoints(for: .prayerLogged(.fajr))
        XCTAssertEqual(points, 10)
    }

    func testAllFivePrayersLoggedPoints() {
        let points = sut.calculatePoints(for: .allFivePrayersLogged)
        XCTAssertEqual(points, 25)
    }

    func testPrayerOnTimePoints() {
        let points = sut.calculatePoints(for: .prayerOnTime)
        XCTAssertEqual(points, 5)
    }

    func testTahajjudPrayerPoints() {
        let points = sut.calculatePoints(for: .tahajjudPrayer)
        XCTAssertEqual(points, 30)
    }

    func testFridayPrayerPoints() {
        let points = sut.calculatePoints(for: .fridayPrayer)
        XCTAssertEqual(points, 20)
    }

    // MARK: - Quran Actions

    func testQuranPageReadPoints() {
        let points = sut.calculatePoints(for: .quranPageRead)
        XCTAssertEqual(points, 5)
    }

    func testQuranSurahCompletedPointsShortSurah() {
        // Al-Fatiha (7 ayahs) - short surah
        let points = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 1))
        XCTAssertGreaterThanOrEqual(points, 15)
    }

    func testQuranSurahCompletedPointsLongSurah() {
        // Al-Baqarah (286 ayahs) - longest surah
        let points = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 2))
        XCTAssertGreaterThan(points, 15) // Should get bonus for long surah
    }

    func testQuranJuzCompletedPoints() {
        let points = sut.calculatePoints(for: .quranJuzCompleted)
        XCTAssertEqual(points, 50)
    }

    func testQuranKhatmPoints() {
        let points = sut.calculatePoints(for: .quranKhatm)
        XCTAssertEqual(points, 500)
    }

    // MARK: - Learning Actions

    func testLessonCompletedPoints() {
        let points = sut.calculatePoints(for: .lessonCompleted)
        XCTAssertEqual(points, 10)
    }

    func testTrackCompletedPoints() {
        let points = sut.calculatePoints(for: .trackCompleted)
        XCTAssertEqual(points, 100)
    }

    func testPerfectPronunciationPoints() {
        let points = sut.calculatePoints(for: .perfectPronunciation)
        XCTAssertEqual(points, 5)
    }

    // MARK: - Dhikr Actions

    func testMorningDhikrPoints() {
        let points = sut.calculatePoints(for: .morningDhikrCompleted)
        XCTAssertEqual(points, 15)
    }

    func testEveningDhikrPoints() {
        let points = sut.calculatePoints(for: .eveningDhikrCompleted)
        XCTAssertEqual(points, 15)
    }

    func testTasbeeh33Points() {
        let points = sut.calculatePoints(for: .tasbeeh(count: 33))
        XCTAssertEqual(points, 10)
    }

    func testTasbeeh100Points() {
        let points = sut.calculatePoints(for: .tasbeeh(count: 100))
        XCTAssertEqual(points, 20)
    }

    func testDuaRecitedPoints() {
        let points = sut.calculatePoints(for: .duaRecited)
        XCTAssertEqual(points, 5)
    }

    // MARK: - Social Actions

    func testInvitedFriendPoints() {
        let points = sut.calculatePoints(for: .invitedFriend)
        XCTAssertEqual(points, 10)
    }

    func testFriendJoinedPoints() {
        let points = sut.calculatePoints(for: .friendJoined)
        XCTAssertEqual(points, 25)
    }

    func testSharedVersePoints() {
        let points = sut.calculatePoints(for: .sharedVerse)
        XCTAssertEqual(points, 5)
    }

    // MARK: - Streak Actions

    func testStreakMilestone7Days() {
        let points = sut.calculatePoints(for: .streakMilestone(days: 7))
        XCTAssertEqual(points, 50)
    }

    func testStreakMilestone30Days() {
        let points = sut.calculatePoints(for: .streakMilestone(days: 30))
        XCTAssertEqual(points, 150)
    }

    func testStreakMilestone100Days() {
        let points = sut.calculatePoints(for: .streakMilestone(days: 100))
        XCTAssertEqual(points, 500)
    }

    func testPerfectWeekPoints() {
        let points = sut.calculatePoints(for: .perfectWeek)
        XCTAssertEqual(points, 100)
    }

    func testPerfectMonthPoints() {
        let points = sut.calculatePoints(for: .perfectMonth)
        XCTAssertEqual(points, 300)
    }

    // MARK: - Multiplier Tests

    func testRamadanMultiplier() {
        let basePoints = sut.calculatePoints(for: .prayerLogged(.fajr))
        let multipliedPoints = sut.calculateWithMultipliers(
            for: .prayerLogged(.fajr),
            isRamadan: true,
            isFriday: false
        )

        XCTAssertEqual(multipliedPoints, basePoints * 2)
    }

    func testFridayMultiplier() {
        let basePoints = sut.calculatePoints(for: .prayerLogged(.dhuhr))
        let multipliedPoints = sut.calculateWithMultipliers(
            for: .prayerLogged(.dhuhr),
            isRamadan: false,
            isFriday: true
        )

        // Friday multiplier is 1.5, result should be rounded
        XCTAssertEqual(multipliedPoints, Int(Double(basePoints) * 1.5))
    }

    func testRamadanAndFridayMultipliersCombined() {
        let basePoints = sut.calculatePoints(for: .prayerLogged(.maghrib))
        let multipliedPoints = sut.calculateWithMultipliers(
            for: .prayerLogged(.maghrib),
            isRamadan: true,
            isFriday: true
        )

        // Ramadan (2x) takes precedence over Friday (1.5x) - uses max, not multiplication
        XCTAssertEqual(multipliedPoints, basePoints * 2)
    }

    func testNoMultipliers() {
        let basePoints = sut.calculatePoints(for: .lessonCompleted)
        let multipliedPoints = sut.calculateWithMultipliers(
            for: .lessonCompleted,
            isRamadan: false,
            isFriday: false
        )

        XCTAssertEqual(multipliedPoints, basePoints)
    }

    // MARK: - First Time Action

    func testFirstTimeActionPoints() {
        let points = sut.calculatePoints(for: .firstTimeAction(action: "prayer"))
        XCTAssertEqual(points, 20)
    }
}

// MARK: - UpdateStreakUseCase Tests

final class UpdateStreakUseCaseTests: XCTestCase {

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

    func testInitialStreaksAreZero() {
        let streaks = sut.getAllStreaks()

        for streak in streaks {
            XCTAssertEqual(streak.currentCount, 0)
            XCTAssertEqual(streak.longestCount, 0)
            XCTAssertNil(streak.lastActivityDate)
        }
    }

    func testAllStreakTypesInitialized() {
        let streaks = sut.getAllStreaks()
        let types = Set(streaks.map { $0.type })

        XCTAssertEqual(types.count, StreakType.allCases.count)
        for type in StreakType.allCases {
            XCTAssertTrue(types.contains(type))
        }
    }

    // MARK: - Record Activity Tests

    func testRecordFirstActivity() {
        let result = sut.recordActivity(.quranReading, at: Date())

        XCTAssertEqual(result.streakType, .quran)
        XCTAssertEqual(result.previousCount, 0)
        XCTAssertEqual(result.newCount, 1)
        XCTAssertTrue(result.isNewRecord)
        XCTAssertFalse(result.streakBroken)
    }

    func testRecordPrayerUpdatesCorrectStreak() {
        let result = sut.recordActivity(.prayer(.fajr), at: Date())

        XCTAssertEqual(result.streakType, .prayer)
        XCTAssertEqual(result.newCount, 1)
    }

    func testRecordDhikrUpdatesCorrectStreak() {
        let result = sut.recordActivity(.dhikr, at: Date())

        XCTAssertEqual(result.streakType, .dhikr)
        XCTAssertEqual(result.newCount, 1)
    }

    func testRecordLearningUpdatesCorrectStreak() {
        let result = sut.recordActivity(.learning, at: Date())

        XCTAssertEqual(result.streakType, .learning)
        XCTAssertEqual(result.newCount, 1)
    }

    func testRecordSameActivityTwiceSameDay() {
        let today = Date()

        _ = sut.recordActivity(.quranReading, at: today)
        let result = sut.recordActivity(.quranReading, at: today)

        // Should not increment on same day
        XCTAssertEqual(result.newCount, result.previousCount)
        XCTAssertFalse(result.countIncreased)
    }

    func testRecordActivityConsecutiveDays() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        _ = sut.recordActivity(.quranReading, at: yesterday)
        let result = sut.recordActivity(.quranReading, at: today)

        XCTAssertEqual(result.newCount, 2)
        XCTAssertTrue(result.countIncreased)
        XCTAssertFalse(result.streakBroken)
    }

    // MARK: - Streak Break Tests

    func testStreakBreaksAfterMissedDay() {
        let today = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today)!

        // Start a streak 3 days ago
        _ = sut.recordActivity(.quranReading, at: threeDaysAgo)

        // Record activity today (missed 2 days)
        let result = sut.recordActivity(.quranReading, at: today)

        // Streak should be broken and reset to 1
        XCTAssertTrue(result.streakBroken)
        XCTAssertEqual(result.newCount, 1)
    }

    // MARK: - Get Streak Tests

    func testGetStreakByType() {
        let streak = sut.getStreak(for: .daily)

        XCTAssertEqual(streak.type, .daily)
    }

    func testGetStreakAfterActivity() {
        _ = sut.recordActivity(.learning, at: Date())
        let streak = sut.getStreak(for: .learning)

        XCTAssertEqual(streak.currentCount, 1)
    }

    // MARK: - Milestone Tests

    func testMilestoneAt7Days() {
        let today = Date()

        // Build up a 7-day streak
        for dayOffset in (1...7).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset + 1, to: today)!
            _ = sut.recordActivity(.dhikr, at: date)
        }

        let streak = sut.getStreak(for: .dhikr)
        XCTAssertEqual(streak.currentCount, 7)
    }

    // MARK: - Daily Streak Tests

    func testActivityUpdatesDaily() {
        let result = sut.recordActivity(.quranReading, at: Date())

        // Quran reading should also update daily streak
        let dailyStreak = sut.getStreak(for: .daily)
        XCTAssertEqual(dailyStreak.currentCount, 1)
    }

    func testAnyActivityUpdatesDailyStreak() {
        let result = sut.recordActivity(.anyActivity, at: Date())

        XCTAssertEqual(result.streakType, .daily)
        XCTAssertEqual(result.newCount, 1)
    }

    // MARK: - Longest Count Tests

    func testLongestCountUpdates() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        _ = sut.recordActivity(.prayer(.fajr), at: yesterday)
        let result = sut.recordActivity(.prayer(.dhuhr), at: today)

        XCTAssertTrue(result.isNewRecord)
        XCTAssertEqual(result.newCount, 2)
    }
}

// MARK: - StreakActivity Tests

final class StreakActivityTests: XCTestCase {

    func testPrayerActivityAssociatedType() {
        let activity = StreakActivity.prayer(.fajr)
        XCTAssertEqual(activity.associatedStreakType, .prayer)
    }

    func testAllPrayersActivityAssociatedType() {
        let activity = StreakActivity.allPrayers
        XCTAssertEqual(activity.associatedStreakType, .prayer)
    }

    func testQuranReadingActivityAssociatedType() {
        let activity = StreakActivity.quranReading
        XCTAssertEqual(activity.associatedStreakType, .quran)
    }

    func testDhikrActivityAssociatedType() {
        let activity = StreakActivity.dhikr
        XCTAssertEqual(activity.associatedStreakType, .dhikr)
    }

    func testLearningActivityAssociatedType() {
        let activity = StreakActivity.learning
        XCTAssertEqual(activity.associatedStreakType, .learning)
    }

    func testAnyActivityAssociatedType() {
        let activity = StreakActivity.anyActivity
        XCTAssertEqual(activity.associatedStreakType, .daily)
    }
}

// MARK: - StreakUpdateResult Tests

final class StreakUpdateResultTests: XCTestCase {

    func testCountIncreasedWhenNewGreaterThanPrevious() {
        let result = StreakUpdateResult(
            streakType: .daily,
            previousCount: 5,
            newCount: 6,
            isNewRecord: true,
            milestoneReached: nil,
            streakBroken: false,
            freezeUsed: false
        )

        XCTAssertTrue(result.countIncreased)
    }

    func testCountNotIncreasedWhenEqual() {
        let result = StreakUpdateResult(
            streakType: .daily,
            previousCount: 5,
            newCount: 5,
            isNewRecord: false,
            milestoneReached: nil,
            streakBroken: false,
            freezeUsed: false
        )

        XCTAssertFalse(result.countIncreased)
    }

    func testCountNotIncreasedWhenReset() {
        let result = StreakUpdateResult(
            streakType: .daily,
            previousCount: 10,
            newCount: 1,
            isNewRecord: false,
            milestoneReached: nil,
            streakBroken: true,
            freezeUsed: false
        )

        XCTAssertFalse(result.countIncreased)
    }
}

// MARK: - HasanatAction Tests

final class HasanatActionTests: XCTestCase {

    func testHasanatActionEquality() {
        let action1 = HasanatAction.prayerLogged(.fajr)
        let action2 = HasanatAction.prayerLogged(.fajr)
        let action3 = HasanatAction.prayerLogged(.dhuhr)

        XCTAssertEqual(action1, action2)
        XCTAssertNotEqual(action1, action3)
    }

    func testQuranSurahCompletedEquality() {
        let action1 = HasanatAction.quranSurahCompleted(surahNumber: 1)
        let action2 = HasanatAction.quranSurahCompleted(surahNumber: 1)
        let action3 = HasanatAction.quranSurahCompleted(surahNumber: 2)

        XCTAssertEqual(action1, action2)
        XCTAssertNotEqual(action1, action3)
    }

    func testTasbeehEquality() {
        let action1 = HasanatAction.tasbeeh(count: 33)
        let action2 = HasanatAction.tasbeeh(count: 33)
        let action3 = HasanatAction.tasbeeh(count: 100)

        XCTAssertEqual(action1, action2)
        XCTAssertNotEqual(action1, action3)
    }

    func testStreakMilestoneEquality() {
        let action1 = HasanatAction.streakMilestone(days: 7)
        let action2 = HasanatAction.streakMilestone(days: 7)
        let action3 = HasanatAction.streakMilestone(days: 30)

        XCTAssertEqual(action1, action2)
        XCTAssertNotEqual(action1, action3)
    }

    func testFirstTimeActionEquality() {
        let action1 = HasanatAction.firstTimeAction(action: "prayer")
        let action2 = HasanatAction.firstTimeAction(action: "prayer")
        let action3 = HasanatAction.firstTimeAction(action: "quran")

        XCTAssertEqual(action1, action2)
        XCTAssertNotEqual(action1, action3)
    }
}
