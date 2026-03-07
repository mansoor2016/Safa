// MARK: - WidgetDataStore.swift
// PURPOSE: Centralized read/write access to App Group data for all widget extensions
// DEPENDENCIES: Foundation, SafaShared

import Foundation
import SafaShared

/// Read/write store for widget-side access to App Group data.
/// All widgets should access data through this store instead of using UserDefaults keys directly.
struct WidgetDataStore {
    private let defaults: UserDefaults?

    init(suiteName: String = "group.com.safa.app") {
        self.defaults = UserDefaults(suiteName: suiteName)
    }

    // MARK: - Prayer Times

    /// Loads the 5 obligatory prayer times as PrayerInfo with stable IDs.
    func loadPrayers() -> [PrayerInfo]? {
        guard let defaults else { return nil }

        let namesFallback = [
            String(localized: "Fajr"), String(localized: "Dhuhr"),
            String(localized: "Asr"), String(localized: "Maghrib"),
            String(localized: "Isha")
        ]
        let names = defaults.stringArray(forKey: WidgetAppGroupKeys.prayerNames) ?? namesFallback
        let prayerDefs: [(id: String, timeKey: String)] = [
            ("fajr", WidgetAppGroupKeys.fajrTime),
            ("dhuhr", WidgetAppGroupKeys.dhuhrTime),
            ("asr", WidgetAppGroupKeys.asrTime),
            ("maghrib", WidgetAppGroupKeys.maghribTime),
            ("isha", WidgetAppGroupKeys.ishaTime)
        ]

        var prayers: [PrayerInfo] = []
        for (index, def) in prayerDefs.enumerated() {
            guard let time = defaults.object(forKey: def.timeKey) as? Date else { return nil }
            let name = index < names.count ? names[index] : namesFallback[index]
            prayers.append(PrayerInfo(id: def.id, name: name, time: time))
        }

        return prayers.count == 5 ? prayers : nil
    }

    // MARK: - Next Prayer

    func readNextPrayer() -> (name: String, time: Date, id: String)? {
        guard let defaults,
              let name = defaults.string(forKey: WidgetAppGroupKeys.nextPrayerName),
              let time = defaults.object(forKey: WidgetAppGroupKeys.nextPrayerTime) as? Date,
              let id = defaults.string(forKey: WidgetAppGroupKeys.nextPrayerId) else {
            return nil
        }
        return (name, time, id)
    }

    // MARK: - Logged Prayers

    func readLoggedPrayerIds(at date: Date = Date()) -> Set<String> {
        guard let defaults else { return [] }
        let key = WidgetAppGroupKeys.loggedPrayersKey(for: date)
        let ids = defaults.stringArray(forKey: key) ?? []
        return Set(ids)
    }

    /// Appends a prayer ID to the logged set for a date. Used by interactive widget intent.
    /// Also persists the tap timestamp so app-side reconciliation can record accurate log times.
    func writeLoggedPrayer(_ prayerId: String, at date: Date = Date()) {
        guard let defaults else { return }
        let key = WidgetAppGroupKeys.loggedPrayersKey(for: date)
        var logged = defaults.stringArray(forKey: key) ?? []
        if !logged.contains(prayerId) {
            logged.append(prayerId)
            defaults.set(logged, forKey: key)
        }
        // Always write tap timestamp (even if ID already existed — latest tap wins)
        let timestampKey = WidgetAppGroupKeys.widgetLogTimestampKey(for: prayerId, date: date)
        defaults.set(Date(), forKey: timestampKey)
        defaults.synchronize()
    }

    // MARK: - Streak

    func readStreakData() -> (current: Int, longest: Int, activeToday: Bool) {
        guard let defaults else { return (0, 0, false) }
        return (
            defaults.integer(forKey: WidgetAppGroupKeys.streakCurrentCount),
            defaults.integer(forKey: WidgetAppGroupKeys.streakLongestCount),
            defaults.bool(forKey: WidgetAppGroupKeys.streakIsActiveToday)
        )
    }

    // MARK: - Post-Prayer Snippet

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

    // MARK: - Hijri Date

    func readHijriDate(for date: Date = Date()) -> String {
        let maghrib = defaults?.object(forKey: WidgetAppGroupKeys.maghribTime) as? Date
        return HijriDateHelper().hijriDateString(from: date, maghribTime: maghrib)
    }

    // MARK: - Fajr Time

    func readFajrTime() -> Date? {
        defaults?.object(forKey: WidgetAppGroupKeys.fajrTime) as? Date
    }

    // MARK: - Tasbeeh

    func readTasbeehData() -> (count: Int, dhikrType: String, dhikrArabic: String, targetCount: Int) {
        guard let defaults else {
            return (0, "SubhanAllah", "سُبْحَانَ اللهِ", 33)
        }
        let target = defaults.integer(forKey: WidgetAppGroupKeys.tasbeehTarget)
        return (
            defaults.integer(forKey: WidgetAppGroupKeys.tasbeehCount),
            defaults.string(forKey: WidgetAppGroupKeys.tasbeehDhikr) ?? "SubhanAllah",
            defaults.string(forKey: WidgetAppGroupKeys.tasbeehArabic) ?? "سُبْحَانَ اللهِ",
            target == 0 ? 33 : target
        )
    }

    func writeTasbeehData(count: Int, dhikrType: String, dhikrArabic: String, targetCount: Int) {
        guard let defaults else { return }
        defaults.set(count, forKey: WidgetAppGroupKeys.tasbeehCount)
        defaults.set(dhikrType, forKey: WidgetAppGroupKeys.tasbeehDhikr)
        defaults.set(dhikrArabic, forKey: WidgetAppGroupKeys.tasbeehArabic)
        defaults.set(targetCount, forKey: WidgetAppGroupKeys.tasbeehTarget)
        defaults.synchronize()
    }

    // MARK: - Write Post-Prayer Snippet (widget-side)

    /// Writes a post-prayer snippet for the given prayer ID.
    /// Delegates to `WidgetSnippetCatalog.writeSnippet` — the same logic used by the app-side writer.
    func writePostPrayerSnippet(for prayerId: String) {
        guard let defaults else { return }
        WidgetSnippetCatalog.writeSnippet(for: prayerId, to: defaults)
    }
}
