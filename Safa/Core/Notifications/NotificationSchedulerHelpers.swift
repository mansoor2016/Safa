// MARK: - NotificationSchedulerHelpers.swift
// PURPOSE: Pure-function decision logic for notification scheduling, testable without UNUserNotificationCenter
// DEPENDENCIES: Foundation

import Foundation

enum NotificationSchedulerHelpers {

    // MARK: - Schedule Decision

    enum ScheduleAction: Equatable {
        case cancelAll              // master toggle OFF — cancel pending notifications
        case skipNotAuthorized      // system notification permission not granted
        case skipAlreadyScheduled   // already scheduled today (daily dedup)
        case schedule               // proceed to schedule notifications
    }

    /// Determines what the scheduler should do given current state.
    /// Used by both `scheduleIfNeeded` (daily) and `forceReschedule`.
    static func determineAction(
        notificationsEnabled: Bool,
        isAuthorized: Bool,
        lastScheduledDate: Date?,
        isForceReschedule: Bool
    ) -> ScheduleAction {
        // Kill switch always wins — even if not authorized, cancel pending requests
        guard notificationsEnabled else { return .cancelAll }

        guard isAuthorized else { return .skipNotAuthorized }

        // Force reschedule skips the daily dedup
        if !isForceReschedule,
           let lastDate = lastScheduledDate,
           Calendar.current.isDateInToday(lastDate) {
            return .skipAlreadyScheduled
        }

        return .schedule
    }

    // MARK: - Notification Identifier

    /// Generates a date-suffixed notification identifier for a prayer.
    /// Format: `prayer_at_{prayerType}_{yyyy-MM-dd}`
    static func notificationIdentifier(for prayerType: PrayerType, on date: Date) -> String {
        let dateString = dateFormatter.string(from: date)
        return "prayer_at_\(prayerType.rawValue)_\(dateString)"
    }

    // MARK: - Prayer Filtering

    /// Filters prayers to only those that should receive notifications.
    /// Returns obligatory prayers that are enabled by the user and scheduled after `now`.
    static func prayersToSchedule(
        from prayers: [PrayerTime],
        enabledPrayers: Set<PrayerType>,
        after now: Date
    ) -> [PrayerTime] {
        prayers.filter { prayer in
            prayer.type.isObligatory
            && enabledPrayers.contains(prayer.type)
            && prayer.time > now
        }
    }

    // MARK: - Cancel Logic

    /// Returns true if the identifier belongs to a prayer notification (any format).
    /// Used by `cancelPrayerNotifications` to find all prayer-related pending requests.
    static func isPrayerNotificationIdentifier(_ identifier: String) -> Bool {
        identifier.starts(with: "prayer_")
    }

    /// Filters a list of notification identifiers to only prayer-related ones.
    static func prayerNotificationIdentifiers(from identifiers: [String]) -> [String] {
        identifiers.filter { isPrayerNotificationIdentifier($0) }
    }

    // MARK: - Date Range

    /// Generates an array of dates starting from `startDate` for `daysAhead` days.
    static func scheduleDates(from startDate: Date, daysAhead: Int) -> [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        return (0..<daysAhead).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }

    // MARK: - Background Refresh

    /// Computes the next 2 AM local time after `now` for background refresh scheduling.
    static func nextBackgroundRefreshDate(after now: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 2
        components.minute = 0
        components.second = 0

        guard let twoAMToday = calendar.date(from: components) else {
            // Fallback: 6 hours from now
            return now.addingTimeInterval(6 * 3600)
        }

        if twoAMToday > now {
            return twoAMToday
        }

        // 2 AM today has passed — schedule for tomorrow
        return calendar.date(byAdding: .day, value: 1, to: twoAMToday)
            ?? now.addingTimeInterval(24 * 3600)
    }

    // MARK: - Wudhu Reminder Identifier

    /// Generates a date-suffixed identifier for a wudhu reminder notification.
    /// Format: `prayer_wudhu_{prayerType}_{yyyy-MM-dd}` — starts with `prayer_`
    /// so existing cancel logic covers it.
    static func wudhuNotificationIdentifier(for prayerType: PrayerType, on date: Date) -> String {
        let dateString = dateFormatter.string(from: date)
        return "prayer_wudhu_\(prayerType.rawValue)_\(dateString)"
    }

    // MARK: - Wudhu Prayer Filtering

    /// Filters prayers to those that should receive a wudhu reminder.
    /// Returns obligatory prayers in the enabled set whose reminder time
    /// (`prayer.time - minutesBefore`) is still in the future.
    static func wudhuPrayersToSchedule(
        from prayers: [PrayerTime],
        enabledPrayers: Set<PrayerType>,
        minutesBefore: Int,
        after now: Date
    ) -> [PrayerTime] {
        let offset = TimeInterval(minutesBefore * 60)
        return prayers.filter { prayer in
            prayer.type.isObligatory
            && enabledPrayers.contains(prayer.type)
            && prayer.time.addingTimeInterval(-offset) > now
        }
    }

    // MARK: - Dynamic Days Ahead

    /// Calculates how many days ahead to schedule based on notification density,
    /// staying within iOS's 64-notification limit.
    static func effectiveDaysAhead(enabledPrayerCount: Int, wudhuEnabled: Bool) -> Int {
        let perDay = enabledPrayerCount * (wudhuEnabled ? 2 : 1)
        guard perDay > 0 else { return 14 }
        return min(14, max(1, 64 / perDay))
    }

    // MARK: - Private

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
