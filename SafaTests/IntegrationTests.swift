// MARK: - IntegrationTests.swift
// PURPOSE: Integration tests for user flows
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

// MARK: - Model Integration Tests

final class ModelIntegrationTests: XCTestCase {

    // MARK: - User Stats & Level Tests

    func testLevelProgression() {
        // Given
        var stats = UserStats()
        XCTAssertEqual(stats.currentLevel, 1)
        XCTAssertEqual(UserStats.levelTitle(for: stats.currentLevel), "Beginner")

        // When - Accumulate hasanat to level 2
        stats.totalHasanat = 100

        // Then - Verify level calculation
        let expectedLevel = UserStats.calculateLevel(from: stats.totalHasanat)
        XCTAssertEqual(expectedLevel, 2)
        XCTAssertEqual(UserStats.levelTitle(for: expectedLevel), "Seeker")
    }

    // Level titles tested in testLevelProgression above (spot-check)
    // Full level title coverage: see hasanatForLevel in Gamification.swift

    func testHasanatThresholds() {
        let thresholds: [(hasanat: Int, expectedLevel: Int)] = [
            (0, 1),
            (99, 1),
            (100, 2),
            (299, 2),
            (300, 3),
            (599, 3),
            (600, 4),
            (999, 4),
            (1000, 5),
            (1999, 5),
            (2000, 6),
            (3999, 6),
            (4000, 7),
            (6999, 7),
            (7000, 8),
            (11999, 8),
            (12000, 9),
            (17999, 9),
            (18000, 10),
            (24999, 10),
            (25000, 11),
            (220000, 20),
            (1_000_000, 20) // Max level
        ]

        for (hasanat, expectedLevel) in thresholds {
            let calculatedLevel = UserStats.calculateLevel(from: hasanat)
            XCTAssertEqual(calculatedLevel, expectedLevel, "Hasanat \(hasanat) should be level \(expectedLevel)")
        }
    }

    // MARK: - Prayer Type Tests

    func testAllPrayerTypes() {
        let obligatoryPrayers = PrayerType.obligatoryPrayers

        XCTAssertEqual(obligatoryPrayers.count, 5)
        XCTAssertTrue(obligatoryPrayers.contains(.fajr))
        XCTAssertTrue(obligatoryPrayers.contains(.dhuhr))
        XCTAssertTrue(obligatoryPrayers.contains(.asr))
        XCTAssertTrue(obligatoryPrayers.contains(.maghrib))
        XCTAssertTrue(obligatoryPrayers.contains(.isha))
        XCTAssertFalse(obligatoryPrayers.contains(.sunrise))
    }

    func testPrayerTypeDisplayNames() {
        XCTAssertEqual(PrayerType.fajr.displayName, "Fajr")
        XCTAssertEqual(PrayerType.sunrise.displayName, "Sunrise")
        XCTAssertEqual(PrayerType.dhuhr.displayName, "Dhuhr")
        XCTAssertEqual(PrayerType.asr.displayName, "Asr")
        XCTAssertEqual(PrayerType.maghrib.displayName, "Maghrib")
        XCTAssertEqual(PrayerType.isha.displayName, "Isha")
    }

    // MARK: - Streak Type Tests

    func testStreakTypes() {
        for streakType in StreakType.allCases {
            XCTAssertFalse(streakType.displayName.isEmpty)
            XCTAssertFalse(streakType.description.isEmpty)
            XCTAssertFalse(streakType.iconName.isEmpty)
        }
    }

