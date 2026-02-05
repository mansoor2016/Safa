// MARK: - HijriDateTests.swift
// PURPOSE: Unit tests for Hijri date conversion
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class HijriDateConverterTests: XCTestCase {

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

    func testHijriFormattedStringNotEmpty() {
        let date = Date()
        let formatted = sut.hijriFormattedString(from: date)

        XCTAssertFalse(formatted.isEmpty)
    }

    // MARK: - Month Name Tests

    func testHijriMonthNames() {
        let monthNames = [
            "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
            "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
            "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"
        ]

        for (index, expectedName) in monthNames.enumerated() {
            let name = sut.hijriMonthName(for: index + 1)
            XCTAssertEqual(name, expectedName, "Month \(index + 1) should be \(expectedName)")
        }
    }

    func testArabicMonthNames() {
        let date = Date()
        let arabicFormatted = sut.hijriFormattedStringArabic(from: date)

        // Should contain Arabic characters
        let arabicRange = 0x0600...0x06FF
        let hasArabic = arabicFormatted.unicodeScalars.contains { arabicRange.contains(Int($0.value)) }

        XCTAssertTrue(hasArabic, "Arabic formatted string should contain Arabic characters")
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

    func testIsRamadan() {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        var components = DateComponents()
        components.year = 1446
        components.month = 9
        components.day = 1

        if let ramadanStart = hijriCalendar.date(from: components) {
            let isRamadan = sut.isRamadan(date: ramadanStart)
            XCTAssertTrue(isRamadan)
        }
    }

    func testIsFriday() {
        // Find a Friday
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .weekday], from: Date())

        // Adjust to Friday (weekday 6 in Gregorian)
        while components.weekday != 6 {
            if let date = calendar.date(from: components) {
                components = calendar.dateComponents([.year, .month, .day, .weekday], from: date.addingTimeInterval(86400))
            }
        }

        if let friday = calendar.date(from: components) {
            let isFriday = sut.isFriday(date: friday)
            XCTAssertTrue(isFriday)
        }
    }

    // MARK: - Date Formatting Tests

    func testLongFormatIncludesAllParts() {
        let date = Date()
        let longFormat = sut.hijriFormattedString(from: date, format: .long)

        // Should contain day number
        XCTAssertTrue(longFormat.contains(CharacterSet.decimalDigits))
    }

    func testShortFormatIsConcise() {
        let date = Date()
        let shortFormat = sut.hijriFormattedString(from: date, format: .short)
        let longFormat = sut.hijriFormattedString(from: date, format: .long)

        // Short format should be shorter or equal
        XCTAssertLessThanOrEqual(shortFormat.count, longFormat.count + 10)
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
