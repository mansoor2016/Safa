// MARK: - PreferencesManagerTests.swift
// PURPOSE: Unit tests for PreferencesManager service
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

// MARK: - Mock User Repository

final class MockUserRepositoryForPrefs: UserRepositoryProtocol {
    var preferences = UserPreferences()
    var updateCallCount = 0
    var lastUpdatedPreferences: UserPreferences?

    func getPreferences() async -> UserPreferences {
        return preferences
    }

    func updatePreferences(_ prefs: UserPreferences) async throws {
        updateCallCount += 1
        lastUpdatedPreferences = prefs
        preferences = prefs
    }

    func getUserStats() async throws -> UserStats {
        return UserStats()
    }

    func updateUserStats(_ stats: UserStats) async throws {}

    func addHasanat(_ amount: Int) async throws -> Int {
        return amount
    }

    func getStreaks() async throws -> [Streak] {
        return []
    }

    func getStreak(type: StreakType) async throws -> Streak? {
        return nil
    }

    func updateStreak(_ streak: Streak) async throws {}

    func recordStreakActivity(type: StreakType) async throws {}

    func getPreference<T: Codable>(key: String) async throws -> T? {
        return nil
    }

    func setPreference<T: Codable>(key: String, value: T) async throws {}

    func getStreakFreezes() async throws -> Int {
        return 0
    }

    func useStreakFreeze() async throws {}

    func awardStreakFreeze() async throws {}
}

// MARK: - Test Cases

final class PreferencesManagerTests: XCTestCase {

