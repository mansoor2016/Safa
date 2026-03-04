// MARK: - PrayerToastService.swift
// PURPOSE: Stateless service for computing in-app prayer toast reminders
// DEPENDENCIES: Foundation, PrayerWindowHelper, PrayerType, PrayerTime, PrayerLog

import Foundation

struct PrayerToastService {

    // MARK: - Prayer Ending Soon

    /// Returns the first unlogged obligatory prayer (excluding Isha) whose window ends
    /// within `thresholdMinutes` of `now`, and hasn't already been toasted today.
    static func prayerEndingSoon(
        now: Date,
        schedule: [PrayerTime],
        loggedPrayers: Set<PrayerType>,
        thresholdMinutes: Int = 20,
        defaults: UserDefaults = .standard
    ) -> PrayerType? {
        let dateKey = dayKey(for: now)
        let threshold = TimeInterval(thresholdMinutes * 60)

        // Check each obligatory prayer (excluding Isha — no natural deadline)
        for prayer in [PrayerType.fajr, .dhuhr, .asr, .maghrib] {
            guard !loggedPrayers.contains(prayer) else { continue }

            guard let windowEnd = PrayerWindowHelper.windowEndTime(for: prayer, schedule: schedule) else {
                continue
            }

            // Prayer window must have started
            guard let prayerStart = schedule.first(where: { $0.type == prayer })?.time,
                  now >= prayerStart else { continue }

            let timeUntilEnd = windowEnd.timeIntervalSince(now)

            // Must be within threshold and window not already passed
            guard timeUntilEnd > 0, timeUntilEnd <= threshold else { continue }

            // Check dedup — already shown today for this prayer?
            let dedupKey = "\(AppConstants.StorageKeys.prayerEndingSoonPrefix)_\(prayer.rawValue)_\(dateKey)"
            guard !defaults.bool(forKey: dedupKey) else { continue }

            return prayer
        }

        return nil
    }

    /// Returns the exact `Date` when the next "ending soon" toast should fire.
    /// Finds the first unlogged prayer whose `windowEnd - threshold` is in the future.
    static func nextEndingSoonFireDate(
        now: Date,
        schedule: [PrayerTime],
        loggedPrayers: Set<PrayerType>,
        thresholdMinutes: Int = 20,
        defaults: UserDefaults = .standard
    ) -> Date? {
        let dateKey = dayKey(for: now)
        let threshold = TimeInterval(thresholdMinutes * 60)

        for prayer in [PrayerType.fajr, .dhuhr, .asr, .maghrib] {
            guard !loggedPrayers.contains(prayer) else { continue }

            guard let windowEnd = PrayerWindowHelper.windowEndTime(for: prayer, schedule: schedule) else {
                continue
            }

            // Check dedup
            let dedupKey = "\(AppConstants.StorageKeys.prayerEndingSoonPrefix)_\(prayer.rawValue)_\(dateKey)"
            guard !defaults.bool(forKey: dedupKey) else { continue }

            let fireDate = windowEnd.addingTimeInterval(-threshold)

            // If fire date is in the future, schedule for it
            if fireDate > now {
                return fireDate
            }

            // If we're already past the fire date but window hasn't ended, fire now
            if windowEnd > now {
                return now
            }
        }

        return nil
    }

    // MARK: - Daily Summary

    /// Returns the logged obligatory count (1–4) if after Isha and not yet shown today.
    /// Returns nil for 0 (discouraging) or 5 (redundant), or if before Isha, or already shown.
    static func dailySummary(
        now: Date,
        schedule: [PrayerTime],
        loggedCount: Int,
        defaults: UserDefaults = .standard
    ) -> Int? {
        // Must be after Isha
        guard let ishaTime = schedule.first(where: { $0.type == .isha })?.time,
              now >= ishaTime else {
            return nil
        }

        // Skip 0 (discouraging) and 5 (redundant)
        guard loggedCount >= 1, loggedCount <= 4 else { return nil }

        // Check dedup — already shown today?
        let dateKey = dayKey(for: now)
        let lastShown = defaults.string(forKey: AppConstants.StorageKeys.dailySummaryToastLastShownDate)
        guard lastShown != dateKey else { return nil }

        return loggedCount
    }

    /// Returns the Isha time if not yet passed and summary not yet shown today.
    static func nextDailySummaryFireDate(
        now: Date,
        schedule: [PrayerTime],
        defaults: UserDefaults = .standard
    ) -> Date? {
        guard let ishaTime = schedule.first(where: { $0.type == .isha })?.time else {
            return nil
        }

        // Check dedup
        let dateKey = dayKey(for: now)
        let lastShown = defaults.string(forKey: AppConstants.StorageKeys.dailySummaryToastLastShownDate)
        guard lastShown != dateKey else { return nil }

        // If Isha is in the future, schedule for it
        if ishaTime > now {
            return ishaTime
        }

        // If already past Isha, fire now (e.g., user opened app post-Isha)
        return now
    }

    // MARK: - Dedup Markers

    static func markEndingSoonShown(for prayer: PrayerType, on date: Date, defaults: UserDefaults = .standard) {
        let dedupKey = "\(AppConstants.StorageKeys.prayerEndingSoonPrefix)_\(prayer.rawValue)_\(dayKey(for: date))"
        defaults.set(true, forKey: dedupKey)
    }

    static func markDailySummaryShown(on date: Date, defaults: UserDefaults = .standard) {
        defaults.set(dayKey(for: date), forKey: AppConstants.StorageKeys.dailySummaryToastLastShownDate)
    }

    // MARK: - Stale Key Pruning

    /// Removes dedup keys older than 2 days to prevent UserDefaults bloat.
    static func pruneStaleKeys(defaults: UserDefaults = .standard) {
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        let cutoffKey = dayKey(for: twoDaysAgo)
        let prefix = AppConstants.StorageKeys.prayerEndingSoonPrefix

        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            // Extract date portion from key: prefix_prayerName_yyyy-MM-dd
            let components = key.split(separator: "_")
            if let dateString = components.last, String(dateString) < cutoffKey {
                defaults.removeObject(forKey: key)
            }
        }
    }

    // MARK: - Scheduler Helper

    /// Determines whether toast scheduling should proceed given current preferences and location.
    /// Returns false if both toggles are off or coordinates are unavailable.
    static func shouldSchedule(
        prefs: UserPreferences,
        coordinates: Coordinates?
    ) -> Bool {
        guard coordinates != nil else { return false }
        return prefs.prayerEndingSoonToastEnabled || prefs.dailyPrayerSummaryToastEnabled
    }

    // MARK: - Private

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func dayKey(for date: Date) -> String {
        dayFormatter.string(from: date)
    }
}
