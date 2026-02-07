// MARK: - HijriDateHelperTests.swift
// PURPOSE: Tests for shared Hijri date helper

import XCTest
@testable import SafaShared

final class HijriDateHelperTests: XCTestCase {

    let helper = HijriDateHelper()

    func test_hijriDateString_isNotEmpty() {
        let result = helper.hijriDateString()
        XCTAssertFalse(result.isEmpty)
    }

    func test_hijriDateString_containsYear() {
        let result = helper.hijriDateString()
        // Hijri year should be in the 1440s-1450s range around 2026
        XCTAssertTrue(result.contains("144") || result.contains("145"))
    }

    func test_hijriDateString_containsMonthName() {
        let result = helper.hijriDateString()
        let monthNames = ["Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
                          "Jumada al-Ula", "Jumada al-Thani", "Rajab", "Sha'ban",
                          "Ramadan", "Shawwal", "Dhul Qa'dah", "Dhul Hijjah"]
        let containsMonth = monthNames.contains { result.contains($0) }
        XCTAssertTrue(containsMonth, "Result '\(result)' should contain a month name")
    }

    func test_hijriMonth_isValidRange() {
        let month = helper.hijriMonth()
        XCTAssertGreaterThanOrEqual(month, 1)
        XCTAssertLessThanOrEqual(month, 12)
    }

    func test_isRamadan_returnsBool() {
        // Just verify it returns without crashing — actual Ramadan status depends on date
        _ = helper.isRamadan()
    }

    func test_hijriDateString_forSpecificDate_isConsistent() {
        let date = Date()
        let result1 = helper.hijriDateString(from: date)
        let result2 = helper.hijriDateString(from: date)
        XCTAssertEqual(result1, result2)
    }
}
