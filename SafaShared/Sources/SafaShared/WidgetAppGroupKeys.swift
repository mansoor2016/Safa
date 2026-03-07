// MARK: - WidgetAppGroupKeys.swift
// PURPOSE: Single source of truth for all App Group UserDefaults key names
// DEPENDENCIES: Foundation

import Foundation

/// All App Group UserDefaults keys shared between the main app and widget extensions.
/// Both sides MUST reference this enum — never hardcode key strings.
public enum WidgetAppGroupKeys {

    // MARK: - Prayer Times

    public static let fajrTime = "fajrTime"
    public static let dhuhrTime = "dhuhrTime"
    public static let asrTime = "asrTime"
    public static let maghribTime = "maghribTime"
    public static let ishaTime = "ishaTime"

    // MARK: - Next Prayer

    public static let nextPrayerName = "nextPrayerName"
    public static let nextPrayerId = "nextPrayerId"
    public static let nextPrayerTime = "nextPrayerTime"

    // MARK: - Metadata

    public static let hijriDate = "hijriDate"
    public static let prayerNames = "prayerNames"
    public static let lastUpdated = "widgetDataLastUpdated"

    // MARK: - Logged Prayers (date-keyed)

    public static func loggedPrayersKey(for date: Date) -> String {
        "loggedPrayers_\(gregorianDateString(date))"
    }

    /// Key for the timestamp when a prayer was logged from the widget.
    /// Format: `widgetLogTime_{prayerId}_{yyyy-MM-dd}` → stores a Date.
    public static func widgetLogTimestampKey(for prayerId: String, date: Date) -> String {
        "widgetLogTime_\(prayerId)_\(gregorianDateString(date))"
    }

    // MARK: - Internal

    /// Locale-pinned Gregorian date string for key suffixes.
    /// Without explicit locale/calendar, DateFormatter can produce non-Gregorian years
    /// (e.g., Buddhist calendar in Thailand), causing key mismatches between app and widget.
    private static func gregorianDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter.string(from: date)
    }

    // MARK: - Streak

    public static let streakCurrentCount = "streakCurrentCount"
    public static let streakLongestCount = "streakLongestCount"
    public static let streakIsActiveToday = "streakIsActiveToday"

    // MARK: - Post-Prayer Snippets

    public static let snippetArabic = "widgetSnippetArabic"
    public static let snippetTranslation = "widgetSnippetTranslation"
    public static let snippetReference = "widgetSnippetReference"
    public static let snippetPrayerId = "widgetSnippetPrayerId"
    public static let snippetDeepLink = "widgetSnippetDeepLink"

    // MARK: - Tasbeeh

    public static let tasbeehCount = "tasbeeh_widget_count"
    public static let tasbeehDhikr = "tasbeeh_widget_dhikr"
    public static let tasbeehArabic = "tasbeeh_widget_arabic"
    public static let tasbeehTarget = "tasbeeh_widget_target"
}
