// MARK: - LocationSettingsCorrectnessTests.swift
// PURPOSE: Regression tests for location and prayer settings consistency
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class LocationSettingsCorrectnessTests: XCTestCase {

    // MARK: - Madhab Affects Asr Time

    func test_madhab_hanafi_producesLaterAsr_thanShafi() {
        // Given: same date, location, and method — only madhab differs
        let calculator = PrayerTimeCalculator()
        let date = Date()
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let method = CalculationMethod.muslimWorldLeague

        // When
        let shafiPrayers = calculator.calculatePrayerTimes(for: date, location: london, method: method, madhab: .shafi)
        let hanafiPrayers = calculator.calculatePrayerTimes(for: date, location: london, method: method, madhab: .hanafi)

        // Then: Hanafi Asr should be later (shadow ratio 2 vs 1)
        let shafiAsr = shafiPrayers.first { $0.type == .asr }!.time
        let hanafiAsr = hanafiPrayers.first { $0.type == .asr }!.time

        XCTAssertGreaterThan(hanafiAsr, shafiAsr, "Hanafi Asr must be later than Shafi Asr (shadow ratio 2 vs 1)")
    }

    func test_madhab_nil_fallsBackToMethodDefault() {
        // Given: no madhab override
        let calculator = PrayerTimeCalculator()
        let date = Date()
        let coords = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let method = CalculationMethod.muslimWorldLeague

        // When: madhab is nil (should use method.asrShadowRatio which is 1.0 for MWL)
        let defaultPrayers = calculator.calculatePrayerTimes(for: date, location: coords, method: method, madhab: nil)
        let shafiPrayers = calculator.calculatePrayerTimes(for: date, location: coords, method: method, madhab: .shafi)

        // Then: nil madhab and Shafi should produce same Asr (both use shadow ratio 1.0)
        let defaultAsr = defaultPrayers.first { $0.type == .asr }!.time
        let shafiAsr = shafiPrayers.first { $0.type == .asr }!.time

        XCTAssertEqual(
            defaultAsr.timeIntervalSince1970,
            shafiAsr.timeIntervalSince1970,
            accuracy: 1.0,
            "Nil madhab should produce same Asr as Shafi (both shadow ratio 1.0)"
        )
    }

    // MARK: - PreferencesManager Sync Read

    func test_loadPreferencesSync_returnsDefaults_whenNoDataStored() {
        // Given: a fresh key with no data
        let key = "\(AppConstants.StorageKeys.userPreferences).all"
        let backup = UserDefaults.standard.data(forKey: key)
        UserDefaults.standard.removeObject(forKey: key)

        // When
        let prefs = PreferencesManager.loadPreferencesSync()

        // Then: returns defaults
        XCTAssertEqual(prefs.calculationMethod, AppDefaults.calculationMethod)
        XCTAssertEqual(prefs.madhab, AppDefaults.madhab)

        // Restore
        if let backup { UserDefaults.standard.set(backup, forKey: key) }
    }

    func test_loadPreferencesSync_returnsStoredPreferences() {
        // Given: stored preferences with non-default values
        let key = "\(AppConstants.StorageKeys.userPreferences).all"
        let backup = UserDefaults.standard.data(forKey: key)

        var prefs = UserPreferences()
        prefs.calculationMethod = .isna
        prefs.madhab = .shafi
        prefs.savedLatitude = 40.7128
        prefs.savedLongitude = -74.0060
        let data = try! JSONEncoder().encode(prefs)
        UserDefaults.standard.set(data, forKey: key)

        // When
        let loaded = PreferencesManager.loadPreferencesSync()

        // Then
        XCTAssertEqual(loaded.calculationMethod, .isna)
        XCTAssertEqual(loaded.madhab, .shafi)
        XCTAssertEqual(loaded.savedLatitude, 40.7128)
        XCTAssertEqual(loaded.savedLongitude, -74.0060)

        // Restore
        if let backup {
            UserDefaults.standard.set(backup, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - Saved Coordinates Resolution

    func test_savedCoordinates_usedWhenPresent() {
        // Given: preferences with saved coordinates
        let key = "\(AppConstants.StorageKeys.userPreferences).all"
        let backup = UserDefaults.standard.data(forKey: key)

        var prefs = UserPreferences()
        prefs.savedLatitude = 21.4225
        prefs.savedLongitude = 39.8262
        let data = try! JSONEncoder().encode(prefs)
        UserDefaults.standard.set(data, forKey: key)

        // When
        let loaded = PreferencesManager.loadPreferencesSync()
        let coords = loaded.savedCoordinates

        // Then
        XCTAssertNotNil(coords)
        XCTAssertEqual(coords!.latitude, 21.4225, accuracy: 0.001)
        XCTAssertEqual(coords!.longitude, 39.8262, accuracy: 0.001)

        // Restore
        if let backup {
            UserDefaults.standard.set(backup, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    func test_savedCoordinates_nilWhenNotPresent() {
        // Given: preferences with no saved coordinates
        let key = "\(AppConstants.StorageKeys.userPreferences).all"
        let backup = UserDefaults.standard.data(forKey: key)

        let prefs = UserPreferences() // defaults have nil lat/lng
        let data = try! JSONEncoder().encode(prefs)
        UserDefaults.standard.set(data, forKey: key)

        // When
        let loaded = PreferencesManager.loadPreferencesSync()

        // Then
        XCTAssertNil(loaded.savedCoordinates)

        // Restore
        if let backup {
            UserDefaults.standard.set(backup, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - Madhab Shadow Ratio Values

    func test_madhab_shafiShadowRatio_isOne() {
        XCTAssertEqual(Madhab.shafi.shadowRatio, 1.0)
    }

    func test_madhab_hanafiShadowRatio_isTwo() {
        XCTAssertEqual(Madhab.hanafi.shadowRatio, 2.0)
    }
}
