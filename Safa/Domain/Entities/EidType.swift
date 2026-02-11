// MARK: - EidType.swift
// PURPOSE: Discriminator for Eid al-Fitr vs Eid al-Adha content, visuals, and reminders
// DEPENDENCIES: SwiftUI

import SwiftUI

enum EidType: String, CaseIterable, Identifiable {
    case fitr
    case adha

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fitr: return "Eid al-Fitr"
        case .adha: return "Eid al-Adha"
        }
    }

    var arabicName: String {
        switch self {
        case .fitr: return "\u{0639}\u{064A}\u{062F} \u{0627}\u{0644}\u{0641}\u{0637}\u{0631}"
        case .adha: return "\u{0639}\u{064A}\u{062F} \u{0627}\u{0644}\u{0623}\u{0636}\u{062D}\u{0649}"
        }
    }

    var subtitle: String {
        switch self {
        case .fitr: return "Festival of Breaking the Fast"
        case .adha: return "Festival of Sacrifice"
        }
    }

    var acceptanceDua: String {
        "May Allah accept from us and you"
    }

    var acceptanceDuaArabic: String {
        "\u{062A}\u{064E}\u{0642}\u{064E}\u{0628}\u{0651}\u{064E}\u{0644}\u{064E} \u{0627}\u{0644}\u{0644}\u{0647}\u{064F} \u{0645}\u{0650}\u{0646}\u{0651}\u{064E}\u{0627} \u{0648}\u{064E}\u{0645}\u{0650}\u{0646}\u{0643}\u{064F}\u{0645}\u{0652}"
    }

    var icon: String {
        switch self {
        case .fitr: return "sparkles"
        case .adha: return "heart.fill"
        }
    }

    var hijriMonth: Int {
        switch self {
        case .fitr: return 10  // Shawwal
        case .adha: return 12  // Dhu al-Hijjah
        }
    }

    var daysRange: ClosedRange<Int> {
        switch self {
        case .fitr: return 1...3
        case .adha: return 10...13
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .fitr: return [Color(red: 0.18, green: 0.49, blue: 0.20), Color(red: 0.0, green: 0.54, blue: 0.48)]
        case .adha: return [Color(red: 0.96, green: 0.50, blue: 0.09), Color(red: 1.0, green: 0.56, blue: 0.0)]
        }
    }

    var reminders: [EidReminder] {
        switch self {
        case .fitr:
            return [
                EidReminder(icon: "clock", title: "Eid Prayer", subtitle: "Attend the congregational Eid prayer", isUrgent: false),
                EidReminder(icon: "sterlingsign.circle", title: "Zakat al-Fitr", subtitle: "Pay before Eid prayer — approx. \u{00A3}4-7/person", isUrgent: true),
                EidReminder(icon: "speaker.wave.2", title: "Takbeer", subtitle: "Recite Takbeer from Maghrib until Eid prayer", isUrgent: false),
            ]
        case .adha:
            return [
                EidReminder(icon: "clock", title: "Eid Prayer", subtitle: "Attend the congregational Eid prayer", isUrgent: false),
                EidReminder(icon: "gift", title: "Qurbani", subtitle: "Arrange Qurbani for 10th-12th Dhul Hijjah", isUrgent: false),
                EidReminder(icon: "speaker.wave.2", title: "Takbeer", subtitle: "From Fajr 9th to Asr 13th Dhul Hijjah", isUrgent: false),
            ]
        }
    }

    var shareMessages: [String] {
        switch self {
        case .fitr:
            return [
                "Wishing you and your family a joyous Eid al-Fitr! May the blessings of Ramadan continue throughout the year.",
                "Eid Mubarak! May Allah accept our fasts, prayers, and good deeds. Wishing you a blessed celebration.",
                "As we celebrate the end of Ramadan, may this Eid bring you peace, happiness, and endless blessings.",
            ]
        case .adha:
            return [
                "Wishing you a blessed Eid al-Adha! May the spirit of sacrifice bring you closer to Allah.",
                "Eid Mubarak! May Allah accept your sacrifices and shower you with His mercy and blessings.",
                "On this blessed day of sacrifice, may Allah grant you and your loved ones peace, joy, and prosperity.",
            ]
        }
    }
}

// MARK: - EidReminder

struct EidReminder: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let isUrgent: Bool
}
