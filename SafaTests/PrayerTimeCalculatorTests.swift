// MARK: - PrayerTimeCalculatorTests.swift
// PURPOSE: Unit tests for prayer time calculations
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class PrayerTimeCalculatorTests: XCTestCase {
    var calculator: PrayerTimeCalculator!

    override func setUp() {
        super.setUp()
        calculator = PrayerTimeCalculator()
    }

    override func tearDown() {
        calculator = nil
        super.tearDown()
    }

    // MARK: - Prayer Time Calculation Tests

    func testCalculatePrayerTimesForNewYork() {
        // New York coordinates
        let location = Coordinates(latitude: 40.7128, longitude: -74.0060)
        let date = createDate(year: 2024, month: 6, day: 21) // Summer solstice

        let prayers = calculator.calculatePrayerTimes(
            for: date,
            location: location,
            method: .isna
        )

        XCTAssertEqual(prayers.count, 6, "Should return 6 prayer times")
        XCTAssertTrue(prayers.contains { $0.type == PrayerType.fajr })
        XCTAssertTrue(prayers.contains { $0.type == PrayerType.sunrise })
        XCTAssertTrue(prayers.contains { $0.type == PrayerType.dhuhr })
        XCTAssertTrue(prayers.contains { $0.type == PrayerType.asr })
        XCTAssertTrue(prayers.contains { $0.type == PrayerType.maghrib })
        XCTAssertTrue(prayers.contains { $0.type == PrayerType.isha })
    }

    func testCalculatePrayerTimesForMakkah() {
        // Makkah coordinates
        let location = Coordinates(latitude: 21.4225, longitude: 39.8262)
        let date = createDate(year: 2024, month: 3, day: 20) // Equinox

        let prayers = calculator.calculatePrayerTimes(
            for: date,
            location: location,
            method: .makkah
        )

        XCTAssertEqual(prayers.count, 6, "Should return 6 prayer times")

        // Verify all prayer types are present
        XCTAssertTrue(prayers.contains { $0.type == PrayerType.fajr })
        XCTAssertTrue(prayers.contains { $0.type == PrayerType.sunrise })
        XCTAssertTrue(prayers.contains { $0.type == PrayerType.dhuhr })
        XCTAssertTrue(prayers.contains { $0.type == PrayerType.asr })
        XCTAssertTrue(prayers.contains { $0.type == PrayerType.maghrib })
        XCTAssertTrue(prayers.contains { $0.type == PrayerType.isha })
    }

    func testPrayerTimesAreInChronologicalOrder() {
        let location = Coordinates(latitude: 51.5074, longitude: -0.1278) // London
        let date = Date()

        let prayers = calculator.calculatePrayerTimes(
            for: date,
            location: location,
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

        let isnaResult = calculator.calculatePrayerTimes(for: date, location: location, method: .isna)
        let mwlResult = calculator.calculatePrayerTimes(for: date, location: location, method: .muslimWorldLeague)

        // ISNA and MWL have different Fajr angles, so times should differ
        let isnaFajr = isnaResult.first { $0.type == PrayerType.fajr }?.time
        let mwlFajr = mwlResult.first { $0.type == PrayerType.fajr }?.time

        XCTAssertNotNil(isnaFajr)
        XCTAssertNotNil(mwlFajr)

        // MWL uses 18 degrees, ISNA uses 15 degrees
        // So MWL Fajr should be earlier
        if let isnaFajr = isnaFajr, let mwlFajr = mwlFajr {
            XCTAssertLessThan(mwlFajr, isnaFajr)
        }
    }

    // MARK: - Additional Calculation Method Tests

    func testAllCalculationMethodsReturn6Prayers() {
        let location = Coordinates(latitude: 40.7128, longitude: -74.0060)
        let date = Date()

        let methods: [CalculationMethod] = [
            .muslimWorldLeague,
            .isna,
            .makkah,
            .karachi,
            .egypt
        ]

        for method in methods {
            let prayers = calculator.calculatePrayerTimes(
                for: date,
                location: location,
                method: method
            )
            XCTAssertEqual(prayers.count, 6, "\(method) should return 6 prayer times")
        }
    }

    func testEgyptianMethodCalculation() {
        let location = Coordinates(latitude: 30.0444, longitude: 31.2357) // Cairo
        let date = createDate(year: 2024, month: 6, day: 21)

        let prayers = calculator.calculatePrayerTimes(
            for: date,
            location: location,
            method: .egypt
        )

        XCTAssertEqual(prayers.count, 6)
        XCTAssertTrue(prayers.allSatisfy { !$0.time.timeIntervalSince1970.isNaN })
    }

    func testKarachiMethodCalculation() {
        let location = Coordinates(latitude: 24.8607, longitude: 67.0011) // Karachi
        let date = createDate(year: 2024, month: 6, day: 21)

        let prayers = calculator.calculatePrayerTimes(
            for: date,
            location: location,
            method: .karachi
        )

        XCTAssertEqual(prayers.count, 6)
        XCTAssertTrue(prayers.allSatisfy { !$0.time.timeIntervalSince1970.isNaN })
    }

    // MARK: - Edge Case Tests

    func testCalculationNearEquator() {
        // Kuala Lumpur - near equator
        let location = Coordinates(latitude: 3.1390, longitude: 101.6869)
        let date = Date()

        let prayers = calculator.calculatePrayerTimes(
            for: date,
            location: location,
            method: .muslimWorldLeague
        )

        XCTAssertEqual(prayers.count, 6)
        // Near equator, day/night is roughly equal year-round
        // All prayers should be valid
        XCTAssertTrue(prayers.allSatisfy { !$0.time.timeIntervalSince1970.isNaN })
    }

    func testCalculationNearInternationalDateLine() {
        // Auckland, New Zealand
        let location = Coordinates(latitude: -36.8485, longitude: 174.7633)
        let date = Date()

        let prayers = calculator.calculatePrayerTimes(
            for: date,
            location: location,
            method: .muslimWorldLeague
        )

        XCTAssertEqual(prayers.count, 6)
        XCTAssertTrue(prayers.allSatisfy { !$0.time.timeIntervalSince1970.isNaN })
    }

    func testCalculationInSouthernHemisphere() {
        // Sydney, Australia
        let location = Coordinates(latitude: -33.8688, longitude: 151.2093)
        let date = createDate(year: 2024, month: 12, day: 21) // Summer in southern hemisphere

        let prayers = calculator.calculatePrayerTimes(
            for: date,
            location: location,
            method: .muslimWorldLeague
        )

        XCTAssertEqual(prayers.count, 6)
        XCTAssertTrue(prayers.allSatisfy { !$0.time.timeIntervalSince1970.isNaN })
    }

    func testWinterSolsticeCalculation() {
        let location = Coordinates(latitude: 40.7128, longitude: -74.0060) // New York
        let date = createDate(year: 2024, month: 12, day: 21) // Winter solstice

        let prayers = calculator.calculatePrayerTimes(
            for: date,
            location: location,
            method: .isna
        )

        XCTAssertEqual(prayers.count, 6)

        // Verify prayers are in order
        for i in 0..<prayers.count - 1 {
            XCTAssertLessThan(prayers[i].time, prayers[i + 1].time)
        }
    }

    // MARK: - Prayer Type Tests

    func testPrayerTypeIsObligatory() {
        // Obligatory prayers
        XCTAssertTrue(PrayerType.fajr.isObligatory)
        XCTAssertTrue(PrayerType.dhuhr.isObligatory)
        XCTAssertTrue(PrayerType.asr.isObligatory)
        XCTAssertTrue(PrayerType.maghrib.isObligatory)
        XCTAssertTrue(PrayerType.isha.isObligatory)

        // Sunrise is not obligatory
        XCTAssertFalse(PrayerType.sunrise.isObligatory)
    }

    func testObligatoryPrayersArray() {
        let obligatory = PrayerType.obligatoryPrayers

        XCTAssertEqual(obligatory.count, 5)
        XCTAssertTrue(obligatory.contains(.fajr))
        XCTAssertTrue(obligatory.contains(.dhuhr))
        XCTAssertTrue(obligatory.contains(.asr))
        XCTAssertTrue(obligatory.contains(.maghrib))
        XCTAssertTrue(obligatory.contains(.isha))
        XCTAssertFalse(obligatory.contains(.sunrise))
    }

    // MARK: - Qibla Direction Edge Cases

    func testQiblaDirectionFromSouthAmerica() {
        // Sao Paulo, Brazil
        let location = Coordinates(latitude: -23.5505, longitude: -46.6333)
        let direction = calculator.calculateQiblaDirection(from: location)

        // Qibla from South America should be roughly east-northeast
        XCTAssertGreaterThan(direction, 50)
        XCTAssertLessThan(direction, 80)
    }

    func testQiblaDirectionFromAustralia() {
        // Sydney
        let location = Coordinates(latitude: -33.8688, longitude: 151.2093)
        let direction = calculator.calculateQiblaDirection(from: location)

        // Qibla from Australia should be roughly west-northwest
        XCTAssertGreaterThan(direction, 270)
        XCTAssertLessThan(direction, 300)
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
