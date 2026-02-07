// MARK: - AnalyticsServiceTests.swift
// PURPOSE: Unit tests for analytics service
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class AnalyticsServiceTests: XCTestCase {

    var sut: AnalyticsService!

    override func setUp() {
        super.setUp()
        sut = AnalyticsService.shared
        sut.clear()
    }

    func test_track_addsEvent() {
        sut.track(.prayerLogged(prayer: "fajr"))
        XCTAssertEqual(sut.getEvents().count, 1)
    }

    func test_track_preservesEventData() {
        sut.track(.prayerLogged(prayer: "dhuhr"))
        let event = sut.getEvents().first
        XCTAssertEqual(event?.name, "prayer_logged")
        XCTAssertEqual(event?.flow, "prayer")
        XCTAssertEqual(event?.context["prayer"], "dhuhr")
    }

    func test_clear_removesAll() {
        sut.track(.prayerLogged(prayer: "fajr"))
        sut.track(.quranResumed(surah: 2, ayah: 255))
        sut.clear()
        XCTAssertTrue(sut.getEvents().isEmpty)
    }

    func test_count_filtersbyFlow() {
        sut.track(.prayerLogged(prayer: "fajr"))
        sut.track(.prayerLogged(prayer: "dhuhr"))
        sut.track(.quranResumed(surah: 1, ayah: 1))
        XCTAssertEqual(sut.count(flow: "prayer"), 2)
        XCTAssertEqual(sut.count(flow: "quran"), 1)
    }

    func test_failureRate_calculatesCorrectly() {
        sut.track(.prayerLogged(prayer: "fajr"))
        sut.track(.notificationFailed(prayer: "dhuhr"))
        sut.track(.prayerLogged(prayer: "asr"))
        // 1 failure out of 1 notification event = 100%
        XCTAssertEqual(sut.failureRate(flow: "notification"), 1.0)
        // 0 failures out of 2 prayer events = 0%
        XCTAssertEqual(sut.failureRate(flow: "prayer"), 0.0)
    }

    func test_failureRate_includesFallbacks() {
        sut.track(.locationFallback(location: "London"))
        sut.track(AnalyticsEvent(name: "location_ok", flow: "location"))
        // 1 fallback out of 2 = 50%
        XCTAssertEqual(sut.failureRate(flow: "location"), 0.5)
    }

    func test_failureRate_zeroForEmptyFlow() {
        XCTAssertEqual(sut.failureRate(flow: "nonexistent"), 0.0)
    }

    func test_standardEvents_haveCorrectFlows() {
        XCTAssertEqual(AnalyticsEvent.prayerLogged(prayer: "fajr").flow, "prayer")
        XCTAssertEqual(AnalyticsEvent.quranResumed(surah: 1, ayah: 1).flow, "quran")
        XCTAssertEqual(AnalyticsEvent.dhikrCompleted(phrase: "SubhanAllah", count: 33).flow, "dhikr")
        XCTAssertEqual(AnalyticsEvent.onboardingCompleted(durationMs: 5000).flow, "onboarding")
        XCTAssertEqual(AnalyticsEvent.locationFallback(location: "London").flow, "location")
        XCTAssertEqual(AnalyticsEvent.notificationFailed(prayer: "fajr").flow, "notification")
        XCTAssertEqual(AnalyticsEvent.syncFallback(reason: "offline").flow, "sync")
    }

    func test_bufferLimitsSize() {
        for i in 0..<150 {
            sut.track(AnalyticsEvent(name: "event_\(i)", flow: "test"))
        }
        XCTAssertLessThanOrEqual(sut.getEvents().count, 100)
    }
}
