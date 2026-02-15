// MARK: - PrayerAccuracyTests.swift
// PURPOSE: Verify prayer time wrapper correctness against known adhan-swift output
// DEPENDENCIES: XCTest, PrayerTimeCalculator
// TOLERANCE: ±1 minute per prayer time

import XCTest
@testable import Safa

final class PrayerAccuracyTests: XCTestCase {
    var calculator: PrayerTimeCalculator!

    override func setUp() {
        super.setUp()
        calculator = PrayerTimeCalculator()
    }

    override func tearDown() {
        calculator = nil
        super.tearDown()
    }

    // MARK: - Scenario 1: London MWL Winter

    func testLondonMWLWinter() {
        let location = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let date = createDate(year: 2026, month: 2, day: 14)
        let prayers = calculator.calculatePrayerTimes(
            for: date, location: location, method: .muslimWorldLeague
        )
        let tz = TimeZone(identifier: "Europe/London")!

        assertTime(prayers, .fajr, hour: 5, minute: 24, timeZone: tz)
        assertTime(prayers, .sunrise, hour: 7, minute: 16, timeZone: tz)
        assertTime(prayers, .dhuhr, hour: 12, minute: 16, timeZone: tz)
        assertTime(prayers, .asr, hour: 14, minute: 45, timeZone: tz)
        assertTime(prayers, .maghrib, hour: 17, minute: 14, timeZone: tz)
        assertTime(prayers, .isha, hour: 19, minute: 0, timeZone: tz)
    }

    // MARK: - Scenario 2: London ISNA Winter

    func testLondonISNAWinter() {
        let location = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let date = createDate(year: 2026, month: 2, day: 14)
        let prayers = calculator.calculatePrayerTimes(
            for: date, location: location, method: .isna
        )
        let tz = TimeZone(identifier: "Europe/London")!

        assertTime(prayers, .fajr, hour: 5, minute: 43, timeZone: tz)
        assertTime(prayers, .sunrise, hour: 7, minute: 16, timeZone: tz)
        assertTime(prayers, .dhuhr, hour: 12, minute: 16, timeZone: tz)
        assertTime(prayers, .asr, hour: 14, minute: 45, timeZone: tz)
        assertTime(prayers, .maghrib, hour: 17, minute: 14, timeZone: tz)
        assertTime(prayers, .isha, hour: 18, minute: 47, timeZone: tz)
    }

    // MARK: - Scenario 3: Makkah Umm al-Qura

    func testMakkahUmmAlQura() {
        let location = Coordinates(latitude: 21.4225, longitude: 39.8262)
        let date = createDate(year: 2026, month: 2, day: 14)
        let prayers = calculator.calculatePrayerTimes(
            for: date, location: location, method: .makkah
        )
        let tz = TimeZone(identifier: "Asia/Riyadh")!

        assertTime(prayers, .fajr, hour: 5, minute: 35, timeZone: tz)
        assertTime(prayers, .sunrise, hour: 6, minute: 52, timeZone: tz)
        assertTime(prayers, .dhuhr, hour: 12, minute: 35, timeZone: tz)
        assertTime(prayers, .asr, hour: 15, minute: 52, timeZone: tz)
        assertTime(prayers, .maghrib, hour: 18, minute: 18, timeZone: tz)
        assertTime(prayers, .isha, hour: 19, minute: 48, timeZone: tz)
    }

    // MARK: - Scenario 4: Karachi

    func testKarachi() {
        let location = Coordinates(latitude: 24.8607, longitude: 67.0011)
        let date = createDate(year: 2026, month: 2, day: 14)
        let prayers = calculator.calculatePrayerTimes(
            for: date, location: location, method: .karachi
        )
        let tz = TimeZone(identifier: "Asia/Karachi")!

        assertTime(prayers, .fajr, hour: 5, minute: 50, timeZone: tz)
        assertTime(prayers, .sunrise, hour: 7, minute: 7, timeZone: tz)
        assertTime(prayers, .dhuhr, hour: 12, minute: 47, timeZone: tz)
        assertTime(prayers, .asr, hour: 16, minute: 1, timeZone: tz)
        assertTime(prayers, .maghrib, hour: 18, minute: 26, timeZone: tz)
        assertTime(prayers, .isha, hour: 19, minute: 42, timeZone: tz)
    }

    // MARK: - Scenario 5: London MWL Summer (DST)

    func testLondonMWLSummer() {
        let location = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let date = createDate(year: 2026, month: 6, day: 21)
        let prayers = calculator.calculatePrayerTimes(
            for: date, location: location, method: .muslimWorldLeague
        )
        let tz = TimeZone(identifier: "Europe/London")!

        assertTime(prayers, .fajr, hour: 3, minute: 40, timeZone: tz)
        assertTime(prayers, .sunrise, hour: 4, minute: 43, timeZone: tz)
        assertTime(prayers, .dhuhr, hour: 13, minute: 3, timeZone: tz)
        assertTime(prayers, .asr, hour: 17, minute: 25, timeZone: tz)
        assertTime(prayers, .maghrib, hour: 21, minute: 22, timeZone: tz)
        assertTime(prayers, .isha, hour: 22, minute: 25, timeZone: tz)
    }

    // MARK: - Scenario 6: Anchorage ISNA Summer

    func testAnchorageISNASummer() {
        let location = Coordinates(latitude: 61.2181, longitude: -149.9003)
        let date = createDate(year: 2026, month: 6, day: 21)
        let prayers = calculator.calculatePrayerTimes(
            for: date, location: location, method: .isna
        )
        let tz = TimeZone(identifier: "America/Anchorage")!

        assertTime(prayers, .fajr, hour: 3, minute: 41, timeZone: tz)
        assertTime(prayers, .sunrise, hour: 4, minute: 20, timeZone: tz)
        assertTime(prayers, .dhuhr, hour: 14, minute: 3, timeZone: tz)
        assertTime(prayers, .asr, hour: 18, minute: 46, timeZone: tz)
        assertTime(prayers, .maghrib, hour: 23, minute: 43, timeZone: tz)
        assertTime(prayers, .isha, hour: 0, minute: 22, timeZone: tz)
    }

    // MARK: - Helpers

    private func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar.current.date(from: components)!
    }

    private func assertTime(
        _ prayers: [PrayerTime],
        _ type: PrayerType,
        hour: Int,
        minute: Int,
        timeZone: TimeZone,
        tolerance: Int = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let prayer = prayers.first(where: { $0.type == type }) else {
            XCTFail("Missing \(type.displayName) prayer", file: file, line: line)
            return
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.hour, .minute], from: prayer.time)

        let actualHour = components.hour ?? 0
        let actualMinute = components.minute ?? 0
        let actualMinutes = actualHour * 60 + actualMinute
        let expectedMinutes = hour * 60 + minute
        var diff = abs(actualMinutes - expectedMinutes)
        if diff > 720 { diff = 1440 - diff }

        XCTAssertLessThanOrEqual(
            diff, tolerance,
            "\(type.displayName): expected \(String(format: "%02d:%02d", hour, minute)), " +
            "got \(String(format: "%02d:%02d", actualHour, actualMinute)) " +
            "(off by \(diff) min)",
            file: file, line: line
        )
    }
}
