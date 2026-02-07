// MARK: - WidgetDataServiceTests.swift
// PURPOSE: Unit tests for WidgetDataService App Group data sharing
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class WidgetDataServiceTests: XCTestCase {

    private var sut: WidgetDataService!
    private let testSuiteName = "group.com.safa.app.test.\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        sut = WidgetDataService(suiteName: testSuiteName)
    }

    override func tearDown() {
        // Clean up test UserDefaults
        if let defaults = UserDefaults(suiteName: testSuiteName) {
            defaults.removePersistentDomain(forName: testSuiteName)
        }
        sut = nil
        super.tearDown()
    }

    // MARK: - Write Prayer Times Tests

    func test_writePrayerTimes_storesAllFivePrayers() {
        let prayers = makeSamplePrayers()
        sut.writePrayerTimes(prayers)

        let stored = sut.readPrayerTimes()
        XCTAssertEqual(stored.count, 5)
        XCTAssertNotNil(stored["Fajr"])
        XCTAssertNotNil(stored["Dhuhr"])
        XCTAssertNotNil(stored["Asr"])
        XCTAssertNotNil(stored["Maghrib"])
        XCTAssertNotNil(stored["Isha"])
    }

    func test_writePrayerTimes_storesCorrectTimes() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let fajrTime = calendar.date(bySettingHour: 5, minute: 30, second: 0, of: today)!

        let prayers = [
            PrayerTime(type: .fajr, time: fajrTime),
            PrayerTime(type: .dhuhr, time: calendar.date(bySettingHour: 12, minute: 15, second: 0, of: today)!),
            PrayerTime(type: .asr, time: calendar.date(bySettingHour: 15, minute: 45, second: 0, of: today)!),
            PrayerTime(type: .maghrib, time: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .isha, time: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!)
        ]

        sut.writePrayerTimes(prayers)

        let stored = sut.readPrayerTimes()
        XCTAssertEqual(stored["Fajr"], fajrTime)
    }

    func test_writePrayerTimes_includesSunrise() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let prayers = [
            PrayerTime(type: .fajr, time: calendar.date(bySettingHour: 5, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .sunrise, time: calendar.date(bySettingHour: 6, minute: 45, second: 0, of: today)!),
            PrayerTime(type: .dhuhr, time: calendar.date(bySettingHour: 12, minute: 15, second: 0, of: today)!),
            PrayerTime(type: .asr, time: calendar.date(bySettingHour: 15, minute: 45, second: 0, of: today)!),
            PrayerTime(type: .maghrib, time: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .isha, time: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!)
        ]

        sut.writePrayerTimes(prayers)

        // readPrayerTimes only returns obligatory prayers (no sunrise)
        let stored = sut.readPrayerTimes()
        XCTAssertEqual(stored.count, 5)
    }

    func test_writePrayerTimes_updatesLastUpdated() {
        let before = Date()
        sut.writePrayerTimes(makeSamplePrayers())
        let after = Date()

        let lastUpdated = sut.lastUpdated()
        XCTAssertNotNil(lastUpdated)
        XCTAssertGreaterThanOrEqual(lastUpdated!, before)
        XCTAssertLessThanOrEqual(lastUpdated!, after)
    }

    // MARK: - Next Prayer Tests

    func test_writePrayerTimes_setsNextPrayer() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Set all times in the future
        let futurePrayers = [
            PrayerTime(type: .fajr, time: Date().addingTimeInterval(3600)),
            PrayerTime(type: .dhuhr, time: Date().addingTimeInterval(7200)),
            PrayerTime(type: .asr, time: Date().addingTimeInterval(10800)),
            PrayerTime(type: .maghrib, time: Date().addingTimeInterval(14400)),
            PrayerTime(type: .isha, time: Date().addingTimeInterval(18000))
        ]

        sut.writePrayerTimes(futurePrayers)

        let defaults = UserDefaults(suiteName: testSuiteName)
        let nextName = defaults?.string(forKey: "nextPrayerName")
        let nextTime = defaults?.object(forKey: "nextPrayerTime") as? Date

        XCTAssertEqual(nextName, "Fajr")
        XCTAssertNotNil(nextTime)
    }

    // MARK: - Hijri Date Tests

    func test_writeHijriDate_storesValue() {
        sut.writeHijriDate("15 Rajab 1447")

        let defaults = UserDefaults(suiteName: testSuiteName)
        let stored = defaults?.string(forKey: "hijriDate")
        XCTAssertEqual(stored, "15 Rajab 1447")
    }

    // MARK: - Logged Prayers Tests

    func test_writeLoggedPrayers_storesValues() {
        let logged: Set<PrayerType> = [.fajr, .dhuhr]
        sut.writeLoggedPrayers(logged, for: Date())

        let stored = sut.readLoggedPrayers(for: Date())
        XCTAssertEqual(stored.count, 2)
        XCTAssertTrue(stored.contains("fajr"))
        XCTAssertTrue(stored.contains("dhuhr"))
    }

    func test_writeLoggedPrayers_emptySetClearsValues() {
        // First write some logged prayers
        sut.writeLoggedPrayers([.fajr, .dhuhr], for: Date())
        XCTAssertEqual(sut.readLoggedPrayers(for: Date()).count, 2)

        // Then write empty set
        sut.writeLoggedPrayers([], for: Date())
        XCTAssertTrue(sut.readLoggedPrayers(for: Date()).isEmpty)
    }

    func test_writeLoggedPrayers_separatesByDate() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        sut.writeLoggedPrayers([.fajr], for: today)
        sut.writeLoggedPrayers([.isha], for: yesterday)

        let todayLogs = sut.readLoggedPrayers(for: today)
        let yesterdayLogs = sut.readLoggedPrayers(for: yesterday)

        XCTAssertTrue(todayLogs.contains("fajr"))
        XCTAssertFalse(todayLogs.contains("isha"))
        XCTAssertTrue(yesterdayLogs.contains("isha"))
        XCTAssertFalse(yesterdayLogs.contains("fajr"))
    }

    func test_readLoggedPrayers_returnsEmptyForNoData() {
        let stored = sut.readLoggedPrayers(for: Date())
        XCTAssertTrue(stored.isEmpty)
    }

    // MARK: - Read Prayer Times Tests

    func test_readPrayerTimes_returnsEmptyWhenNoData() {
        let stored = sut.readPrayerTimes()
        XCTAssertTrue(stored.isEmpty)
    }

    func test_lastUpdated_returnsNilWhenNoData() {
        XCTAssertNil(sut.lastUpdated())
    }

    // MARK: - Overwrite Tests

    func test_writePrayerTimes_overwritesPreviousValues() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Write first set
        let firstPrayers = [
            PrayerTime(type: .fajr, time: calendar.date(bySettingHour: 5, minute: 0, second: 0, of: today)!),
            PrayerTime(type: .dhuhr, time: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!),
            PrayerTime(type: .asr, time: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today)!),
            PrayerTime(type: .maghrib, time: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!),
            PrayerTime(type: .isha, time: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!)
        ]
        sut.writePrayerTimes(firstPrayers)

        // Write second set with different times
        let newFajrTime = calendar.date(bySettingHour: 4, minute: 30, second: 0, of: today)!
        let secondPrayers = [
            PrayerTime(type: .fajr, time: newFajrTime),
            PrayerTime(type: .dhuhr, time: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .asr, time: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: today)!),
            PrayerTime(type: .maghrib, time: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today)!),
            PrayerTime(type: .isha, time: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: today)!)
        ]
        sut.writePrayerTimes(secondPrayers)

        let stored = sut.readPrayerTimes()
        XCTAssertEqual(stored["Fajr"], newFajrTime)
    }

    // MARK: - Helpers

    private func makeSamplePrayers() -> [PrayerTime] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return [
            PrayerTime(type: .fajr, time: calendar.date(bySettingHour: 5, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .sunrise, time: calendar.date(bySettingHour: 6, minute: 45, second: 0, of: today)!),
            PrayerTime(type: .dhuhr, time: calendar.date(bySettingHour: 12, minute: 15, second: 0, of: today)!),
            PrayerTime(type: .asr, time: calendar.date(bySettingHour: 15, minute: 45, second: 0, of: today)!),
            PrayerTime(type: .maghrib, time: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .isha, time: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!)
        ]
    }
}
