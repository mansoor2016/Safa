// MARK: - IslamicEventService.swift
// PURPOSE: Islamic calendar events and reminders
// DEPENDENCIES: Foundation, UserNotifications

import Foundation
import UserNotifications

// MARK: - Islamic Event Service

@Observable
final class IslamicEventService {

    // MARK: - Properties

    var upcomingEvents: [IslamicEvent] = []
    var todayEvents: [IslamicEvent] = []

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Storage Keys

    private let enabledEventsKey = AppConstants.StorageKeys.islamicEventsEnabled
    private let reminderDaysKey = AppConstants.StorageKeys.islamicEventsReminderDays

    // MARK: - Settings

    var enabledEventTypes: Set<IslamicEventType> {
        get {
            guard let data = UserDefaults.standard.data(forKey: enabledEventsKey),
                  let types = try? JSONDecoder().decode(Set<IslamicEventType>.self, from: data) else {
                return Set(IslamicEventType.allCases) // All enabled by default
            }
            return types
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: enabledEventsKey)
            }
        }
    }

    var reminderDaysBefore: Int {
        get {
            let days = UserDefaults.standard.integer(forKey: reminderDaysKey)
            return days == 0 ? 1 : days // Default to 1 day
        }
        set {
            UserDefaults.standard.set(newValue, forKey: reminderDaysKey)
        }
    }

    // MARK: - Initialization

    init() {
        loadEvents()
    }

    // MARK: - Event Loading

    func loadEvents() {
        let allEvents = IslamicEvent.allEvents
        let now = Date()
        let calendar = Calendar.current

        // Filter upcoming events (next 60 days)
        let sixtyDaysFromNow = calendar.date(byAdding: .day, value: 60, to: now) ?? now

        upcomingEvents = allEvents
            .compactMap { event -> IslamicEvent? in
                guard let gregorianDate = event.nextOccurrence(from: now) else {
                    return nil
                }
                var updatedEvent = event
                updatedEvent.gregorianDate = gregorianDate
                return updatedEvent
            }
            .filter { $0.gregorianDate ?? now <= sixtyDaysFromNow }
            .filter { enabledEventTypes.contains($0.type) }
            .sorted { ($0.gregorianDate ?? now) < ($1.gregorianDate ?? now) }

        // Filter today's events
        todayEvents = upcomingEvents.filter { event in
            guard let date = event.gregorianDate else { return false }
            return calendar.isDateInToday(date)
        }
    }

    // MARK: - Event Reminders

    func scheduleReminders() async {
        // Cancel existing reminders
        notificationCenter.removePendingNotificationRequests(withIdentifiers:
            upcomingEvents.map { "event_\($0.id)" }
        )

        for event in upcomingEvents {
            guard let eventDate = event.gregorianDate else { continue }

            // Schedule reminder for days before
            let reminderDate = Calendar.current.date(
                byAdding: .day,
                value: -reminderDaysBefore,
                to: eventDate
            )

            guard let reminderDate = reminderDate, reminderDate > Date() else { continue }

            await scheduleEventReminder(event: event, at: reminderDate)

            // Also schedule for the day of the event
            if Calendar.current.isDateInToday(eventDate) == false {
                await scheduleEventReminder(event: event, at: eventDate, isDayOf: true)
            }
        }
    }

    private func scheduleEventReminder(event: IslamicEvent, at date: Date, isDayOf: Bool = false) async {
        let content = UNMutableNotificationContent()

        if isDayOf {
            content.title = event.name
            content.body = event.description
        } else {
            content.title = String(localized: "Upcoming: \(event.name)")
            content.body = String(localized: "\(event.name) is in \(reminderDaysBefore) day(s). \(event.description)")
        }

        content.categoryIdentifier = "ISLAMIC_EVENT"
        content.sound = .default
        content.userInfo = [
            "eventId": event.id,
            "eventType": event.type.rawValue
        ]

        // Set notification time to 9 AM
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let identifier = isDayOf ? "event_day_\(event.id)" : "event_\(event.id)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    func cancelReminder(for eventId: String) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["event_\(eventId)", "event_day_\(eventId)"]
        )
    }

    // MARK: - Event Actions

    func getRecommendedActions(for event: IslamicEvent) -> [EventAction] {
        switch event.type {
        case .ramadanStart, .ramadanEnd:
            return [
                EventAction(title: String(localized: "View Fasting Guide"), action: .openFastingGuide),
                EventAction(title: String(localized: "Set Suhoor Reminder"), action: .setSuhoorReminder),
                EventAction(title: String(localized: "Set Iftar Reminder"), action: .setIftarReminder)
            ]

        case .eidAlFitr, .eidAlAdha:
            return [
                EventAction(title: String(localized: "View Eid Prayers"), action: .openEidPrayers),
                EventAction(title: String(localized: "Share Eid Greeting"), action: .shareGreeting),
                EventAction(title: String(localized: "Zakat Calculator"), action: .openZakatCalculator)
            ]

        case .ashura:
            return [
                EventAction(title: String(localized: "Learn About Ashura"), action: .openLearning),
                EventAction(title: String(localized: "Fasting Sunnah"), action: .openFastingGuide)
            ]

        case .mawlidAlNabi:
            return [
                EventAction(title: String(localized: "Read Seerah"), action: .openSeerah),
                EventAction(title: String(localized: "Send Salawat"), action: .openDhikr)
            ]

        case .isra, .miraj:
            return [
                EventAction(title: String(localized: "Learn About Isra & Mi'raj"), action: .openLearning),
                EventAction(title: String(localized: "Night Prayers"), action: .openNightPrayers)
            ]

        case .laylatAlQadr:
            return [
                EventAction(title: String(localized: "Laylat al-Qadr Duas"), action: .openLaylatAlQadrDuas),
                EventAction(title: String(localized: "Night of Power Guide"), action: .openLearning)
            ]

        case .arafah:
            return [
                EventAction(title: String(localized: "Day of Arafah Duas"), action: .openArafahDuas),
                EventAction(title: String(localized: "Fasting Sunnah"), action: .openFastingGuide)
            ]

        case .hijriNewYear:
            return [
                EventAction(title: String(localized: "Reflect on the Year"), action: .openReflection),
                EventAction(title: String(localized: "Set Islamic Goals"), action: .openGoals)
            ]

        case .whiteDays:
            return [
                EventAction(title: String(localized: "White Days Fasting"), action: .openFastingGuide)
            ]

        case .jumuah:
            return [
                EventAction(title: String(localized: "Surah Al-Kahf"), action: .openSurahKahf),
                EventAction(title: String(localized: "Friday Duas"), action: .openFridayDuas)
            ]
        }
    }
}

