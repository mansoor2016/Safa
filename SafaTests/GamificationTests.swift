// MARK: - GamificationTests.swift
// PURPOSE: Unit tests for achievement system
// DEPENDENCIES: XCTest
// NOTE: Level calc → IntegrationTests, HasanatAward points → HasanatTrackingTests,
//       Streak behavior → StreakTests, UserStats init → UserStatsTests

import XCTest
@testable import Safa

final class GamificationTests: XCTestCase {

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
}
