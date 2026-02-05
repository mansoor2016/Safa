// MARK: - CalendarEventModel.swift
// PURPOSE: Islamic calendar event model and data
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Calendar Event Model

struct CalendarEvent: Identifiable {
    let id = UUID()
    let name: String
    let arabicName: String
    let description: String
    let hijriMonth: Int
    let hijriDay: Int
    let type: EventType
    let isHoliday: Bool

    enum EventType {
        case holiday, observance, specialNight, blessed
    }

    var color: Color {
        switch type {
        case .holiday: return .green
        case .observance: return .blue
        case .specialNight: return .purple
        case .blessed: return .orange
        }
    }

    func nextOccurrence() -> Date? {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        var components = hijriCalendar.dateComponents([.year], from: Date())
        components.month = hijriMonth
        components.day = hijriDay

        if let date = hijriCalendar.date(from: components), date > Date() {
            return date
        }

        // Try next year
        components.year = (components.year ?? 0) + 1
        return hijriCalendar.date(from: components)
    }

    func daysUntilNextOccurrence() -> Int? {
        guard let occurrence = nextOccurrence() else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: occurrence).day
    }
}

// MARK: - Static Event Data

extension CalendarEvent {
    static let allEvents: [CalendarEvent] = [
        // Muharram
        CalendarEvent(
            name: "Islamic New Year",
            arabicName: "رأس السنة الهجرية",
            description: "The first day of the Islamic calendar year.",
            hijriMonth: 1, hijriDay: 1,
            type: .holiday, isHoliday: true
        ),
        CalendarEvent(
            name: "Day of Ashura",
            arabicName: "يوم عاشوراء",
            description: "The 10th day of Muharram, commemorating various historical events. It is recommended to fast on this day.",
            hijriMonth: 1, hijriDay: 10,
            type: .observance, isHoliday: false
        ),

        // Rabi' al-Awwal
        CalendarEvent(
            name: "Mawlid al-Nabi",
            arabicName: "المولد النبوي",
            description: "The birthday of Prophet Muhammad (PBUH).",
            hijriMonth: 3, hijriDay: 12,
            type: .holiday, isHoliday: true
        ),

        // Rajab
        CalendarEvent(
            name: "Isra and Mi'raj",
            arabicName: "الإسراء والمعراج",
            description: "The night journey of Prophet Muhammad (PBUH) from Makkah to Jerusalem and his ascension to the heavens.",
            hijriMonth: 7, hijriDay: 27,
            type: .specialNight, isHoliday: false
        ),

        // Sha'ban
        CalendarEvent(
            name: "Laylat al-Bara'at",
            arabicName: "ليلة البراءة",
            description: "The Night of Forgiveness, a blessed night in the middle of Sha'ban.",
            hijriMonth: 8, hijriDay: 15,
            type: .specialNight, isHoliday: false
        ),

        // Ramadan
        CalendarEvent(
            name: "Beginning of Ramadan",
            arabicName: "بداية رمضان",
            description: "The first day of the blessed month of fasting.",
            hijriMonth: 9, hijriDay: 1,
            type: .holiday, isHoliday: true
        ),
        CalendarEvent(
            name: "Laylat al-Qadr",
            arabicName: "ليلة القدر",
            description: "The Night of Power, better than a thousand months. It falls in the last 10 nights of Ramadan, most likely on the 27th.",
            hijriMonth: 9, hijriDay: 27,
            type: .specialNight, isHoliday: false
        ),

        // Shawwal
        CalendarEvent(
            name: "Eid al-Fitr",
            arabicName: "عيد الفطر",
            description: "The Festival of Breaking the Fast, celebrating the end of Ramadan.",
            hijriMonth: 10, hijriDay: 1,
            type: .holiday, isHoliday: true
        ),

        // Dhul Hijjah
        CalendarEvent(
            name: "Day of Arafah",
            arabicName: "يوم عرفة",
            description: "The most important day of Hajj. Fasting on this day expiates sins of the previous and coming year.",
            hijriMonth: 12, hijriDay: 9,
            type: .blessed, isHoliday: false
        ),
        CalendarEvent(
            name: "Eid al-Adha",
            arabicName: "عيد الأضحى",
            description: "The Festival of Sacrifice, commemorating Prophet Ibrahim's willingness to sacrifice his son.",
            hijriMonth: 12, hijriDay: 10,
            type: .holiday, isHoliday: true
        ),
    ]

    static let hijriMonthNames = [
        "", "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
        "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
        "Ramadan", "Shawwal", "Dhul Qi'dah", "Dhul Hijjah"
    ]
}