// MARK: - Islamic Event

struct IslamicEvent: Identifiable, Equatable {
    let id: String
    let name: String
    let nameArabic: String
    let description: String
    let type: IslamicEventType
    let hijriMonth: Int
    let hijriDay: Int
    var gregorianDate: Date?

    func nextOccurrence(from date: Date) -> Date? {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)

        // Get current Hijri year
        let currentHijriYear = hijriCalendar.component(.year, from: date)

        // Create date components for the event
        var components = DateComponents()
        components.month = hijriMonth
        components.day = hijriDay

        // Try current year first
        components.year = currentHijriYear
        if let eventDate = hijriCalendar.date(from: components) {
            if eventDate >= date {
                return eventDate
            }
        }

        // Try next year
        components.year = currentHijriYear + 1
        return hijriCalendar.date(from: components)
    }

    static func == (lhs: IslamicEvent, rhs: IslamicEvent) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Islamic Event Type

enum IslamicEventType: String, CaseIterable, Codable {
    case ramadanStart = "ramadan_start"
    case ramadanEnd = "ramadan_end"
    case eidAlFitr = "eid_al_fitr"
    case eidAlAdha = "eid_al_adha"
    case ashura = "ashura"
    case mawlidAlNabi = "mawlid_al_nabi"
    case isra = "isra"
    case miraj = "miraj"
    case laylatAlQadr = "laylat_al_qadr"
    case arafah = "arafah"
    case hijriNewYear = "hijri_new_year"
    case whiteDays = "white_days"
    case jumuah = "jumuah"

    var displayName: String {
        switch self {
        case .ramadanStart: return String(localized: "Ramadan Begins")
        case .ramadanEnd: return String(localized: "Ramadan Ends")
        case .eidAlFitr: return String(localized: "Eid al-Fitr")
        case .eidAlAdha: return String(localized: "Eid al-Adha")
        case .ashura: return String(localized: "Ashura")
        case .mawlidAlNabi: return String(localized: "Mawlid al-Nabi")
        case .isra: return String(localized: "Isra")
        case .miraj: return String(localized: "Mi'raj")
        case .laylatAlQadr: return String(localized: "Laylat al-Qadr")
        case .arafah: return String(localized: "Day of Arafah")
        case .hijriNewYear: return String(localized: "Islamic New Year")
        case .whiteDays: return String(localized: "White Days")
        case .jumuah: return String(localized: "Jumu'ah")
        }
    }

