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
        let latitude = 40.7128
        let longitude = -74.0060

        let prayers = sut.calculatePrayerTimes(
            date: createDate(year: 2026, month: 2, day: 4),
            latitude: latitude,
            longitude: longitude,
            method: .isna
        )

        XCTAssertNotNil(prayers)
        XCTAssertEqual(prayers.count, 5)

        // Verify all prayer times are present
        XCTAssertNotNil(prayers.first { $0.type == .fajr })
        XCTAssertNotNil(prayers.first { $0.type == .dhuhr })
        XCTAssertNotNil(prayers.first { $0.type == .asr })
        XCTAssertNotNil(prayers.first { $0.type == .maghrib })
        XCTAssertNotNil(prayers.first { $0.type == .isha })
    }

    func testISNACalculationForLondon() {
        // London coordinates
        let latitude = 51.5074
        let longitude = -0.1278

        let prayers = sut.calculatePrayerTimes(
            date: createDate(year: 2026, month: 2, day: 4),
            latitude: latitude,
            longitude: longitude,
            method: .isna
        )

        XCTAssertNotNil(prayers)
        XCTAssertEqual(prayers.count, 5)
    }

    // MARK: - MWL Calculation Method Tests

    func testMWLCalculation() {
        let prayers = sut.calculatePrayerTimes(
            date: createDate(year: 2026, month: 2, day: 4),
            latitude: 21.4225,
            longitude: 39.8262, // Makkah
            method: .mwl
        )

        XCTAssertNotNil(prayers)
        XCTAssertEqual(prayers.count, 5)
    }

    // MARK: - Egyptian Calculation Method Tests

    func testEgyptCalculation() {
        let prayers = sut.calculatePrayerTimes(
            date: createDate(year: 2026, month: 2, day: 4),
            latitude: 30.0444, // Cairo
            longitude: 31.2357,
            method: .egypt
        )

        XCTAssertNotNil(prayers)
        XCTAssertEqual(prayers.count, 5)
    }

    // MARK: - Makkah Calculation Method Tests

    func testMakkahCalculation() {
        let prayers = sut.calculatePrayerTimes(
            date: createDate(year: 2026, month: 2, day: 4),
            latitude: 21.4225,
            longitude: 39.8262,
            method: .makkah
        )

        XCTAssertNotNil(prayers)
        XCTAssertEqual(prayers.count, 5)
    }

    // MARK: - Karachi Calculation Method Tests

    func testKarachiCalculation() {
        let prayers = sut.calculatePrayerTimes(
            date: createDate(year: 2026, month: 2, day: 4),
            latitude: 24.8607, // Karachi
            longitude: 67.0011,
            method: .karachi
        )

        XCTAssertNotNil(prayers)
        XCTAssertEqual(prayers.count, 5)
    }

    // MARK: - Prayer Time Ordering Tests

    func testPrayerTimesAreInOrder() {
        let prayers = sut.calculatePrayerTimes(
            date: createDate(year: 2026, month: 6, day: 15), // Summer day
            latitude: 40.7128,
            longitude: -74.0060,
            method: .isna
        )

        let fajr = prayers.first { $0.type == .fajr }!.time
        let dhuhr = prayers.first { $0.type == .dhuhr }!.time
        let asr = prayers.first { $0.type == .asr }!.time
        let maghrib = prayers.first { $0.type == .maghrib }!.time
        let isha = prayers.first { $0.type == .isha }!.time

        XCTAssertTrue(fajr < dhuhr, "Fajr should be before Dhuhr")
        XCTAssertTrue(dhuhr < asr, "Dhuhr should be before Asr")
        XCTAssertTrue(asr < maghrib, "Asr should be before Maghrib")
        XCTAssertTrue(maghrib < isha, "Maghrib should be before Isha")
    }

    // MARK: - Edge Cases

    func testCalculationForHighLatitude() {
        // Oslo, Norway - high latitude
        let prayers = sut.calculatePrayerTimes(
            date: createDate(year: 2026, month: 6, day: 21), // Summer solstice
            latitude: 59.9139,
            longitude: 10.7522,
            method: .isna
        )

        // Should still return 5 prayer times even at high latitudes
        XCTAssertEqual(prayers.count, 5)
    }

    func testCalculationForSouthernHemisphere() {
        // Sydney, Australia
        let prayers = sut.calculatePrayerTimes(
            date: createDate(year: 2026, month: 2, day: 4),
            latitude: -33.8688,
            longitude: 151.2093,
            method: .isna
        )

        XCTAssertNotNil(prayers)
        XCTAssertEqual(prayers.count, 5)
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
        let latitude = 40.7128
        let longitude = -74.0060

        let qiblaDirection = sut.calculateQiblaDirection(
            latitude: latitude,
            longitude: longitude
        )

        // Qibla from New York should be approximately 58-59 degrees (ENE)
        XCTAssertGreaterThan(qiblaDirection, 55)
        XCTAssertLessThan(qiblaDirection, 65)
    }

    func testQiblaDirectionFromLondon() {
        // London coordinates
        let latitude = 51.5074
        let longitude = -0.1278

        let qiblaDirection = sut.calculateQiblaDirection(
            latitude: latitude,
            longitude: longitude
        )

        // Qibla from London should be approximately 119 degrees (ESE)
        XCTAssertGreaterThan(qiblaDirection, 115)
        XCTAssertLessThan(qiblaDirection, 125)
    }

    func testQiblaDirectionFromTokyo() {
        // Tokyo coordinates
        let latitude = 35.6762
        let longitude = 139.6503

        let qiblaDirection = sut.calculateQiblaDirection(
            latitude: latitude,
            longitude: longitude
        )

        // Qibla from Tokyo should be approximately 293 degrees (WNW)
        XCTAssertGreaterThan(qiblaDirection, 288)
        XCTAssertLessThan(qiblaDirection, 298)
    }

    func testQiblaDirectionFromSydney() {
        // Sydney coordinates
        let latitude = -33.8688
        let longitude = 151.2093

        let qiblaDirection = sut.calculateQiblaDirection(
            latitude: latitude,
            longitude: longitude
        )

        // Qibla from Sydney should be approximately 277 degrees (W)
        XCTAssertGreaterThan(qiblaDirection, 273)
        XCTAssertLessThan(qiblaDirection, 283)
    }

    func testQiblaDirectionFromMakkah() {
        // Makkah coordinates (should be 0 or undefined)
        let latitude = 21.4225
        let longitude = 39.8262

        let qiblaDirection = sut.calculateQiblaDirection(
            latitude: latitude,
            longitude: longitude
        )

        // From Makkah itself, direction is essentially 0
        XCTAssertGreaterThanOrEqual(qiblaDirection, 0)
        XCTAssertLessThanOrEqual(qiblaDirection, 360)
    }

    // MARK: - Direction Range Tests

    func testQiblaDirectionIsWithinValidRange() {
        let testLocations: [(Double, Double)] = [
            (40.7128, -74.0060),   // New York
            (51.5074, -0.1278),    // London
            (35.6762, 139.6503),   // Tokyo
            (-33.8688, 151.2093),  // Sydney
            (55.7558, 37.6173),    // Moscow
            (19.4326, -99.1332),   // Mexico City
            (1.3521, 103.8198)     // Singapore
        ]

        for (lat, lon) in testLocations {
            let direction = sut.calculateQiblaDirection(latitude: lat, longitude: lon)

            XCTAssertGreaterThanOrEqual(direction, 0, "Direction should be >= 0 for (\(lat), \(lon))")
            XCTAssertLessThanOrEqual(direction, 360, "Direction should be <= 360 for (\(lat), \(lon))")
        }
    }
}

