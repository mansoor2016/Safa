// MARK: - RamadanQadaReminderService.swift
// PURPOSE: One-off in-app reminder for missed Ramadan fasts (Qada)
// DEPENDENCIES: Foundation, HijriDateConverter

import Foundation

enum RamadanQadaReminderService {

    // MARK: - Payload

    struct ReminderPayload {
        let trackedDays: Int
        let hijriYear: Int
    }

    // MARK: - Public API

    /// Determines whether to show the Qada reminder.
    /// Returns a payload with tracked day count if eligible, nil otherwise.
    static func shouldShowReminder(
        now: Date = Date(),
        defaults: UserDefaults = .standard,
        hasCompletedOnboarding: Bool
    ) -> ReminderPayload? {
        guard hasCompletedOnboarding else { return nil }

        let converter = HijriDateConverter.shared
        // Maghrib-aware: read persisted Maghrib with same-day validation
        let maghrib: Date? = {
            guard let t = defaults.object(forKey: AppConstants.StorageKeys.todayMaghribTime) as? Date,
                  Calendar.current.isDate(t, inSameDayAs: now) else { return nil }
            return t
        }()
        let components = converter.islamicDate(from: now, adjustedFor: maghrib)
        let hijriYear = components.year ?? 0
        let hijriMonth = components.month ?? 0
        let hijriDay = components.day ?? 0

        // Must be past Eid al-Fitr day 3 (Shawwal 1-3).
        // Eligible from Shawwal 4 onward.
        guard isEligibleDate(month: hijriMonth, day: hijriDay) else { return nil }

        // Determine which Hijri year's Ramadan to check.
        let ramadanHijriYear = mostRecentRamadanYear(
            currentHijriYear: hijriYear,
            currentHijriMonth: hijriMonth
        )

        // Already shown for this Hijri year?
        let shownYear = defaults.integer(forKey: AppConstants.StorageKeys.qadaReminderShownHijriYear)
        guard shownYear != ramadanHijriYear else { return nil }

        // Read fasting days from storage.
        let trackedDays = readFastingDays(
            ramadanHijriYear: ramadanHijriYear,
            converter: converter,
            defaults: defaults
        )

        // No tracking data = don't show (user didn't use the feature).
        guard trackedDays > 0 else { return nil }

        // All 30 days tracked = no reminder needed.
        guard trackedDays < 30 else { return nil }

        return ReminderPayload(trackedDays: trackedDays, hijriYear: ramadanHijriYear)
    }

    /// Marks the reminder as shown for the given Hijri year.
    static func markShown(hijriYear: Int, defaults: UserDefaults = .standard) {
        defaults.set(hijriYear, forKey: AppConstants.StorageKeys.qadaReminderShownHijriYear)
    }

    // MARK: - Private Helpers

    /// Eligible from Shawwal (month 10) day 4 onward, through the rest of the year.
    static func isEligibleDate(month: Int, day: Int) -> Bool {
        if month == 10 { return day >= 4 }
        return month > 10
    }

    /// Determine which Hijri year's Ramadan was most recent.
    /// If current month >= 10 (Shawwal or later), Ramadan was this Hijri year.
    /// If current month < 10, Ramadan was last Hijri year.
    static func mostRecentRamadanYear(currentHijriYear: Int, currentHijriMonth: Int) -> Int {
        currentHijriMonth >= 10 ? currentHijriYear : currentHijriYear - 1
    }

    /// Read tracked fasting days from UserDefaults.
    /// RamadanView stores under "ramadan_fasting_days_<gregorianYear>".
    /// A Ramadan can span two Gregorian years, so check both if needed.
    static func readFastingDays(
        ramadanHijriYear: Int,
        converter: HijriDateConverter,
        defaults: UserDefaults
    ) -> Int {
        // Find the Gregorian year(s) that the target Ramadan spans.
        let gregorianYears = gregorianYearsForRamadan(
            hijriYear: ramadanHijriYear,
            converter: converter
        )

        var allDays: Set<Int> = []
        for year in gregorianYears {
            let key = "ramadan_fasting_days_\(year)"
            if let days = defaults.array(forKey: key) as? [Int] {
                // Only count valid day values (1...30).
                let valid = days.filter { (1...30).contains($0) }
                allDays.formUnion(valid)
            }
        }

        return allDays.count
    }

    /// Returns the Gregorian year(s) that a given Hijri Ramadan spans.
    private static func gregorianYearsForRamadan(
        hijriYear: Int,
        converter: HijriDateConverter
    ) -> Set<Int> {
        var years: Set<Int> = []
        let gregorianCalendar = Calendar(identifier: .gregorian)

        // Ramadan 1
        var ramadan1 = DateComponents()
        ramadan1.year = hijriYear
        ramadan1.month = 9
        ramadan1.day = 1
        if let date = converter.gregorianDate(from: ramadan1) {
            years.insert(gregorianCalendar.component(.year, from: date))
        }

        // Shawwal 1 (end of Ramadan)
        var shawwal1 = DateComponents()
        shawwal1.year = hijriYear
        shawwal1.month = 10
        shawwal1.day = 1
        if let date = converter.gregorianDate(from: shawwal1) {
            years.insert(gregorianCalendar.component(.year, from: date))
        }

        return years
    }
}
