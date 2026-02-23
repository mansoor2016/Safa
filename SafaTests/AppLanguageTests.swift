// MARK: - AppLanguageTests.swift
// PURPOSE: Tests for SupportedAppLanguage, AppLanguageManager.sanitize, and UserPreferences decode

import XCTest
@testable import Safa

final class AppLanguageTests: XCTestCase {

    // MARK: - SupportedAppLanguage Enum

    func test_supportedAppLanguage_allCasesCount() {
        XCTAssertEqual(SupportedAppLanguage.allCases.count, 9)
    }

    func test_supportedAppLanguage_rawValueRoundTrip() {
        for language in SupportedAppLanguage.allCases {
            XCTAssertEqual(SupportedAppLanguage(rawValue: language.rawValue), language)
        }
    }

    func test_supportedAppLanguage_displayNamesNonEmpty() {
        for language in SupportedAppLanguage.allCases {
            XCTAssertFalse(language.displayName.isEmpty, "\(language) has empty displayName")
        }
    }

    func test_supportedAppLanguage_nativeNamesNonEmpty() {
        for language in SupportedAppLanguage.allCases {
            XCTAssertFalse(language.nativeName.isEmpty, "\(language) has empty nativeName")
        }
    }

    // MARK: - AppLanguageManager.sanitize (pure static function — no instance needed)

    func test_sanitize_nilInput_returnsNil() {
        XCTAssertNil(AppLanguageManager.sanitize(nil))
    }

    func test_sanitize_validCode_returnsCode() {
        XCTAssertEqual(AppLanguageManager.sanitize("ar"), "ar")
    }

    func test_sanitize_invalidCode_returnsNil() {
        XCTAssertNil(AppLanguageManager.sanitize("xx"))
    }

    func test_sanitize_emptyString_returnsNil() {
        XCTAssertNil(AppLanguageManager.sanitize(""))
    }

    func test_sanitize_allSupportedCodes() {
        for language in SupportedAppLanguage.allCases {
            XCTAssertEqual(
                AppLanguageManager.sanitize(language.rawValue),
                language.rawValue,
                "\(language.rawValue) should pass sanitize"
            )
        }
    }

    // MARK: - UserPreferences Decode (appLanguageCode field)

    func test_userPreferences_decodesWithUnknownAppLanguageCode() throws {
        let prefs = UserPreferences()
        let data = try JSONEncoder().encode(prefs)
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json["appLanguageCode"] = "zz"
        let modifiedData = try JSONSerialization.data(withJSONObject: json)

        let decoded = try JSONDecoder().decode(UserPreferences.self, from: modifiedData)
        XCTAssertNil(decoded.appLanguageCode, "Unknown code 'zz' should be sanitized to nil")
    }

    func test_userPreferences_decodesWithValidAppLanguageCode() throws {
        let prefs = UserPreferences()
        let data = try JSONEncoder().encode(prefs)
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json["appLanguageCode"] = "fr"
        let modifiedData = try JSONSerialization.data(withJSONObject: json)

        let decoded = try JSONDecoder().decode(UserPreferences.self, from: modifiedData)
        XCTAssertEqual(decoded.appLanguageCode, "fr")
    }

    func test_userPreferences_decodesWithMissingAppLanguageCode() throws {
        let prefs = UserPreferences()
        let data = try JSONEncoder().encode(prefs)
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json.removeValue(forKey: "appLanguageCode")
        let modifiedData = try JSONSerialization.data(withJSONObject: json)

        let decoded = try JSONDecoder().decode(UserPreferences.self, from: modifiedData)
        XCTAssertNil(decoded.appLanguageCode, "Missing key should default to nil")
    }

    func test_userPreferences_appLanguageCodeRoundTrip() throws {
        var prefs = UserPreferences()
        prefs.appLanguageCode = "bn"
        let data = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)
        XCTAssertEqual(decoded.appLanguageCode, "bn")
    }

    func test_userPreferences_appLanguageCodeNilRoundTrip() throws {
        var prefs = UserPreferences()
        prefs.appLanguageCode = nil
        let data = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)
        XCTAssertNil(decoded.appLanguageCode)
    }

    // MARK: - Regression: deviceLanguageCode returns a valid language code

    func test_deviceLanguageCode_returnsNonEmpty() {
        let code = AppLanguageManager.deviceLanguageCode
        XCTAssertFalse(code.isEmpty, "deviceLanguageCode should never be empty")
    }

    func test_deviceLanguageCode_returnsValidBCP47() {
        // deviceLanguageCode should return a bare language code (e.g. "en", "ar"),
        // not a full locale identifier with region
        let code = AppLanguageManager.deviceLanguageCode
        XCTAssertFalse(code.contains("-"), "Should be a language code, not a locale identifier: '\(code)'")
        XCTAssertFalse(code.contains("_"), "Should be a language code, not a locale identifier: '\(code)'")
    }

    func test_deviceLanguageDisplayName_returnsNonEmpty() {
        let name = AppLanguageManager.deviceLanguageDisplayName
        XCTAssertFalse(name.isEmpty, "deviceLanguageDisplayName should never be empty")
    }

    // MARK: - Regression: appLanguageCode does not affect other prefs

    func test_appLanguageCode_changeDoesNotAffectSelectedTranslation() throws {
        var prefs = UserPreferences(selectedTranslation: "Urdu")
        prefs.appLanguageCode = "ur"

        let data = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)

        XCTAssertEqual(decoded.selectedTranslation, "Urdu",
                       "appLanguageCode change must not affect selectedTranslation")
        XCTAssertEqual(decoded.appLanguageCode, "ur")
    }

    // MARK: - Regression: PrayerType.localizedDisplayName exists and returns non-empty

    func test_prayerType_localizedDisplayName_nonEmpty() {
        for prayer in PrayerType.allCases {
            XCTAssertFalse(prayer.localizedDisplayName.isEmpty,
                           "\(prayer) has empty localizedDisplayName")
        }
    }
}
