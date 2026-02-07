// MARK: - NextPrayerCalculatorTests.swift
// PURPOSE: Comprehensive tests for the shared next-prayer calculation logic

import XCTest
@testable import SafaShared

final class NextPrayerCalculatorTests: XCTestCase {

    let calculator = NextPrayerCalculator()

    private func makePrayers(
        fajrOffset: TimeInterval = -7200,
        dhuhrOffset: TimeInterval = -3600,
        asrOffset: TimeInterval = 3600,
        maghribOffset: TimeInterval = 7200,
        ishaOffset: TimeInterval = 10800,
        relativeTo now: Date = Date()
    ) -> [PrayerInfo] {
        [
            PrayerInfo(name: "Fajr", time: now.addingTimeInterval(fajrOffset)),
            PrayerInfo(name: "Dhuhr", time: now.addingTimeInterval(dhuhrOffset)),
            PrayerInfo(name: "Asr", time: now.addingTimeInterval(asrOffset)),
            PrayerInfo(name: "Maghrib", time: now.addingTimeInterval(maghribOffset)),
            PrayerInfo(name: "Isha", time: now.addingTimeInterval(ishaOffset))
        ]
    }

    // MARK: - nextPrayer()

    func test_nextPrayer_returnsFirstFuturePrayer() {
        let now = Date()
        let prayers = makePrayers(relativeTo: now)
        let result = calculator.nextPrayer(from: prayers, at: now)
        XCTAssertEqual(result?.name, "Asr")
    }

    func test_nextPrayer_returnsFajrWhenAllFuture() {
        let now = Date()
        let prayers = makePrayers(fajrOffset: 100, dhuhrOffset: 3600, relativeTo: now)
        let result = calculator.nextPrayer(from: prayers, at: now)
        XCTAssertEqual(result?.name, "Fajr")
    }

    func test_nextPrayer_returnsNilWhenAllPast() {
        let now = Date()
        let prayers = makePrayers(
            fajrOffset: -10000, dhuhrOffset: -8000,
            asrOffset: -6000, maghribOffset: -4000, ishaOffset: -2000,
            relativeTo: now
        )
        let result = calculator.nextPrayer(from: prayers, at: now)
        XCTAssertNil(result)
    }

    func test_nextPrayer_skipsPastPrayers() {
        let now = Date()
        let prayers = makePrayers(
            fajrOffset: -10000, dhuhrOffset: -8000,
            asrOffset: -2000, maghribOffset: 1800, ishaOffset: 5400,
            relativeTo: now
        )
        let result = calculator.nextPrayer(from: prayers, at: now)
        XCTAssertEqual(result?.name, "Maghrib")
    }

    func test_nextPrayer_returnsIshaWhenOnlyIshaFuture() {
        let now = Date()
        let prayers = makePrayers(
            fajrOffset: -20000, dhuhrOffset: -15000,
            asrOffset: -10000, maghribOffset: -5000, ishaOffset: 1800,
            relativeTo: now
        )
        let result = calculator.nextPrayer(from: prayers, at: now)
        XCTAssertEqual(result?.name, "Isha")
    }

    func test_nextPrayer_emptyList_returnsNil() {
        let result = calculator.nextPrayer(from: [])
        XCTAssertNil(result)
    }

    func test_nextPrayer_exactlyNow_notIncluded() {
        // Prayer time exactly at now should NOT be "next" (uses >)
        let now = Date()
        let prayers = [PrayerInfo(name: "Asr", time: now)]
        let result = calculator.nextPrayer(from: prayers, at: now)
        XCTAssertNil(result)
    }

    func test_nextPrayer_oneSecondFuture_isIncluded() {
        let now = Date()
        let prayers = [PrayerInfo(name: "Asr", time: now.addingTimeInterval(1))]
        let result = calculator.nextPrayer(from: prayers, at: now)
        XCTAssertEqual(result?.name, "Asr")
    }

    // MARK: - nextPrayerName()

    func test_nextPrayerName_returnsName() {
        let now = Date()
        let prayers = makePrayers(relativeTo: now)
        XCTAssertEqual(calculator.nextPrayerName(from: prayers, at: now), "Asr")
    }

