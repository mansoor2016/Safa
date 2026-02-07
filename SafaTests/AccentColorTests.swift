// MARK: - AccentColorTests.swift
// PURPOSE: Unit tests for accent color selection and persistence
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class AccentColorTests: XCTestCase {

    // MARK: - AccentColorOption Tests

    func test_allCases_hasFiveOptions() {
        XCTAssertEqual(AccentColorOption.allCases.count, 5)
    }

    func test_allCases_haveDistinctRawValues() {
        let rawValues = AccentColorOption.allCases.map { $0.rawValue }
        let uniqueValues = Set(rawValues)
        XCTAssertEqual(uniqueValues.count, 5)
    }

    func test_allCases_haveDisplayNames() {
        for option in AccentColorOption.allCases {
            XCTAssertFalse(option.displayName.isEmpty)
        }
    }

    func test_rawValue_roundTrip() {
        for option in AccentColorOption.allCases {
            let reconstructed = AccentColorOption(rawValue: option.rawValue)
            XCTAssertEqual(reconstructed, option)
        }
    }

    func test_invalidRawValue_returnsNil() {
        XCTAssertNil(AccentColorOption(rawValue: "Pink"))
    }

    func test_defaultAccentColor_isTeal() {
        let defaultColor = AppDefaults.accentColorName
        XCTAssertEqual(defaultColor, "Teal")
        XCTAssertNotNil(AccentColorOption(rawValue: defaultColor))
    }

    // MARK: - Preference Persistence Tests

    func test_userPreferences_defaultAccentColor() {
        let prefs = UserPreferences()
        XCTAssertEqual(prefs.accentColorName, AppDefaults.accentColorName)
    }

    func test_userPreferences_accentColorPersists() {
        var prefs = UserPreferences()
        prefs.accentColorName = AccentColorOption.purple.rawValue
        XCTAssertEqual(prefs.accentColorName, "Purple")

        let loaded = AccentColorOption(rawValue: prefs.accentColorName)
        XCTAssertEqual(loaded, .purple)
    }

    func test_allOptions_mapToValidPreferenceValues() {
        for option in AccentColorOption.allCases {
            var prefs = UserPreferences()
            prefs.accentColorName = option.rawValue

            let loaded = AccentColorOption(rawValue: prefs.accentColorName)
            XCTAssertEqual(loaded, option, "\(option.rawValue) should round-trip through preferences")
        }
    }

    // MARK: - Color Output Tests

    func test_green_hasColor() {
        let color = AccentColorOption.green.color
        XCTAssertNotNil(color)
    }

    func test_teal_hasColor() {
        let color = AccentColorOption.teal.color
        XCTAssertNotNil(color)
    }

    func test_blue_hasColor() {
        let color = AccentColorOption.blue.color
        XCTAssertNotNil(color)
    }

    func test_purple_hasColor() {
        let color = AccentColorOption.purple.color
        XCTAssertNotNil(color)
    }

    func test_gold_hasColor() {
        let color = AccentColorOption.gold.color
        XCTAssertNotNil(color)
    }
}
