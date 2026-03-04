// MARK: - PrayerWindowHelper.swift
// PURPOSE: Shared helper to compute prayer window end times
// DEPENDENCIES: Foundation, PrayerType, PrayerTime

import Foundation

enum PrayerWindowHelper {
    /// End time of a prayer's window (= start of next prayer). Nil for Isha and Sunrise.
    static func windowEndTime(for prayer: PrayerType, schedule: [PrayerTime]) -> Date? {
        switch prayer {
        case .fajr:
            return schedule.first(where: { $0.type == .sunrise })?.time
        case .dhuhr:
            return schedule.first(where: { $0.type == .asr })?.time
        case .asr:
            return schedule.first(where: { $0.type == .maghrib })?.time
        case .maghrib:
            return schedule.first(where: { $0.type == .isha })?.time
        case .isha:
            return nil
        case .sunrise:
            return nil
        }
    }
}
