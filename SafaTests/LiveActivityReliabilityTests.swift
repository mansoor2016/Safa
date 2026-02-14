// MARK: - LiveActivityReliabilityTests.swift
// PURPOSE: Tests for Live Activity reliability — preference defaults, codable backward
//          compatibility, next-prayer resolution, and coordinate fallback logic
// DEPENDENCIES: XCTest, @testable Safa, SafaShared

import XCTest
@testable import Safa
import SafaShared

// MARK: - Preference Defaults

final class LiveActivityPreferenceTests: XCTestCase {

    func test_liveActivityEnabled_defaultsToTrue() {
        // Given — a fresh UserPreferences with default init
        let prefs = UserPreferences()

        // Then — Live Activity should be on by default
        XCTAssertTrue(prefs.liveActivityEnabled)
    }

    func test_appDefaults_liveActivityEnabled_isTrue() {
        XCTAssertTrue(AppDefaults.liveActivityEnabled)
    }

    // MARK: - Codable Round-Trip

    func test_liveActivityEnabled_codableRoundTrip_preservesFalse() throws {
        // Given — prefs with Live Activity disabled
        var prefs = UserPreferences()
        prefs.liveActivityEnabled = false

        // When — encode then decode
        let data = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)

        // Then — the value survives the round-trip
        XCTAssertFalse(decoded.liveActivityEnabled)
    }

    func test_liveActivityEnabled_codableRoundTrip_preservesTrue() throws {
        // Given
        var prefs = UserPreferences()
        prefs.liveActivityEnabled = true

        // When
        let data = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)

        // Then
        XCTAssertTrue(decoded.liveActivityEnabled)
    }

    // MARK: - Backward Compatibility (missing key in stored JSON)

    func test_backwardCompat_missingLiveActivityKey_defaultsToTrue() throws {
        // Given — encode a full prefs, then strip the liveActivityEnabled key
        let prefs = UserPreferences()
        let data = try JSONEncoder().encode(prefs)
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json.removeValue(forKey: "liveActivityEnabled")
        let strippedData = try JSONSerialization.data(withJSONObject: json)

        // When — decode the stripped JSON
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: strippedData)

        // Then — should default to true (not crash)
        XCTAssertTrue(decoded.liveActivityEnabled)
    }

    func test_backwardCompat_missingKey_preservesAllOtherFields() throws {
        // Given — a prefs with non-default values
        var prefs = UserPreferences()
        prefs.calculationMethod = .karachi
        prefs.madhab = .shafi
        prefs.notificationsEnabled = false
        prefs.hapticFeedbackEnabled = false
        prefs.savedLocationName = "Dubai, UAE"
        prefs.savedLatitude = 25.2048
        prefs.savedLongitude = 55.2708
        prefs.hasCompletedOnboarding = true

        let data = try JSONEncoder().encode(prefs)
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json.removeValue(forKey: "liveActivityEnabled")
        let strippedData = try JSONSerialization.data(withJSONObject: json)

        // When
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: strippedData)

        // Then — all other fields preserved
        XCTAssertEqual(decoded.calculationMethod, .karachi)
        XCTAssertEqual(decoded.madhab, .shafi)
        XCTAssertFalse(decoded.notificationsEnabled)
        XCTAssertFalse(decoded.hapticFeedbackEnabled)
        XCTAssertEqual(decoded.savedLocationName, "Dubai, UAE")
        XCTAssertEqual(decoded.savedLatitude ?? 0, 25.2048, accuracy: 0.0001)
        XCTAssertEqual(decoded.savedLongitude ?? 0, 55.2708, accuracy: 0.0001)
        XCTAssertTrue(decoded.hasCompletedOnboarding)
        // And the new field defaults correctly
        XCTAssertTrue(decoded.liveActivityEnabled)
    }
}

// MARK: - Next Obligatory Prayer Logic

final class LiveActivityNextPrayerTests: XCTestCase {

    private func makePrayers(offsets: [(String, PrayerType, TimeInterval)], from base: Date) -> [PrayerTime] {
        offsets.map { name, type, offset in
            PrayerTime(
                type: type,
                time: base.addingTimeInterval(offset),
                isNext: false
            )
        }
    }

