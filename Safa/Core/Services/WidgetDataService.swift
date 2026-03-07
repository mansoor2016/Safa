// MARK: - WidgetDataService.swift
// PURPOSE: Writes prayer times and logged prayers to App Group UserDefaults for widget access
// DEPENDENCIES: Foundation, WidgetKit, SafaShared

import Foundation
import WidgetKit
import SafaShared

// MARK: - Notification Name

extension Notification.Name {
    /// Posted when prayer times are written and the Islamic day boundary may have shifted (e.g. after Maghrib).
    static let islamicDayMayHaveChanged = Notification.Name("islamicDayMayHaveChanged")
}

final class WidgetDataService {
    // MARK: - Shared Instance
    static let shared = WidgetDataService()

    // MARK: - Dependencies
    private let defaults: UserDefaults?

    // MARK: - Init
    init(suiteName: String = AppConstants.appGroupId) {
        self.defaults = UserDefaults(suiteName: suiteName)
    }

    // MARK: - Write Prayer Times

    /// Writes all prayer times to App Group so widgets can read them
    func writePrayerTimes(_ prayers: [PrayerTime]) {
        guard let defaults else { return }

        for prayer in prayers {
            switch prayer.type {
            case .fajr: defaults.set(prayer.time, forKey: WidgetAppGroupKeys.fajrTime)
            case .sunrise: break // Sunrise not used by widgets
            case .dhuhr: defaults.set(prayer.time, forKey: WidgetAppGroupKeys.dhuhrTime)
            case .asr: defaults.set(prayer.time, forKey: WidgetAppGroupKeys.asrTime)
            case .maghrib: defaults.set(prayer.time, forKey: WidgetAppGroupKeys.maghribTime)
            case .isha: defaults.set(prayer.time, forKey: WidgetAppGroupKeys.ishaTime)
            }
        }

        // Compute and write next prayer (localized name for widget display)
        // Include prayers in grace window (0–15 min after prayer time)
        let now = Date()
        if let next = prayers.first(where: { $0.type.isObligatory && ($0.time > now || isPrayerTimeNow($0.time, at: now)) }) {
            defaults.set(next.type.localizedDisplayName, forKey: WidgetAppGroupKeys.nextPrayerName)
            defaults.set(next.type.rawValue, forKey: WidgetAppGroupKeys.nextPrayerId)
            defaults.set(next.time, forKey: WidgetAppGroupKeys.nextPrayerTime)
        } else {
            // All prayers past grace — clear stale keys so widgets don't show old data
            defaults.removeObject(forKey: WidgetAppGroupKeys.nextPrayerName)
            defaults.removeObject(forKey: WidgetAppGroupKeys.nextPrayerId)
            defaults.removeObject(forKey: WidgetAppGroupKeys.nextPrayerTime)
        }

        // Persist Maghrib to standard UserDefaults for Islamic day boundary calculations.
        // Day-guard: only persist if Maghrib belongs to today (prevents future-day prayer sets from overwriting).
        var maghribTime: Date?
        if let maghrib = prayers.first(where: { $0.type == .maghrib }),
           Calendar.current.isDate(maghrib.time, inSameDayAs: Date()) {
            maghribTime = maghrib.time
            UserDefaults.standard.set(maghrib.time, forKey: AppConstants.StorageKeys.todayMaghribTime)
        }

        // Compute and write Hijri date (Maghrib-aware) so widgets always have it
        let hijriString = HijriDateConverter.shared.hijriDateString(
            from: Date(), style: .dayMonth, maghribTime: maghribTime
        )
        defaults.set(hijriString, forKey: WidgetAppGroupKeys.hijriDate)

        defaults.set(Date(), forKey: WidgetAppGroupKeys.lastUpdated)
        defaults.synchronize()

        // Notify services that the Islamic day may have changed (e.g. after Maghrib)
        NotificationCenter.default.post(name: .islamicDayMayHaveChanged, object: nil)

        // Clean up date-keyed keys older than 7 days
        pruneStaleKeys()

        reloadWidgets()
    }

    /// Writes the Hijri date string for widget display
    func writeHijriDate(_ hijriDate: String) {
        guard let defaults else { return }
        defaults.set(hijriDate, forKey: WidgetAppGroupKeys.hijriDate)
    }

    // MARK: - Write Logged Prayers

    /// Writes logged prayer IDs for a specific date so widgets can show check marks.
    /// Overwrites the widget key with the authoritative set from the app.
    /// Widget-only logs are safe: `reconcileWidgetLoggedPrayers()` in PrayerViewModel merges them
    /// into `loggedPrayers` before this write-back runs, so they are included in the set.
    /// Overwrite (not merge) is required so that unlogs actually remove prayers from the widget key.
    func writeLoggedPrayers(_ loggedPrayers: Set<PrayerType>, for date: Date) {
        guard let defaults else { return }
        let key = WidgetAppGroupKeys.loggedPrayersKey(for: date)
        defaults.set(loggedPrayers.map { $0.rawValue }, forKey: key)
        defaults.synchronize()

        reloadWidgets()
    }

    /// Removes the logged-prayers key for a date.
    /// Used to clean up previous-day keys after successful reconciliation,
    /// preventing redundant idempotent logPrayer calls on subsequent loads.
    func clearLoggedPrayers(for date: Date) {
        guard let defaults else { return }
        defaults.removeObject(forKey: WidgetAppGroupKeys.loggedPrayersKey(for: date))
    }

    // MARK: - Write Streak Data

