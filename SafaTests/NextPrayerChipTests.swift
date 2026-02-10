// MARK: - NextPrayerChipTests.swift
// PURPOSE: Tests for NextPrayerChip accessibility label formatting
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class NextPrayerChipTests: XCTestCase {

    // MARK: - Pluralization

    func test_accessibilityLabel_hoursAndMinutesPlural() {
        let label = formatNextPrayerAccessibilityLabel(prayerName: "Dhuhr", hours: 2, minutes: 30)
        XCTAssertEqual(label, "Next prayer: Dhuhr in 2 hours 30 minutes")
    }

    func test_accessibilityLabel_oneHourSingular() {
        let label = formatNextPrayerAccessibilityLabel(prayerName: "Asr", hours: 1, minutes: 15)
        XCTAssertEqual(label, "Next prayer: Asr in 1 hour 15 minutes")
    }

    func test_accessibilityLabel_oneMinuteSingular() {
        let label = formatNextPrayerAccessibilityLabel(prayerName: "Maghrib", hours: 0, minutes: 1)
        XCTAssertEqual(label, "Next prayer: Maghrib in 1 minute")
    }

    func test_accessibilityLabel_oneHourOneMinute() {
        let label = formatNextPrayerAccessibilityLabel(prayerName: "Isha", hours: 1, minutes: 1)
        XCTAssertEqual(label, "Next prayer: Isha in 1 hour 1 minute")
    }

    // MARK: - Edge Cases

    func test_accessibilityLabel_zeroHoursAndMinutes_showsNow() {
        let label = formatNextPrayerAccessibilityLabel(prayerName: "Fajr", hours: 0, minutes: 0)
        XCTAssertEqual(label, "Next prayer: Fajr now")
    }

    func test_accessibilityLabel_hoursOnly_noMinutes() {
        let label = formatNextPrayerAccessibilityLabel(prayerName: "Dhuhr", hours: 3, minutes: 0)
        XCTAssertEqual(label, "Next prayer: Dhuhr in 3 hours")
    }

    func test_accessibilityLabel_minutesOnly_noHours() {
        let label = formatNextPrayerAccessibilityLabel(prayerName: "Fajr", hours: 0, minutes: 45)
        XCTAssertEqual(label, "Next prayer: Fajr in 45 minutes")
    }

    // MARK: - Prayer Name Passthrough

    func test_accessibilityLabel_includesPrayerName() {
        let label = formatNextPrayerAccessibilityLabel(prayerName: "Maghrib", hours: 2, minutes: 10)
        XCTAssertTrue(label.hasPrefix("Next prayer: Maghrib"))
    }
}