    func testStreakIsActiveToday() {
        // Active streak (today)
        let activeStreak = Streak(
            type: .prayer,
            currentCount: 5,
            longestCount: 10,
            lastActivityDate: Date()
        )
        XCTAssertTrue(activeStreak.isActiveToday)

        // Inactive streak (no activity)
        let inactiveStreak = Streak(
            type: .prayer,
            currentCount: 0,
            longestCount: 0,
            lastActivityDate: nil
        )
        XCTAssertFalse(inactiveStreak.isActiveToday)

        // Streak from yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayStreak = Streak(
            type: .prayer,
            currentCount: 5,
            longestCount: 10,
            lastActivityDate: yesterday
        )
        XCTAssertFalse(yesterdayStreak.isActiveToday)
    }

    // MARK: - Hasanat Award Tests

    func testHasanatAwardPoints() {
        // Verify all hasanat awards have positive points
        XCTAssertGreaterThan(HasanatAward.prayerLogged.points, 0)
        XCTAssertGreaterThan(HasanatAward.prayerAllFive.points, 0)
        XCTAssertGreaterThan(HasanatAward.quranPage.points, 0)
        XCTAssertGreaterThan(HasanatAward.lessonComplete.points, 0)
        XCTAssertGreaterThan(HasanatAward.morningDhikr.points, 0)
        XCTAssertGreaterThan(HasanatAward.eveningDhikr.points, 0)

        // Verify all five prayers bonus is greater than single prayer
        XCTAssertGreaterThan(HasanatAward.prayerAllFive.points, HasanatAward.prayerLogged.points)
    }

    // MARK: - User Preferences Tests

    func testUserPreferencesDefaults() {
        let prefs = UserPreferences()

        // Verify defaults are set
        XCTAssertEqual(prefs.calculationMethod, AppDefaults.calculationMethod)
        XCTAssertEqual(prefs.madhab, AppDefaults.madhab)
        XCTAssertFalse(prefs.hasCompletedOnboarding)
    }

    func testUserPreferencesCustomization() {
        var prefs = UserPreferences()

        // Customize preferences
        prefs.calculationMethod = .muslimWorldLeague
        prefs.madhab = .hanafi
        prefs.notificationsEnabled = true
        prefs.hasCompletedOnboarding = true

        // Verify customization
        XCTAssertEqual(prefs.calculationMethod, .muslimWorldLeague)
        XCTAssertEqual(prefs.madhab, .hanafi)
        XCTAssertTrue(prefs.notificationsEnabled)
        XCTAssertTrue(prefs.hasCompletedOnboarding)
    }

    func testUserPreferencesCodable() throws {
        let original = UserPreferences(
            calculationMethod: .egypt,
            madhab: .hanafi,
            notificationsEnabled: true,
            hasCompletedOnboarding: true
        )

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserPreferences.self, from: data)

        // Verify
        XCTAssertEqual(original.calculationMethod, decoded.calculationMethod)
        XCTAssertEqual(original.madhab, decoded.madhab)
        XCTAssertEqual(original.hasCompletedOnboarding, decoded.hasCompletedOnboarding)
    }

    // MARK: - Calculation Method Tests

    func testCalculationMethods() {
        for method in CalculationMethod.allCases {
            XCTAssertFalse(method.displayName.isEmpty)
            XCTAssertFalse(method.methodDescription.isEmpty)
        }
    }

    // MARK: - Madhab Tests

    func testMadhabs() {
        for madhab in Madhab.allCases {
            XCTAssertFalse(madhab.displayName.isEmpty)
            XCTAssertGreaterThan(madhab.shadowRatio, 0)
        }
    }

    // MARK: - Hijri Date Tests

    func testHijriDateConversion() {
        let converter = HijriDateConverter.shared
        let date = Date()

        let (year, month, day) = converter.hijriComponents(from: date)

        // Valid Hijri year range
        XCTAssertGreaterThan(year, 1400)
        XCTAssertLessThan(year, 1500)

        // Valid month
        XCTAssertGreaterThanOrEqual(month, 1)
        XCTAssertLessThanOrEqual(month, 12)

        // Valid day
        XCTAssertGreaterThanOrEqual(day, 1)
        XCTAssertLessThanOrEqual(day, 30)
    }

    func testHijriDateFormatting() {
        let converter = HijriDateConverter.shared
        let date = Date()

        let fullFormat = converter.hijriDateString(from: date, style: .full)
        let shortFormat = converter.hijriDateString(from: date, style: .short)
        let arabicFormat = converter.hijriDateString(from: date, style: .arabic)
        let monthYearFormat = converter.hijriDateString(from: date, style: .monthYear)

        XCTAssertFalse(fullFormat.isEmpty)
        XCTAssertFalse(shortFormat.isEmpty)
        XCTAssertFalse(arabicFormat.isEmpty)
        XCTAssertFalse(monthYearFormat.isEmpty)

        // Full format should contain "AH"
        XCTAssertTrue(fullFormat.contains("AH"))

        // Short format should be shorter
        XCTAssertLessThan(shortFormat.count, fullFormat.count)
    }
}

// MARK: - Prayer Log Integration Tests

final class PrayerLogIntegrationTests: XCTestCase {

    func testPrayerLogCreation() {
        let log = PrayerLog(
            prayerType: .fajr,
            date: Date(),
            loggedAt: Date(),
            isOnTime: true,
            isMakeup: false
        )

        XCTAssertEqual(log.prayerType, .fajr)
        XCTAssertTrue(log.isOnTime)
        XCTAssertFalse(log.isMakeup)
    }

    func testPrayerLogCodable() throws {
        let original = PrayerLog(
            prayerType: .dhuhr,
            date: Date(),
            loggedAt: Date(),
            isOnTime: false,
            isMakeup: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PrayerLog.self, from: data)

        XCTAssertEqual(original.prayerType, decoded.prayerType)
        XCTAssertEqual(original.isOnTime, decoded.isOnTime)
        XCTAssertEqual(original.isMakeup, decoded.isMakeup)
    }
}

// MARK: - Hadith Model Integration Tests

final class HadithModelIntegrationTests: XCTestCase {

    func testHadithGradingDescriptions() {
        XCTAssertEqual(HadithGrading.sahih.description, "Authentic")
        XCTAssertEqual(HadithGrading.hasan.description, "Good")
        XCTAssertEqual(HadithGrading.daif.description, "Weak")
        XCTAssertEqual(HadithGrading.mawdu.description, "Fabricated")
    }

    func testHadithCollectionStatics() {
        let bukhari = HadithCollection.sahihBukhari
        let muslim = HadithCollection.sahihMuslim

        XCTAssertEqual(bukhari.id, "bukhari")
        XCTAssertEqual(muslim.id, "muslim")
        XCTAssertGreaterThan(bukhari.totalHadiths, 0)
        XCTAssertGreaterThan(muslim.totalHadiths, 0)
    }
}
