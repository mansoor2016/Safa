// MARK: - CalendarExportService.swift
// PURPOSE: Export Islamic events to Apple Calendar or .ics files
// DEPENDENCIES: EventKit, Foundation, UIKit

import Foundation
import EventKit
import UIKit

// MARK: - Islamic Calendar Event

struct IslamicCalendarEvent: Identifiable, Codable {
    let id: UUID
    let title: String
    let titleArabic: String?
    let eventType: IslamicEventType
    let startDate: Date
    let endDate: Date?
    let isAllDay: Bool
    let notes: String?
    let recurrenceRule: RecurrenceRule?

    init(
        title: String,
        titleArabic: String? = nil,
        eventType: IslamicEventType,
        startDate: Date,
        endDate: Date? = nil,
        isAllDay: Bool = true,
        notes: String? = nil,
        recurrenceRule: RecurrenceRule? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.titleArabic = titleArabic
        self.eventType = eventType
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.notes = notes
        self.recurrenceRule = recurrenceRule
    }

    enum IslamicEventType: String, Codable, CaseIterable {
        case eidAlFitr = "eid_al_fitr"
        case eidAlAdha = "eid_al_adha"
        case ramadan = "ramadan"
        case islamicNewYear = "islamic_new_year"
        case ashura = "ashura"
        case mawlidAlNabi = "mawlid_al_nabi"
        case isra = "isra_miraj"
        case shaban = "mid_shaban"
        case prayerTime = "prayer_time"

        var displayName: String {
            switch self {
            case .eidAlFitr: return "Eid al-Fitr"
            case .eidAlAdha: return "Eid al-Adha"
            case .ramadan: return "Ramadan"
            case .islamicNewYear: return "Islamic New Year"
            case .ashura: return "Ashura"
            case .mawlidAlNabi: return "Mawlid al-Nabi"
            case .isra: return "Isra and Mi'raj"
            case .shaban: return "Mid-Sha'ban"
            case .prayerTime: return "Prayer Time"
            }
        }
    }

    enum RecurrenceRule: String, Codable {
        case yearly
        case monthly
        case daily
    }
}

// MARK: - Export Options

struct CalendarExportOptions {
    var includeEid: Bool = true
    var includeRamadan: Bool = true
    var includeIslamicHolidays: Bool = true
    var includePrayerTimes: Bool = false
    var year: Int = Calendar.current.component(.year, from: Date())
}

// MARK: - Calendar Export Service

@Observable
final class CalendarExportService {
    static let shared = CalendarExportService()

    // MARK: - Properties

    private let eventStore = EKEventStore()
    private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined
    private(set) var safaCalendar: EKCalendar?

    private let calendarName = "Safa - Islamic Events"
    private let calendarIdentifierKey = "com.safa.calendar.identifier"

