// MARK: - AchievementsViewModelTests.swift
// PURPOSE: Unit tests for AchievementsViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
import SwiftUI
@testable import Safa

final class AchievementsViewModelTests: XCTestCase {

    var sut: AchievementsViewModel!

    override func setUp() {
        super.setUp()
        sut = AchievementsViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_loadsAchievements() {
        XCTAssertFalse(sut.achievements.isEmpty)
    }

    func test_initialState_selectedCategoryIsNil() {
        XCTAssertNil(sut.selectedCategory)
    }

    func test_initialState_filteredAchievementsEqualsAllAchievements() {
        XCTAssertEqual(sut.filteredAchievements.count, sut.achievements.count)
    }

    func test_initialState_hasCorrectTotalCount() {
        XCTAssertEqual(sut.totalCount, sut.achievements.count)
    }

    // MARK: - Achievement Count Tests

    func test_totalCount_matchesAchievementsCount() {
        XCTAssertEqual(sut.totalCount, sut.achievements.count)
    }

    func test_unlockedCount_matchesUnlockedAchievements() {
        let expectedUnlocked = sut.achievements.filter { $0.isUnlocked }.count
        XCTAssertEqual(sut.unlockedCount, expectedUnlocked)
    }

    func test_initialState_hasUnlockedAchievements() {
        // The loadAchievements method unlocks some demo achievements
        XCTAssertGreaterThan(sut.unlockedCount, 0)
    }

    // MARK: - Progress Percentage Tests

    func test_progressPercentage_calculatesCorrectly() {
        guard sut.totalCount > 0 else {
            XCTFail("Should have achievements")
            return
        }
        let expectedPercentage = Double(sut.unlockedCount) / Double(sut.totalCount)
        XCTAssertEqual(sut.progressPercentage, expectedPercentage, accuracy: 0.001)
    }

    func test_progressPercentage_isBetweenZeroAndOne() {
        XCTAssertGreaterThanOrEqual(sut.progressPercentage, 0)
        XCTAssertLessThanOrEqual(sut.progressPercentage, 1)
    }

    func test_progressPercentage_isZero_whenNoAchievementsUnlocked() {
        // Lock all achievements
        sut.achievements = sut.achievements.map { achievement in
            var updated = achievement
            updated.isUnlocked = false
            return updated
        }
        XCTAssertEqual(sut.progressPercentage, 0)
    }

    func test_progressPercentage_isOne_whenAllAchievementsUnlocked() {
        // Unlock all achievements
        sut.achievements = sut.achievements.map { achievement in
            var updated = achievement
            updated.isUnlocked = true
            return updated
        }
        XCTAssertEqual(sut.progressPercentage, 1)
    }

    // MARK: - Category Filter Tests

    func test_filteredAchievements_returnsAll_whenNoCategorySelected() {
        sut.selectedCategory = nil
        XCTAssertEqual(sut.filteredAchievements.count, sut.achievements.count)
    }

    func test_filteredAchievements_filtersByQuranCategory() {
        sut.selectedCategory = .quran
        let results = sut.filteredAchievements
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.allSatisfy { $0.category == .quran })
    }

