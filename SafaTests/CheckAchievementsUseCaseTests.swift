// MARK: - CheckAchievementsUseCaseTests.swift
// PURPOSE: Unit tests for CheckAchievementsUseCase and AchievementManager
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

// MARK: - CheckAchievementsUseCase Tests

final class CheckAchievementsUseCaseTests: XCTestCase {

    var sut: CheckAchievementsUseCase!

    override func setUp() {
        super.setUp()
        sut = CheckAchievementsUseCase()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitiallyNoAchievementsUnlocked() {
        let unlocked = sut.getUnlockedAchievements()
        XCTAssertTrue(unlocked.isEmpty)
    }

    func testLockedAchievementsReturnsAll() {
        let locked = sut.getLockedAchievements()
        XCTAssertGreaterThan(locked.count, 0)
    }

    func testAllAchievementsAreLocked() {
        let stats = UserStats()
        let results = sut.checkAllAchievements(with: stats)

        // With zero stats, no achievements should be unlocked
        let unlockedCount = results.filter { $0.wasUnlocked }.count
        XCTAssertEqual(unlockedCount, 0)
    }

    // MARK: - Level Achievement Tests

    func testLevel5AchievementUnlocks() {
        let stats = UserStats(
            totalHasanat: 1000,
            currentLevel: 5,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let result = sut.checkSpecificAchievement("level_5", with: stats)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    func testLevel10AchievementUnlocks() {
        let stats = UserStats(
            totalHasanat: 20000,
            currentLevel: 10,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let result = sut.checkSpecificAchievement("level_10", with: stats)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    func testLevelAchievementProgress() {
        let stats = UserStats(
            totalHasanat: 500,
            currentLevel: 3,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let progress = sut.getProgress(for: "level_5", with: stats)

        // Level 3 out of 5 = 60%
        XCTAssertEqual(progress, 0.6, accuracy: 0.01)
    }

    // MARK: - Hasanat Achievement Tests

    func testHasanat1000AchievementUnlocks() {
        let stats = UserStats(
            totalHasanat: 1000,
            currentLevel: 5,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let result = sut.checkSpecificAchievement("hasanat_1000", with: stats)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    func testHasanat10000AchievementUnlocks() {
        let stats = UserStats(
            totalHasanat: 10000,
            currentLevel: 9,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let result = sut.checkSpecificAchievement("hasanat_10000", with: stats)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    func testHasanatProgress() {
        let stats = UserStats(
            totalHasanat: 500,
            currentLevel: 3,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let progress = sut.getProgress(for: "hasanat_1000", with: stats)

        // 500 out of 1000 = 50%
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    // MARK: - Prayer Achievement Tests

    func testFirstPrayerAchievementUnlocks() {
        let stats = UserStats(
            totalHasanat: 10,
            currentLevel: 1,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 1,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let result = sut.checkSpecificAchievement("first_prayer", with: stats)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    func testPrayers100AchievementUnlocks() {
        let stats = UserStats(
            totalHasanat: 1000,
            currentLevel: 5,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 100,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let result = sut.checkSpecificAchievement("prayers_logged_100", with: stats)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    func testPrayerProgress() {
        let stats = UserStats(
            totalHasanat: 500,
            currentLevel: 3,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 50,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let progress = sut.getProgress(for: "prayers_logged_100", with: stats)

        // 50 out of 100 = 50%
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    // MARK: - Quran Achievement Tests

    func testQuranReader100Progress() {
        let stats = UserStats(
            totalHasanat: 500,
            currentLevel: 3,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 50, // ~3.33 pages
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let progress = sut.getProgress(for: "quran_reader_100", with: stats)

        // Progress based on pages (50/15 = ~3.33 pages out of 7 pages target)
        XCTAssertGreaterThan(progress, 0)
        XCTAssertLessThan(progress, 1.0)
    }

    func testQuranKhatmAchievement() {
        let stats = UserStats(
            totalHasanat: 50000,
            currentLevel: 10,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 6236, // Complete Quran
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let result = sut.checkSpecificAchievement("quran_khatm", with: stats)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    // MARK: - Learning Achievement Tests

    func testFirstLessonAchievementUnlocks() {
        let stats = UserStats(
            totalHasanat: 10,
            currentLevel: 1,
            unlockedAchievements: [],
            lessonsCompleted: 1,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let result = sut.checkSpecificAchievement("first_lesson", with: stats)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    func testLessons10AchievementUnlocks() {
        let stats = UserStats(
            totalHasanat: 100,
            currentLevel: 2,
            unlockedAchievements: [],
            lessonsCompleted: 10,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let result = sut.checkSpecificAchievement("lessons_10", with: stats)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    func testLessonProgress() {
        let stats = UserStats(
            totalHasanat: 50,
            currentLevel: 1,
            unlockedAchievements: [],
            lessonsCompleted: 5,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let progress = sut.getProgress(for: "lessons_10", with: stats)

        // 5 out of 10 = 50%
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    // MARK: - Tasbeeh Achievement Tests

    func testTasbeeh1000AchievementUnlocks() {
        let stats = UserStats(
            totalHasanat: 500,
            currentLevel: 3,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 1000,
            streakFreezes: 0
        )

        let result = sut.checkSpecificAchievement("tasbeeh_1000", with: stats)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    func testTasbeehProgress() {
        let stats = UserStats(
            totalHasanat: 250,
            currentLevel: 2,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 500,
            streakFreezes: 0
        )

        let progress = sut.getProgress(for: "tasbeeh_1000", with: stats)

        // 500 out of 1000 = 50%
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    // MARK: - Check All Achievements Tests

    func testCheckAllAchievementsReturnsResults() {
        let stats = UserStats()
        let results = sut.checkAllAchievements(with: stats)

        XCTAssertGreaterThan(results.count, 0)
    }

    func testCheckAllAchievementsContainsAllAchievements() {
        let stats = UserStats()
        let results = sut.checkAllAchievements(with: stats)
        let locked = sut.getLockedAchievements()

        // Results should contain all achievements
        XCTAssertEqual(results.count, locked.count)
    }

    func testMultipleAchievementsUnlockTogether() {
        // Stats that should unlock multiple achievements at once
        let stats = UserStats(
            totalHasanat: 1000,
            currentLevel: 5,
            unlockedAchievements: [],
            lessonsCompleted: 10,
            totalPrayersLogged: 100,
            totalAyahsRead: 0,
            totalTasbeehCount: 1000,
            streakFreezes: 0
        )

        let results = sut.checkAllAchievements(with: stats)
        let newlyUnlocked = results.filter { $0.wasUnlocked }

        // Should unlock: first_prayer, prayers_logged_100, first_lesson, lessons_10,
        // tasbeeh_1000, level_5, hasanat_1000
        XCTAssertGreaterThan(newlyUnlocked.count, 3)
    }

    // MARK: - Achievement Not Re-Unlocked Tests

    func testAchievementNotReUnlocked() {
        let stats = UserStats(
            totalHasanat: 1000,
            currentLevel: 5,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        // First check - should unlock
        let firstResult = sut.checkSpecificAchievement("level_5", with: stats)
        XCTAssertTrue(firstResult?.wasUnlocked ?? false)

        // Second check with same stats - should NOT report as newly unlocked
        let secondResult = sut.checkSpecificAchievement("level_5", with: stats)
        XCTAssertFalse(secondResult?.wasUnlocked ?? true)
    }

    // MARK: - Progress Values Tests

    func testProgressNeverExceedsOne() {
        let stats = UserStats(
            totalHasanat: 100000,
            currentLevel: 10,
            unlockedAchievements: [],
            lessonsCompleted: 1000,
            totalPrayersLogged: 10000,
            totalAyahsRead: 100000,
            totalTasbeehCount: 100000,
            streakFreezes: 0
        )

        let results = sut.checkAllAchievements(with: stats)

        for result in results {
            XCTAssertLessThanOrEqual(result.progress, 1.0, "Progress for \(result.achievement.id) exceeds 1.0")
        }
    }

    func testProgressNeverNegative() {
        let stats = UserStats()
        let results = sut.checkAllAchievements(with: stats)

        for result in results {
            XCTAssertGreaterThanOrEqual(result.progress, 0.0, "Progress for \(result.achievement.id) is negative")
        }
    }

    // MARK: - Unknown Achievement Tests

    func testCheckUnknownAchievementReturnsNil() {
        let stats = UserStats()
        let result = sut.checkSpecificAchievement("unknown_achievement_id", with: stats)

        XCTAssertNil(result)
    }

    func testProgressForUnknownAchievementIsZero() {
        let stats = UserStats()
        let progress = sut.getProgress(for: "unknown_achievement_id", with: stats)

        XCTAssertEqual(progress, 0.0)
    }
}

// MARK: - AchievementCriteria Tests

final class AchievementCriteriaTests: XCTestCase {

    func testAchievementTierRawValues() {
        XCTAssertEqual(AchievementCriteria.AchievementTier.bronze.rawValue, 1)
        XCTAssertEqual(AchievementCriteria.AchievementTier.silver.rawValue, 2)
        XCTAssertEqual(AchievementCriteria.AchievementTier.gold.rawValue, 3)
        XCTAssertEqual(AchievementCriteria.AchievementTier.platinum.rawValue, 4)
    }

    func testAchievementCriteriaInitialization() {
        let criteria = AchievementCriteria(
            achievementId: "test_achievement",
            requirement: .levelReached(level: 5),
            category: .milestone,
            tier: .silver
        )

        XCTAssertEqual(criteria.achievementId, "test_achievement")
        XCTAssertEqual(criteria.category, .milestone)
        XCTAssertEqual(criteria.tier, .silver)
    }
}

// MARK: - AchievementRequirement Tests

final class AchievementRequirementTests: XCTestCase {

    func testSingleActionRequirement() {
        let requirement = AchievementRequirement.singleAction(action: "first_prayer")

        if case .singleAction(let action) = requirement {
            XCTAssertEqual(action, "first_prayer")
        } else {
            XCTFail("Expected singleAction requirement")
        }
    }

    func testCumulativeCountRequirement() {
        let requirement = AchievementRequirement.cumulativeCount(action: "prayer", count: 100)

        if case .cumulativeCount(let action, let count) = requirement {
            XCTAssertEqual(action, "prayer")
            XCTAssertEqual(count, 100)
        } else {
            XCTFail("Expected cumulativeCount requirement")
        }
    }

    func testStreakDaysRequirement() {
        let requirement = AchievementRequirement.streakDays(type: .daily, days: 7)

        if case .streakDays(let type, let days) = requirement {
            XCTAssertEqual(type, .daily)
            XCTAssertEqual(days, 7)
        } else {
            XCTFail("Expected streakDays requirement")
        }
    }

    func testLevelReachedRequirement() {
        let requirement = AchievementRequirement.levelReached(level: 10)

        if case .levelReached(let level) = requirement {
            XCTAssertEqual(level, 10)
        } else {
            XCTFail("Expected levelReached requirement")
        }
    }

    func testHasanatEarnedRequirement() {
        let requirement = AchievementRequirement.hasanatEarned(amount: 10000)

        if case .hasanatEarned(let amount) = requirement {
            XCTAssertEqual(amount, 10000)
        } else {
            XCTFail("Expected hasanatEarned requirement")
        }
    }

    func testQuranProgressRequirement() {
        let requirement = AchievementRequirement.quranProgress(pages: 100)

        if case .quranProgress(let pages) = requirement {
            XCTAssertEqual(pages, 100)
        } else {
            XCTFail("Expected quranProgress requirement")
        }
    }

    func testTasbeehCountRequirement() {
        let requirement = AchievementRequirement.tasbeehCount(total: 10000)

        if case .tasbeehCount(let total) = requirement {
            XCTAssertEqual(total, 10000)
        } else {
            XCTFail("Expected tasbeehCount requirement")
        }
    }
}

// MARK: - AchievementCheckResult Tests

final class AchievementCheckResultTests: XCTestCase {

    func testAchievementCheckResultInitialization() {
        let achievement = Achievement(
            id: "test",
            title: "Test",
            description: "Test achievement",
            iconName: "star",
            category: .milestone,
            requirement: "Test requirement"
        )

        let result = AchievementCheckResult(
            achievement: achievement,
            wasUnlocked: true,
            progress: 1.0,
            currentValue: 100,
            targetValue: 100
        )

        XCTAssertEqual(result.achievement.id, "test")
        XCTAssertTrue(result.wasUnlocked)
        XCTAssertEqual(result.progress, 1.0)
        XCTAssertEqual(result.currentValue, 100)
        XCTAssertEqual(result.targetValue, 100)
    }

    func testAchievementCheckResultPartialProgress() {
        let achievement = Achievement(
            id: "test",
            title: "Test",
            description: "Test achievement",
            iconName: "star",
            category: .milestone,
            requirement: "Test requirement"
        )

        let result = AchievementCheckResult(
            achievement: achievement,
            wasUnlocked: false,
            progress: 0.5,
            currentValue: 50,
            targetValue: 100
        )

        XCTAssertFalse(result.wasUnlocked)
        XCTAssertEqual(result.progress, 0.5)
        XCTAssertEqual(result.currentValue, 50)
        XCTAssertEqual(result.targetValue, 100)
    }
}

// MARK: - AchievementManager Tests

final class AchievementManagerTests: XCTestCase {

    var sut: AchievementManager!

    override func setUp() {
        super.setUp()
        sut = AchievementManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertTrue(sut.recentlyUnlocked.isEmpty)
        XCTAssertFalse(sut.showingAchievementBanner)
        XCTAssertNil(sut.currentAchievementToShow)
    }

    func testUnlockedCountInitiallyZero() {
        XCTAssertEqual(sut.unlockedCount, 0)
    }

    func testTotalCountGreaterThanZero() {
        XCTAssertGreaterThan(sut.totalCount, 0)
    }

    func testCheckAchievementsWithZeroStats() {
        let stats = UserStats()
        sut.checkAchievements(with: stats)

        // Should not unlock any achievements with zero stats
        XCTAssertTrue(sut.recentlyUnlocked.isEmpty)
    }

    func testCheckAchievementsWithHighStats() {
        let stats = UserStats(
            totalHasanat: 1000,
            currentLevel: 5,
            unlockedAchievements: [],
            lessonsCompleted: 10,
            totalPrayersLogged: 100,
            totalAyahsRead: 0,
            totalTasbeehCount: 1000,
            streakFreezes: 0
        )

        sut.checkAchievements(with: stats)

        // Should unlock multiple achievements
        XCTAssertGreaterThan(sut.recentlyUnlocked.count, 0)
    }

    func testClearRecentlyUnlocked() {
        let stats = UserStats(
            totalHasanat: 1000,
            currentLevel: 5,
            unlockedAchievements: [],
            lessonsCompleted: 10,
            totalPrayersLogged: 100,
            totalAyahsRead: 0,
            totalTasbeehCount: 1000,
            streakFreezes: 0
        )

        sut.checkAchievements(with: stats)
        XCTAssertGreaterThan(sut.recentlyUnlocked.count, 0)

        sut.clearRecentlyUnlocked()
        XCTAssertTrue(sut.recentlyUnlocked.isEmpty)
    }

    func testDismissAchievementBanner() {
        sut.dismissAchievementBanner()

        XCTAssertFalse(sut.showingAchievementBanner)
        XCTAssertNil(sut.currentAchievementToShow)
    }

    func testGetUnlockedAchievements() {
        let stats = UserStats(
            totalHasanat: 1000,
            currentLevel: 5,
            unlockedAchievements: [],
            lessonsCompleted: 10,
            totalPrayersLogged: 100,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        sut.checkAchievements(with: stats)
        let unlocked = sut.getUnlockedAchievements()

        XCTAssertGreaterThan(unlocked.count, 0)
    }

    func testGetLockedAchievementsWithProgress() {
        let stats = UserStats(
            totalHasanat: 500,
            currentLevel: 3,
            unlockedAchievements: [],
            lessonsCompleted: 5,
            totalPrayersLogged: 50,
            totalAyahsRead: 0,
            totalTasbeehCount: 500,
            streakFreezes: 0
        )

        let lockedWithProgress = sut.getLockedAchievementsWithProgress(stats: stats)

        XCTAssertGreaterThan(lockedWithProgress.count, 0)

        // At least some should have progress
        let withProgress = lockedWithProgress.filter { $0.progress > 0 }
        XCTAssertGreaterThan(withProgress.count, 0)
    }
}
