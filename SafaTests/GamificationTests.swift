// MARK: - GamificationTests.swift
// PURPOSE: Unit tests for gamification system
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class GamificationTests: XCTestCase {

    // MARK: - Level Calculation Tests

    func testCalculateLevelBeginner() {
        let level = UserStats.calculateLevel(from: 0)
        XCTAssertEqual(level, 1)

        let levelAt50 = UserStats.calculateLevel(from: 50)
        XCTAssertEqual(levelAt50, 1)

        let levelAt99 = UserStats.calculateLevel(from: 99)
        XCTAssertEqual(levelAt99, 1)
    }

    func testCalculateLevelSeeker() {
        let level = UserStats.calculateLevel(from: 100)
        XCTAssertEqual(level, 2)

        let levelAt200 = UserStats.calculateLevel(from: 200)
        XCTAssertEqual(levelAt200, 2)

        let levelAt299 = UserStats.calculateLevel(from: 299)
        XCTAssertEqual(levelAt299, 2)
    }

    func testCalculateLevelProgression() {
        XCTAssertEqual(UserStats.calculateLevel(from: 300), 3)   // Learner
        XCTAssertEqual(UserStats.calculateLevel(from: 600), 4)   // Dedicated
        XCTAssertEqual(UserStats.calculateLevel(from: 1000), 5)  // Consistent
        XCTAssertEqual(UserStats.calculateLevel(from: 2000), 6)  // Devoted
        XCTAssertEqual(UserStats.calculateLevel(from: 4000), 7)  // Steadfast
        XCTAssertEqual(UserStats.calculateLevel(from: 7000), 8)  // Committed
        XCTAssertEqual(UserStats.calculateLevel(from: 12000), 9) // Excellent
        XCTAssertEqual(UserStats.calculateLevel(from: 20000), 10) // Muhsin
    }

    func testCalculateLevelMaxLevel() {
        let level = UserStats.calculateLevel(from: 100000)
        XCTAssertEqual(level, 10)
    }

    // MARK: - Level Title Tests

    func testLevelTitles() {
        XCTAssertEqual(UserStats.levelTitle(for: 1), "Beginner")
        XCTAssertEqual(UserStats.levelTitle(for: 2), "Seeker")
        XCTAssertEqual(UserStats.levelTitle(for: 3), "Learner")
        XCTAssertEqual(UserStats.levelTitle(for: 4), "Dedicated")
        XCTAssertEqual(UserStats.levelTitle(for: 5), "Consistent")
        XCTAssertEqual(UserStats.levelTitle(for: 6), "Devoted")
        XCTAssertEqual(UserStats.levelTitle(for: 7), "Steadfast")
        XCTAssertEqual(UserStats.levelTitle(for: 8), "Committed")
        XCTAssertEqual(UserStats.levelTitle(for: 9), "Excellent")
        XCTAssertEqual(UserStats.levelTitle(for: 10), "Muhsin")
    }

    func testLevelTitleInvalidLevel() {
        XCTAssertEqual(UserStats.levelTitle(for: 0), "Beginner")
        XCTAssertEqual(UserStats.levelTitle(for: -1), "Beginner")
        XCTAssertEqual(UserStats.levelTitle(for: 100), "Beginner")
    }

    // MARK: - Hasanat Required Tests

    func testHasanatForLevel() {
        XCTAssertEqual(UserStats.hasanatForLevel(1), 0)
        XCTAssertEqual(UserStats.hasanatForLevel(2), 100)
        XCTAssertEqual(UserStats.hasanatForLevel(3), 300)
        XCTAssertEqual(UserStats.hasanatForLevel(4), 600)
        XCTAssertEqual(UserStats.hasanatForLevel(5), 1000)
        XCTAssertEqual(UserStats.hasanatForLevel(6), 2000)
        XCTAssertEqual(UserStats.hasanatForLevel(7), 4000)
        XCTAssertEqual(UserStats.hasanatForLevel(8), 7000)
        XCTAssertEqual(UserStats.hasanatForLevel(9), 12000)
        XCTAssertEqual(UserStats.hasanatForLevel(10), 20000)
    }

    // MARK: - Hasanat Award Tests

    func testHasanatAwardPoints() {
        XCTAssertEqual(HasanatAward.prayerLogged.points, 10)
        XCTAssertEqual(HasanatAward.prayerAllFive.points, 25)
        XCTAssertEqual(HasanatAward.quranPage.points, 5)
        XCTAssertEqual(HasanatAward.quranSurah.points, 15)
        XCTAssertEqual(HasanatAward.quranJuz.points, 50)
        XCTAssertEqual(HasanatAward.lessonComplete.points, 10)
        XCTAssertEqual(HasanatAward.lessonPerfect.points, 5)
        XCTAssertEqual(HasanatAward.morningDhikr.points, 15)
        XCTAssertEqual(HasanatAward.eveningDhikr.points, 15)
        XCTAssertEqual(HasanatAward.tasbeehSession.points, 10)
        XCTAssertEqual(HasanatAward.fastingDay.points, 20)
        XCTAssertEqual(HasanatAward.taraweeh.points, 25)
    }

    // MARK: - Streak Tests

    func testStreakInitialization() {
        let streak = Streak(type: .daily)

        XCTAssertEqual(streak.currentCount, 0)
        XCTAssertEqual(streak.longestCount, 0)
        XCTAssertNil(streak.lastActivityDate)
        XCTAssertEqual(streak.type, .daily)
    }

    func testStreakIsActiveToday() {
        var streak = Streak(type: .daily)
        streak.lastActivityDate = Date()

        XCTAssertTrue(streak.isActiveToday)
    }

    func testStreakNotActiveYesterday() {
        var streak = Streak(type: .daily)
        streak.lastActivityDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())

        XCTAssertFalse(streak.isActiveToday)
    }

    func testStreakTypeDisplayNames() {
        XCTAssertEqual(StreakType.daily.displayName, "Daily")
        XCTAssertEqual(StreakType.prayer.displayName, "Prayer")
        XCTAssertEqual(StreakType.quran.displayName, "Quran")
        XCTAssertEqual(StreakType.dhikr.displayName, "Dhikr")
        XCTAssertEqual(StreakType.learning.displayName, "Learning")
    }

    // MARK: - Achievement Tests

    func testAllAchievementsExist() {
        let achievements = Achievement.allAchievements

        XCTAssertGreaterThan(achievements.count, 0)
        XCTAssertGreaterThan(achievements.count, 20) // We defined many achievements
    }

    func testAchievementCategories() {
        let achievements = Achievement.allAchievements

        let quranAchievements = achievements.filter { $0.category == .quran }
        let prayerAchievements = achievements.filter { $0.category == .prayer }
        let learningAchievements = achievements.filter { $0.category == .learning }
        let dhikrAchievements = achievements.filter { $0.category == .dhikr }
        let ramadanAchievements = achievements.filter { $0.category == .ramadan }

        XCTAssertGreaterThan(quranAchievements.count, 0)
        XCTAssertGreaterThan(prayerAchievements.count, 0)
        XCTAssertGreaterThan(learningAchievements.count, 0)
        XCTAssertGreaterThan(dhikrAchievements.count, 0)
        XCTAssertGreaterThan(ramadanAchievements.count, 0)
    }

    func testAchievementsHaveUniqueIds() {
        let achievements = Achievement.allAchievements
        let ids = achievements.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All achievement IDs should be unique")
    }

    func testAchievementsHaveRequiredFields() {
        for achievement in Achievement.allAchievements {
            XCTAssertFalse(achievement.id.isEmpty, "Achievement ID should not be empty")
            XCTAssertFalse(achievement.title.isEmpty, "Achievement title should not be empty")
            XCTAssertFalse(achievement.description.isEmpty, "Achievement description should not be empty")
            XCTAssertFalse(achievement.iconName.isEmpty, "Achievement icon should not be empty")
        }
    }

    // MARK: - User Stats Tests

    func testUserStatsInitialization() {
        let stats = UserStats()

        XCTAssertEqual(stats.totalHasanat, 0)
        XCTAssertEqual(stats.currentLevel, 1)
        XCTAssertTrue(stats.unlockedAchievements.isEmpty)
        XCTAssertEqual(stats.lessonsCompleted, 0)
        XCTAssertEqual(stats.totalPrayersLogged, 0)
        XCTAssertEqual(stats.totalAyahsRead, 0)
        XCTAssertEqual(stats.totalTasbeehCount, 0)
        XCTAssertEqual(stats.streakFreezes, 0)
    }

    func testUserStatsCustomInitialization() {
        let stats = UserStats(
            totalHasanat: 500,
            currentLevel: 3,
            unlockedAchievements: ["achievement1", "achievement2"],
            lessonsCompleted: 10,
            totalPrayersLogged: 50,
            totalAyahsRead: 100,
            totalTasbeehCount: 1000,
            streakFreezes: 2
        )

        XCTAssertEqual(stats.totalHasanat, 500)
        XCTAssertEqual(stats.currentLevel, 3)
        XCTAssertEqual(stats.unlockedAchievements.count, 2)
        XCTAssertEqual(stats.lessonsCompleted, 10)
        XCTAssertEqual(stats.totalPrayersLogged, 50)
        XCTAssertEqual(stats.totalAyahsRead, 100)
        XCTAssertEqual(stats.totalTasbeehCount, 1000)
        XCTAssertEqual(stats.streakFreezes, 2)
    }
}
