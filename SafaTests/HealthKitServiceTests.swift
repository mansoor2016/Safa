// MARK: - HealthKitServiceTests.swift
// PURPOSE: Tests for HealthKitService and FastingLogEntry
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class HealthKitServiceTests: XCTestCase {

    // MARK: - FastingLogEntry Tests

    func testFastingLogEntryDuration() {
        let start = createDate(hour: 5, minute: 30)! // Suhoor
        let end = createDate(hour: 18, minute: 30)! // Iftar

        let entry = FastingLogEntry(startDate: start, endDate: end, type: .ramadan)

        // 13 hours of fasting
        XCTAssertEqual(entry.durationHours, 13.0, accuracy: 0.01)
    }

    func testFastingLogEntryDurationWithMinutes() {
        let start = createDate(hour: 5, minute: 0)!
        let end = createDate(hour: 18, minute: 45)!

        let entry = FastingLogEntry(startDate: start, endDate: end, type: .ramadan)

        // 13 hours 45 minutes = 13.75 hours
        XCTAssertEqual(entry.durationHours, 13.75, accuracy: 0.01)
    }

    func testFastingLogEntryTypes() {
        let ramadanEntry = FastingLogEntry(startDate: Date(), endDate: Date(), type: .ramadan)
        let voluntaryEntry = FastingLogEntry(startDate: Date(), endDate: Date(), type: .voluntary)
        let qadhaEntry = FastingLogEntry(startDate: Date(), endDate: Date(), type: .qadha)

        XCTAssertEqual(ramadanEntry.type, .ramadan)
        XCTAssertEqual(voluntaryEntry.type, .voluntary)
        XCTAssertEqual(qadhaEntry.type, .qadha)
    }

    func testFastingLogEntryTypeRawValues() {
        XCTAssertEqual(FastingLogEntry.FastingType.ramadan.rawValue, "ramadan")
        XCTAssertEqual(FastingLogEntry.FastingType.voluntary.rawValue, "voluntary")
        XCTAssertEqual(FastingLogEntry.FastingType.qadha.rawValue, "qadha")
    }

    func testFastingLogEntryDefaultValues() {
        let start = Date()
        let end = Date().addingTimeInterval(3600 * 12) // 12 hours later

        let entry = FastingLogEntry(startDate: start, endDate: end)

        XCTAssertEqual(entry.type, .ramadan)
        XCTAssertFalse(entry.syncedToHealth)
        XCTAssertNotNil(entry.id)
    }

    func testFastingLogEntryCodable() throws {
        let entry = FastingLogEntry(
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600 * 13),
            type: .ramadan,
            syncedToHealth: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(entry)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FastingLogEntry.self, from: data)

        XCTAssertEqual(decoded.id, entry.id)
        XCTAssertEqual(decoded.type, entry.type)
        XCTAssertEqual(decoded.syncedToHealth, entry.syncedToHealth)
        XCTAssertEqual(decoded.durationHours, entry.durationHours, accuracy: 0.01)
    }

    // MARK: - HealthKitError Tests

    func testHealthKitErrorNotAvailableDescription() {
        let error = HealthKitError.notAvailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("not available"))
    }

    func testHealthKitErrorAuthorizationDeniedDescription() {
        let error = HealthKitError.authorizationDenied
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("denied"))
    }

    func testHealthKitErrorTypeNotAvailableDescription() {
        let error = HealthKitError.typeNotAvailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("type"))
    }

    func testHealthKitErrorSaveFailedDescription() {
        let underlyingError = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = HealthKitError.saveFailed(underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Test error"))
    }

    // MARK: - Calculate Fasting Hours Tests

    func testCalculateFastingHoursTypical() {
        let service = HealthKitService.shared

        let suhoor = createDate(hour: 5, minute: 0)!
        let iftar = createDate(hour: 18, minute: 0)!

        let hours = service.calculateFastingHours(suhoorTime: suhoor, iftarTime: iftar)

        XCTAssertEqual(hours, 13.0, accuracy: 0.01)
    }

    func testCalculateFastingHoursLongDay() {
        let service = HealthKitService.shared

        let suhoor = createDate(hour: 3, minute: 0)!
        let iftar = createDate(hour: 21, minute: 0)!

        let hours = service.calculateFastingHours(suhoorTime: suhoor, iftarTime: iftar)

        XCTAssertEqual(hours, 18.0, accuracy: 0.01)
    }

    func testCalculateFastingHoursWithMinutes() {
        let service = HealthKitService.shared

        let suhoor = createDate(hour: 4, minute: 45)!
        let iftar = createDate(hour: 18, minute: 15)!

        let hours = service.calculateFastingHours(suhoorTime: suhoor, iftarTime: iftar)

        XCTAssertEqual(hours, 13.5, accuracy: 0.01)
    }

    func testCalculateFastingHoursNegativeReturnsZero() {
        let service = HealthKitService.shared

        // Iftar before suhoor (invalid)
        let suhoor = createDate(hour: 18, minute: 0)!
        let iftar = createDate(hour: 5, minute: 0)!

        let hours = service.calculateFastingHours(suhoorTime: suhoor, iftarTime: iftar)

        XCTAssertEqual(hours, 0.0)
    }

    // MARK: - Helpers

    private func createDate(hour: Int, minute: Int) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)
    }
}
