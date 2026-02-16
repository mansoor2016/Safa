// MARK: - LanguageSettingsTests.swift
// PURPOSE: Behavior tests for QuranTranslation, UserPreferences decode resilience, and LanguageDisplayHelpers

import XCTest
@testable import Safa

final class LanguageSettingsTests: XCTestCase {

    // MARK: - QuranTranslation Enum

    func test_quranTranslation_allCasesHaveDisplayName() {
        for translation in QuranTranslation.allCases {
            XCTAssertFalse(translation.displayName.isEmpty, "\(translation) has empty displayName")
        }
    }

    func test_quranTranslation_allCasesHaveLanguage() {
        for translation in QuranTranslation.allCases {
            XCTAssertFalse(translation.language.isEmpty, "\(translation) has empty language")
        }
    }

    func test_quranTranslation_fullDisplayNameFormat() {
        for translation in QuranTranslation.allCases {
            let expected = "\(translation.displayName) (\(translation.language))"
            XCTAssertEqual(translation.fullDisplayName, expected)
        }
    }

    func test_quranTranslation_codableRoundTrip() throws {
        let original = QuranTranslation.sahihInternational
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(QuranTranslation.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    // MARK: - Decode Resilience

    func test_userPreferences_quranTranslationDefault() {
        let prefs = UserPreferences()
        XCTAssertEqual(prefs.quranTranslation, .sahihInternational)
    }

    func test_userPreferences_decodesWithoutQuranTranslation() throws {
        // Encode current prefs, then strip the quranTranslation key to simulate legacy data
        let prefs = UserPreferences()
        let data = try JSONEncoder().encode(prefs)
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json.removeValue(forKey: "quranTranslation")
        let modifiedData = try JSONSerialization.data(withJSONObject: json)

        let decoded = try JSONDecoder().decode(UserPreferences.self, from: modifiedData)
        XCTAssertEqual(decoded.quranTranslation, .sahihInternational)
    }

    func test_userPreferences_decodesUnknownQuranTranslation() throws {
        // Encode current prefs, then set quranTranslation to an unknown raw value
        let prefs = UserPreferences()
        let data = try JSONEncoder().encode(prefs)
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json["quranTranslation"] = "unknown_future_translation"
        let modifiedData = try JSONSerialization.data(withJSONObject: json)

        let decoded = try JSONDecoder().decode(UserPreferences.self, from: modifiedData)
        XCTAssertEqual(decoded.quranTranslation, .sahihInternational)
    }

    func test_userPreferences_decodesCorruptNonStringQuranTranslation() throws {
        // Store a non-string type (integer) for quranTranslation to simulate corrupt data
        let prefs = UserPreferences()
        let data = try JSONEncoder().encode(prefs)
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json["quranTranslation"] = 42
        let modifiedData = try JSONSerialization.data(withJSONObject: json)

        let decoded = try JSONDecoder().decode(UserPreferences.self, from: modifiedData)
        XCTAssertEqual(decoded.quranTranslation, .sahihInternational,
                       "Non-string quranTranslation should fall back to default, not crash")
    }

    // MARK: - Persistence Isolation

    func test_quranTranslation_changeDoesNotMutateSelectedTranslation() throws {
        // Modify quranTranslation, encode, decode, and verify selectedTranslation survives unchanged
        var prefs = UserPreferences(selectedTranslation: "Urdu")
        let originalSelectedTranslation = prefs.selectedTranslation

        prefs.quranTranslation = .sahihInternational

        let data = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)

        XCTAssertEqual(decoded.selectedTranslation, originalSelectedTranslation,
                       "quranTranslation change must not affect selectedTranslation after save/load")
        XCTAssertEqual(decoded.quranTranslation, .sahihInternational)
    }

    // MARK: - Language Display Helpers

    func test_displayName_englishCode() {
        let name = LanguageDisplayHelpers.displayName(forLanguageCode: "en", locale: Locale(identifier: "en_US"))
        XCTAssertTrue(name.contains("English"), "Expected 'English' but got '\(name)'")
    }

    func test_displayName_arabicCode() {
        let name = LanguageDisplayHelpers.displayName(forLanguageCode: "ar", locale: Locale(identifier: "en_US"))
        XCTAssertFalse(name.isEmpty)
        // In English locale, "ar" resolves to "Arabic"
        XCTAssertTrue(name.contains("Arabic"), "Expected 'Arabic' but got '\(name)'")
    }

    func test_displayName_unknownCode() {
        let code = "xx-ZZZZ"
        let name = LanguageDisplayHelpers.displayName(forLanguageCode: code, locale: Locale(identifier: "en_US"))
        // Unrecognized code should return the code itself as fallback
        XCTAssertEqual(name, code, "Unknown code should be returned verbatim, got '\(name)'")
    }

    func test_displayName_regionSubtag() {
        let name = LanguageDisplayHelpers.displayName(forLanguageCode: "en-US", locale: Locale(identifier: "en_US"))
        XCTAssertTrue(name.contains("English"), "Expected 'English' in '\(name)'")
        XCTAssertFalse(name.isEmpty)
    }

    func test_currentAppLanguageCode_base() {
        // Exercise the fallback branch directly via pure function — no Bundle subclass needed
        let code = LanguageDisplayHelpers.resolveLanguageCode(preferred: "Base", developmentLanguage: "en")
        XCTAssertEqual(code, "en", "Should resolve 'Base' to development language 'en'")
    }

    func test_currentAppLanguageCode_baseCaseInsensitive() {
        let code = LanguageDisplayHelpers.resolveLanguageCode(preferred: "base", developmentLanguage: "ar")
        XCTAssertEqual(code, "ar", "Should resolve lowercase 'base' to development language")
    }

    func test_currentAppLanguageCode_baseWithNilDevLanguage() {
        let code = LanguageDisplayHelpers.resolveLanguageCode(preferred: "Base", developmentLanguage: nil)
        XCTAssertEqual(code, "en", "Should fall back to 'en' when development language is nil")
    }

    func test_currentAppLanguageCode_realBundle() {
        let code = LanguageDisplayHelpers.currentAppLanguageCode()
        XCTAssertFalse(code.isEmpty)
        XCTAssertNotEqual(code, "Base", "Real bundle should never return 'Base'")
    }
}
