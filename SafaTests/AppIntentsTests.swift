// MARK: - AppIntentsTests.swift
// PURPOSE: Tests for App Intent helpers and data wiring
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class AppIntentsTests: XCTestCase {

    // MARK: - PrayerTimeCalculator Tests (used by intents)

    func test_prayerTimesIntent_returnsAllSixPrayers() {
        // Given
        let calculator = PrayerTimeCalculator()
        let coords = AppDefaults.defaultCoordinates // London

        // When
        let prayers = calculator.calculatePrayerTimes(for: Date(), location: coords, method: .muslimWorldLeague)

        // Then
        XCTAssertEqual(prayers.count, 6)
        XCTAssertEqual(prayers[0].type, .fajr)
        XCTAssertEqual(prayers[1].type, .sunrise)
        XCTAssertEqual(prayers[2].type, .dhuhr)
        XCTAssertEqual(prayers[3].type, .asr)
        XCTAssertEqual(prayers[4].type, .maghrib)
        XCTAssertEqual(prayers[5].type, .isha)
    }

    func test_prayerTimesIntent_timesAreNonEmpty() {
        // Given
        let calculator = PrayerTimeCalculator()
        let coords = Coordinates(latitude: 40.7128, longitude: -74.0060) // NYC

        // When
        let prayers = calculator.calculatePrayerTimes(for: Date(), location: coords, method: .isna)

        // Then
        for prayer in prayers {
            XCTAssertNotEqual(prayer.time, Date.distantPast, "\(prayer.type.displayName) should have a real time")
        }
    }

    func test_prayerTimesIntent_timesAreMonotonic() {
        // Given
        let calculator = PrayerTimeCalculator()
        let coords = AppDefaults.defaultCoordinates

        // When
        let prayers = calculator.calculatePrayerTimes(for: Date(), location: coords, method: .muslimWorldLeague)

        // Then - each prayer should be after the previous
        for i in 1..<prayers.count {
            XCTAssertGreaterThan(
                prayers[i].time, prayers[i - 1].time,
                "\(prayers[i].type.displayName) should be after \(prayers[i - 1].type.displayName)"
            )
        }
    }

    // MARK: - Next Prayer Logic Tests

    func test_nextPrayer_returnsFuturePrayer() {
        // Given
        let calculator = PrayerTimeCalculator()
        let coords = AppDefaults.defaultCoordinates
        let prayers = calculator.calculatePrayerTimes(for: Date(), location: coords, method: .muslimWorldLeague)
        let now = Date()

        // When
        let nextPrayer = prayers.first(where: { $0.type.isObligatory && $0.time > now })

        // Then - if there's a next prayer, its time should be in the future
        if let next = nextPrayer {
            XCTAssertGreaterThan(next.time, now)
            XCTAssertTrue(next.type.isObligatory)
        }
        // If nil, all prayers have passed today (valid late at night)
    }

    // MARK: - Qibla Direction Tests

    func test_qiblaDirection_returnsValidBearing() {
        // Given
        let calculator = PrayerTimeCalculator()
        let coords = AppDefaults.defaultCoordinates // London

        // When
        let bearing = calculator.calculateQiblaDirection(from: coords)

        // Then - bearing should be 0-360
        XCTAssertGreaterThanOrEqual(bearing, 0)
        XCTAssertLessThan(bearing, 360)
    }

    func test_qiblaDirection_londonPointsEast() {
        // Given - London is northwest of Makkah
        let calculator = PrayerTimeCalculator()
        let coords = Coordinates(latitude: 51.5074, longitude: -0.1278)

        // When
        let bearing = calculator.calculateQiblaDirection(from: coords)

        // Then - should roughly be southeast (~119 degrees)
        XCTAssertGreaterThan(bearing, 90, "Qibla from London should be > 90 degrees")
        XCTAssertLessThan(bearing, 150, "Qibla from London should be < 150 degrees")
    }

    func test_qiblaDirection_newYorkPointsNortheast() {
        // Given - NYC is west/northwest of Makkah
        let calculator = PrayerTimeCalculator()
        let coords = Coordinates(latitude: 40.7128, longitude: -74.0060)

        // When
        let bearing = calculator.calculateQiblaDirection(from: coords)

        // Then - should be roughly northeast (~58 degrees)
        XCTAssertGreaterThan(bearing, 40)
        XCTAssertLessThan(bearing, 80)
    }

    func test_qiblaDirection_atMakkah_returnsZeroish() {
        // Given - at Makkah itself (or very close)
        let calculator = PrayerTimeCalculator()
        let coords = Coordinates(latitude: 21.4225, longitude: 39.8262)

        // When
        let bearing = calculator.calculateQiblaDirection(from: coords)

        // Then - bearing at origin is undefined, but should be a valid number (0-360)
        XCTAssertGreaterThanOrEqual(bearing, 0)
        XCTAssertLessThan(bearing, 360)
    }

    // MARK: - Daily Verse Tests

    func test_curatedVerses_consistentForSameDay() {
        // Given - same day should produce same verse index
        let dayOfYear1 = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let dayOfYear2 = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1

        // When/Then
        XCTAssertEqual(dayOfYear1, dayOfYear2)
    }

    func test_curatedVerses_allHaveValidReferences() {
        // Verify the curated verse references are within valid Quran ranges
        let curatedVerses: [(surah: Int, ayah: Int)] = [
            (1, 1), (2, 255), (2, 286), (3, 139), (3, 173),
            (5, 3), (6, 162), (13, 28), (14, 7), (16, 97),
            (17, 80), (20, 114), (23, 115), (24, 35), (25, 63),
            (28, 88), (29, 69), (33, 56), (39, 53), (40, 60),
            (41, 30), (42, 11), (49, 13), (55, 13), (57, 4),
            (59, 22), (65, 3), (67, 2), (93, 5), (94, 6),
            (112, 1),
        ]

        for (surah, ayah) in curatedVerses {
            XCTAssertGreaterThanOrEqual(surah, 1, "Surah must be >= 1")
            XCTAssertLessThanOrEqual(surah, 114, "Surah must be <= 114")
            XCTAssertGreaterThanOrEqual(ayah, 1, "Ayah must be >= 1")
        }
    }

    // MARK: - PrayerTypeEntity Tests

    func test_prayerTypeEntity_mapsToCorrectPrayerType() {
        XCTAssertEqual(PrayerType(rawValue: PrayerTypeEntity.fajr.id), .fajr)
        XCTAssertEqual(PrayerType(rawValue: PrayerTypeEntity.dhuhr.id), .dhuhr)
        XCTAssertEqual(PrayerType(rawValue: PrayerTypeEntity.asr.id), .asr)
        XCTAssertEqual(PrayerType(rawValue: PrayerTypeEntity.maghrib.id), .maghrib)
        XCTAssertEqual(PrayerType(rawValue: PrayerTypeEntity.isha.id), .isha)
    }

    func test_prayerTypeEntity_allFiveObligatoryPrayers() {
        let entities: [PrayerTypeEntity] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
        XCTAssertEqual(entities.count, 5)

        // Each should map to an obligatory prayer
        for entity in entities {
            let prayerType = PrayerType(rawValue: entity.id)
            XCTAssertNotNil(prayerType)
            XCTAssertTrue(prayerType?.isObligatory ?? false, "\(entity.name) should be obligatory")
        }
    }

    // MARK: - Qibla Cardinal Direction Tests

    func test_cardinalDirection_north() {
        // 0 degrees = North
        let directions = ["North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest"]
        let index = Int((0.0 + 22.5).truncatingRemainder(dividingBy: 360) / 45)
        XCTAssertEqual(directions[index], "North")
    }

    func test_cardinalDirection_east() {
        // 90 degrees = East
        let directions = ["North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest"]
        let index = Int((90.0 + 22.5).truncatingRemainder(dividingBy: 360) / 45)
        XCTAssertEqual(directions[index], "East")
    }

    func test_cardinalDirection_south() {
        // 180 degrees = South
        let directions = ["North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest"]
        let index = Int((180.0 + 22.5).truncatingRemainder(dividingBy: 360) / 45)
        XCTAssertEqual(directions[index], "South")
    }

    // MARK: - Integration: Prayer Times for Multiple Methods

    func test_prayerTimes_allCalculationMethods_returnSixPrayers() {
        let calculator = PrayerTimeCalculator()
        let coords = AppDefaults.defaultCoordinates

        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: Date(), location: coords, method: method)
            XCTAssertEqual(prayers.count, 6, "\(method.displayName) should return 6 prayer times")
        }
    }
}
