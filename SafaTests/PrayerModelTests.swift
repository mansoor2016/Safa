// MARK: - PrayerModelTests.swift
// PURPOSE: Unit tests for Prayer domain models
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class PrayerModelTests: XCTestCase {

    // MARK: - Prayer Type Tests

    func testPrayerTypeRawValues() {
        XCTAssertEqual(PrayerType.fajr.rawValue, "fajr")
        XCTAssertEqual(PrayerType.sunrise.rawValue, "sunrise")
        XCTAssertEqual(PrayerType.dhuhr.rawValue, "dhuhr")
        XCTAssertEqual(PrayerType.asr.rawValue, "asr")
        XCTAssertEqual(PrayerType.maghrib.rawValue, "maghrib")
        XCTAssertEqual(PrayerType.isha.rawValue, "isha")
    }

    func testPrayerTypeDisplayNames() {
        XCTAssertEqual(PrayerType.fajr.displayName, "Fajr")
        XCTAssertEqual(PrayerType.sunrise.displayName, "Sunrise")
        XCTAssertEqual(PrayerType.dhuhr.displayName, "Dhuhr")
        XCTAssertEqual(PrayerType.asr.displayName, "Asr")
        XCTAssertEqual(PrayerType.maghrib.displayName, "Maghrib")
        XCTAssertEqual(PrayerType.isha.displayName, "Isha")
    }

    func testPrayerTypeColors() {
        XCTAssertNotNil(PrayerType.fajr.color)
        XCTAssertNotNil(PrayerType.dhuhr.color)
        XCTAssertNotNil(PrayerType.asr.color)
        XCTAssertNotNil(PrayerType.maghrib.color)
        XCTAssertNotNil(PrayerType.isha.color)
    }

    // MARK: - Prayer Time Tests

    func testPrayerTimeInitialization() {
        let date = Date()
        let prayerTime = PrayerTime(type: .fajr, time: date)

        XCTAssertEqual(prayerTime.type, .fajr)
        XCTAssertEqual(prayerTime.time, date)
    }

    // MARK: - Daily Prayer Times Tests

    func testDailyPrayerTimesInitialization() {
        let now = Date()
        let dailyTimes = DailyPrayerTimes(
            date: now,
            fajr: now,
            sunrise: now.addingTimeInterval(3600),
            dhuhr: now.addingTimeInterval(7200),
            asr: now.addingTimeInterval(10800),
            maghrib: now.addingTimeInterval(14400),
            isha: now.addingTimeInterval(18000)
        )

        XCTAssertEqual(dailyTimes.date, now)
        XCTAssertNotNil(dailyTimes.fajr)
        XCTAssertNotNil(dailyTimes.sunrise)
        XCTAssertNotNil(dailyTimes.dhuhr)
        XCTAssertNotNil(dailyTimes.asr)
        XCTAssertNotNil(dailyTimes.maghrib)
        XCTAssertNotNil(dailyTimes.isha)
    }

    func testDailyPrayerTimesOrdering() {
        let now = Date()
        let dailyTimes = DailyPrayerTimes(
            date: now,
            fajr: now,
            sunrise: now.addingTimeInterval(3600),
            dhuhr: now.addingTimeInterval(7200),
            asr: now.addingTimeInterval(10800),
            maghrib: now.addingTimeInterval(14400),
            isha: now.addingTimeInterval(18000)
        )

        XCTAssertTrue(dailyTimes.fajr < dailyTimes.sunrise)
        XCTAssertTrue(dailyTimes.sunrise < dailyTimes.dhuhr)
        XCTAssertTrue(dailyTimes.dhuhr < dailyTimes.asr)
        XCTAssertTrue(dailyTimes.asr < dailyTimes.maghrib)
        XCTAssertTrue(dailyTimes.maghrib < dailyTimes.isha)
    }

    // MARK: - Prayer Log Tests

    func testPrayerLogInitialization() {
        let log = PrayerLog(
            prayerType: .fajr,
            status: .onTime
        )

        XCTAssertEqual(log.prayerType, .fajr)
        XCTAssertEqual(log.status, .onTime)
        XCTAssertNotNil(log.loggedAt)
    }

    func testPrayerLogStatuses() {
        XCTAssertEqual(PrayerLogStatus.onTime.rawValue, "onTime")
        XCTAssertEqual(PrayerLogStatus.late.rawValue, "late")
        XCTAssertEqual(PrayerLogStatus.missed.rawValue, "missed")
        XCTAssertEqual(PrayerLogStatus.makeUp.rawValue, "makeUp")
    }

    // MARK: - Calculation Method Tests

    func testCalculationMethodRawValues() {
        XCTAssertEqual(CalculationMethod.isna.rawValue, "isna")
        XCTAssertEqual(CalculationMethod.mwl.rawValue, "mwl")
        XCTAssertEqual(CalculationMethod.egypt.rawValue, "egypt")
        XCTAssertEqual(CalculationMethod.makkah.rawValue, "makkah")
        XCTAssertEqual(CalculationMethod.karachi.rawValue, "karachi")
    }

    func testCalculationMethodDisplayNames() {
        XCTAssertEqual(CalculationMethod.isna.displayName, "ISNA")
        XCTAssertEqual(CalculationMethod.mwl.displayName, "Muslim World League")
        XCTAssertEqual(CalculationMethod.egypt.displayName, "Egyptian Authority")
    }

    // MARK: - Madhab Tests

    func testMadhabRawValues() {
        XCTAssertEqual(Madhab.shafi.rawValue, "shafi")
        XCTAssertEqual(Madhab.hanafi.rawValue, "hanafi")
    }

    func testMadhabDisplayNames() {
        XCTAssertEqual(Madhab.shafi.displayName, "Shafi'i/Hanbali/Maliki")
        XCTAssertEqual(Madhab.hanafi.displayName, "Hanafi")
    }

    // MARK: - Qibla Direction Tests

    func testQiblaDirectionInitialization() {
        let qibla = QiblaDirection(
            bearing: 58.5,
            distance: 12500.0
        )

        XCTAssertEqual(qibla.bearing, 58.5)
        XCTAssertEqual(qibla.distance, 12500.0)
    }

    func testQiblaBearingRange() {
        // Bearing should be between 0 and 360
        let qibla = QiblaDirection(bearing: 180.0, distance: 10000.0)
        XCTAssertTrue(qibla.bearing >= 0 && qibla.bearing < 360)
    }

    // MARK: - Encoding/Decoding Tests

    func testPrayerLogCodable() throws {
        let original = PrayerLog(prayerType: .dhuhr, status: .onTime)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PrayerLog.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.prayerType, decoded.prayerType)
        XCTAssertEqual(original.status, decoded.status)
    }

    func testCalculationMethodCodable() throws {
        let original = CalculationMethod.mwl

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CalculationMethod.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    // MARK: - Prayer Log Count Tests

    func testCountingPrayersByStatus() {
        let logs = [
            PrayerLog(prayerType: .fajr, status: .onTime),
            PrayerLog(prayerType: .dhuhr, status: .onTime),
            PrayerLog(prayerType: .asr, status: .late),
            PrayerLog(prayerType: .maghrib, status: .onTime),
            PrayerLog(prayerType: .isha, status: .missed)
        ]

        let onTimeCount = logs.filter { $0.status == .onTime }.count
        let lateCount = logs.filter { $0.status == .late }.count
        let missedCount = logs.filter { $0.status == .missed }.count

        XCTAssertEqual(onTimeCount, 3)
        XCTAssertEqual(lateCount, 1)
        XCTAssertEqual(missedCount, 1)
    }
}
