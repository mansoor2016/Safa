// MARK: - WidgetPrayerTimeTests.swift
// PURPOSE: Tests for widget prayer time next-prayer logic to prevent regression
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

/// Tests the "next prayer" calculation logic used by the widget.
/// Since widget types aren't directly importable from test target,
/// we test the equivalent algorithm here.
final class WidgetPrayerTimeTests: XCTestCase {

    typealias PrayerEntry = (name: String, time: Date)

    private func nextPrayer(from prayers: [PrayerEntry]) -> PrayerEntry? {
        let now = Date()
        return prayers.first { $0.time > now }
    }

    private func nextPrayerName(from prayers: [PrayerEntry]) -> String {
        nextPrayer(from: prayers)?.name ?? "Isha"
    }

    private func makePrayers(
        fajrOffset: TimeInterval = -7200,
        dhuhrOffset: TimeInterval = -3600,
        asrOffset: TimeInterval = 3600,
        maghribOffset: TimeInterval = 7200,
        ishaOffset: TimeInterval = 10800
    ) -> [PrayerEntry] {
        let now = Date()
        return [
            ("Fajr", now.addingTimeInterval(fajrOffset)),
            ("Dhuhr", now.addingTimeInterval(dhuhrOffset)),
            ("Asr", now.addingTimeInterval(asrOffset)),
            ("Maghrib", now.addingTimeInterval(maghribOffset)),
            ("Isha", now.addingTimeInterval(ishaOffset))
        ]
    }

    // MARK: - Next Prayer Calculation

    func test_nextPrayer_returnsFirstFuturePrayer() {
        let prayers = makePrayers() // Fajr+Dhuhr past, Asr next
        XCTAssertEqual(nextPrayerName(from: prayers), "Asr")
    }

    func test_nextPrayer_returnsFajrWhenAllFuture() {
        let prayers = makePrayers(fajrOffset: 100, dhuhrOffset: 3600)
        XCTAssertEqual(nextPrayerName(from: prayers), "Fajr")
    }

    func test_nextPrayer_defaultsToIshaWhenAllPast() {
        let prayers = makePrayers(
            fajrOffset: -10000, dhuhrOffset: -8000,
            asrOffset: -6000, maghribOffset: -4000, ishaOffset: -2000
        )
        XCTAssertEqual(nextPrayerName(from: prayers), "Isha")
    }

    func test_nextPrayer_skipsPastPrayers() {
        let prayers = makePrayers(
            fajrOffset: -10000, dhuhrOffset: -8000,
            asrOffset: -2000, maghribOffset: 1800, ishaOffset: 5400
        )
        XCTAssertEqual(nextPrayerName(from: prayers), "Maghrib")
    }

    func test_nextPrayer_returnsIshaWhenOnlyIshaFuture() {
        let prayers = makePrayers(
            fajrOffset: -20000, dhuhrOffset: -15000,
            asrOffset: -10000, maghribOffset: -5000, ishaOffset: 1800
        )
        XCTAssertEqual(nextPrayerName(from: prayers), "Isha")
    }

    func test_prayerList_hasFiveEntries() {
        let prayers = makePrayers()
        XCTAssertEqual(prayers.count, 5)
    }

    func test_prayerList_correctOrder() {
        let prayers = makePrayers()
        XCTAssertEqual(prayers.map { $0.name }, ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"])
    }

    func test_prayerList_timesAreChronological() {
        let prayers = makePrayers(
            fajrOffset: -10000, dhuhrOffset: -5000,
            asrOffset: 1000, maghribOffset: 5000, ishaOffset: 10000
        )
        for i in 0..<(prayers.count - 1) {
            XCTAssertLessThan(prayers[i].time, prayers[i + 1].time,
                              "\(prayers[i].name) should be before \(prayers[i + 1].name)")
        }
    }
}