    var sut: PreferencesManager!
    var mockRepository: MockUserRepositoryForPrefs!

    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepositoryForPrefs()
        // Pre-set migration key so non-migration tests don't trigger async side-effects
        UserDefaults.standard.set(true, forKey: "beta_migration_makkah_default_v2")
        sut = PreferencesManager.shared
        sut.configure(userRepository: mockRepository)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "beta_migration_makkah_default_v2")
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Configuration Tests

    func test_configure_setsRepository() async {
        // Verify that get returns default when configured
        let prefs = await sut.getPreferences()
        XCTAssertNotNil(prefs)
    }

    // MARK: - Calculation Method Tests

    func test_saveCalculationMethod_updatesPreferences() async {
        await sut.saveCalculationMethod(.egypt)

        XCTAssertEqual(mockRepository.updateCallCount, 1)
        XCTAssertEqual(mockRepository.lastUpdatedPreferences?.calculationMethod, .egypt)
    }

    func test_saveCalculationMethod_persistsValue() async {
        await sut.saveCalculationMethod(.makkah)

        let prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.calculationMethod, .makkah)
    }

    // MARK: - Madhab Tests

    func test_saveMadhab_updatesPreferences() async {
        await sut.saveMadhab(.shafi)

        XCTAssertEqual(mockRepository.updateCallCount, 1)
    }

    func test_saveMadhab_persistsValue() async {
        await sut.saveMadhab(.shafi)

        let prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.madhab, .shafi)
    }

    // MARK: - Notification Tests

    func test_saveNotificationsEnabled_true() async {
        mockRepository.preferences.notificationsEnabled = false

        await sut.saveNotificationsEnabled(true)

        let prefs = await sut.getPreferences()
        XCTAssertTrue(prefs.notificationsEnabled)
    }

    func test_saveNotificationsEnabled_false() async {
        mockRepository.preferences.notificationsEnabled = true

        await sut.saveNotificationsEnabled(false)

        let prefs = await sut.getPreferences()
        XCTAssertFalse(prefs.notificationsEnabled)
    }

    // MARK: - Haptic Feedback Tests

    func test_saveHapticFeedback_true() async {
        await sut.saveHapticFeedback(true)

        let prefs = await sut.getPreferences()
        XCTAssertTrue(prefs.hapticFeedbackEnabled)
    }

    func test_saveHapticFeedback_false() async {
        await sut.saveHapticFeedback(false)

        let prefs = await sut.getPreferences()
        XCTAssertFalse(prefs.hapticFeedbackEnabled)
    }

    // MARK: - Translation Tests

    func test_saveTranslation_updatesPreferences() async {
        await sut.saveTranslation("Arabic")

        let prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.selectedTranslation, "Arabic")
    }

    // MARK: - Location Tests

    func test_saveLocation_updatesAllFields() async {
        await sut.saveLocation(
            name: "New York",
            latitude: 40.7128,
            longitude: -74.0060,
            countryCode: "US"
        )

        let prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.savedLocationName, "New York")
        XCTAssertEqual(prefs.savedLatitude, 40.7128)
        XCTAssertEqual(prefs.savedLongitude, -74.0060)
        XCTAssertEqual(prefs.savedCountryCode, "US")
    }

    func test_saveLocation_withNilCountryCode() async {
        await sut.saveLocation(
            name: "Unknown Location",
            latitude: 0.0,
            longitude: 0.0,
            countryCode: nil
        )

        let prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.savedLocationName, "Unknown Location")
        XCTAssertNil(prefs.savedCountryCode)
    }

    // MARK: - Location Settings Tests

    func test_saveLocationSettings_updatesAllFields() async {
        await sut.saveLocationSettings(
            method: .karachi,
            madhab: .hanafi,
            language: "Urdu"
        )

        let prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.calculationMethod, .karachi)
        XCTAssertEqual(prefs.madhab, .hanafi)
        XCTAssertEqual(prefs.selectedTranslation, "Urdu")
    }

    func test_saveLocationSettings_singleUpdate() async {
        await sut.saveLocationSettings(
            method: .muslimWorldLeague,
            madhab: .hanafi,
            language: "English"
        )

        // Should be a single update call, not multiple
        XCTAssertEqual(mockRepository.updateCallCount, 1)
    }

    // MARK: - Accessibility Tests

    func test_saveAccessibility_allOptions() async {
        await sut.saveAccessibility(
            reduceMotion: true,
            largerText: true,
            highContrast: true
        )

        let prefs = await sut.getPreferences()
        XCTAssertTrue(prefs.reduceMotionEnabled)
        XCTAssertTrue(prefs.largerArabicTextEnabled)
        XCTAssertTrue(prefs.highContrastEnabled)
    }

    func test_saveAccessibility_partialUpdate() async {
        mockRepository.preferences.reduceMotionEnabled = false
        mockRepository.preferences.largerArabicTextEnabled = false

        await sut.saveAccessibility(reduceMotion: true, largerText: nil, highContrast: nil)

        let prefs = await sut.getPreferences()
        XCTAssertTrue(prefs.reduceMotionEnabled)
        XCTAssertFalse(prefs.largerArabicTextEnabled) // Should remain unchanged
    }

    // MARK: - Quran Settings Tests

    func test_saveQuranSettings_allOptions() async {
        await sut.saveQuranSettings(showArabic: true, showTransliteration: true)

        let prefs = await sut.getPreferences()
        XCTAssertTrue(prefs.showArabicText)
        XCTAssertTrue(prefs.showTransliteration)
    }

    func test_saveQuranSettings_partialUpdate() async {
        mockRepository.preferences.showArabicText = false
        mockRepository.preferences.showTransliteration = false

        await sut.saveQuranSettings(showArabic: true, showTransliteration: nil)

        let prefs = await sut.getPreferences()
        XCTAssertTrue(prefs.showArabicText)
        XCTAssertFalse(prefs.showTransliteration) // Should remain unchanged
    }

    // MARK: - Generic Update Tests

    func test_update_withKeyPath() async {
        await sut.update(\.accentColorName, to: "blue")

        let prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.accentColorName, "blue")
    }

    func test_update_withClosure() async {
        await sut.update { prefs in
            prefs.accentColorName = "green"
            prefs.hapticFeedbackEnabled = false
        }

        let prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.accentColorName, "green")
        XCTAssertFalse(prefs.hapticFeedbackEnabled)
    }

    // MARK: - Cross-Surface Sync Tests
    // These verify settings that appear on multiple screens (Prayer page, Quran page, Settings)
    // all roundtrip through the same PreferencesManager path.

    func test_autoScrollEnabled_savedViaPrefsMgr_readableViaGetPreferences() async {
        // Settings/Quran page saves via update(keyPath), AyahReaderView reads via getPreferences
        await sut.update(\.autoScrollEnabled, to: true)

        let prefs = await sut.getPreferences()
        XCTAssertTrue(prefs.autoScrollEnabled, "Auto-scroll enabled via Settings should be readable")

        await sut.update(\.autoScrollEnabled, to: false)
        let prefs2 = await sut.getPreferences()
        XCTAssertFalse(prefs2.autoScrollEnabled, "Auto-scroll disabled should persist")
    }

    func test_prayerAdjustments_roundtrip() async {
        await sut.update { prefs in
            prefs.setAdjustment(5, for: .fajr)
            prefs.setAdjustment(-3, for: .asr)
        }

        let prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.adjustment(for: .fajr), 5)
        XCTAssertEqual(prefs.adjustment(for: .asr), -3)
        XCTAssertEqual(prefs.adjustment(for: .maghrib), 0) // untouched
    }

    func test_prayerAdjustments_clearRoundtrip() async {
        await sut.update { prefs in
            prefs.setAdjustment(10, for: .isha)
        }
        var prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.adjustment(for: .isha), 10)

        await sut.update { prefs in
            prefs.setAdjustment(0, for: .isha)
        }
        prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.adjustment(for: .isha), 0)
        XCTAssertTrue(prefs.prayerAdjustments.isEmpty)
    }

    func test_calculationMethod_multipleSaves_lastWins() async {
        // Simulates changing method in Prayer settings then Settings page
        await sut.saveCalculationMethod(.egypt)
        await sut.saveCalculationMethod(.isna)

        let prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.calculationMethod, .isna)
    }

    func test_madhab_multipleSaves_lastWins() async {
        await sut.saveMadhab(.shafi)
        await sut.saveMadhab(.hanafi)

        let prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.madhab, .hanafi)
    }

    func test_quranAndPrayerSettings_independent() async {
        // Saving Quran settings should not affect prayer settings
        await sut.saveCalculationMethod(.makkah)
        await sut.saveQuranSettings(showArabic: false, showTransliteration: true)

        let prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.calculationMethod, .makkah) // unchanged
        XCTAssertFalse(prefs.showArabicText)
        XCTAssertTrue(prefs.showTransliteration)
    }

    // MARK: - Get Preferences Tests

    func test_getPreferences_returnsCurrentState() async {
        mockRepository.preferences.notificationsEnabled = true
        mockRepository.preferences.accentColorName = "purple"

        let prefs = await sut.getPreferences()

        XCTAssertTrue(prefs.notificationsEnabled)
        XCTAssertEqual(prefs.accentColorName, "purple")
    }

    // MARK: - Beta Migration Tests

    func test_betaMigration_writesForMakkahUsers() async {
        // User on old .makkah default — migration should fire an update
        mockRepository.preferences.calculationMethod = .makkah
        UserDefaults.standard.removeObject(forKey: "beta_migration_makkah_default_v2")
        let countBefore = mockRepository.updateCallCount

        sut.configure(userRepository: mockRepository)

        // Wait for the async migration Task to set the completion key
        let migrated = XCTestExpectation(description: "Migration task completes")
        Task {
            while !UserDefaults.standard.bool(forKey: "beta_migration_makkah_default_v2") {
                try? await Task.sleep(for: .milliseconds(10))
            }
            migrated.fulfill()
        }
        await fulfillment(of: [migrated], timeout: 2.0)

        XCTAssertGreaterThan(mockRepository.updateCallCount, countBefore,
                             "Migration should trigger an update call for .makkah users")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "beta_migration_makkah_default_v2"),
                      "Completion key should be set after migration")
    }

    func test_betaMigration_skipsNonMakkahUsers() async {
        // User explicitly chose ISNA — migration should NOT write
        mockRepository.preferences.calculationMethod = .isna
        UserDefaults.standard.removeObject(forKey: "beta_migration_makkah_default_v2")
        let countBefore = mockRepository.updateCallCount

        sut.configure(userRepository: mockRepository)

        // Wait for the migration Task to finish (it sets the key even when skipping)
        let completed = XCTestExpectation(description: "Migration task completes")
        Task {
            while !UserDefaults.standard.bool(forKey: "beta_migration_makkah_default_v2") {
                try? await Task.sleep(for: .milliseconds(10))
            }
            completed.fulfill()
        }
        await fulfillment(of: [completed], timeout: 2.0)

        XCTAssertEqual(mockRepository.updateCallCount, countBefore,
                       "Migration should NOT update preferences for non-.makkah users")
        let prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.calculationMethod, .isna,
                       "User's explicit ISNA choice should be preserved")
    }

    func test_betaMigration_onlyRunsOnce() async {
        mockRepository.preferences.calculationMethod = .makkah
        UserDefaults.standard.removeObject(forKey: "beta_migration_makkah_default_v2")

        // First configure — migration runs
        sut.configure(userRepository: mockRepository)

        let firstDone = XCTestExpectation(description: "First migration completes")
        Task {
            while !UserDefaults.standard.bool(forKey: "beta_migration_makkah_default_v2") {
                try? await Task.sleep(for: .milliseconds(10))
            }
            firstDone.fulfill()
        }
        await fulfillment(of: [firstDone], timeout: 2.0)

        // User manually changes to ISNA after migration
        await sut.saveCalculationMethod(.isna)
        let countAfterManualChange = mockRepository.updateCallCount

        // Second configure — guard returns synchronously because key is already set
        sut.configure(userRepository: mockRepository)

        XCTAssertEqual(mockRepository.updateCallCount, countAfterManualChange,
                       "No additional update — migration guard exits synchronously")
        let prefs = await sut.getPreferences()
        XCTAssertEqual(prefs.calculationMethod, .isna,
                       "User's post-migration ISNA choice should be preserved")
    }
}
