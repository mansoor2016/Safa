// MARK: - PrayerTimeLogic.swift
// PURPOSE: Shared prayer time logic used by both the main app and widget extension
// This is the SINGLE SOURCE OF TRUTH for next-prayer calculation

import Foundation

// MARK: - Prayer Time Constants

public enum PrayerTimeConstants {
    /// Grace window after prayer time arrives (15 minutes).
    /// During this window, "Prayer time" is shown instead of a countdown.
    public static let graceInterval: TimeInterval = 15 * 60
}

/// Whether the given prayer time is in its grace window (0...15 min after prayer time).
/// Pure function — accepts a reference date for testability.
public func isPrayerTimeNow(_ prayerTime: Date, at reference: Date = Date()) -> Bool {
    let elapsed = reference.timeIntervalSince(prayerTime)
    return elapsed >= 0 && elapsed < PrayerTimeConstants.graceInterval
}

// MARK: - Prayer Info

public struct PrayerInfo: Equatable, Sendable {
    public let name: String
    public let time: Date

    public init(name: String, time: Date) {
        self.name = name
        self.time = time
    }
}

// MARK: - Next Prayer Calculator

public struct NextPrayerCalculator {

    public init() {}

    /// Find the next prayer from a list of prayers.
    /// Returns the first prayer whose time is in the future.
    /// Returns nil if all prayers have passed.
    public func nextPrayer(from prayers: [PrayerInfo], at now: Date = Date()) -> PrayerInfo? {
        prayers.first { $0.time > now }
    }

    /// Name of the next prayer, or "Isha" if all have passed.
    public func nextPrayerName(from prayers: [PrayerInfo], at now: Date = Date()) -> String {
        nextPrayer(from: prayers, at: now)?.name ?? "Isha"
    }

    /// Time of the next prayer, or current time if all have passed.
    public func nextPrayerTime(from prayers: [PrayerInfo], at now: Date = Date()) -> Date {
        nextPrayer(from: prayers, at: now)?.time ?? now
    }

    /// Whether a specific prayer is the next one.
    public func isNextPrayer(_ name: String, from prayers: [PrayerInfo], at now: Date = Date()) -> Bool {
        nextPrayer(from: prayers, at: now)?.name == name
    }

    // MARK: - Timeline Boundaries

    /// Generate timeline boundary entries for widget/Live Activity use.
    ///
    /// Returns one entry per prayer transition: first at `startingAt` showing the current next prayer,
    /// then one at each future prayer time switching to the subsequent prayer.
    /// The final entry (after the last prayer) has `nextPrayer == nil`.
    ///
    /// Example for 5 prayers all in the future:
    /// ```
    /// [now → Fajr, fajrTime → Dhuhr, dhuhrTime → Asr, asrTime → Maghrib,
    ///  maghribTime → Isha, ishaTime → nil]
    /// ```
    public func timelineBoundaries(from prayers: [PrayerInfo], startingAt now: Date) -> [PrayerBoundary] {
        // Find prayers that haven't passed yet (including those in grace window)
        let futurePrayers = prayers.filter { $0.time > now }

        // Check if any prayer is currently in its grace window
        let graceActivePrayer = prayers.last { isPrayerTimeNow($0.time, at: now) }

        // If no future prayers and no grace prayer, single entry with nil
        guard !futurePrayers.isEmpty || graceActivePrayer != nil else {
            return [PrayerBoundary(date: now, nextPrayer: nil)]
        }

        var boundaries: [PrayerBoundary] = []

        if let gracePrayer = graceActivePrayer {
            // Currently in grace window — show grace entry first
            boundaries.append(PrayerBoundary(date: now, nextPrayer: gracePrayer, isGrace: true))
            // At grace end, switch to the next future prayer
            let graceEnd = gracePrayer.time.addingTimeInterval(PrayerTimeConstants.graceInterval)
            boundaries.append(PrayerBoundary(date: graceEnd, nextPrayer: futurePrayers.first))
        } else if let first = futurePrayers.first {
            // Not in grace — show countdown to next prayer
            boundaries.append(PrayerBoundary(date: now, nextPrayer: first))
        }

        // For each future prayer: at prayer time → grace, at prayer+15m → next prayer
        for i in 0..<futurePrayers.count {
            let prayer = futurePrayers[i]
            let nextAfterThis = (i + 1 < futurePrayers.count) ? futurePrayers[i + 1] : nil

            // Grace start: prayer time arrives
            boundaries.append(PrayerBoundary(date: prayer.time, nextPrayer: prayer, isGrace: true))

            // Grace end: 15 min later, advance to next prayer
            let graceEnd = prayer.time.addingTimeInterval(PrayerTimeConstants.graceInterval)
            boundaries.append(PrayerBoundary(date: graceEnd, nextPrayer: nextAfterThis))
        }

        return boundaries
    }

