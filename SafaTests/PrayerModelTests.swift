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

    func testPrayerTypeArabicNames() {
        XCTAssertEqual(PrayerType.fajr.arabicName, "الفجر")
        XCTAssertEqual(PrayerType.sunrise.arabicName, "الشروق")
        XCTAssertEqual(PrayerType.dhuhr.arabicName, "الظهر")
        XCTAssertEqual(PrayerType.asr.arabicName, "العصر")
        XCTAssertEqual(PrayerType.maghrib.arabicName, "المغرب")
        XCTAssertEqual(PrayerType.isha.arabicName, "العشاء")
    }

    func testPrayerTypeObligatory() {
        XCTAssertTrue(PrayerType.fajr.isObligatory)
        XCTAssertFalse(PrayerType.sunrise.isObligatory)
        XCTAssertTrue(PrayerType.dhuhr.isObligatory)
        XCTAssertTrue(PrayerType.asr.isObligatory)
        XCTAssertTrue(PrayerType.maghrib.isObligatory)
        XCTAssertTrue(PrayerType.isha.isObligatory)
    }

    func testObligatoryPrayers() {
        let obligatory = PrayerType.obligatoryPrayers
        XCTAssertEqual(obligatory.count, 5)
        XCTAssertFalse(obligatory.contains(.sunrise))
        XCTAssertTrue(obligatory.contains(.fajr))
    }

    func testPrayerTypeIconNames() {
        XCTAssertFalse(PrayerType.fajr.iconName.isEmpty)
        XCTAssertFalse(PrayerType.dhuhr.iconName.isEmpty)
        XCTAssertFalse(PrayerType.asr.iconName.isEmpty)
        XCTAssertFalse(PrayerType.maghrib.iconName.isEmpty)
        XCTAssertFalse(PrayerType.isha.iconName.isEmpty)
    }

    // MARK: - Prayer Time Tests

    func testPrayerTimeInitialization() {
        let date = Date()
        let prayerTime = PrayerTime(type: .fajr, time: date)

        XCTAssertEqual(prayerTime.type, .fajr)
        XCTAssertEqual(prayerTime.time, date)
        XCTAssertFalse(prayerTime.isNext)
    }

    func testPrayerTimeWithIsNext() {
        let date = Date()
        let prayerTime = PrayerTime(type: .dhuhr, time: date, isNext: true)

        XCTAssertEqual(prayerTime.type, .dhuhr)
        XCTAssertTrue(prayerTime.isNext)
    }

    func testPrayerTimeString() {
        let date = Date()
        let prayerTime = PrayerTime(type: .asr, time: date)

        XCTAssertFalse(prayerTime.timeString.isEmpty)
    }

    // MARK: - Daily Prayer Times Tests

    func testDailyPrayerTimesInitialization() {
        let now = Date()
        let fajr = PrayerTime(type: .fajr, time: now)
        let sunrise = PrayerTime(type: .sunrise, time: now.addingTimeInterval(3600))
        let dhuhr = PrayerTime(type: .dhuhr, time: now.addingTimeInterval(7200))
        let asr = PrayerTime(type: .asr, time: now.addingTimeInterval(10800))
        let maghrib = PrayerTime(type: .maghrib, time: now.addingTimeInterval(14400))
        let isha = PrayerTime(type: .isha, time: now.addingTimeInterval(18000))

        let dailyTimes = DailyPrayerTimes(
            fajr: fajr,
            sunrise: sunrise,
            dhuhr: dhuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha
        )

        XCTAssertEqual(dailyTimes.fajr.type, .fajr)
        XCTAssertEqual(dailyTimes.sunrise.type, .sunrise)
        XCTAssertEqual(dailyTimes.dhuhr.type, .dhuhr)
        XCTAssertEqual(dailyTimes.asr.type, .asr)
        XCTAssertEqual(dailyTimes.maghrib.type, .maghrib)
        XCTAssertEqual(dailyTimes.isha.type, .isha)
    }

    func testDailyPrayerTimesAllProperty() {
        let now = Date()
        let fajr = PrayerTime(type: .fajr, time: now)
        let sunrise = PrayerTime(type: .sunrise, time: now.addingTimeInterval(3600))
        let dhuhr = PrayerTime(type: .dhuhr, time: now.addingTimeInterval(7200))
        let asr = PrayerTime(type: .asr, time: now.addingTimeInterval(10800))
        let maghrib = PrayerTime(type: .maghrib, time: now.addingTimeInterval(14400))
        let isha = PrayerTime(type: .isha, time: now.addingTimeInterval(18000))

        let dailyTimes = DailyPrayerTimes(
            fajr: fajr,
            sunrise: sunrise,
            dhuhr: dhuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha
        )

        XCTAssertEqual(dailyTimes.all.count, 6)
        XCTAssertEqual(dailyTimes.obligatory.count, 5)
    }

    // MARK: - Prayer Log Tests

    func testPrayerLogInitialization() {
        let date = Date()
        let log = PrayerLog(
            prayerType: .fajr,
            date: date,
            isOnTime: true,
            isMakeup: false
        )

        XCTAssertEqual(log.prayerType, .fajr)
        XCTAssertTrue(log.isOnTime)
        XCTAssertFalse(log.isMakeup)
    }

    func testPrayerLogMakeup() {
        let date = Date()
        let log = PrayerLog(
            prayerType: .dhuhr,
            date: date,
            isOnTime: false,
            isMakeup: true
        )

        XCTAssertEqual(log.prayerType, .dhuhr)
        XCTAssertFalse(log.isOnTime)
        XCTAssertTrue(log.isMakeup)
    }

    // MARK: - Calculation Method Tests

    func testCalculationMethodRawValues() {
        XCTAssertEqual(CalculationMethod.isna.rawValue, "isna")
        XCTAssertEqual(CalculationMethod.muslimWorldLeague.rawValue, "mwl")
        XCTAssertEqual(CalculationMethod.egypt.rawValue, "egypt")
        XCTAssertEqual(CalculationMethod.makkah.rawValue, "makkah")
        XCTAssertEqual(CalculationMethod.karachi.rawValue, "karachi")
    }

    func testCalculationMethodDisplayNames() {
        XCTAssertFalse(CalculationMethod.isna.displayName.isEmpty)
        XCTAssertFalse(CalculationMethod.muslimWorldLeague.displayName.isEmpty)
        XCTAssertFalse(CalculationMethod.egypt.displayName.isEmpty)
    }

    func testCalculationMethodDescriptions() {
        XCTAssertFalse(CalculationMethod.muslimWorldLeague.methodDescription.isEmpty)
        XCTAssertFalse(CalculationMethod.isna.methodDescription.isEmpty)
        XCTAssertTrue(CalculationMethod.dubai.methodDescription.contains("United Arab Emirates"))
    }

    // MARK: - Madhab Tests

    func testMadhabRawValues() {
        XCTAssertEqual(Madhab.shafi.rawValue, "shafi")
        XCTAssertEqual(Madhab.hanafi.rawValue, "hanafi")
    }

    func testMadhabDisplayNames() {
        XCTAssertFalse(Madhab.shafi.displayName.isEmpty)
        XCTAssertFalse(Madhab.hanafi.displayName.isEmpty)
    }

    func testMadhabShadowRatio() {
        XCTAssertEqual(Madhab.shafi.shadowRatio, 1.0)
        XCTAssertEqual(Madhab.hanafi.shadowRatio, 2.0)
    }

    // MARK: - Coordinates Tests

    func testCoordinatesInitialization() {
        let coords = Coordinates(latitude: 37.7749, longitude: -122.4194)

        XCTAssertEqual(coords.latitude, 37.7749)
        XCTAssertEqual(coords.longitude, -122.4194)
    }

    // MARK: - Encoding/Decoding Tests

    func testPrayerLogCodable() throws {
        let date = Date()
        let original = PrayerLog(
            prayerType: .dhuhr,
            date: date,
            isOnTime: true,
            isMakeup: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PrayerLog.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.prayerType, decoded.prayerType)
        XCTAssertEqual(original.isOnTime, decoded.isOnTime)
        XCTAssertEqual(original.isMakeup, decoded.isMakeup)
    }

    func testCalculationMethodCodable() throws {
        let original = CalculationMethod.muslimWorldLeague

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CalculationMethod.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func testCoordinatesCodable() throws {
        let original = Coordinates(latitude: 21.4225, longitude: 39.8262)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Coordinates.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    // MARK: - Prayer Log Count Tests

    func testCountingPrayersByStatus() {
        let date = Date()
        let logs = [
            PrayerLog(prayerType: .fajr, date: date, isOnTime: true),
            PrayerLog(prayerType: .dhuhr, date: date, isOnTime: true),
            PrayerLog(prayerType: .asr, date: date, isOnTime: false),
            PrayerLog(prayerType: .maghrib, date: date, isOnTime: true),
            PrayerLog(prayerType: .isha, date: date, isOnTime: false, isMakeup: true)
        ]

        let onTimeCount = logs.filter { $0.isOnTime }.count
        let lateCount = logs.filter { !$0.isOnTime && !$0.isMakeup }.count
        let makeupCount = logs.filter { $0.isMakeup }.count

        XCTAssertEqual(onTimeCount, 3)
        XCTAssertEqual(lateCount, 1)
        XCTAssertEqual(makeupCount, 1)
    }
}
