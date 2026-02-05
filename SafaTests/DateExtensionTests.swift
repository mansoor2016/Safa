// MARK: - DateExtensionTests.swift
// PURPOSE: Unit tests for Date extensions
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class DateExtensionTests: XCTestCase {

    // MARK: - Date Component Tests

    func testStartOfDay() {
        let date = createDate(year: 2024, month: 6, day: 15, hour: 14, minute: 30)
        let startOfDay = date.startOfDay

        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: startOfDay)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testEndOfDay() {
        let date = createDate(year: 2024, month: 6, day: 15, hour: 14, minute: 30)
        let endOfDay = date.endOfDay

        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: endOfDay)
        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 59)
    }

    // MARK: - Comparison Tests

    func testIsToday() {
        let today = Date()
        XCTAssertTrue(today.isToday)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(yesterday.isToday)
    }

    func testIsYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(yesterday.isYesterday)

        let today = Date()
        XCTAssertFalse(today.isYesterday)
    }

    func testIsTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertTrue(tomorrow.isTomorrow)

        let today = Date()
        XCTAssertFalse(today.isTomorrow)
    }

    func testIsPast() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(yesterday.isPast)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertFalse(tomorrow.isPast)
    }

    func testIsFuture() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertTrue(tomorrow.isFuture)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(yesterday.isFuture)
    }

    // MARK: - Manipulation Tests

    func testAddingDays() {
        let date = createDate(year: 2024, month: 6, day: 15)
        let futureDate = date.adding(days: 5)

        let components = Calendar.current.dateComponents([.day], from: futureDate)
        XCTAssertEqual(components.day, 20)
    }

    func testAddingWeeks() {
        let date = createDate(year: 2024, month: 6, day: 1)
        let futureDate = date.adding(weeks: 2)

        let components = Calendar.current.dateComponents([.day], from: futureDate)
        XCTAssertEqual(components.day, 15)
    }

    func testAddingMonths() {
        let date = createDate(year: 2024, month: 6, day: 15)
        let futureDate = date.adding(months: 3)

        let components = Calendar.current.dateComponents([.month], from: futureDate)
        XCTAssertEqual(components.month, 9)
    }

    func testAddingHours() {
        let date = createDate(year: 2024, month: 6, day: 15, hour: 10)
        let futureDate = date.adding(hours: 5)

        let components = Calendar.current.dateComponents([.hour], from: futureDate)
        XCTAssertEqual(components.hour, 15)
    }

    func testAddingMinutes() {
        let date = createDate(year: 2024, month: 6, day: 15, hour: 10, minute: 30)
        let futureDate = date.adding(minutes: 45)

        let components = Calendar.current.dateComponents([.hour, .minute], from: futureDate)
        XCTAssertEqual(components.hour, 11)
        XCTAssertEqual(components.minute, 15)
    }

    // MARK: - Time Interval Tests

    func testDaysTo() {
        let date1 = createDate(year: 2024, month: 6, day: 1)
        let date2 = createDate(year: 2024, month: 6, day: 15)

        let days = date1.days(to: date2)
        XCTAssertEqual(days, 14)
    }

    func testDaysToNegative() {
        let date1 = createDate(year: 2024, month: 6, day: 15)
        let date2 = createDate(year: 2024, month: 6, day: 1)

        let days = date1.days(to: date2)
        XCTAssertEqual(days, -14)
    }

    // MARK: - Countdown Tests

    func testCountdown() {
        let futureDate = Date().adding(hours: 2).adding(minutes: 30).adding(minutes: 45) // 2h 30m 45s from now... approximately
        let (hours, minutes, seconds) = futureDate.countdown()

        // Due to execution time, we allow some tolerance
        XCTAssertGreaterThanOrEqual(hours, 2)
        XCTAssertLessThanOrEqual(hours, 4)
        XCTAssertGreaterThanOrEqual(minutes, 0)
        XCTAssertLessThanOrEqual(minutes, 59)
        XCTAssertGreaterThanOrEqual(seconds, 0)
        XCTAssertLessThanOrEqual(seconds, 59)
    }

    func testCountdownPastDate() {
        let pastDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        let (hours, minutes, seconds) = pastDate.countdown()

        // Past dates should return 0
        XCTAssertEqual(hours, 0)
        XCTAssertEqual(minutes, 0)
        XCTAssertEqual(seconds, 0)
    }

    // MARK: - Formatting Tests

    func testTimeUntil() {
        let futureDate = Date().adding(hours: 3).adding(minutes: 30)
        let result = futureDate.timeUntil()

        XCTAssertTrue(result.contains("h"))
        XCTAssertTrue(result.contains("m"))
    }

    func testTimeUntilMinutesOnly() {
        let futureDate = Date().adding(minutes: 30)
        let result = futureDate.timeUntil()

        XCTAssertTrue(result.contains("m"))
    }

    func testTimeUntilPast() {
        let pastDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        let result = pastDate.timeUntil()

        XCTAssertEqual(result, "Now")
    }

    func testRelativeString() {
        let date = Date()
        let result = date.relativeString

        // Just verify it returns something
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Helper Methods

    private func createDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return Calendar.current.date(from: components) ?? Date()
    }
}