    /// The date to request a widget timeline refresh — 30 minutes after the last prayer,
    /// or 30 minutes from now if all prayers have passed.
    public func timelineRefreshDate(from prayers: [PrayerInfo], startingAt now: Date) -> Date {
        let lastPrayerTime = prayers.last(where: { $0.time > now })?.time ?? now
        let fallback = prayers.last?.time ?? now
        let anchor = max(lastPrayerTime, fallback)
        return anchor.addingTimeInterval(1800)
    }

    /// The next date at which the displayed prayer should change.
    /// Returns either:
    /// - A grace-end date (prayer+15m) if currently in a grace window
    /// - The time of the next future prayer (when grace starts)
    /// Returns nil if no more prayer transitions remain.
    public func nextBoundaryDate(from prayers: [PrayerInfo], after now: Date) -> Date? {
        // Check if we're in a grace window — next boundary is when grace ends
        if let gracePrayer = prayers.last(where: { isPrayerTimeNow($0.time, at: now) }) {
            return gracePrayer.time.addingTimeInterval(PrayerTimeConstants.graceInterval)
        }

        // Otherwise, the next boundary is the time of the next future prayer
        return prayers.first(where: { $0.time > now })?.time
    }
}

// MARK: - Prayer Boundary

public struct PrayerBoundary: Equatable, Sendable {
    /// The date this entry becomes active (for widget timeline) or the time to update (for Live Activity).
    public let date: Date
    /// The prayer to display as "next". Nil means all prayers for the day have passed.
    public let nextPrayer: PrayerInfo?
    /// Whether this boundary is a grace window (prayer time just arrived, show "Prayer time").
    public let isGrace: Bool

    public init(date: Date, nextPrayer: PrayerInfo?, isGrace: Bool = false) {
        self.date = date
        self.nextPrayer = nextPrayer
        self.isGrace = isGrace
    }
}

// MARK: - Live Activity Staleness

public enum LiveActivityStaleness {
    /// Buffer after prayer time before ActivityKit marks content stale (seconds).
    public static let buffer: TimeInterval = 90

    /// Calculate the staleDate for a Live Activity showing a prayer.
    /// During grace window, stale date is after grace ends + buffer.
    /// Otherwise, adds a buffer after prayerTime so the boundary Task.sleep has time to fire.
    public static func staleDate(for prayerTime: Date, isGrace: Bool = false) -> Date {
        if isGrace {
            return prayerTime.addingTimeInterval(PrayerTimeConstants.graceInterval + buffer)
        }
        return prayerTime.addingTimeInterval(buffer)
    }
}

// MARK: - Default Prayer Times (London Seasonal Approximation)

public struct DefaultPrayerTimes {

    public init() {}

    /// Generate approximate prayer times for London based on month.
    /// TECH DEBT: This is a temporary solution. Proper implementation should
    /// use actual prayer time calculation from coordinates + calculation method.
    public func forToday() -> [PrayerInfo] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let month = cal.component(.month, from: Date())

        let (fajrH, fajrM) = fajrTime(month: month)
        let (dhuhrH, dhuhrM) = (12, 30)
        let (asrH, asrM) = asrTime(month: month)
        let (maghribH, maghribM) = maghribTime(month: month)
        let (ishaH, ishaM) = ishaTime(month: month)

        return [
            PrayerInfo(name: "Fajr", time: cal.date(bySettingHour: fajrH, minute: fajrM, second: 0, of: today)!),
            PrayerInfo(name: "Dhuhr", time: cal.date(bySettingHour: dhuhrH, minute: dhuhrM, second: 0, of: today)!),
            PrayerInfo(name: "Asr", time: cal.date(bySettingHour: asrH, minute: asrM, second: 0, of: today)!),
            PrayerInfo(name: "Maghrib", time: cal.date(bySettingHour: maghribH, minute: maghribM, second: 0, of: today)!),
            PrayerInfo(name: "Isha", time: cal.date(bySettingHour: ishaH, minute: ishaM, second: 0, of: today)!)
        ]
    }

    private func fajrTime(month: Int) -> (Int, Int) {
        switch month {
        case 11, 12, 1, 2: return (6, 30)
        case 3, 4: return (5, 0)
        case 5, 6, 7: return (3, 30)
        case 8, 9, 10: return (5, 0)
        default: return (5, 30)
        }
    }

    private func asrTime(month: Int) -> (Int, Int) {
        switch month {
        case 11, 12, 1, 2: return (14, 45)
        case 3, 4: return (15, 45)
        case 5, 6, 7: return (17, 45)
        case 8, 9, 10: return (16, 45)
        default: return (15, 45)
        }
    }

    private func maghribTime(month: Int) -> (Int, Int) {
        switch month {
        case 11, 12, 1, 2: return (16, 15)
        case 3, 4: return (18, 30)
        case 5, 6, 7: return (21, 0)
        case 8, 9, 10: return (19, 0)
        default: return (18, 0)
        }
    }

    private func ishaTime(month: Int) -> (Int, Int) {
        switch month {
        case 11, 12, 1, 2: return (18, 0)
        case 3, 4: return (20, 0)
        case 5, 6, 7: return (22, 30)
        case 8, 9, 10: return (20, 30)
        default: return (20, 0)
        }
    }
}