    /// Writes streak data to App Group so the streak widget can display it
    func writeStreakData(currentCount: Int, longestCount: Int, isActiveToday: Bool) {
        guard let defaults else { return }
        defaults.set(currentCount, forKey: WidgetAppGroupKeys.streakCurrentCount)
        defaults.set(longestCount, forKey: WidgetAppGroupKeys.streakLongestCount)
        defaults.set(isActiveToday, forKey: WidgetAppGroupKeys.streakIsActiveToday)
        defaults.synchronize()

        reloadWidgets()
    }

    /// Reads streak data from App Group (used by widgets)
    func readStreakData() -> (currentCount: Int, longestCount: Int, isActiveToday: Bool) {
        guard let defaults else { return (0, 0, false) }
        return (
            defaults.integer(forKey: WidgetAppGroupKeys.streakCurrentCount),
            defaults.integer(forKey: WidgetAppGroupKeys.streakLongestCount),
            defaults.bool(forKey: WidgetAppGroupKeys.streakIsActiveToday)
        )
    }

    // MARK: - Read (for testing / widget-side)

    /// Reads prayer times from App Group (used by widgets)
    func readPrayerTimes() -> [String: Date] {
        guard let defaults else { return [:] }

        var times: [String: Date] = [:]
        if let fajr = defaults.object(forKey: WidgetAppGroupKeys.fajrTime) as? Date { times["Fajr"] = fajr }
        if let dhuhr = defaults.object(forKey: WidgetAppGroupKeys.dhuhrTime) as? Date { times["Dhuhr"] = dhuhr }
        if let asr = defaults.object(forKey: WidgetAppGroupKeys.asrTime) as? Date { times["Asr"] = asr }
        if let maghrib = defaults.object(forKey: WidgetAppGroupKeys.maghribTime) as? Date { times["Maghrib"] = maghrib }
        if let isha = defaults.object(forKey: WidgetAppGroupKeys.ishaTime) as? Date { times["Isha"] = isha }
        return times
    }

    /// Reads logged prayers for a date (used by widgets)
    func readLoggedPrayers(for date: Date) -> [String] {
        guard let defaults else { return [] }
        return defaults.stringArray(forKey: WidgetAppGroupKeys.loggedPrayersKey(for: date)) ?? []
    }

    /// Reads the widget tap timestamp for a specific prayer on a date.
    /// Returns nil if the prayer wasn't logged from the widget or the timestamp was pruned.
    func readWidgetLogTimestamp(for prayerId: String, date: Date) -> Date? {
        defaults?.object(forKey: WidgetAppGroupKeys.widgetLogTimestampKey(for: prayerId, date: date)) as? Date
    }

    /// Reads the stable prayer ID (e.g. "fajr") for the next prayer
    func readNextPrayerId() -> String? {
        defaults?.string(forKey: WidgetAppGroupKeys.nextPrayerId)
    }

    /// Reads post-prayer snippet data for widget display
    func readSnippet() -> (arabic: String, translation: String, reference: String, prayerId: String, deepLink: String)? {
        guard let defaults,
              let arabic = defaults.string(forKey: WidgetAppGroupKeys.snippetArabic),
              let translation = defaults.string(forKey: WidgetAppGroupKeys.snippetTranslation),
              let reference = defaults.string(forKey: WidgetAppGroupKeys.snippetReference),
              let prayerId = defaults.string(forKey: WidgetAppGroupKeys.snippetPrayerId) else {
            return nil
        }
        let deepLink = defaults.string(forKey: WidgetAppGroupKeys.snippetDeepLink) ?? "safa://quran"
        return (arabic, translation, reference, prayerId, deepLink)
    }

    /// Reads the last-updated timestamp
    func lastUpdated() -> Date? {
        defaults?.object(forKey: WidgetAppGroupKeys.lastUpdated) as? Date
    }

    // MARK: - Write Post-Prayer Content

    /// Writes a post-prayer snippet to App Group for widget display.
    /// Uses `WidgetSnippetCatalog.writeSnippet` — the same logic used by the widget extension.
    func writePostPrayerContent(for prayerId: String) {
        guard let defaults else { return }
        WidgetSnippetCatalog.writeSnippet(for: prayerId, to: defaults)
        reloadWidgets()
    }

    // MARK: - Write Localized Prayer Names

    /// Writes localized prayer names to App Group for widget display
    func writePrayerNames(_ prayers: [PrayerTime]) {
        guard let defaults else { return }
        let names = prayers.filter { $0.type.isObligatory }
            .map { $0.type.localizedDisplayName }
        defaults.set(names, forKey: WidgetAppGroupKeys.prayerNames)
    }

    // MARK: - Pruning

    /// Removes date-keyed widget keys older than `daysToKeep` days.
    /// Cleans up `loggedPrayers_YYYY-MM-DD` and `widgetLogTime_{prayerId}_YYYY-MM-DD` keys
    /// that accumulate over time.
    func pruneStaleKeys(daysToKeep: Int = 7) {
        guard let defaults else { return }
        let allKeys = defaults.dictionaryRepresentation().keys
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -daysToKeep, to: calendar.startOfDay(for: Date()))!

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.calendar = Calendar(identifier: .gregorian)

        for key in allKeys {
            // Match loggedPrayers_YYYY-MM-DD and widgetLogTime_{id}_YYYY-MM-DD
            guard key.hasPrefix("loggedPrayers_") || key.hasPrefix("widgetLogTime_") else { continue }
            // Extract the date suffix (last 10 characters: YYYY-MM-DD)
            let suffix = String(key.suffix(10))
            guard let keyDate = dateFormatter.date(from: suffix) else { continue }
            if keyDate < cutoff {
                defaults.removeObject(forKey: key)
            }
        }
    }

    // MARK: - Widget Reload

    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
