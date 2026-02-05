// MARK: - WidgetTests.swift
// PURPOSE: Unit tests for widget functionality
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class WidgetDataProviderTests: XCTestCase {

    var sut: WidgetDataProvider!

    override func setUp() {
        super.setUp()
        sut = WidgetDataProvider()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Prayer Data Tests

    func testGetPrayerWidgetDataReturnsData() async {
        let data = await sut.getPrayerWidgetData()

        XCTAssertNotNil(data)
    }

    func testPrayerWidgetDataContainsPrayerInfo() async {
        let data = await sut.getPrayerWidgetData()

        XCTAssertNotNil(data.nextPrayer)
        XCTAssertNotNil(data.nextPrayerTime)
    }

    // MARK: - Streak Data Tests

    func testGetStreakWidgetDataReturnsData() async {
        let data = await sut.getStreakWidgetData()

        XCTAssertNotNil(data)
        XCTAssertGreaterThanOrEqual(data.currentStreak, 0)
    }

    // MARK: - Verse Data Tests

    func testGetVerseWidgetDataReturnsVerse() async {
        let data = await sut.getVerseWidgetData()

        XCTAssertNotNil(data)
        XCTAssertFalse(data.arabicText.isEmpty)
    }

    func testVerseHasTranslation() async {
        let data = await sut.getVerseWidgetData()

        XCTAssertFalse(data.translation.isEmpty)
    }

    func testVerseHasReference() async {
        let data = await sut.getVerseWidgetData()

        XCTAssertFalse(data.reference.isEmpty)
    }

    // MARK: - Dashboard Data Tests

    func testGetDashboardWidgetDataReturnsComprehensiveData() async {
        let data = await sut.getDashboardWidgetData()

        XCTAssertNotNil(data.prayerData)
        XCTAssertNotNil(data.streakData)
        XCTAssertNotNil(data.hasanatCount)
    }
}

// MARK: - Widget Entry Tests

final class PrayerWidgetEntryTests: XCTestCase {

    func testEntryCreation() {
        let entry = PrayerWidgetEntry(
            date: Date(),
            nextPrayer: "Fajr",
            nextPrayerTime: Date(),
            remainingTime: "1h 30m"
        )

        XCTAssertEqual(entry.nextPrayer, "Fajr")
        XCTAssertEqual(entry.remainingTime, "1h 30m")
    }

    func testPlaceholderEntry() {
        let entry = PrayerWidgetEntry.placeholder

        XCTAssertFalse(entry.nextPrayer.isEmpty)
        XCTAssertFalse(entry.remainingTime.isEmpty)
    }
}

final class StreakWidgetEntryTests: XCTestCase {

    func testEntryCreation() {
        let entry = StreakWidgetEntry(
            date: Date(),
            streakType: "Prayer",
            currentStreak: 7,
            isActive: true
        )

        XCTAssertEqual(entry.streakType, "Prayer")
        XCTAssertEqual(entry.currentStreak, 7)
        XCTAssertTrue(entry.isActive)
    }

    func testPlaceholderEntry() {
        let entry = StreakWidgetEntry.placeholder

        XCTAssertGreaterThanOrEqual(entry.currentStreak, 0)
    }
}

final class VerseWidgetEntryTests: XCTestCase {

    func testEntryCreation() {
        let entry = VerseWidgetEntry(
            date: Date(),
            arabicText: "بِسْمِ اللَّهِ",
            translation: "In the name of Allah",
            reference: "Al-Fatiha:1"
        )

        XCTAssertEqual(entry.arabicText, "بِسْمِ اللَّهِ")
        XCTAssertEqual(entry.reference, "Al-Fatiha:1")
    }

    func testPlaceholderEntry() {
        let entry = VerseWidgetEntry.placeholder

        XCTAssertFalse(entry.arabicText.isEmpty)
        XCTAssertFalse(entry.translation.isEmpty)
    }
}

// MARK: - Live Activity Tests

final class PrayerActivityAttributesTests: XCTestCase {

    func testAttributesCreation() {
        let attributes = PrayerActivityAttributes(prayerName: "Fajr")

        XCTAssertEqual(attributes.prayerName, "Fajr")
    }

    func testContentStateCreation() {
        let state = PrayerActivityAttributes.ContentState(
            prayerTime: Date(),
            remainingMinutes: 30
        )

        XCTAssertEqual(state.remainingMinutes, 30)
    }

    func testFormattedRemainingTime() {
        let state = PrayerActivityAttributes.ContentState(
            prayerTime: Date(),
            remainingMinutes: 90
        )

        // 90 minutes = 1h 30m
        XCTAssertTrue(state.formattedRemainingTime.contains("1") || state.formattedRemainingTime.contains("30"))
    }
}
