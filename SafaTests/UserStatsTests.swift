// MARK: - UserStatsTests.swift
// PURPOSE: Unit tests for UserStats and level calculations
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class UserStatsTests: XCTestCase {

    // MARK: - Initialization Tests

    func testUserStatsDefaultInitialization() {
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
            totalHasanat: 1000,
            currentLevel: 5,
            unlockedAchievements: ["achievement1", "achievement2"],
            lessonsCompleted: 10,
            totalPrayersLogged: 50,
            totalAyahsRead: 200,
            totalTasbeehCount: 1000,
            streakFreezes: 2
        )

        XCTAssertEqual(stats.totalHasanat, 1000)
        XCTAssertEqual(stats.currentLevel, 5)
        XCTAssertEqual(stats.unlockedAchievements.count, 2)
        XCTAssertEqual(stats.lessonsCompleted, 10)
    }

    // MARK: - Level Calculation Tests

    func testCalculateLevelFromHasanat() {
        XCTAssertEqual(UserStats.calculateLevel(from: 0), 1)
        XCTAssertEqual(UserStats.calculateLevel(from: 50), 1)
        XCTAssertEqual(UserStats.calculateLevel(from: 100), 2)
        XCTAssertEqual(UserStats.calculateLevel(from: 300), 3)
        XCTAssertEqual(UserStats.calculateLevel(from: 600), 4)
        XCTAssertEqual(UserStats.calculateLevel(from: 1000), 5)
        XCTAssertEqual(UserStats.calculateLevel(from: 2000), 6)
        XCTAssertEqual(UserStats.calculateLevel(from: 4000), 7)
        XCTAssertEqual(UserStats.calculateLevel(from: 7000), 8)
        XCTAssertEqual(UserStats.calculateLevel(from: 12000), 9)
        XCTAssertEqual(UserStats.calculateLevel(from: 20000), 10)
        XCTAssertEqual(UserStats.calculateLevel(from: 50000), 10)
    }

    func testCalculateLevelBoundaries() {
        XCTAssertEqual(UserStats.calculateLevel(from: 99), 1)
        XCTAssertEqual(UserStats.calculateLevel(from: 100), 2)
        XCTAssertEqual(UserStats.calculateLevel(from: 299), 2)
        XCTAssertEqual(UserStats.calculateLevel(from: 300), 3)
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
        XCTAssertEqual(UserStats.levelTitle(for: 11), "Beginner")
    }

    // MARK: - Hasanat For Level Tests

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

    // MARK: - Encoding/Decoding Tests

    func testUserStatsCodable() throws {
        let original = UserStats(
            totalHasanat: 500,
            currentLevel: 3,
            unlockedAchievements: ["test"],
            lessonsCompleted: 5,
            totalPrayersLogged: 25,
            totalAyahsRead: 100,
            totalTasbeehCount: 500,
            streakFreezes: 1
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserStats.self, from: data)

        XCTAssertEqual(original.totalHasanat, decoded.totalHasanat)
        XCTAssertEqual(original.currentLevel, decoded.currentLevel)
        XCTAssertEqual(original.unlockedAchievements, decoded.unlockedAchievements)
    }

    // MARK: - Hasanat Award Tests

    func testHasanatAwardPoints() {
        XCTAssertEqual(HasanatAward.prayerLogged.points, 10)
        XCTAssertEqual(HasanatAward.prayerAllFive.points, 25)
        XCTAssertEqual(HasanatAward.quranPage.points, 5)
        XCTAssertEqual(HasanatAward.quranSurah.points, 15)
        XCTAssertEqual(HasanatAward.quranJuz.points, 50)
        XCTAssertEqual(HasanatAward.lessonComplete.points, 10)
        XCTAssertEqual(HasanatAward.morningDhikr.points, 15)
        XCTAssertEqual(HasanatAward.eveningDhikr.points, 15)
    }

    // MARK: - User Preferences Tests

    func testUserPreferencesDefault() {
        let prefs = UserPreferences()

        // Defaults are now set via AppDefaults
        XCTAssertEqual(prefs.calculationMethod, AppDefaults.calculationMethod)
        XCTAssertEqual(prefs.madhab, AppDefaults.madhab)
        XCTAssertEqual(prefs.notificationsEnabled, AppDefaults.notificationsEnabled)
        XCTAssertEqual(prefs.hapticFeedbackEnabled, AppDefaults.hapticFeedbackEnabled)
        XCTAssertFalse(prefs.hasCompletedOnboarding)
    }

    func testUserPreferencesCustom() {
        let prefs = UserPreferences(
            calculationMethod: .muslimWorldLeague,
            madhab: .hanafi,
            notificationsEnabled: false,
            hasCompletedOnboarding: true
        )

        XCTAssertEqual(prefs.calculationMethod, .muslimWorldLeague)
        XCTAssertEqual(prefs.madhab, .hanafi)
        XCTAssertFalse(prefs.notificationsEnabled)
        XCTAssertTrue(prefs.hasCompletedOnboarding)
    }

    func testUserPreferencesCodable() throws {
        let original = UserPreferences(
            calculationMethod: .egypt,
            madhab: .hanafi,
            notificationsEnabled: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserPreferences.self, from: data)

        XCTAssertEqual(original.calculationMethod, decoded.calculationMethod)
        XCTAssertEqual(original.madhab, decoded.madhab)
    }
}
