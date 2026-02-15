// MARK: - PrayerLiveActivityTests.swift
// PURPOSE: Tests for PrayerActivityAttributes and Live Activity behavior
// DEPENDENCIES: XCTest, SafaShared

import XCTest
@testable import Safa
import SafaShared

final class PrayerActivityAttributesCodableTests: XCTestCase {

    // MARK: - ContentState Codable Round-Trip

    func test_contentState_encodesAndDecodesAllFields() throws {
        // Given
        let prayerTime = Date(timeIntervalSince1970: 1_700_000_000)
        let original = PrayerActivityAttributes.ContentState(
            nextPrayerName: "Dhuhr",
            nextPrayerTime: prayerTime,
            hijriDate: "15 Rabi al-Thani 1445",
            locationName: "London, UK"
        )

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PrayerActivityAttributes.ContentState.self, from: data)

        // Then
        XCTAssertEqual(decoded.nextPrayerName, "Dhuhr")
        XCTAssertEqual(decoded.nextPrayerTime.timeIntervalSince1970, prayerTime.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(decoded.hijriDate, "15 Rabi al-Thani 1445")
        XCTAssertEqual(decoded.locationName, "London, UK")
    }

    func test_contentState_hashable_sameValuesAreEqual() {
        // Given
        let time = Date(timeIntervalSince1970: 1_700_000_000)
        let stateA = PrayerActivityAttributes.ContentState(
            nextPrayerName: "Asr",
            nextPrayerTime: time,
            hijriDate: "10 Jumada al-Ula 1445",
            locationName: "Makkah"
        )
        let stateB = PrayerActivityAttributes.ContentState(
            nextPrayerName: "Asr",
            nextPrayerTime: time,
            hijriDate: "10 Jumada al-Ula 1445",
            locationName: "Makkah"
        )

        // Then
        XCTAssertEqual(stateA, stateB)
        XCTAssertEqual(stateA.hashValue, stateB.hashValue)
    }

    func test_contentState_hashable_differentValuesNotEqual() {
        // Given
        let time = Date(timeIntervalSince1970: 1_700_000_000)
        let stateA = PrayerActivityAttributes.ContentState(
            nextPrayerName: "Fajr",
            nextPrayerTime: time,
            hijriDate: "1 Muharram 1446",
            locationName: "Madinah"
        )
        let stateB = PrayerActivityAttributes.ContentState(
            nextPrayerName: "Maghrib",
            nextPrayerTime: time,
            hijriDate: "1 Muharram 1446",
            locationName: "Madinah"
        )

        // Then
        XCTAssertNotEqual(stateA, stateB)
    }

    // MARK: - Attributes

    func test_attributes_preservePrayerType() throws {
        // Given
        let attributes = PrayerActivityAttributes(prayerType: "Fajr")

        // Then
        XCTAssertEqual(attributes.prayerType, "Fajr")
    }

    // MARK: - ContentState with Extreme Dates

    func test_contentState_handlesDistantFutureDate() throws {
        // Given — prayer time far in the future
        let distantTime = Date.distantFuture
        let state = PrayerActivityAttributes.ContentState(
            nextPrayerName: "Isha",
            nextPrayerTime: distantTime,
            hijriDate: "30 Dhul Hijjah 1500",
            locationName: "Jakarta"
        )

        // When
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(PrayerActivityAttributes.ContentState.self, from: data)

        // Then — round-trip preserves distant date
        XCTAssertEqual(decoded.nextPrayerTime, distantTime)
        XCTAssertEqual(decoded.nextPrayerName, "Isha")
    }

    func test_contentState_handlesEmptyStrings() throws {
        // Given — edge case with empty location/hijri
        let state = PrayerActivityAttributes.ContentState(
            nextPrayerName: "",
            nextPrayerTime: Date(),
            hijriDate: "",
            locationName: ""
        )

        // When
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(PrayerActivityAttributes.ContentState.self, from: data)

        // Then
        XCTAssertEqual(decoded.nextPrayerName, "")
        XCTAssertEqual(decoded.hijriDate, "")
        XCTAssertEqual(decoded.locationName, "")
    }

    func test_contentState_usedAsSetElement() {
        // Given — Hashable conformance allows use in Set
        let time = Date()
        let stateA = PrayerActivityAttributes.ContentState(
            nextPrayerName: "Fajr",
            nextPrayerTime: time,
            hijriDate: "1 Muharram",
            locationName: "London"
        )
        let stateB = PrayerActivityAttributes.ContentState(
            nextPrayerName: "Dhuhr",
            nextPrayerTime: time,
            hijriDate: "1 Muharram",
            locationName: "London"
        )
        let duplicate = PrayerActivityAttributes.ContentState(
            nextPrayerName: "Fajr",
            nextPrayerTime: time,
            hijriDate: "1 Muharram",
            locationName: "London"
        )

        // When
        let set: Set<PrayerActivityAttributes.ContentState> = [stateA, stateB, duplicate]

        // Then — duplicate should be deduplicated
        XCTAssertEqual(set.count, 2)
    }
}

// MARK: - Manager State Tests

final class PrayerLiveActivityManagerTests: XCTestCase {

    @MainActor
    func test_endAllActivities_clearsCurrentActivity() async {
        // Given — no current activity (fresh state)
        let manager = PrayerLiveActivityManager.shared

        // When — ending all is safe even with no activities
        await manager.endAllActivities()

        // Then — endActivity is also safe with no current activity
        await manager.endActivity()
        // No crash = success
    }
}

// MARK: - Staleness Tests

final class PrayerLiveActivityStalenessTests: XCTestCase {

    func test_staleDateIsAfterPrayerTime() {
        // Given — a prayer time in the near future
        let prayerTime = Date().addingTimeInterval(3600)

        // When
        let staleDate = LiveActivityStaleness.staleDate(for: prayerTime)

        // Then — staleDate must be strictly after the prayer time
        XCTAssertGreaterThan(staleDate, prayerTime)
    }

    func test_staleDateBufferIs90Seconds() {
        // Given — a specific prayer time
        let prayerTime = Date(timeIntervalSince1970: 1_700_000_000)

        // When
        let staleDate = LiveActivityStaleness.staleDate(for: prayerTime)

        // Then — the buffer between prayerTime and staleDate is exactly 90 seconds
        let buffer = staleDate.timeIntervalSince(prayerTime)
        XCTAssertEqual(buffer, 90, accuracy: 0.001)
    }

    func test_staleDateForDistantFuturePrayer() {
        // Given — a prayer time far in the future
        let distantPrayerTime = Date.distantFuture

        // When
        let staleDate = LiveActivityStaleness.staleDate(for: distantPrayerTime)

        // Then — staleDate is still after the prayer time
        XCTAssertGreaterThan(staleDate, distantPrayerTime)
    }

    func test_staleDateUsesBufferNotRawPrayerTime() {
        // Given — a prayer time
        let prayerTime = Date().addingTimeInterval(3600)

        // When — computing the stale date
        let staleDate = LiveActivityStaleness.staleDate(for: prayerTime)

        // Then — staleDate is after prayerTime (not equal)
        XCTAssertGreaterThan(staleDate, prayerTime)

        // And — the buffer matches the declared constant
        let expectedBuffer = LiveActivityStaleness.buffer
        XCTAssertEqual(staleDate.timeIntervalSince(prayerTime), expectedBuffer, accuracy: 0.001)
    }
}