    func test_filteredAchievements_filtersByPrayerCategory() {
        sut.selectedCategory = .prayer
        let results = sut.filteredAchievements
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.allSatisfy { $0.category == .prayer })
    }

    func test_filteredAchievements_filtersByLearningCategory() {
        sut.selectedCategory = .learning
        let results = sut.filteredAchievements
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.allSatisfy { $0.category == .learning })
    }

    func test_filteredAchievements_filtersByDhikrCategory() {
        sut.selectedCategory = .dhikr
        let results = sut.filteredAchievements
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.allSatisfy { $0.category == .dhikr })
    }

    func test_filteredAchievements_filtersByRamadanCategory() {
        sut.selectedCategory = .ramadan
        let results = sut.filteredAchievements
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.allSatisfy { $0.category == .ramadan })
    }

    func test_selectedCategory_canBeChanged() {
        sut.selectedCategory = .quran
        XCTAssertEqual(sut.selectedCategory, .quran)

        sut.selectedCategory = .prayer
        XCTAssertEqual(sut.selectedCategory, .prayer)
    }

    func test_selectedCategory_canBeCleared() {
        sut.selectedCategory = .quran
        XCTAssertNotNil(sut.selectedCategory)

        sut.selectedCategory = nil
        XCTAssertNil(sut.selectedCategory)
    }

    // MARK: - Load Achievements Tests

    func test_loadAchievements_populatesAchievementsArray() {
        sut.achievements = []
        XCTAssertTrue(sut.achievements.isEmpty)

        sut.loadAchievements()
        XCTAssertFalse(sut.achievements.isEmpty)
    }

    func test_loadAchievements_unlocksSpecificAchievements() {
        sut.loadAchievements()

        // These achievements are unlocked for demo
        let prayerFirst = sut.achievements.first { $0.id == "prayer_first" }
        let quranFirstPage = sut.achievements.first { $0.id == "quran_first_page" }
        let dhikrFirst = sut.achievements.first { $0.id == "dhikr_first" }
        let prayerPerfectDay = sut.achievements.first { $0.id == "prayer_perfect_day" }

        XCTAssertTrue(prayerFirst?.isUnlocked ?? false)
        XCTAssertTrue(quranFirstPage?.isUnlocked ?? false)
        XCTAssertTrue(dhikrFirst?.isUnlocked ?? false)
        XCTAssertTrue(prayerPerfectDay?.isUnlocked ?? false)
    }

    func test_loadAchievements_setsUnlockedAtDate() {
        sut.loadAchievements()

        let unlockedAchievements = sut.achievements.filter { $0.isUnlocked }
        for achievement in unlockedAchievements {
            XCTAssertNotNil(achievement.unlockedAt, "Achievement \(achievement.id) should have unlockedAt date")
        }
    }

    // MARK: - Achievement Data Tests

    func test_achievements_allHaveValidIds() {
        for achievement in sut.achievements {
            XCTAssertFalse(achievement.id.isEmpty, "Achievement should have non-empty id")
        }
    }

    func test_achievements_allHaveValidTitles() {
        for achievement in sut.achievements {
            XCTAssertFalse(achievement.title.isEmpty, "Achievement \(achievement.id) should have title")
        }
    }

    func test_achievements_allHaveValidDescriptions() {
        for achievement in sut.achievements {
            XCTAssertFalse(achievement.description.isEmpty, "Achievement \(achievement.id) should have description")
        }
    }

    func test_achievements_allHaveValidIcons() {
        for achievement in sut.achievements {
            XCTAssertFalse(achievement.iconName.isEmpty, "Achievement \(achievement.id) should have icon")
        }
    }

    func test_achievements_containsQuranAchievements() {
        let quranAchievements = sut.achievements.filter { $0.category == .quran }
        XCTAssertFalse(quranAchievements.isEmpty)
    }

    func test_achievements_containsPrayerAchievements() {
        let prayerAchievements = sut.achievements.filter { $0.category == .prayer }
        XCTAssertFalse(prayerAchievements.isEmpty)
    }

    func test_achievements_containsLearningAchievements() {
        let learningAchievements = sut.achievements.filter { $0.category == .learning }
        XCTAssertFalse(learningAchievements.isEmpty)
    }

    // MARK: - Achievement Entity Tests

    func test_achievement_iconAliasMatchesIconName() {
        let achievement = Achievement(
            id: "test",
            category: .quran,
            title: "Test",
            description: "Test",
            iconName: "book",
            isUnlocked: false
        )
        XCTAssertEqual(achievement.icon, achievement.iconName)
    }

    func test_achievement_colorForQuranCategory() {
        let achievement = Achievement(
            id: "test",
            category: .quran,
            title: "Test",
            description: "Test",
            iconName: "book",
            isUnlocked: false
        )
        XCTAssertEqual(achievement.color, .green)
    }

    func test_achievement_colorForPrayerCategory() {
        let achievement = Achievement(
            id: "test",
            category: .prayer,
            title: "Test",
            description: "Test",
            iconName: "moon",
            isUnlocked: false
        )
        XCTAssertEqual(achievement.color, .blue)
    }

    func test_achievement_colorForLearningCategory() {
        let achievement = Achievement(
            id: "test",
            category: .learning,
            title: "Test",
            description: "Test",
            iconName: "book",
            isUnlocked: false
        )
        XCTAssertEqual(achievement.color, .purple)
    }

    // MARK: - Achievement Category Tests

    func test_achievementCategory_allCasesContainsAllCategories() {
        let allCases = Achievement.AchievementCategory.allCases
        XCTAssertTrue(allCases.contains(.quran))
        XCTAssertTrue(allCases.contains(.prayer))
        XCTAssertTrue(allCases.contains(.learning))
        XCTAssertTrue(allCases.contains(.dhikr))
        XCTAssertTrue(allCases.contains(.ramadan))
        XCTAssertTrue(allCases.contains(.social))
        XCTAssertTrue(allCases.contains(.streak))
        XCTAssertTrue(allCases.contains(.milestone))
        XCTAssertTrue(allCases.contains(.special))
    }

    func test_achievementCategory_displayNameCapitalized() {
        XCTAssertEqual(Achievement.AchievementCategory.quran.displayName, "Quran")
        XCTAssertEqual(Achievement.AchievementCategory.prayer.displayName, "Prayer")
        XCTAssertEqual(Achievement.AchievementCategory.learning.displayName, "Learning")
        XCTAssertEqual(Achievement.AchievementCategory.dhikr.displayName, "Dhikr")
        XCTAssertEqual(Achievement.AchievementCategory.ramadan.displayName, "Ramadan")
    }

    // MARK: - Edge Cases

    func test_progressPercentage_handlesEmptyAchievements() {
        sut.achievements = []
        XCTAssertEqual(sut.progressPercentage, 0)
    }

    func test_totalCount_handlesEmptyAchievements() {
        sut.achievements = []
        XCTAssertEqual(sut.totalCount, 0)
    }

    func test_unlockedCount_handlesEmptyAchievements() {
        sut.achievements = []
        XCTAssertEqual(sut.unlockedCount, 0)
    }

    func test_filteredAchievements_handlesEmptyAchievements() {
        sut.achievements = []
        sut.selectedCategory = .quran
        XCTAssertTrue(sut.filteredAchievements.isEmpty)
    }
}
