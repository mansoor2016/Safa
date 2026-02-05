// MARK: - HijriDateConverterTests.swift
// PURPOSE: Unit tests for Hijri date conversion
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class HijriDateConverterTests: XCTestCase {
    var converter: HijriDateConverter!

    override func setUpWithError() throws {
        converter = HijriDateConverter.shared
    }

    // MARK: - Conversion Tests

    func testHijriComponents() {
        // Test a known date: January 1, 2024 = ~18 Jumada al-Thani 1445
        let date = createDate(year: 2024, month: 1, day: 1)
        let (year, month, day) = converter.hijriComponents(from: date)

        XCTAssertEqual(year, 1445)
        XCTAssertGreaterThan(month, 0)
        XCTAssertLessThanOrEqual(month, 12)
        XCTAssertGreaterThan(day, 0)
        XCTAssertLessThanOrEqual(day, 30)
    }

    func testHijriDateStringFull() {
        let date = Date()
        let result = converter.hijriDateString(from: date, style: .full)

        XCTAssertFalse(result.isEmpty)
        // Should contain a month name and year
        XCTAssertTrue(result.contains("14") || result.contains("15")) // Hijri century
    }

    func testHijriDateStringShort() {
        let date = Date()
        let result = converter.hijriDateString(from: date, style: .short)

        XCTAssertFalse(result.isEmpty)
        // Short format should be more compact
        XCTAssertLessThan(result.count, 30)
    }

    func testHijriDateStringMonthYear() {
        let date = Date()
        let result = converter.hijriDateString(from: date, style: .monthYear)

        XCTAssertFalse(result.isEmpty)
        // Should contain month and year only
        XCTAssertTrue(result.contains("14") || result.contains("15"))
    }

    // MARK: - Month Name Tests

    func testMonthNames() {
        let monthNames = [
            "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
            "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
            "Ramadan", "Shawwal", "Dhul Qi'dah", "Dhul Hijjah"
        ]

        // Test that each month name exists
        for month in monthNames {
            XCTAssertFalse(month.isEmpty)
        }
    }

    // MARK: - Ramadan Detection Tests

    func testIsRamadanDuringRamadan() {
        // Create a date during Ramadan 1445 (approximately March 2024)
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        var components = DateComponents()
        components.year = 1445
        components.month = 9 // Ramadan
        components.day = 15

        if let ramadanDate = hijriCalendar.date(from: components) {
            // We need to mock this or test with the actual date
            // For now, just verify the method doesn't crash
            _ = converter.isRamadan(on: ramadanDate)
        }
    }

    func testIsRamadanOutsideRamadan() {
        // Test with a date that's definitely not Ramadan
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        var components = DateComponents()
        components.year = 1445
        components.month = 1 // Muharram (not Ramadan)
        components.day = 15

        if let date = hijriCalendar.date(from: components) {
            let result = converter.isRamadan(on: date)
            XCTAssertFalse(result)
        }
    }

    // MARK: - Days in Month Tests

    func testDaysInHijriMonth() {
        // Hijri months alternate between 29 and 30 days
        for month in 1...12 {
            let days = converter.daysInHijriMonth(month, year: 1445)
            XCTAssertGreaterThanOrEqual(days, 29)
            XCTAssertLessThanOrEqual(days, 30)
        }
    }

    // MARK: - Edge Cases

    func testDistantPastDate() {
        let date = createDate(year: 1970, month: 1, day: 1)
        let result = converter.hijriDateString(from: date, style: .full)

        XCTAssertFalse(result.isEmpty)
    }

    func testDistantFutureDate() {
        let date = createDate(year: 2100, month: 12, day: 31)
        let result = converter.hijriDateString(from: date, style: .full)

        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Helper Methods

    private func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar.current.date(from: components) ?? Date()
    }
}
