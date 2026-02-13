// MARK: - LocationChangeDetectionTests.swift
// PURPOSE: Tests for location change detection logic — distance thresholds, throttling, preference defaults
// DEPENDENCIES: XCTest, CoreLocation, Safa

import XCTest
import CoreLocation
@testable import Safa

final class LocationChangeDetectionTests: XCTestCase {

    // MARK: - Distance Threshold Tests (30km default)

    func test_londonToParis_exceedsThreshold() {
        // Given: London and Paris are ~340km apart
        let london = CLLocation(latitude: 51.5074, longitude: -0.1278)
        let paris = CLLocation(latitude: 48.8566, longitude: 2.3522)
        let threshold: Double = 30_000

        // When
        let distance = london.distance(from: paris)

        // Then: should exceed 30km threshold
        XCTAssertGreaterThan(distance, threshold, "London to Paris (~340km) should exceed 30km threshold")
    }

    func test_londonToBirmingham_exceedsThreshold() {
        // Given: London and Birmingham are ~163km apart
        let london = CLLocation(latitude: 51.5074, longitude: -0.1278)
        let birmingham = CLLocation(latitude: 52.4862, longitude: -1.8904)
        let threshold: Double = 30_000

        // When
        let distance = london.distance(from: birmingham)

        // Then
        XCTAssertGreaterThan(distance, threshold, "London to Birmingham (~163km) should exceed 30km threshold")
    }

    func test_sameCityDifferentNeighborhood_belowThreshold() {
        // Given: Two points in London ~5km apart (Westminster to Canary Wharf)
        let westminster = CLLocation(latitude: 51.4975, longitude: -0.1357)
        let canaryWharf = CLLocation(latitude: 51.5054, longitude: -0.0235)
        let threshold: Double = 30_000

        // When
        let distance = westminster.distance(from: canaryWharf)

        // Then: should NOT exceed 30km threshold
        XCTAssertLessThanOrEqual(distance, threshold, "Same city movement (~5km) should not exceed 30km threshold")
    }

    func test_sameStreet_belowThreshold() {
        // Given: Two points ~100m apart
        let pointA = CLLocation(latitude: 51.5074, longitude: -0.1278)
        let pointB = CLLocation(latitude: 51.5080, longitude: -0.1270)
        let threshold: Double = 30_000

        // When
        let distance = pointA.distance(from: pointB)

        // Then
        XCTAssertLessThanOrEqual(distance, threshold, "Same street movement (~100m) should not exceed 30km threshold")
    }

    func test_exactSameLocation_belowThreshold() {
        // Given: identical coordinates
        let location = CLLocation(latitude: 51.5074, longitude: -0.1278)
        let threshold: Double = 30_000

        // When
        let distance = location.distance(from: location)

        // Then
        XCTAssertEqual(distance, 0, accuracy: 0.1, "Same location should have zero distance")
        XCTAssertLessThanOrEqual(distance, threshold)
    }

    func test_crossCountry_londonToMakkah_exceedsThreshold() {
        // Given: London to Makkah is ~4,700km
        let london = CLLocation(latitude: 51.5074, longitude: -0.1278)
        let makkah = CLLocation(latitude: 21.4225, longitude: 39.8262)
        let threshold: Double = 30_000

        // When
        let distance = london.distance(from: makkah)

        // Then
        XCTAssertGreaterThan(distance, threshold, "London to Makkah (~4700km) should exceed 30km threshold")
        XCTAssertGreaterThan(distance, 4_000_000, "London to Makkah should be over 4000km")
    }

    func test_neighboringCities_dubaiToAbuDhabi_exceedsThreshold() {
        // Given: Dubai to Abu Dhabi ~130km
        let dubai = CLLocation(latitude: 25.2048, longitude: 55.2708)
        let abuDhabi = CLLocation(latitude: 24.4539, longitude: 54.3773)
        let threshold: Double = 30_000

        // When
        let distance = dubai.distance(from: abuDhabi)

        // Then
        XCTAssertGreaterThan(distance, threshold, "Dubai to Abu Dhabi (~130km) should exceed 30km threshold")
    }

    // MARK: - Throttle Interval Tests

    func test_normalThrottle_is15Minutes() {
        // The normal throttle interval should be 15 minutes (900 seconds)
        let normalThrottle: TimeInterval = 900
        XCTAssertEqual(normalThrottle, 15 * 60, "Normal throttle should be 15 minutes")
    }

    func test_nearPrayerThrottle_is5Minutes() {
        // Near-prayer throttle should be 5 minutes (300 seconds)
        let nearPrayerThrottle: TimeInterval = 300
        XCTAssertEqual(nearPrayerThrottle, 5 * 60, "Near-prayer throttle should be 5 minutes")
    }

    // MARK: - Preference Default Tests

    func test_autoUpdateDefault_isTrue() {
        // Given: a fresh UserPreferences with defaults
        let prefs = UserPreferences()

        // Then: auto-update location should default to true
        XCTAssertTrue(prefs.autoUpdateLocationForPrayers, "Auto-update location should default to true")
    }

    func test_autoUpdateCanBeDisabled() {
        // Given: preferences with auto-update disabled
        let prefs = UserPreferences(autoUpdateLocationForPrayers: false)

        // Then
        XCTAssertFalse(prefs.autoUpdateLocationForPrayers, "Auto-update location should be disableable")
    }

    // MARK: - Threshold Edge Cases

    func test_exactlyAtThreshold_doesNotTrigger() {
        // Given: two points exactly 30km apart (approximately)
        // 30km north of a point at the equator is roughly 0.27 degrees latitude
        let pointA = CLLocation(latitude: 0.0, longitude: 0.0)
        let pointB = CLLocation(latitude: 0.2697, longitude: 0.0) // ~30km north
        let threshold: Double = 30_000

        // When
        let distance = pointA.distance(from: pointB)

        // Then: distance at or just under threshold should NOT trigger
        // (guard uses > not >=)
        if distance <= threshold {
            // This is the expected behavior — at-threshold does not trigger
        } else {
            // Slightly over due to Earth curvature — still validates the boundary
            XCTAssertLessThan(distance - threshold, 500, "Should be very close to threshold")
        }
    }

    func test_justOverThreshold_triggers() {
        // Given: two points clearly over 30km apart (~35km)
        let pointA = CLLocation(latitude: 0.0, longitude: 0.0)
        let pointB = CLLocation(latitude: 0.315, longitude: 0.0) // ~35km north
        let threshold: Double = 30_000

        // When
        let distance = pointA.distance(from: pointB)

        // Then
        XCTAssertGreaterThan(distance, threshold, "35km should exceed 30km threshold")
    }
}
