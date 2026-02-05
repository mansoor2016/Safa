// MARK: - CalendarExportTests.swift
// PURPOSE: Tests for CalendarExportService ICS file generation
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class CalendarExportTests: XCTestCase {

    var service: CalendarExportService!

    override func setUp() {
        super.setUp()
        service = CalendarExportService.shared
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - ICS Generation Tests

    func testGenerateICSContentHeader() {
        let events: [IslamicCalendarEvent] = []
        let icsContent = service.generateICSContent(events: events)

        XCTAssertTrue(icsContent.contains("BEGIN:VCALENDAR"))
        XCTAssertTrue(icsContent.contains("VERSION:2.0"))
        XCTAssertTrue(icsContent.contains("PRODID:-//Safa//Islamic Events//EN"))
        XCTAssertTrue(icsContent.contains("END:VCALENDAR"))
    }

    func testGenerateICSContentWithSingleEvent() {
        let event = IslamicCalendarEvent(
            title: "Eid al-Fitr",
            titleArabic: "عيد الفطر",
            eventType: .eidAlFitr,
            startDate: createDate(year: 2026, month: 3, day: 20)!,
            isAllDay: true,
            notes: "Eid Mubarak!"
        )

        let icsContent = service.generateICSContent(events: [event])

        XCTAssertTrue(icsContent.contains("BEGIN:VEVENT"))
        XCTAssertTrue(icsContent.contains("SUMMARY:Eid al-Fitr"))
        XCTAssertTrue(icsContent.contains("DESCRIPTION:Eid Mubarak!"))
        XCTAssertTrue(icsContent.contains("END:VEVENT"))
    }

    func testGenerateICSContentWithAllDayEvent() {
        let event = IslamicCalendarEvent(
            title: "Ramadan Begins",
            eventType: .ramadan,
            startDate: createDate(year: 2026, month: 2, day: 17)!,
            isAllDay: true
        )

        let icsContent = service.generateICSContent(events: [event])

        XCTAssertTrue(icsContent.contains("DTSTART;VALUE=DATE:20260217"))
    }

    func testGenerateICSContentWithTimedEvent() {
        let event = IslamicCalendarEvent(
            title: "Fajr Prayer",
            eventType: .prayerTime,
            startDate: createDate(year: 2026, month: 1, day: 15, hour: 6, minute: 30)!,
            isAllDay: false
        )

        let icsContent = service.generateICSContent(events: [event])

        // Should have DTSTART without VALUE=DATE
        XCTAssertTrue(icsContent.contains("DTSTART:"))
        XCTAssertFalse(icsContent.contains("DTSTART;VALUE=DATE:"))
    }

    func testGenerateICSContentWithRecurrence() {
        let event = IslamicCalendarEvent(
            title: "Weekly Reminder",
            eventType: .ramadan,
            startDate: Date(),
            recurrenceRule: .yearly
        )

        let icsContent = service.generateICSContent(events: [event])

        XCTAssertTrue(icsContent.contains("RRULE:FREQ=YEARLY"))
    }

    func testGenerateICSContentEscapesSpecialCharacters() {
        let event = IslamicCalendarEvent(
            title: "Event; with, special\\ characters",
            eventType: .ramadan,
            startDate: Date(),
            notes: "Line 1\nLine 2"
        )

        let icsContent = service.generateICSContent(events: [event])

        // Check escaping of semicolon, comma, and newline
        XCTAssertTrue(icsContent.contains("\\;"))
        XCTAssertTrue(icsContent.contains("\\,"))
        XCTAssertTrue(icsContent.contains("\\n"))
    }

    func testGenerateICSContentWithMultipleEvents() {
        let events = [
            IslamicCalendarEvent(title: "Event 1", eventType: .eidAlFitr, startDate: Date()),
            IslamicCalendarEvent(title: "Event 2", eventType: .eidAlAdha, startDate: Date())
        ]

        let icsContent = service.generateICSContent(events: events)

        let eventCount = icsContent.components(separatedBy: "BEGIN:VEVENT").count - 1
        XCTAssertEqual(eventCount, 2)
    }

    // MARK: - Sample Events Tests

    func testGetSampleEventsIncludesEid() {
        let options = CalendarExportOptions(
            includeEid: true,
            includeRamadan: false,
            includeIslamicHolidays: false
        )

        let events = service.getSampleEvents(options: options)

        let eidEvents = events.filter { $0.eventType == .eidAlFitr || $0.eventType == .eidAlAdha }
        XCTAssertGreaterThan(eidEvents.count, 0)
    }

    func testGetSampleEventsIncludesRamadan() {
        let options = CalendarExportOptions(
            includeEid: false,
            includeRamadan: true,
            includeIslamicHolidays: false
        )

        let events = service.getSampleEvents(options: options)

        let ramadanEvents = events.filter { $0.eventType == .ramadan }
        XCTAssertGreaterThan(ramadanEvents.count, 0)
    }

    func testGetSampleEventsExcludesWhenDisabled() {
        let options = CalendarExportOptions(
            includeEid: false,
            includeRamadan: false,
            includeIslamicHolidays: false
        )

        let events = service.getSampleEvents(options: options)

        XCTAssertEqual(events.count, 0)
    }

    // MARK: - IslamicEventType Tests

    func testIslamicEventTypeDisplayNames() {
        XCTAssertEqual(IslamicCalendarEvent.IslamicEventType.eidAlFitr.displayName, "Eid al-Fitr")
        XCTAssertEqual(IslamicCalendarEvent.IslamicEventType.eidAlAdha.displayName, "Eid al-Adha")
        XCTAssertEqual(IslamicCalendarEvent.IslamicEventType.ramadan.displayName, "Ramadan")
        XCTAssertEqual(IslamicCalendarEvent.IslamicEventType.islamicNewYear.displayName, "Islamic New Year")
        XCTAssertEqual(IslamicCalendarEvent.IslamicEventType.ashura.displayName, "Ashura")
    }

    // MARK: - CalendarExportError Tests

    func testCalendarExportErrorDescriptions() {
        XCTAssertNotNil(CalendarExportError.authorizationDenied.errorDescription)
        XCTAssertNotNil(CalendarExportError.calendarNotFound.errorDescription)

        let sampleError = NSError(domain: "test", code: 0, userInfo: nil)
        XCTAssertNotNil(CalendarExportError.exportFailed(sampleError).errorDescription)
    }

    // MARK: - Helpers

    private func createDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)
    }
}