    func test_nextObligatoryPrayer_skipsPassed() {
        // Given — Fajr and Dhuhr are in the past, Asr is next
        let now = Date()
        let prayers = [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(-7200), isNext: false),
            PrayerTime(type: .sunrise, time: now.addingTimeInterval(-5400), isNext: false),
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(-3600), isNext: false),
            PrayerTime(type: .asr, time: now.addingTimeInterval(1800), isNext: false),
            PrayerTime(type: .maghrib, time: now.addingTimeInterval(7200), isNext: false),
            PrayerTime(type: .isha, time: now.addingTimeInterval(10800), isNext: false),
        ]

        // When
        let next = prayers.first { $0.time > now && $0.type.isObligatory }

        // Then
        XCTAssertEqual(next?.type, .asr)
    }

    func test_nextObligatoryPrayer_skipsNonObligatory() {
        // Given — only Sunrise is in the future, but it's not obligatory
        let now = Date()
        let prayers = [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(-3600), isNext: false),
            PrayerTime(type: .sunrise, time: now.addingTimeInterval(1800), isNext: false),
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(7200), isNext: false),
        ]

        // When — filter for obligatory only
        let next = prayers.first { $0.time > now && $0.type.isObligatory }

        // Then — should skip Sunrise and find Dhuhr
        XCTAssertEqual(next?.type, .dhuhr)
    }

    func test_allPrayersPassed_returnsNil() {
        // Given — all prayers in the past
        let now = Date()
        let prayers = [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(-36000), isNext: false),
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(-28800), isNext: false),
            PrayerTime(type: .asr, time: now.addingTimeInterval(-21600), isNext: false),
            PrayerTime(type: .maghrib, time: now.addingTimeInterval(-14400), isNext: false),
            PrayerTime(type: .isha, time: now.addingTimeInterval(-7200), isNext: false),
        ]

        // When
        let next = prayers.first { $0.time > now && $0.type.isObligatory }

        // Then
        XCTAssertNil(next)
    }

    func test_prayerInfoConversion_excludesSunrise() {
        // Given — a full day including Sunrise
        let now = Date()
        let prayers = [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(3600), isNext: false),
            PrayerTime(type: .sunrise, time: now.addingTimeInterval(7200), isNext: false),
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(14400), isNext: false),
            PrayerTime(type: .asr, time: now.addingTimeInterval(21600), isNext: false),
            PrayerTime(type: .maghrib, time: now.addingTimeInterval(28800), isNext: false),
            PrayerTime(type: .isha, time: now.addingTimeInterval(36000), isNext: false),
        ]

        // When — convert using the same filter as the Live Activity code
        let prayerInfos = prayers
            .filter { $0.type.isObligatory }
            .map { PrayerInfo(name: $0.type.displayName, time: $0.time) }

        // Then — Sunrise is excluded, 5 obligatory prayers remain
        XCTAssertEqual(prayerInfos.count, 5)
        XCTAssertFalse(prayerInfos.contains { $0.name == "Sunrise" })
        XCTAssertEqual(prayerInfos.map(\.name), ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"])
    }
}

// MARK: - Coordinate Fallback Logic

final class LiveActivityCoordinateFallbackTests: XCTestCase {

    func test_savedCoordinates_usedWhenAvailable() {
        // Given — prefs with saved location
        var prefs = UserPreferences()
        prefs.savedLatitude = 21.4225
        prefs.savedLongitude = 39.8262

        // When
        let coords = prefs.savedCoordinates

        // Then — saved coordinates returned
        XCTAssertNotNil(coords)
        XCTAssertEqual(coords!.latitude, 21.4225, accuracy: 0.0001)
        XCTAssertEqual(coords!.longitude, 39.8262, accuracy: 0.0001)
    }

    func test_noSavedCoordinates_returnsNil() {
        // Given — fresh prefs with no saved location
        let prefs = UserPreferences()

        // Then
        XCTAssertNil(prefs.savedCoordinates)
    }

    func test_defaultCoordinates_areLondon() {
        // Given — AppDefaults
        let coords = AppDefaults.defaultCoordinates

        // Then — London, UK
        XCTAssertEqual(coords.latitude, 51.5074, accuracy: 0.0001)
        XCTAssertEqual(coords.longitude, -0.1278, accuracy: 0.0001)
    }
}
