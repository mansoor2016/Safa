// MARK: - UserStatsTests.swift
// PURPOSE: Unit tests for UserStats initialization, codable, and UserPreferences
// DEPENDENCIES: XCTest
// NOTE: Level calc → IntegrationTests, HasanatAward points → HasanatTrackingTests,
//       Level titles → IntegrationTests

import XCTest
@testable import Safa

final class UserStatsTests: XCTestCase {

    // MARK: - Initialization Tests

    func testUserStatsDefaultInitialization() {
        let stats = UserStats()

        XCTAssertEqual(stats.totalHasanat, 0)
        XCTAssertEqual(stats.currentLevel, 1)
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
            lessonsCompleted: 10,
            totalPrayersLogged: 50,
            totalAyahsRead: 200,
            totalTasbeehCount: 1000,
            streakFreezes: 2
        )

        XCTAssertEqual(stats.totalHasanat, 1000)
        XCTAssertEqual(stats.currentLevel, 5)
        XCTAssertEqual(stats.lessonsCompleted, 10)
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
        XCTAssertEqual(UserStats.levelTitle(for: 11), "Sabir")
        XCTAssertEqual(UserStats.levelTitle(for: 12), "Shakir")
        XCTAssertEqual(UserStats.levelTitle(for: 13), "Mukhlis")
        XCTAssertEqual(UserStats.levelTitle(for: 14), "Muttaqi")
        XCTAssertEqual(UserStats.levelTitle(for: 15), "Sadiq")
        XCTAssertEqual(UserStats.levelTitle(for: 16), "Zahid")
        XCTAssertEqual(UserStats.levelTitle(for: 17), "Arif")
        XCTAssertEqual(UserStats.levelTitle(for: 18), "Qani")
        XCTAssertEqual(UserStats.levelTitle(for: 19), "Siddiq")
        XCTAssertEqual(UserStats.levelTitle(for: 20), "Muhsin al-Kamil")
    }

    // MARK: - Level Title Edge Cases

    func testLevelTitleInvalidLevel() {
        XCTAssertEqual(UserStats.levelTitle(for: 0), "Beginner")
        XCTAssertEqual(UserStats.levelTitle(for: -1), "Beginner")
        XCTAssertEqual(UserStats.levelTitle(for: 100), "Beginner")
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
        XCTAssertEqual(UserStats.hasanatForLevel(10), 18000)
        XCTAssertEqual(UserStats.hasanatForLevel(11), 25000)
        XCTAssertEqual(UserStats.hasanatForLevel(12), 35000)
        XCTAssertEqual(UserStats.hasanatForLevel(13), 50000)
        XCTAssertEqual(UserStats.hasanatForLevel(14), 70000)
        XCTAssertEqual(UserStats.hasanatForLevel(15), 95000)
        XCTAssertEqual(UserStats.hasanatForLevel(16), 120000)
        XCTAssertEqual(UserStats.hasanatForLevel(17), 145000)
        XCTAssertEqual(UserStats.hasanatForLevel(18), 170000)
        XCTAssertEqual(UserStats.hasanatForLevel(19), 195000)
        XCTAssertEqual(UserStats.hasanatForLevel(20), 220000)
    }

    // MARK: - Encoding/Decoding Tests

    func testUserStatsCodable() throws {
        let original = UserStats(
            totalHasanat: 500,
            currentLevel: 3,
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
        XCTAssertEqual(original.lessonsCompleted, decoded.lessonsCompleted)
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
