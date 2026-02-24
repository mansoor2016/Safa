// MARK: - ProgressDashboardModels.swift
// PURPOSE: Data models for the Progress Dashboard prayer consistency features
// DEPENDENCIES: Foundation

import Foundation

// MARK: - Prayer Day Status

/// Status of a single prayer on a specific day (logged, missed, upcoming, etc.)
struct PrayerDayStatus: Identifiable {
    let prayerType: PrayerType
    let date: Date
    let log: PrayerLog?
    let isPast: Bool

    /// Deterministic ID from date + prayer for stable SwiftUI diffing
    var id: String {
        let day = Int(Calendar.current.startOfDay(for: date).timeIntervalSince1970)
        return "\(day)_\(prayerType.rawValue)"
    }

    var isLogged: Bool { log != nil }
    var isOnTime: Bool { log?.isOnTime ?? false }
    var isMakeup: Bool { log?.isMakeup ?? false }
    var isMissed: Bool { isPast && !isLogged }
    var isUpcoming: Bool { !isPast && !isLogged }
}

// MARK: - Day Prayer Summary

/// Summary of all 5 obligatory prayers for a single day
struct DayPrayerSummary: Identifiable {
    let date: Date
    let prayers: [PrayerDayStatus]

    var id: String {
        String(Int(Calendar.current.startOfDay(for: date).timeIntervalSince1970))
    }

    var loggedCount: Int { prayers.filter(\.isLogged).count }
}

// MARK: - Consistency Trend

/// This week vs last week comparison
struct ConsistencyTrend {
    let thisWeekLogged: Int
    let thisWeekOpportunities: Int  // elapsed opportunities (not flat 35)
    let lastWeekLogged: Int
    let lastWeekOpportunities: Int  // 35 (full week) or 0 if no baseline
    let onTimeRate: Double          // this week, excludes makeup
    let hasBaseline: Bool           // false when lastWeekOpportunities == 0

    var thisWeekRate: Double {
        guard thisWeekOpportunities > 0 else { return 0 }
        return Double(thisWeekLogged) / Double(thisWeekOpportunities)
    }

    var lastWeekRate: Double {
        guard lastWeekOpportunities > 0 else { return 0 }
        return Double(lastWeekLogged) / Double(lastWeekOpportunities)
    }

    /// Only meaningful when hasBaseline == true
    var delta: Double { thisWeekRate - lastWeekRate }
}
