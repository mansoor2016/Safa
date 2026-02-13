// MARK: - DailyGoalsHelpers.swift
// PURPOSE: Testable pure-function helpers for daily goals time-gating
// DEPENDENCIES: Foundation

import Foundation

enum DailyGoalsHelpers {

    /// Fallback hour (24h) used when Asr prayer time is unavailable
    static let eveningFallbackHour = 17

    /// Evening Dhikr unlocks after Asr prayer time (or 5 PM fallback).
    static func isEveningDhikrAvailable(
        now: Date,
        todayPrayers: [PrayerTime],
        calendar: Calendar = .current
    ) -> Bool {
        // Use Asr time if available
        if let asrTime = todayPrayers.first(where: { $0.type == .asr })?.time {
            return now >= asrTime
        }

        // Fallback: 5 PM local time
        let hour = calendar.component(.hour, from: now)
        return hour >= eveningFallbackHour
    }
}
