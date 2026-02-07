// MARK: - ThemeManagerTests.swift
// PURPOSE: Unit tests for ThemeManager appearance and accent color persistence
// DEPENDENCIES: XCTest, Safa

import XCTest
import SwiftUI
@testable import Safa

final class ThemeManagerTests: XCTestCase {

    private var sut: ThemeManager!

    override func setUp() {
        super.setUp()
        // Clear any persisted theme state before each test
        UserDefaults.standard.removeObject(forKey: "com.safa.theme.colorScheme")
        UserDefaults.standard.removeObject(forKey: "com.safa.theme.accentColor")
        sut = ThemeManager()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "com.safa.theme.colorScheme")
        UserDefaults.standard.removeObject(forKey: "com.safa.theme.accentColor")
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_initialState_colorSchemeIsNil() {
        XCTAssertNil(sut.colorScheme, "Default should be system (nil)")
    }

    func test_initialState_accentColorIsGreen() {
        XCTAssertEqual(sut.accentColor, .green)
    }

    // MARK: - Color Scheme

    func test_setColorScheme_dark() {
        sut.setColorScheme(.dark)
        XCTAssertEqual(sut.colorScheme, .dark)
    }

    func test_setColorScheme_light() {
        sut.setColorScheme(.light)
        XCTAssertEqual(sut.colorScheme, .light)
    }

    func test_setColorScheme_system() {
        sut.setColorScheme(.dark)
        sut.setColorScheme(nil)
        XCTAssertNil(sut.colorScheme)
    }

    func test_setColorScheme_persistsToDisk() {
        sut.setColorScheme(.dark)

        // Verify UserDefaults was written (avoids parallel clone race condition)
        let saved = UserDefaults.standard.string(forKey: "com.safa.theme.colorScheme")
        XCTAssertEqual(saved, "dark")
    }

    func test_setColorScheme_nil_removesFromDisk() {
        sut.setColorScheme(.light)
        sut.setColorScheme(nil)

        let saved = UserDefaults.standard.string(forKey: "com.safa.theme.colorScheme")
        XCTAssertNil(saved)
    }

    // MARK: - Accent Color

    func test_setAccentColor_teal() {
        sut.setAccentColor(.teal)
        XCTAssertEqual(sut.accentColor, .teal)
    }

    func test_setAccentColor_persistsToDisk() {
        sut.setAccentColor(.purple)

        let saved = UserDefaults.standard.string(forKey: "com.safa.theme.accentColor")
        XCTAssertEqual(saved, "Purple")
    }

    // MARK: - AppearanceOption Enum

    func test_appearanceOption_systemMapsToNil() {
        XCTAssertNil(AppearanceOption.system.colorScheme)
    }

    func test_appearanceOption_lightMapsToLight() {
        XCTAssertEqual(AppearanceOption.light.colorScheme, .light)
    }

    func test_appearanceOption_darkMapsToDark() {
        XCTAssertEqual(AppearanceOption.dark.colorScheme, .dark)
    }

    func test_appearanceOption_allCasesHasThreeOptions() {
        XCTAssertEqual(AppearanceOption.allCases.count, 3)
    }

    func test_appearanceOption_allHaveIcons() {
        for option in AppearanceOption.allCases {
            XCTAssertFalse(option.iconName.isEmpty, "\(option.rawValue) should have an icon")
        }
    }

    // MARK: - AccentColorOption

    func test_accentColorOption_allCasesHaveFive() {
        XCTAssertEqual(AccentColorOption.allCases.count, 5)
    }

    func test_accentColorOption_allHaveDisplayNames() {
        for option in AccentColorOption.allCases {
            XCTAssertFalse(option.displayName.isEmpty, "\(option.rawValue) should have display name")
        }
    }
}
