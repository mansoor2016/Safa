// MARK: - AppIconPickerTests.swift
// PURPOSE: Tests for AppIcon enum display names, asset mappings, and alternate icon names

import XCTest
@testable import Safa

final class AppIconPickerTests: XCTestCase {

    typealias AppIcon = AppIconPickerView.AppIcon

    // MARK: - All Cases

    func test_allCases_containsFourIcons() {
        XCTAssertEqual(AppIcon.allCases.count, 4)
    }

    // MARK: - Display Names

    func test_displayName_primary_isDefault() {
        XCTAssertEqual(AppIcon.primary.displayName, "Default")
    }

    func test_displayName_gold_isGold() {
        XCTAssertEqual(AppIcon.gold.displayName, "Gold")
    }

    func test_displayName_midnight_isMidnight() {
        XCTAssertEqual(AppIcon.midnight.displayName, "Midnight")
    }

    func test_displayName_minimal_isMinimal() {
        XCTAssertEqual(AppIcon.minimal.displayName, "Minimal")
    }

    // MARK: - Alternate Icon Names

    func test_alternateIconName_primary_isNil() {
        XCTAssertNil(AppIcon.primary.alternateIconName,
                     "Primary icon should return nil (system default)")
    }

    func test_alternateIconName_gold_matchesRawValue() {
        XCTAssertEqual(AppIcon.gold.alternateIconName, "AppIcon-Gold")
    }

    func test_alternateIconName_midnight_matchesRawValue() {
        XCTAssertEqual(AppIcon.midnight.alternateIconName, "AppIcon-Midnight")
    }

    func test_alternateIconName_minimal_matchesRawValue() {
        XCTAssertEqual(AppIcon.minimal.alternateIconName, "AppIcon-Minimal")
    }

    // MARK: - Preview Assets

    func test_previewAsset_primary_usesPreviewSuffix() {
        XCTAssertEqual(AppIcon.primary.previewAsset, "AppIcon-Preview")
    }

    func test_previewAsset_alternates_useRawValueWithPreviewSuffix() {
        XCTAssertEqual(AppIcon.gold.previewAsset, "AppIcon-Gold-Preview")
        XCTAssertEqual(AppIcon.midnight.previewAsset, "AppIcon-Midnight-Preview")
        XCTAssertEqual(AppIcon.minimal.previewAsset, "AppIcon-Minimal-Preview")
    }

    // MARK: - Round-Trip

    func test_allAlternateIcons_roundTripFromRawValue() {
        for icon in AppIcon.allCases where icon != .primary {
            let resolved = AppIcon(rawValue: icon.alternateIconName!)
            XCTAssertEqual(resolved, icon,
                           "\(icon) should round-trip from alternateIconName to enum case")
        }
    }
}
