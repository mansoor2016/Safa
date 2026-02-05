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

    func getAchievements() async throws -> [Achievement] {
        return []
    }

    func unlockAchievement(_ achievementId: String) async throws {}

    func isAchievementUnlocked(_ achievementId: String) async throws -> Bool {
        return false
    }

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
        sut = PreferencesManager.shared
        sut.configure(userRepository: mockRepository)
    }

    override func tearDown() {
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

    // MARK: - Get Preferences Tests

    func test_getPreferences_returnsCurrentState() async {
        mockRepository.preferences.notificationsEnabled = true
        mockRepository.preferences.accentColorName = "purple"

        let prefs = await sut.getPreferences()

        XCTAssertTrue(prefs.notificationsEnabled)
        XCTAssertEqual(prefs.accentColorName, "purple")
    }
}
