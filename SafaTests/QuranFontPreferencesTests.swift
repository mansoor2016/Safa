// MARK: - QuranFontPreferencesTests.swift
// PURPOSE: Tests for QuranFontPreferences persistence and defaults
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class QuranFontPreferencesTests: XCTestCase {

    override func tearDown() {
        // Clean up UserDefaults after each test
        UserDefaults.standard.removeObject(forKey: "quranFontPreferences")
        super.tearDown()
    }

    // MARK: - Default Values

    func test_defaultArabicFontSize_isMedium() {
        let prefs = QuranFontPreferences()
        XCTAssertEqual(prefs.arabicFontSize, .medium)
    }

    func test_defaultTranslationFontSize_isMedium() {
        let prefs = QuranFontPreferences()
        XCTAssertEqual(prefs.translationFontSize, .medium)
    }

    // MARK: - Point Size Mappings

    func test_arabicFontSize_pointSizes() {
        XCTAssertEqual(QuranFontPreferences.ArabicFontSize.small.pointSize, 22)
        XCTAssertEqual(QuranFontPreferences.ArabicFontSize.medium.pointSize, 28)
        XCTAssertEqual(QuranFontPreferences.ArabicFontSize.large.pointSize, 34)
        XCTAssertEqual(QuranFontPreferences.ArabicFontSize.extraLarge.pointSize, 42)
    }

    func test_translationFontSize_pointSizes() {
        XCTAssertEqual(QuranFontPreferences.TranslationFontSize.small.pointSize, 14)
        XCTAssertEqual(QuranFontPreferences.TranslationFontSize.medium.pointSize, 16)
        XCTAssertEqual(QuranFontPreferences.TranslationFontSize.large.pointSize, 20)
    }

    // MARK: - Labels

    func test_arabicFontSize_labels() {
        XCTAssertEqual(QuranFontPreferences.ArabicFontSize.small.label, "Small")
        XCTAssertEqual(QuranFontPreferences.ArabicFontSize.medium.label, "Medium")
        XCTAssertEqual(QuranFontPreferences.ArabicFontSize.large.label, "Large")
        XCTAssertEqual(QuranFontPreferences.ArabicFontSize.extraLarge.label, "Extra Large")
    }

    func test_translationFontSize_labels() {
        XCTAssertEqual(QuranFontPreferences.TranslationFontSize.small.label, "Small")
        XCTAssertEqual(QuranFontPreferences.TranslationFontSize.medium.label, "Medium")
        XCTAssertEqual(QuranFontPreferences.TranslationFontSize.large.label, "Large")
    }

    // MARK: - Persistence

    func test_saveAndLoad_roundTrip() {
        var prefs = QuranFontPreferences()
        prefs.arabicFontSize = .extraLarge
        prefs.translationFontSize = .small
        prefs.save()

        let loaded = QuranFontPreferences.load()
        XCTAssertEqual(loaded.arabicFontSize, .extraLarge)
        XCTAssertEqual(loaded.translationFontSize, .small)
    }

    func test_load_returnsDefaults_whenNoDataStored() {
        UserDefaults.standard.removeObject(forKey: "quranFontPreferences")
        let loaded = QuranFontPreferences.load()
        XCTAssertEqual(loaded.arabicFontSize, .medium)
        XCTAssertEqual(loaded.translationFontSize, .medium)
    }

    // MARK: - All Cases

    func test_arabicFontSize_hasFourCases() {
        XCTAssertEqual(QuranFontPreferences.ArabicFontSize.allCases.count, 4)
    }

    func test_translationFontSize_hasThreeCases() {
        XCTAssertEqual(QuranFontPreferences.TranslationFontSize.allCases.count, 3)
    }

    // MARK: - Equatable

    func test_preferences_equality() {
        let a = QuranFontPreferences(arabicFontSize: .large, translationFontSize: .small)
        let b = QuranFontPreferences(arabicFontSize: .large, translationFontSize: .small)
        XCTAssertEqual(a, b)
    }

    func test_preferences_inequality() {
        let a = QuranFontPreferences(arabicFontSize: .large, translationFontSize: .small)
        let b = QuranFontPreferences(arabicFontSize: .small, translationFontSize: .large)
        XCTAssertNotEqual(a, b)
    }
}
