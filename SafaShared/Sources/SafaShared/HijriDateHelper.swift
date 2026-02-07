// MARK: - HijriDateHelper.swift
// PURPOSE: Shared Hijri date calculation for app and widget
// This is the SINGLE SOURCE OF TRUTH for Hijri date display

import Foundation

public struct HijriDateHelper {

    public init() {}

    private let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)

    /// Returns a formatted Hijri date string for the given date.
    public func hijriDateString(from date: Date = Date()) -> String {
        let components = hijriCalendar.dateComponents([.year, .month, .day], from: date)
        guard let day = components.day, let month = components.month, let year = components.year else {
            return ""
        }
        return "\(day) \(monthName(month)) \(year)"
    }

    /// Returns the Hijri month number (1-12) for the given date.
    public func hijriMonth(from date: Date = Date()) -> Int {
        hijriCalendar.component(.month, from: date)
    }

    /// Returns true if the given date falls in Ramadan (month 9).
    public func isRamadan(on date: Date = Date()) -> Bool {
        hijriMonth(from: date) == 9
    }

    private func monthName(_ month: Int) -> String {
        switch month {
        case 1: return "Muharram"
        case 2: return "Safar"
        case 3: return "Rabi al-Awwal"
        case 4: return "Rabi al-Thani"
        case 5: return "Jumada al-Ula"
        case 6: return "Jumada al-Thani"
        case 7: return "Rajab"
        case 8: return "Sha'ban"
        case 9: return "Ramadan"
        case 10: return "Shawwal"
        case 11: return "Dhul Qa'dah"
        case 12: return "Dhul Hijjah"
        default: return ""
        }
    }
}