// MARK: - Calculation Method Tests

final class CalculationMethodTests: XCTestCase {

    func testAllMethodsExist() {
        let methods = CalculationMethod.allCases

        XCTAssertTrue(methods.contains(.isna))
        XCTAssertTrue(methods.contains(.mwl))
        XCTAssertTrue(methods.contains(.egypt))
        XCTAssertTrue(methods.contains(.makkah))
        XCTAssertTrue(methods.contains(.karachi))
    }

    func testMethodDisplayNames() {
        XCTAssertFalse(CalculationMethod.isna.displayName.isEmpty)
        XCTAssertFalse(CalculationMethod.mwl.displayName.isEmpty)
        XCTAssertFalse(CalculationMethod.egypt.displayName.isEmpty)
        XCTAssertFalse(CalculationMethod.makkah.displayName.isEmpty)
        XCTAssertFalse(CalculationMethod.karachi.displayName.isEmpty)
    }

    func testMethodFajrAngles() {
        // ISNA uses 15 degrees for Fajr
        XCTAssertEqual(CalculationMethod.isna.fajrAngle, 15.0)

        // MWL uses 18 degrees for Fajr
        XCTAssertEqual(CalculationMethod.mwl.fajrAngle, 18.0)
    }

    func testMethodIshaAngles() {
        // ISNA uses 15 degrees for Isha
        XCTAssertEqual(CalculationMethod.isna.ishaAngle, 15.0)

        // MWL uses 17 degrees for Isha
        XCTAssertEqual(CalculationMethod.mwl.ishaAngle, 17.0)
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

    func testMadhabAsrShadowFactor() {
        // Hanafi uses shadow factor of 2 for Asr
        XCTAssertEqual(Madhab.hanafi.asrShadowFactor, 2)

        // Shafi uses shadow factor of 1 for Asr
        XCTAssertEqual(Madhab.shafi.asrShadowFactor, 1)
    }
}