    var iconName: String {
        switch self {
        case .ramadanStart, .ramadanEnd: return "moon.stars"
        case .eidAlFitr, .eidAlAdha: return "star.fill"
        case .ashura: return "heart.fill"
        case .mawlidAlNabi: return "sun.max.fill"
        case .isra, .miraj: return "moon.fill"
        case .laylatAlQadr: return "sparkles"
        case .arafah: return "mountain.2"
        case .hijriNewYear: return "calendar"
        case .whiteDays: return "circle.grid.3x3"
        case .jumuah: return "building.columns"
        }
    }
}

// MARK: - Event Action

struct EventAction: Identifiable {
    let id = UUID()
    let title: String
    let action: EventActionType

    enum EventActionType {
        case openFastingGuide
        case setSuhoorReminder
        case setIftarReminder
        case openEidPrayers
        case shareGreeting
        case openZakatCalculator
        case openLearning
        case openSeerah
        case openDhikr
        case openNightPrayers
        case openLaylatAlQadrDuas
        case openArafahDuas
        case openReflection
        case openGoals
        case openSurahKahf
        case openFridayDuas
    }
}

// MARK: - All Events

extension IslamicEvent {
    static let allEvents: [IslamicEvent] = [
        IslamicEvent(
            id: "ramadan_start",
            name: String(localized: "Ramadan Begins"),
            nameArabic: "بداية رمضان",
            description: String(localized: "The blessed month of fasting begins."),
            type: .ramadanStart,
            hijriMonth: 9,
            hijriDay: 1
        ),
        IslamicEvent(
            id: "laylat_al_qadr",
            name: String(localized: "Laylat al-Qadr"),
            nameArabic: "ليلة القدر",
            description: String(localized: "The Night of Power."),
            type: .laylatAlQadr,
            hijriMonth: 9,
            hijriDay: 27
        ),
        IslamicEvent(
            id: "eid_al_fitr",
            name: String(localized: "Eid al-Fitr"),
            nameArabic: "عيد الفطر",
            description: String(localized: "Eid Mubarak! Taqabbal Allahu minna wa minkum."),
            type: .eidAlFitr,
            hijriMonth: 10,
            hijriDay: 1
        ),
        IslamicEvent(
            id: "arafah",
            name: String(localized: "Day of Arafah"),
            nameArabic: "يوم عرفة",
            description: String(localized: "Important day of the Hajj pilgrimage. Fasting is highly recommended."),
            type: .arafah,
            hijriMonth: 12,
            hijriDay: 9
        ),
        IslamicEvent(
            id: "eid_al_adha",
            name: String(localized: "Eid al-Adha"),
            nameArabic: "عيد الأضحى",
            description: String(localized: "Eid Mubarak! A time for sacrifice, charity, and reflection."),
            type: .eidAlAdha,
            hijriMonth: 12,
            hijriDay: 10
        ),
        IslamicEvent(
            id: "hijri_new_year",
            name: String(localized: "Islamic New Year"),
            nameArabic: "رأس السنة الهجرية",
            description: String(localized: "The beginning of a new Islamic year."),
            type: .hijriNewYear,
            hijriMonth: 1,
            hijriDay: 1
        ),
        IslamicEvent(
            id: "ashura",
            name: String(localized: "Ashura"),
            nameArabic: "عاشوراء",
            description: String(localized: "The 10th of Muharram. Fasting this day expiates sins of the previous year."),
            type: .ashura,
            hijriMonth: 1,
            hijriDay: 10
        ),
        IslamicEvent(
            id: "mawlid",
            name: String(localized: "Mawlid al-Nabi"),
            nameArabic: "المولد النبوي",
            description: String(localized: "Birth of Prophet Muhammad ﷺ"),
            type: .mawlidAlNabi,
            hijriMonth: 3,
            hijriDay: 12
        ),
        IslamicEvent(
            id: "isra_miraj",
            name: String(localized: "Isra and Mi'raj"),
            nameArabic: "الإسراء والمعراج",
            description: String(localized: "The Night Journey and Ascension of Prophet Muhammad ﷺ"),
            type: .isra,
            hijriMonth: 7,
            hijriDay: 27
        )
    ]
}
