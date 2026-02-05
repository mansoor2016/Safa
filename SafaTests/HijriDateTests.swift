// MARK: - HijriDateTests.swift
// PURPOSE: Additional unit tests for Hijri date functionality
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class HijriDateAdvancedTests: XCTestCase {

    var sut: HijriDateConverter!

    override func setUp() {
        super.setUp()
        sut = HijriDateConverter.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Conversion Tests

    func testConvertToHijriReturnsValidComponents() {
        let date = Date()
        let (year, month, day) = sut.hijriComponents(from: date)

        // Hijri year should be reasonable (1400-1500 range for current era)
        XCTAssertGreaterThan(year, 1400)
        XCTAssertLessThan(year, 1500)

        // Month should be 1-12
        XCTAssertGreaterThanOrEqual(month, 1)
        XCTAssertLessThanOrEqual(month, 12)

        // Day should be 1-30
        XCTAssertGreaterThanOrEqual(day, 1)
        XCTAssertLessThanOrEqual(day, 30)
    }

    func testHijriDateStringNotEmpty() {
        let date = Date()
        let formatted = sut.hijriDateString(from: date)

        XCTAssertFalse(formatted.isEmpty)
    }

    // MARK: - Month Name Tests

    func testHijriMonthNamesCorrectCount() {
        // Test that each month returns a non-empty name
        for month in 1...12 {
            let name = sut.hijriMonthName(month)
            XCTAssertFalse(name.isEmpty, "Month \(month) should have a name")
        }
    }

    func testInvalidMonthReturnsEmpty() {
        let invalidName = sut.hijriMonthName(13)
        XCTAssertTrue(invalidName.isEmpty)

        let zeroName = sut.hijriMonthName(0)
        XCTAssertTrue(zeroName.isEmpty)
    }

    // MARK: - Specific Date Tests

    func testRamadanDetection() {
        // Create a date in Ramadan (month 9)
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        var components = DateComponents()
        components.year = 1446
        components.month = 9
        components.day = 15

        if let ramadanDate = hijriCalendar.date(from: components) {
            let (_, month, _) = sut.hijriComponents(from: ramadanDate)
            XCTAssertEqual(month, 9, "Ramadan should be month 9")
        }
    }

    func testDhuAlHijjahDetection() {
        // Create a date in Dhu al-Hijjah (month 12)
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        var components = DateComponents()
        components.year = 1446
        components.month = 12
        components.day = 10

        if let hajjDate = hijriCalendar.date(from: components) {
            let (_, month, _) = sut.hijriComponents(from: hajjDate)
            XCTAssertEqual(month, 12, "Dhu al-Hijjah should be month 12")
        }
    }

    // MARK: - Edge Cases

    func testFarPastDate() {
        var components = DateComponents()
        components.year = 1970
        components.month = 1
        components.day = 1
        let pastDate = Calendar.current.date(from: components)!

        let (year, month, day) = sut.hijriComponents(from: pastDate)

        XCTAssertGreaterThan(year, 0)
        XCTAssertGreaterThanOrEqual(month, 1)
        XCTAssertLessThanOrEqual(month, 12)
        XCTAssertGreaterThanOrEqual(day, 1)
    }

    func testFarFutureDate() {
        var components = DateComponents()
        components.year = 2050
        components.month = 12
        components.day = 31
        let futureDate = Calendar.current.date(from: components)!

        let (year, month, day) = sut.hijriComponents(from: futureDate)

        XCTAssertGreaterThan(year, 1400)
        XCTAssertGreaterThanOrEqual(month, 1)
        XCTAssertLessThanOrEqual(month, 12)
        XCTAssertGreaterThanOrEqual(day, 1)
    }

    // MARK: - Islamic Event Detection

    func testIsRamadanTrue() {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        var components = DateComponents()
        components.year = 1446
        components.month = 9
        components.day = 1

        if let ramadanStart = hijriCalendar.date(from: components) {
            let isRamadan = sut.isRamadan(on: ramadanStart)
            XCTAssertTrue(isRamadan)
        }
    }

    func testIsRamadanFalse() {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        var components = DateComponents()
        components.year = 1446
        components.month = 3 // Rabi' al-Awwal
        components.day = 15

        if let notRamadan = hijriCalendar.date(from: components) {
            let isRamadan = sut.isRamadan(on: notRamadan)
            XCTAssertFalse(isRamadan)
        }
    }

    // MARK: - Blessed Night Tests

    func testBlessedNightLailatAlQadr() {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        var components = DateComponents()
        components.year = 1446
        components.month = 9 // Ramadan
        components.day = 27 // Odd night in last 10

        if let lailatAlQadr = hijriCalendar.date(from: components) {
            let isBlessedNight = sut.isBlessedNight(on: lailatAlQadr)
            XCTAssertTrue(isBlessedNight)
        }
    }

    func testBlessedNightMidShaban() {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        var components = DateComponents()
        components.year = 1446
        components.month = 8 // Sha'ban
        components.day = 15 // Mid-Sha'ban

        if let midShaban = hijriCalendar.date(from: components) {
            let isBlessedNight = sut.isBlessedNight(on: midShaban)
            XCTAssertTrue(isBlessedNight)
        }
    }

    // MARK: - Date Formatting Tests

    func testLongFormatIncludesAllParts() {
        let date = Date()
        let longFormat = sut.hijriDateString(from: date, style: .full)

        // Should contain day number
        XCTAssertTrue(longFormat.rangeOfCharacter(from: .decimalDigits) != nil)
        // Should contain "AH"
        XCTAssertTrue(longFormat.contains("AH"))
    }

    func testShortFormatIsConcise() {
        let date = Date()
        let shortFormat = sut.hijriDateString(from: date, style: .short)
        let longFormat = sut.hijriDateString(from: date, style: .full)

        // Short format should typically be shorter
        XCTAssertLessThan(shortFormat.count, longFormat.count)
    }
}

// MARK: - Islamic Calendar Helper Tests

final class IslamicCalendarTests: XCTestCase {

    func testIslamicCalendarExists() {
        let calendar = Calendar(identifier: .islamicUmmAlQura)
        XCTAssertNotNil(calendar)
    }

    func testIslamicCalendarHas12Months() {
        let calendar = Calendar(identifier: .islamicUmmAlQura)
        let monthRange = calendar.range(of: .month, in: .year, for: Date())

        XCTAssertEqual(monthRange?.count, 12)
    }

    func testIslamicMonthHas29Or30Days() {
        let calendar = Calendar(identifier: .islamicUmmAlQura)
        let dayRange = calendar.range(of: .day, in: .month, for: Date())

        // Islamic months have 29 or 30 days
        if let range = dayRange {
            XCTAssertTrue(range.count == 29 || range.count == 30)
        }
    }
}
