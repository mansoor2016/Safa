// MARK: - PrayerTimeLogic.swift
// PURPOSE: Shared prayer time logic used by both the main app and widget extension
// This is the SINGLE SOURCE OF TRUTH for next-prayer calculation

import Foundation

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
        // Find prayers that haven't passed yet
        let futurePrayers = prayers.filter { $0.time > now }

        // If no future prayers, single entry with nil
        guard !futurePrayers.isEmpty else {
            return [PrayerBoundary(date: now, nextPrayer: nil)]
        }

        var boundaries: [PrayerBoundary] = []

        // First entry: now, showing the next upcoming prayer
        boundaries.append(PrayerBoundary(date: now, nextPrayer: futurePrayers[0]))

        // Subsequent entries: at each prayer time, the next prayer switches
        for i in 0..<futurePrayers.count {
            let nextAfterThis = (i + 1 < futurePrayers.count) ? futurePrayers[i + 1] : nil
            boundaries.append(PrayerBoundary(date: futurePrayers[i].time, nextPrayer: nextAfterThis))
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
    /// Returns the time of the next future prayer (the boundary where the name switches).
    /// Returns nil if no more prayer transitions remain.
    public func nextBoundaryDate(from prayers: [PrayerInfo], after now: Date) -> Date? {
        // The "next boundary" is the time of the first future prayer.
        // When that time arrives, the displayed prayer should switch to the one after it.
        guard let next = prayers.first(where: { $0.time > now }) else { return nil }

        // If that's the last prayer, the boundary is its time (switches to nil after)
        // If there's one after, the boundary is still this prayer's time
        // (because at this moment, "next" changes from this prayer to the following one)
        return next.time
    }
}

// MARK: - Prayer Boundary

public struct PrayerBoundary: Equatable, Sendable {
    /// The date this entry becomes active (for widget timeline) or the time to update (for Live Activity).
    public let date: Date
    /// The prayer to display as "next". Nil means all prayers for the day have passed.
    public let nextPrayer: PrayerInfo?

    public init(date: Date, nextPrayer: PrayerInfo?) {
        self.date = date
        self.nextPrayer = nextPrayer
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
