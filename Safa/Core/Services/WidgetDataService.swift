// MARK: - WidgetDataService.swift
// PURPOSE: Writes prayer times and logged prayers to App Group UserDefaults for widget access
// DEPENDENCIES: Foundation, WidgetKit

import Foundation
import WidgetKit

final class WidgetDataService {
    // MARK: - Shared Instance
    static let shared = WidgetDataService()

    // MARK: - App Group UserDefaults Keys
    private enum Keys {
        static let fajrTime = "fajrTime"
        static let sunriseTime = "sunriseTime"
        static let dhuhrTime = "dhuhrTime"
        static let asrTime = "asrTime"
        static let maghribTime = "maghribTime"
        static let ishaTime = "ishaTime"
        static let nextPrayerName = "nextPrayerName"
        static let nextPrayerTime = "nextPrayerTime"
        static let hijriDate = "hijriDate"
        static let lastUpdated = "widgetDataLastUpdated"

        static func loggedPrayersKey(for date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return "loggedPrayers_\(formatter.string(from: date))"
        }
    }

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
            case .fajr: defaults.set(prayer.time, forKey: Keys.fajrTime)
            case .sunrise: defaults.set(prayer.time, forKey: Keys.sunriseTime)
            case .dhuhr: defaults.set(prayer.time, forKey: Keys.dhuhrTime)
            case .asr: defaults.set(prayer.time, forKey: Keys.asrTime)
            case .maghrib: defaults.set(prayer.time, forKey: Keys.maghribTime)
            case .isha: defaults.set(prayer.time, forKey: Keys.ishaTime)
            }
        }

        // Compute and write next prayer
        let now = Date()
        if let next = prayers.first(where: { $0.time > now && $0.type.isObligatory }) {
            defaults.set(next.type.displayName, forKey: Keys.nextPrayerName)
            defaults.set(next.time, forKey: Keys.nextPrayerTime)
        }

        defaults.set(Date(), forKey: Keys.lastUpdated)
        defaults.synchronize()

        reloadWidgets()
    }

    /// Writes the Hijri date string for widget display
    func writeHijriDate(_ hijriDate: String) {
        guard let defaults else { return }
        defaults.set(hijriDate, forKey: Keys.hijriDate)
    }

    // MARK: - Write Logged Prayers

    /// Writes logged prayer IDs for a specific date so widgets can show check marks
    func writeLoggedPrayers(_ loggedPrayers: Set<PrayerType>, for date: Date) {
        guard let defaults else { return }
        let key = Keys.loggedPrayersKey(for: date)
        let values = loggedPrayers.map { $0.rawValue }
        defaults.set(values, forKey: key)
        defaults.synchronize()

        reloadWidgets()
    }

    // MARK: - Read (for testing / widget-side)

    /// Reads prayer times from App Group (used by widgets)
    func readPrayerTimes() -> [String: Date] {
        guard let defaults else { return [:] }

        var times: [String: Date] = [:]
        if let fajr = defaults.object(forKey: Keys.fajrTime) as? Date { times["Fajr"] = fajr }
        if let dhuhr = defaults.object(forKey: Keys.dhuhrTime) as? Date { times["Dhuhr"] = dhuhr }
        if let asr = defaults.object(forKey: Keys.asrTime) as? Date { times["Asr"] = asr }
        if let maghrib = defaults.object(forKey: Keys.maghribTime) as? Date { times["Maghrib"] = maghrib }
        if let isha = defaults.object(forKey: Keys.ishaTime) as? Date { times["Isha"] = isha }
        return times
    }

    /// Reads logged prayers for a date (used by widgets)
    func readLoggedPrayers(for date: Date) -> [String] {
        guard let defaults else { return [] }
        return defaults.stringArray(forKey: Keys.loggedPrayersKey(for: date)) ?? []
    }

    /// Reads the last-updated timestamp
    func lastUpdated() -> Date? {
        defaults?.object(forKey: Keys.lastUpdated) as? Date
    }

    // MARK: - Private

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
