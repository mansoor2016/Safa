// MARK: - PrayerCalculationTests.swift
// PURPOSE: Unit tests for prayer time calculations
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class PrayerCalculationTests: XCTestCase {

    var sut: PrayerTimeCalculator!

    override func setUp() {
        super.setUp()
        sut = PrayerTimeCalculator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - ISNA Calculation Method Tests

    func testISNACalculationForNewYork() {
        // New York coordinates
        let location = Coordinates(latitude: 40.7128, longitude: -74.0060)

        let prayers = sut.calculatePrayerTimes(
            for: createDate(year: 2026, month: 2, day: 4),
            location: location,
            method: .isna
        )

        XCTAssertNotNil(prayers)
        XCTAssertEqual(prayers.count, 6)

        // Verify all prayer times are present
        XCTAssertNotNil(prayers.first { $0.type == PrayerType.fajr })
        XCTAssertNotNil(prayers.first { $0.type == PrayerType.sunrise })
        XCTAssertNotNil(prayers.first { $0.type == PrayerType.dhuhr })
        XCTAssertNotNil(prayers.first { $0.type == PrayerType.asr })
        XCTAssertNotNil(prayers.first { $0.type == PrayerType.maghrib })
        XCTAssertNotNil(prayers.first { $0.type == PrayerType.isha })
    }

    func testISNACalculationForLondon() {
        // London coordinates
        let location = Coordinates(latitude: 51.5074, longitude: -0.1278)

        let prayers = sut.calculatePrayerTimes(
            for: createDate(year: 2026, month: 2, day: 4),
            location: location,
            method: .isna
        )

        XCTAssertNotNil(prayers)
        XCTAssertEqual(prayers.count, 6)
    }

    // MARK: - MWL Calculation Method Tests

    func testMWLCalculation() {
        let location = Coordinates(latitude: 21.4225, longitude: 39.8262) // Makkah

        let prayers = sut.calculatePrayerTimes(
            for: createDate(year: 2026, month: 2, day: 4),
            location: location,
            method: .muslimWorldLeague
        )

        XCTAssertNotNil(prayers)
        XCTAssertEqual(prayers.count, 6)
    }

    // MARK: - Egyptian Calculation Method Tests

    func testEgyptCalculation() {
        let location = Coordinates(latitude: 30.0444, longitude: 31.2357) // Cairo

        let prayers = sut.calculatePrayerTimes(
            for: createDate(year: 2026, month: 2, day: 4),
            location: location,
            method: .egypt
        )

        XCTAssertNotNil(prayers)
        XCTAssertEqual(prayers.count, 6)
    }

    // MARK: - Makkah Calculation Method Tests

    func testMakkahCalculation() {
        let location = Coordinates(latitude: 21.4225, longitude: 39.8262)

        let prayers = sut.calculatePrayerTimes(
            for: createDate(year: 2026, month: 2, day: 4),
            location: location,
            method: .makkah
        )

        XCTAssertNotNil(prayers)
        XCTAssertEqual(prayers.count, 6)
    }

    // MARK: - Karachi Calculation Method Tests

    func testKarachiCalculation() {
        let location = Coordinates(latitude: 24.8607, longitude: 67.0011) // Karachi

        let prayers = sut.calculatePrayerTimes(
            for: createDate(year: 2026, month: 2, day: 4),
            location: location,
            method: .karachi
        )

        XCTAssertNotNil(prayers)
        XCTAssertEqual(prayers.count, 6)
    }

    // MARK: - Prayer Time Ordering Tests

    func testPrayerTimesAreInOrder() {
        let location = Coordinates(latitude: 40.7128, longitude: -74.0060)

        let prayers = sut.calculatePrayerTimes(
            for: createDate(year: 2026, month: 6, day: 15), // Summer day
            location: location,
            method: .isna
        )

        let fajr = prayers.first { $0.type == PrayerType.fajr }!.time
        let sunrise = prayers.first { $0.type == PrayerType.sunrise }!.time
        let dhuhr = prayers.first { $0.type == PrayerType.dhuhr }!.time
        let asr = prayers.first { $0.type == PrayerType.asr }!.time
        let maghrib = prayers.first { $0.type == PrayerType.maghrib }!.time
        let isha = prayers.first { $0.type == PrayerType.isha }!.time

        XCTAssertTrue(fajr < sunrise, "Fajr should be before Sunrise")
        XCTAssertTrue(sunrise < dhuhr, "Sunrise should be before Dhuhr")
        XCTAssertTrue(dhuhr < asr, "Dhuhr should be before Asr")
        XCTAssertTrue(asr < maghrib, "Asr should be before Maghrib")
        XCTAssertTrue(maghrib < isha, "Maghrib should be before Isha")
    }

    // MARK: - Edge Cases

    func testCalculationForHighLatitude() {
        // Oslo, Norway - high latitude
        let location = Coordinates(latitude: 59.9139, longitude: 10.7522)

        let prayers = sut.calculatePrayerTimes(
            for: createDate(year: 2026, month: 6, day: 21), // Summer solstice
            location: location,
            method: .isna
        )

        // Should still return 6 prayer times even at high latitudes
        XCTAssertEqual(prayers.count, 6)
    }

    func testCalculationForSouthernHemisphere() {
        // Sydney, Australia
        let location = Coordinates(latitude: -33.8688, longitude: 151.2093)

        let prayers = sut.calculatePrayerTimes(
            for: createDate(year: 2026, month: 2, day: 4),
            location: location,
            method: .isna
        )

        XCTAssertNotNil(prayers)
        XCTAssertEqual(prayers.count, 6)
    }

    // MARK: - Helper Methods

    private func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
}

// MARK: - Qibla Calculation Tests

final class QiblaCalculationTests: XCTestCase {

    var sut: PrayerTimeCalculator!

    override func setUp() {
        super.setUp()
        sut = PrayerTimeCalculator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Qibla Direction Tests

    func testQiblaDirectionFromNewYork() {
        // New York coordinates
        let location = Coordinates(latitude: 40.7128, longitude: -74.0060)
        let qiblaDirection = sut.calculateQiblaDirection(from: location)

        // Qibla from New York should be approximately 58-59 degrees (ENE)
        XCTAssertGreaterThan(qiblaDirection, 55)
        XCTAssertLessThan(qiblaDirection, 65)
    }

    func testQiblaDirectionFromLondon() {
        // London coordinates
        let location = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let qiblaDirection = sut.calculateQiblaDirection(from: location)

        // Qibla from London should be approximately 119 degrees (ESE)
        XCTAssertGreaterThan(qiblaDirection, 115)
        XCTAssertLessThan(qiblaDirection, 125)
    }

    func testQiblaDirectionFromTokyo() {
        // Tokyo coordinates
        let location = Coordinates(latitude: 35.6762, longitude: 139.6503)
        let qiblaDirection = sut.calculateQiblaDirection(from: location)

        // Qibla from Tokyo should be approximately 293 degrees (WNW)
        XCTAssertGreaterThan(qiblaDirection, 288)
        XCTAssertLessThan(qiblaDirection, 298)
    }

    func testQiblaDirectionFromSydney() {
        // Sydney coordinates
        let location = Coordinates(latitude: -33.8688, longitude: 151.2093)
        let qiblaDirection = sut.calculateQiblaDirection(from: location)

        // Qibla from Sydney should be approximately 277 degrees (W)
        XCTAssertGreaterThan(qiblaDirection, 273)
        XCTAssertLessThan(qiblaDirection, 283)
    }

    func testQiblaDirectionFromMakkah() {
        // Makkah coordinates (should be 0 or undefined)
        let location = Coordinates(latitude: 21.4225, longitude: 39.8262)
        let qiblaDirection = sut.calculateQiblaDirection(from: location)

        // From Makkah itself, direction is essentially 0
        XCTAssertGreaterThanOrEqual(qiblaDirection, 0)
        XCTAssertLessThanOrEqual(qiblaDirection, 360)
    }

    // MARK: - Direction Range Tests

    func testQiblaDirectionIsWithinValidRange() {
        let testLocations: [Coordinates] = [
            Coordinates(latitude: 40.7128, longitude: -74.0060),   // New York
            Coordinates(latitude: 51.5074, longitude: -0.1278),    // London
            Coordinates(latitude: 35.6762, longitude: 139.6503),   // Tokyo
            Coordinates(latitude: -33.8688, longitude: 151.2093),  // Sydney
            Coordinates(latitude: 55.7558, longitude: 37.6173),    // Moscow
            Coordinates(latitude: 19.4326, longitude: -99.1332),   // Mexico City
            Coordinates(latitude: 1.3521, longitude: 103.8198)     // Singapore
        ]

        for location in testLocations {
            let direction = sut.calculateQiblaDirection(from: location)

            XCTAssertGreaterThanOrEqual(direction, 0, "Direction should be >= 0 for (\(location.latitude), \(location.longitude))")
            XCTAssertLessThanOrEqual(direction, 360, "Direction should be <= 360 for (\(location.latitude), \(location.longitude))")
        }
    }
}

// MARK: - Calculation Method Tests

final class CalculationMethodTests: XCTestCase {

    func testAllMethodsExist() {
        let methods = CalculationMethod.allCases

        XCTAssertTrue(methods.contains(.isna))
        XCTAssertTrue(methods.contains(.muslimWorldLeague))
        XCTAssertTrue(methods.contains(.egypt))
        XCTAssertTrue(methods.contains(.makkah))
        XCTAssertTrue(methods.contains(.karachi))
    }

    func testMethodDisplayNames() {
        XCTAssertFalse(CalculationMethod.isna.displayName.isEmpty)
        XCTAssertFalse(CalculationMethod.muslimWorldLeague.displayName.isEmpty)
        XCTAssertFalse(CalculationMethod.egypt.displayName.isEmpty)
        XCTAssertFalse(CalculationMethod.makkah.displayName.isEmpty)
        XCTAssertFalse(CalculationMethod.karachi.displayName.isEmpty)
    }

    func testMethodDescriptions() {
        // All methods should have non-empty descriptions
        for method in CalculationMethod.allCases {
            XCTAssertFalse(method.methodDescription.isEmpty,
                           "\(method) should have a description")
        }

        // Spot-check content
        XCTAssertTrue(CalculationMethod.isna.methodDescription.contains("United States"))
        XCTAssertTrue(CalculationMethod.muslimWorldLeague.methodDescription.contains("Europe"))
    }
}

// MARK: - Madhab Tests

final class MadhabTests: XCTestCase {

    func testAllMadhabsExist() {
        let madhabs = Madhab.allCases

        XCTAssertTrue(madhabs.contains(.hanafi))
        XCTAssertTrue(madhabs.contains(.shafi))
    }

    func testMadhabDisplayNames() {
        XCTAssertFalse(Madhab.hanafi.displayName.isEmpty)
        XCTAssertFalse(Madhab.shafi.displayName.isEmpty)
    }

    func testMadhabShadowRatio() {
        // Hanafi uses shadow ratio of 2 for Asr
        XCTAssertEqual(Madhab.hanafi.shadowRatio, 2.0)

        // Shafi uses shadow ratio of 1 for Asr
        XCTAssertEqual(Madhab.shafi.shadowRatio, 1.0)
    }
}