    func test_nextPrayerName_defaultsToIshaWhenAllPast() {
        let now = Date()
        let prayers = makePrayers(
            fajrOffset: -10000, dhuhrOffset: -8000,
            asrOffset: -6000, maghribOffset: -4000, ishaOffset: -2000,
            relativeTo: now
        )
        XCTAssertEqual(calculator.nextPrayerName(from: prayers, at: now), "Isha")
    }

    // MARK: - nextPrayerTime()

    func test_nextPrayerTime_matchesPrayerTime() {
        let now = Date()
        let prayers = makePrayers(relativeTo: now)
        let expected = prayers[2].time // Asr
        XCTAssertEqual(calculator.nextPrayerTime(from: prayers, at: now), expected)
    }

    func test_nextPrayerTime_returnsNowWhenAllPast() {
        let now = Date()
        let prayers = makePrayers(
            fajrOffset: -10000, dhuhrOffset: -8000,
            asrOffset: -6000, maghribOffset: -4000, ishaOffset: -2000,
            relativeTo: now
        )
        let result = calculator.nextPrayerTime(from: prayers, at: now)
        XCTAssertEqual(result.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 1)
    }

    // MARK: - isNextPrayer()

    func test_isNextPrayer_trueForNext() {
        let now = Date()
        let prayers = makePrayers(relativeTo: now)
        XCTAssertTrue(calculator.isNextPrayer("Asr", from: prayers, at: now))
    }

    func test_isNextPrayer_falseForPast() {
        let now = Date()
        let prayers = makePrayers(relativeTo: now)
        XCTAssertFalse(calculator.isNextPrayer("Fajr", from: prayers, at: now))
    }

    func test_isNextPrayer_falseForFutureButNotNext() {
        let now = Date()
        let prayers = makePrayers(relativeTo: now)
        XCTAssertFalse(calculator.isNextPrayer("Maghrib", from: prayers, at: now))
    }
}

// MARK: - DefaultPrayerTimes Tests

final class DefaultPrayerTimesTests: XCTestCase {

    let defaults = DefaultPrayerTimes()

    func test_forToday_returnsFivePrayers() {
        let prayers = defaults.forToday()
        XCTAssertEqual(prayers.count, 5)
    }

    func test_forToday_correctOrder() {
        let prayers = defaults.forToday()
        XCTAssertEqual(prayers.map { $0.name }, ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"])
    }

    func test_forToday_timesAreChronological() {
        let prayers = defaults.forToday()
        for i in 0..<(prayers.count - 1) {
            XCTAssertLessThan(prayers[i].time, prayers[i + 1].time,
                              "\(prayers[i].name) should be before \(prayers[i + 1].name)")
        }
    }

    func test_forToday_allTimesToday() {
        let prayers = defaults.forToday()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!

        for prayer in prayers {
            XCTAssertGreaterThanOrEqual(prayer.time, today, "\(prayer.name) should be today")
            XCTAssertLessThan(prayer.time, tomorrow, "\(prayer.name) should be today")
        }
    }

    func test_forToday_fajrBeforeNoon() {
        let prayers = defaults.forToday()
        let fajr = prayers[0]
        let hour = Calendar.current.component(.hour, from: fajr.time)
        XCTAssertLessThan(hour, 12, "Fajr should be before noon")
    }

    func test_forToday_ishaAfterMaghrib() {
        let prayers = defaults.forToday()
        let maghrib = prayers[3]
        let isha = prayers[4]
        XCTAssertGreaterThan(isha.time, maghrib.time, "Isha should be after Maghrib")
    }
}

// MARK: - PrayerInfo Tests

final class PrayerInfoTests: XCTestCase {

    func test_equality() {
        let now = Date()
        let a = PrayerInfo(name: "Fajr", time: now)
        let b = PrayerInfo(name: "Fajr", time: now)
        XCTAssertEqual(a, b)
    }

    func test_inequality_differentName() {
        let now = Date()
        let a = PrayerInfo(name: "Fajr", time: now)
        let b = PrayerInfo(name: "Dhuhr", time: now)
        XCTAssertNotEqual(a, b)
    }

    func test_inequality_differentTime() {
        let a = PrayerInfo(name: "Fajr", time: Date())
        let b = PrayerInfo(name: "Fajr", time: Date().addingTimeInterval(60))
        XCTAssertNotEqual(a, b)
    }
}