    // MARK: - Init

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestCalendarAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                authorizationStatus = granted ? .fullAccess : .denied
            }
            return granted
        } catch {
            print("CalendarExportService: Authorization error: \(error)")
            return false
        }
    }

    // MARK: - Calendar Management

    /// Find or create the Safa calendar
    func findOrCreateSafaCalendar() async throws -> EKCalendar {
        // Check if we already have a saved calendar
        if let savedIdentifier = UserDefaults.standard.string(forKey: calendarIdentifierKey),
           let existingCalendar = eventStore.calendar(withIdentifier: savedIdentifier) {
            safaCalendar = existingCalendar
            return existingCalendar
        }

        // Look for existing Safa calendar
        let calendars = eventStore.calendars(for: .event)
        if let existing = calendars.first(where: { $0.title == calendarName }) {
            safaCalendar = existing
            UserDefaults.standard.set(existing.calendarIdentifier, forKey: calendarIdentifierKey)
            return existing
        }

        // Create new calendar
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = calendarName
        newCalendar.cgColor = UIColor.systemGreen.cgColor

        // Find best source for new calendar
        if let iCloudSource = eventStore.sources.first(where: { $0.sourceType == .calDAV && $0.title.contains("iCloud") }) {
            newCalendar.source = iCloudSource
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = localSource
        } else if let firstSource = eventStore.sources.first {
            newCalendar.source = firstSource
        }

        try eventStore.saveCalendar(newCalendar, commit: true)
        UserDefaults.standard.set(newCalendar.calendarIdentifier, forKey: calendarIdentifierKey)
        safaCalendar = newCalendar

        return newCalendar
    }

    // MARK: - Export to Apple Calendar

    /// Export events to Apple Calendar
    func exportToCalendar(events: [IslamicCalendarEvent]) async throws -> Int {
        if authorizationStatus != .fullAccess {
            let granted = await requestCalendarAccess()
            if !granted {
                throw CalendarExportError.authorizationDenied
            }
        }

        let calendar = try await findOrCreateSafaCalendar()
        var exportedCount = 0

        for event in events {
            let ekEvent = EKEvent(eventStore: eventStore)
            ekEvent.title = event.title
            ekEvent.startDate = event.startDate
            ekEvent.endDate = event.endDate ?? event.startDate
            ekEvent.isAllDay = event.isAllDay
            ekEvent.notes = event.notes
            ekEvent.calendar = calendar

            // Add recurrence if specified
            if let rule = event.recurrenceRule {
                let frequency: EKRecurrenceFrequency
                switch rule {
                case .yearly: frequency = .yearly
                case .monthly: frequency = .monthly
                case .daily: frequency = .daily
                }

                let recurrenceRule = EKRecurrenceRule(
                    recurrenceWith: frequency,
                    interval: 1,
                    end: nil
                )
                ekEvent.recurrenceRules = [recurrenceRule]
            }

            try eventStore.save(ekEvent, span: .thisEvent)
            exportedCount += 1
        }

        return exportedCount
    }

    // MARK: - ICS File Generation

    /// Generate ICS file content for events
    func generateICSContent(events: [IslamicCalendarEvent]) -> String {
        var ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Safa//Islamic Events//EN
        CALSCALE:GREGORIAN
        METHOD:PUBLISH
        X-WR-CALNAME:Safa - Islamic Events

        """

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"

        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateTimeFormatter.timeZone = TimeZone(identifier: "UTC")

        for event in events {
            ics += "BEGIN:VEVENT\n"
            ics += "UID:\(event.id.uuidString)@safaapp.com\n"
            ics += "DTSTAMP:\(dateTimeFormatter.string(from: Date()))\n"

            if event.isAllDay {
                ics += "DTSTART;VALUE=DATE:\(dateFormatter.string(from: event.startDate))\n"
                if let endDate = event.endDate {
                    ics += "DTEND;VALUE=DATE:\(dateFormatter.string(from: endDate))\n"
                }
            } else {
                ics += "DTSTART:\(dateTimeFormatter.string(from: event.startDate))\n"
                if let endDate = event.endDate {
                    ics += "DTEND:\(dateTimeFormatter.string(from: endDate))\n"
                }
            }

            ics += "SUMMARY:\(escapeICSString(event.title))\n"

            if let notes = event.notes {
                ics += "DESCRIPTION:\(escapeICSString(notes))\n"
            }

            if let recurrence = event.recurrenceRule {
                let freq: String
                switch recurrence {
                case .yearly: freq = "YEARLY"
                case .monthly: freq = "MONTHLY"
                case .daily: freq = "DAILY"
                }
                ics += "RRULE:FREQ=\(freq)\n"
            }

            ics += "END:VEVENT\n\n"
        }

        ics += "END:VCALENDAR"
        return ics
    }

    /// Create and save ICS file, returning the URL
    func createICSFile(events: [IslamicCalendarEvent], fileName: String = "safa_islamic_events") throws -> URL {
        let content = generateICSContent(events: events)
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("\(fileName).ics")

        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    // MARK: - Sample Events

    /// Get sample Islamic events for the current year
    func getSampleEvents(options: CalendarExportOptions = CalendarExportOptions()) -> [IslamicCalendarEvent] {
        var events: [IslamicCalendarEvent] = []
        let year = options.year

        // Note: These are approximate dates - in production, use proper Hijri calendar calculations

        if options.includeRamadan {
            // Ramadan Start (approximate for 2026)
            if let ramadanStart = createDate(year: year, month: 2, day: 17) {
                events.append(IslamicCalendarEvent(
                    title: "Ramadan Begins",
                    titleArabic: "بداية رمضان",
                    eventType: .ramadan,
                    startDate: ramadanStart,
                    notes: "The blessed month of fasting begins. May Allah accept your fasting and prayers."
                ))
            }

            // Laylatul Qadr (approximate - 27th night)
            if let laylatul = createDate(year: year, month: 3, day: 13) {
                events.append(IslamicCalendarEvent(
                    title: "Laylatul Qadr (Night of Power)",
                    titleArabic: "ليلة القدر",
                    eventType: .ramadan,
                    startDate: laylatul,
                    notes: "The Night of Power - better than a thousand months"
                ))
            }
        }

        if options.includeEid {
            // Eid al-Fitr (approximate)
            if let eidFitr = createDate(year: year, month: 3, day: 20) {
                events.append(IslamicCalendarEvent(
                    title: "Eid al-Fitr",
                    titleArabic: "عيد الفطر",
                    eventType: .eidAlFitr,
                    startDate: eidFitr,
                    notes: "Eid Mubarak! The celebration marking the end of Ramadan."
                ))
            }

            // Eid al-Adha (approximate)
            if let eidAdha = createDate(year: year, month: 5, day: 27) {
                events.append(IslamicCalendarEvent(
                    title: "Eid al-Adha",
                    titleArabic: "عيد الأضحى",
                    eventType: .eidAlAdha,
                    startDate: eidAdha,
                    notes: "Eid Mubarak! The Festival of Sacrifice."
                ))
            }
        }

        if options.includeIslamicHolidays {
            // Islamic New Year
            if let newYear = createDate(year: year, month: 6, day: 17) {
                events.append(IslamicCalendarEvent(
                    title: "Islamic New Year",
                    titleArabic: "رأس السنة الهجرية",
                    eventType: .islamicNewYear,
                    startDate: newYear,
                    notes: "The first day of Muharram, the Islamic New Year."
                ))
            }

            // Ashura
            if let ashura = createDate(year: year, month: 6, day: 26) {
                events.append(IslamicCalendarEvent(
                    title: "Day of Ashura",
                    titleArabic: "يوم عاشوراء",
                    eventType: .ashura,
                    startDate: ashura,
                    notes: "The 10th of Muharram - a day of fasting recommended by the Prophet (PBUH)."
                ))
            }

            // Mawlid al-Nabi
            if let mawlid = createDate(year: year, month: 8, day: 25) {
                events.append(IslamicCalendarEvent(
                    title: "Mawlid al-Nabi",
                    titleArabic: "المولد النبوي",
                    eventType: .mawlidAlNabi,
                    startDate: mawlid,
                    notes: "Birth of Prophet Muhammad (Peace Be Upon Him)."
                ))
            }
        }

        return events
    }

    // MARK: - Private Helpers

    private func escapeICSString(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private func createDate(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }
}

// MARK: - Errors

enum CalendarExportError: LocalizedError {
    case authorizationDenied
    case calendarNotFound
    case exportFailed(Error)

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Calendar access was denied. Please enable access in Settings."
        case .calendarNotFound:
            return "Could not find or create calendar."
        case .exportFailed(let error):
            return "Export failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Feature Flag Integration

extension CalendarExportService {
    var isAvailable: Bool {
        FeatureFlags.shared.isEnabled(.calendarExport)
    }
}
