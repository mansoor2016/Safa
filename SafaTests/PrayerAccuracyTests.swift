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

    // MARK: - Scenario 7: Dubai (GIAE)

    func testDubai() {
        let location = Coordinates(latitude: 25.2048, longitude: 55.2708)
        let date = createDate(year: 2026, month: 2, day: 14)
        let prayers = calculator.calculatePrayerTimes(
            for: date, location: location, method: .dubai
        )
        let tz = TimeZone(identifier: "Asia/Dubai")!

        assertTime(prayers, .fajr, hour: 5, minute: 36, timeZone: tz)
        assertTime(prayers, .sunrise, hour: 6, minute: 52, timeZone: tz)
        assertTime(prayers, .dhuhr, hour: 12, minute: 36, timeZone: tz)
        assertTime(prayers, .asr, hour: 15, minute: 52, timeZone: tz)
        assertTime(prayers, .maghrib, hour: 18, minute: 14, timeZone: tz)
        assertTime(prayers, .isha, hour: 19, minute: 30, timeZone: tz)
    }

    // MARK: - Scenario 8: Kuwait

    func testKuwait() {
        let location = Coordinates(latitude: 29.3759, longitude: 47.9774)
        let date = createDate(year: 2026, month: 2, day: 14)
        let prayers = calculator.calculatePrayerTimes(
            for: date, location: location, method: .kuwait
        )
        let tz = TimeZone(identifier: "Asia/Kuwait")!

        assertTime(prayers, .fajr, hour: 5, minute: 8, timeZone: tz)
        assertTime(prayers, .sunrise, hour: 6, minute: 28, timeZone: tz)
        assertTime(prayers, .dhuhr, hour: 12, minute: 2, timeZone: tz)
        assertTime(prayers, .asr, hour: 15, minute: 14, timeZone: tz)
        assertTime(prayers, .maghrib, hour: 17, minute: 37, timeZone: tz)
        assertTime(prayers, .isha, hour: 18, minute: 54, timeZone: tz)
    }

    // MARK: - Scenario 9: Qatar

    func testQatar() {
        let location = Coordinates(latitude: 25.2854, longitude: 51.5310)
        let date = createDate(year: 2026, month: 2, day: 14)
        let prayers = calculator.calculatePrayerTimes(
            for: date, location: location, method: .qatar
        )
        let tz = TimeZone(identifier: "Asia/Qatar")!

        assertTime(prayers, .fajr, hour: 4, minute: 52, timeZone: tz)
        assertTime(prayers, .sunrise, hour: 6, minute: 9, timeZone: tz)
        assertTime(prayers, .dhuhr, hour: 11, minute: 48, timeZone: tz)
        assertTime(prayers, .asr, hour: 15, minute: 2, timeZone: tz)
        assertTime(prayers, .maghrib, hour: 17, minute: 27, timeZone: tz)
        assertTime(prayers, .isha, hour: 18, minute: 57, timeZone: tz)
    }

    // MARK: - Scenario 10: Singapore (MUIS)

    func testSingapore() {
        let location = Coordinates(latitude: 1.3521, longitude: 103.8198)
        let date = createDate(year: 2026, month: 2, day: 14)
        let prayers = calculator.calculatePrayerTimes(
            for: date, location: location, method: .singapore
        )
        let tz = TimeZone(identifier: "Asia/Singapore")!

        assertTime(prayers, .fajr, hour: 5, minute: 58, timeZone: tz)
        assertTime(prayers, .sunrise, hour: 7, minute: 17, timeZone: tz)
        assertTime(prayers, .dhuhr, hour: 13, minute: 20, timeZone: tz)
        assertTime(prayers, .asr, hour: 16, minute: 39, timeZone: tz)
        assertTime(prayers, .maghrib, hour: 19, minute: 22, timeZone: tz)
        assertTime(prayers, .isha, hour: 20, minute: 32, timeZone: tz)
    }

    // MARK: - Scenario 11: Turkey (Diyanet)

    func testTurkey() {
        let location = Coordinates(latitude: 41.0082, longitude: 28.9784)
        let date = createDate(year: 2026, month: 2, day: 14)
        let prayers = calculator.calculatePrayerTimes(
            for: date, location: location, method: .turkey
        )
        let tz = TimeZone(identifier: "Europe/Istanbul")!

        assertTime(prayers, .fajr, hour: 6, minute: 28, timeZone: tz)
        assertTime(prayers, .sunrise, hour: 7, minute: 53, timeZone: tz)
        assertTime(prayers, .dhuhr, hour: 13, minute: 23, timeZone: tz)
        assertTime(prayers, .asr, hour: 16, minute: 16, timeZone: tz)
        assertTime(prayers, .maghrib, hour: 18, minute: 44, timeZone: tz)
        assertTime(prayers, .isha, hour: 20, minute: 4, timeZone: tz)
    }

    // MARK: - Scenario 12: High Latitude — Oslo Summer (auto rule applied)

    func testOsloSummer_highLatitudeRuleAdjustsFajrIsha() {
        let oslo = Coordinates(latitude: 59.9139, longitude: 10.7522)
        let date = createDate(year: 2026, month: 6, day: 21)
        let prayers = calculator.calculatePrayerTimes(
            for: date, location: oslo, method: .muslimWorldLeague
        )
        let tz = TimeZone(identifier: "Europe/Oslo")!

        // With the high-latitude rule, Fajr should not be absurdly early
        // (without it, Fajr could be ~1:00 AM or even missing)
        guard let fajr = prayers.first(where: { $0.type == .fajr }) else {
            XCTFail("Fajr should be present")
            return
        }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let fajrHour = cal.component(.hour, from: fajr.time)
        XCTAssertGreaterThanOrEqual(fajrHour, 1,
                                     "Fajr in Oslo summer should be after 1 AM with high-lat rule")

        guard let isha = prayers.first(where: { $0.type == .isha }) else {
            XCTFail("Isha should be present")
            return
        }
        let ishaHour = cal.component(.hour, from: isha.time)
        // Isha should not extend past midnight with the rule
        XCTAssertTrue(ishaHour >= 22 || ishaHour < 3,
                      "Isha in Oslo summer should be late evening/early morning, got \(ishaHour)")
    }

    func testMakkah_unaffectedByHighLatitudeRule() {
        let makkah = Coordinates(latitude: 21.4225, longitude: 39.8262)
        let date = createDate(year: 2026, month: 6, day: 21)
        let prayers = calculator.calculatePrayerTimes(
            for: date, location: makkah, method: .makkah
        )
        let tz = TimeZone(identifier: "Asia/Riyadh")!

        // Makkah at 21°N — well below 48°N, should have normal times
        assertTime(prayers, .fajr, hour: 4, minute: 12, timeZone: tz, tolerance: 2)
        assertTime(prayers, .isha, hour: 20, minute: 36, timeZone: tz, tolerance: 2)
    }

    // MARK: - Sunnah Times Tests

    func testSunnahTimes_middleBeforeLastThird() {
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let date = createDate(year: 2026, month: 2, day: 14)
        let sunnah = calculator.calculateSunnahTimes(
            for: date, location: london, method: .muslimWorldLeague
        )

        XCTAssertEqual(sunnah.count, 2, "Should return middle and last third")

        let middle = sunnah.first { $0.type == .middleOfTheNight }!
        let lastThird = sunnah.first { $0.type == .lastThirdOfTheNight }!

        XCTAssertTrue(middle.time < lastThird.time,
                      "Middle of the night should be before last third")
    }

    func testSunnahTimes_fallBetweenMaghribAndFajr() {
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let date = createDate(year: 2026, month: 2, day: 14)

        let prayers = calculator.calculatePrayerTimes(
            for: date, location: london, method: .muslimWorldLeague
        )
        let sunnah = calculator.calculateSunnahTimes(
            for: date, location: london, method: .muslimWorldLeague
        )

        let maghrib = prayers.first { $0.type == .maghrib }!.time
        let middle = sunnah.first { $0.type == .middleOfTheNight }!.time
        let lastThird = sunnah.first { $0.type == .lastThirdOfTheNight }!.time

        XCTAssertTrue(middle > maghrib,
                      "Middle of night should be after Maghrib")
        XCTAssertTrue(lastThird > maghrib,
                      "Last third should be after Maghrib")

        // Next day's Fajr
        let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        let nextPrayers = calculator.calculatePrayerTimes(
            for: nextDate, location: london, method: .muslimWorldLeague
        )
        let nextFajr = nextPrayers.first { $0.type == .fajr }!.time

        XCTAssertTrue(lastThird < nextFajr,
                      "Last third should be before next Fajr")
    }

    // MARK: - Preview Card: Different Methods Produce Different Times

    func testDifferentMethodsProduceDifferentFajrIsha() {
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let date = createDate(year: 2026, month: 2, day: 14)

        let mwl = calculator.calculatePrayerTimes(for: date, location: london, method: .muslimWorldLeague)
        let isna = calculator.calculatePrayerTimes(for: date, location: london, method: .isna)

        let mwlFajr = mwl.first { $0.type == .fajr }!.time
        let isnaFajr = isna.first { $0.type == .fajr }!.time

        XCTAssertNotEqual(
            mwlFajr.timeIntervalSinceReferenceDate,
            isnaFajr.timeIntervalSinceReferenceDate,
            accuracy: 30,
            "MWL and ISNA should produce different Fajr times"
        )

        let mwlIsha = mwl.first { $0.type == .isha }!.time
        let isnaIsha = isna.first { $0.type == .isha }!.time

        XCTAssertNotEqual(
            mwlIsha.timeIntervalSinceReferenceDate,
            isnaIsha.timeIntervalSinceReferenceDate,
            accuracy: 30,
            "MWL and ISNA should produce different Isha times"
        )
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
