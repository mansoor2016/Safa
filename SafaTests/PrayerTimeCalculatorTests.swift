// MARK: - PrayerTimeCalculatorTests.swift
// PURPOSE: Unit tests for prayer time calculations
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class PrayerTimeCalculatorTests: XCTestCase {
    var calculator: PrayerTimeCalculator!

    override func setUpWithError() throws {
        calculator = PrayerTimeCalculator()
    }

    override func tearDownWithError() throws {
        calculator = nil
    }

    // MARK: - Prayer Time Calculation Tests

    func testCalculatePrayerTimesForNewYork() {
        // New York coordinates
        let location = Coordinates(latitude: 40.7128, longitude: -74.0060)
        let date = createDate(year: 2024, month: 6, day: 21) // Summer solstice

        let prayers = calculator.calculatePrayerTimes(
            for: date,
            at: location,
            method: .isna
        )

        XCTAssertEqual(prayers.count, 6, "Should return 6 prayer times")
        XCTAssertTrue(prayers.contains { $0.type == .fajr })
        XCTAssertTrue(prayers.contains { $0.type == .sunrise })
        XCTAssertTrue(prayers.contains { $0.type == .dhuhr })
        XCTAssertTrue(prayers.contains { $0.type == .asr })
        XCTAssertTrue(prayers.contains { $0.type == .maghrib })
        XCTAssertTrue(prayers.contains { $0.type == .isha })
    }

    func testCalculatePrayerTimesForMakkah() {
        // Makkah coordinates
        let location = Coordinates(latitude: 21.4225, longitude: 39.8262)
        let date = createDate(year: 2024, month: 3, day: 20) // Equinox

        let prayers = calculator.calculatePrayerTimes(
            for: date,
            at: location,
            method: .makkah
        )

        XCTAssertEqual(prayers.count, 6, "Should return 6 prayer times")

        // Verify order
        let sortedPrayers = prayers.sorted { $0.time < $1.time }
        XCTAssertEqual(sortedPrayers[0].type, .fajr)
        XCTAssertEqual(sortedPrayers[1].type, .sunrise)
        XCTAssertEqual(sortedPrayers[2].type, .dhuhr)
        XCTAssertEqual(sortedPrayers[3].type, .asr)
        XCTAssertEqual(sortedPrayers[4].type, .maghrib)
        XCTAssertEqual(sortedPrayers[5].type, .isha)
    }

    func testPrayerTimesAreInChronologicalOrder() {
        let location = Coordinates(latitude: 51.5074, longitude: -0.1278) // London
        let date = Date()

        let prayers = calculator.calculatePrayerTimes(
            for: date,
            at: location,
            method: .muslimWorldLeague
        )

        for i in 0..<prayers.count - 1 {
            XCTAssertLessThan(
                prayers[i].time,
                prayers[i + 1].time,
                "\(prayers[i].type) should be before \(prayers[i + 1].type)"
            )
        }
    }

    // MARK: - Qibla Direction Tests

    func testQiblaDirectionFromNewYork() {
        let location = Coordinates(latitude: 40.7128, longitude: -74.0060)
        let direction = calculator.calculateQiblaDirection(from: location)

        // Qibla from New York should be roughly 58-59 degrees (NE)
        XCTAssertGreaterThan(direction, 55)
        XCTAssertLessThan(direction, 65)
    }

    func testQiblaDirectionFromLondon() {
        let location = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let direction = calculator.calculateQiblaDirection(from: location)

        // Qibla from London should be roughly 118-119 degrees (ESE)
        XCTAssertGreaterThan(direction, 115)
        XCTAssertLessThan(direction, 125)
    }

    func testQiblaDirectionFromTokyo() {
        let location = Coordinates(latitude: 35.6762, longitude: 139.6503)
        let direction = calculator.calculateQiblaDirection(from: location)

        // Qibla from Tokyo should be roughly 293 degrees (WNW)
        XCTAssertGreaterThan(direction, 288)
        XCTAssertLessThan(direction, 298)
    }

    func testQiblaDirectionFromMakkah() {
        let location = Coordinates(latitude: 21.4225, longitude: 39.8262)
        let direction = calculator.calculateQiblaDirection(from: location)

        // From Makkah, direction should be approximately 0 or any value (at the Kaaba)
        // This is a special case - just verify it returns a valid number
        XCTAssertFalse(direction.isNaN)
        XCTAssertFalse(direction.isInfinite)
    }

    // MARK: - Calculation Method Tests

    func testDifferentCalculationMethods() {
        let location = Coordinates(latitude: 40.7128, longitude: -74.0060)
        let date = Date()

        let isnaResult = calculator.calculatePrayerTimes(for: date, at: location, method: .isna)
        let mwlResult = calculator.calculatePrayerTimes(for: date, at: location, method: .muslimWorldLeague)

        // ISNA and MWL have different Fajr angles, so times should differ
        let isnaFajr = isnaResult.first { $0.type == .fajr }?.time
        let mwlFajr = mwlResult.first { $0.type == .fajr }?.time

        XCTAssertNotNil(isnaFajr)
        XCTAssertNotNil(mwlFajr)

        // MWL uses 18 degrees, ISNA uses 15 degrees
        // So MWL Fajr should be earlier
        if let isnaFajr = isnaFajr, let mwlFajr = mwlFajr {
            XCTAssertLessThan(mwlFajr, isnaFajr)
        }
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
