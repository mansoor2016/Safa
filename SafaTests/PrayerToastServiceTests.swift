// MARK: - PrayerToastServiceTests.swift
// PURPOSE: Tests for PrayerToastService logic
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class PrayerToastServiceTests: XCTestCase {

    private var defaults: UserDefaults!
    private var schedule: [PrayerTime]!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "PrayerToastServiceTests.\(UUID().uuidString)")!
        schedule = makeSchedule()
    }

    override func tearDown() {
        if let suiteName = defaults.volatileDomainNames.first {
            UserDefaults.standard.removePersistentDomain(forName: suiteName)
        }
        defaults = nil
        schedule = nil
        super.tearDown()
    }

    // MARK: - Prayer Ending Soon Tests

    func test_endingSoon_withinThresholdAndNotLogged_returnsPrayer() {
        // Dhuhr at 12:15, Asr at 15:45 — "now" is 15:30 (15 min before Asr = Dhuhr window end)
        let now = dateAt(hour: 15, minute: 30)

        let result = PrayerToastService.prayerEndingSoon(
            now: now,
            schedule: schedule,
            loggedPrayers: [],
            thresholdMinutes: 20,
            defaults: defaults
        )

        XCTAssertEqual(result, .dhuhr)
    }

    func test_endingSoon_alreadyLogged_skips() {
        let now = dateAt(hour: 15, minute: 30)

        let result = PrayerToastService.prayerEndingSoon(
            now: now,
            schedule: schedule,
            loggedPrayers: [.dhuhr],
            thresholdMinutes: 20,
            defaults: defaults
        )

        // Dhuhr logged, next candidate is Asr but its window hasn't started ending yet
        XCTAssertNil(result)
    }

    func test_endingSoon_exceedsThreshold_returnsNil() {
        // Dhuhr window ends at Asr (15:45), now is 15:00 — 45 min away, threshold is 20
        let now = dateAt(hour: 15, minute: 0)

        let result = PrayerToastService.prayerEndingSoon(
            now: now,
            schedule: schedule,
            loggedPrayers: [],
            thresholdMinutes: 20,
            defaults: defaults
        )

        // Fajr window already passed, Dhuhr too far from end
        XCTAssertNil(result)
    }

    func test_endingSoon_alreadyShown_skips() {
        let now = dateAt(hour: 15, minute: 30)
        PrayerToastService.markEndingSoonShown(for: .dhuhr, on: now, defaults: defaults)

        let result = PrayerToastService.prayerEndingSoon(
            now: now,
            schedule: schedule,
            loggedPrayers: [],
            thresholdMinutes: 20,
            defaults: defaults
        )

        XCTAssertNil(result)
    }

    func test_endingSoon_windowNotStarted_skips() {
        // Now is 11:00, before Dhuhr starts at 12:15
        let now = dateAt(hour: 11, minute: 0)

        let result = PrayerToastService.prayerEndingSoon(
            now: now,
            schedule: schedule,
            loggedPrayers: [],
            thresholdMinutes: 20,
            defaults: defaults
        )

        XCTAssertNil(result)
    }

    func test_endingSoon_ishaExcluded() {
        // Even if Isha is unlogged and "ending," it should never be returned
        let now = dateAt(hour: 23, minute: 0)

        let result = PrayerToastService.prayerEndingSoon(
            now: now,
            schedule: schedule,
            loggedPrayers: [.fajr, .dhuhr, .asr, .maghrib],
            thresholdMinutes: 120,
            defaults: defaults
        )

        XCTAssertNil(result)
    }

    func test_endingSoon_correctPriority_earliestPrayerFirst() {
        // Fajr window ending at 6:45 (sunrise). Now is 6:30 — 15 min away.
        let now = dateAt(hour: 6, minute: 30)

        let result = PrayerToastService.prayerEndingSoon(
            now: now,
            schedule: schedule,
            loggedPrayers: [],
            thresholdMinutes: 20,
            defaults: defaults
        )

        XCTAssertEqual(result, .fajr, "Should return earliest eligible prayer (Fajr)")
    }

    // MARK: - Fire Date Tests

    func test_nextEndingSoonFireDate_returnsCorrectDate() {
        // Now is 12:20 (Dhuhr just started at 12:15). Dhuhr window ends at 15:45.
        // Fire date = 15:45 - 20min = 15:25
        let now = dateAt(hour: 12, minute: 20)

        // Mark Fajr as already shown (its window already passed)
        PrayerToastService.markEndingSoonShown(for: .fajr, on: now, defaults: defaults)

        let fireDate = PrayerToastService.nextEndingSoonFireDate(
            now: now,
            schedule: schedule,
            loggedPrayers: [],
            thresholdMinutes: 20,
            defaults: defaults
        )

        let expected = dateAt(hour: 15, minute: 25)
        XCTAssertNotNil(fireDate)
        XCTAssertEqual(
            Int(fireDate!.timeIntervalSince1970),
            Int(expected.timeIntervalSince1970),
            "Fire date should be 20 min before Asr (Dhuhr window end)"
        )
    }

    func test_nextEndingSoonFireDate_allLogged_returnsNil() {
        let now = dateAt(hour: 14, minute: 0)

        let fireDate = PrayerToastService.nextEndingSoonFireDate(
            now: now,
            schedule: schedule,
            loggedPrayers: Set(PrayerType.obligatoryPrayers),
            thresholdMinutes: 20,
            defaults: defaults
        )

        XCTAssertNil(fireDate)
    }

    // MARK: - Daily Summary Tests

    func test_dailySummary_afterIshaWithLoggedPrayers_returnsCount() {
        let now = dateAt(hour: 20, minute: 30)

        let result = PrayerToastService.dailySummary(
            now: now,
            schedule: schedule,
            loggedCount: 3,
            defaults: defaults
        )

        XCTAssertEqual(result, 3)
    }

    func test_dailySummary_beforeIsha_returnsNil() {
        let now = dateAt(hour: 19, minute: 0)

        let result = PrayerToastService.dailySummary(
            now: now,
            schedule: schedule,
            loggedCount: 3,
            defaults: defaults
        )

        XCTAssertNil(result)
    }

    func test_dailySummary_zeroLogged_returnsNil() {
        let now = dateAt(hour: 20, minute: 30)

        let result = PrayerToastService.dailySummary(
            now: now,
            schedule: schedule,
            loggedCount: 0,
            defaults: defaults
        )

        XCTAssertNil(result, "Should skip 0 logged (discouraging)")
    }

    func test_dailySummary_fiveLogged_returnsNil() {
        let now = dateAt(hour: 20, minute: 30)

        let result = PrayerToastService.dailySummary(
            now: now,
            schedule: schedule,
            loggedCount: 5,
            defaults: defaults
        )

        XCTAssertNil(result, "Should skip 5 logged (redundant)")
    }

    func test_dailySummary_alreadyShown_returnsNil() {
        let now = dateAt(hour: 20, minute: 30)
        PrayerToastService.markDailySummaryShown(on: now, defaults: defaults)

        let result = PrayerToastService.dailySummary(
            now: now,
            schedule: schedule,
            loggedCount: 3,
            defaults: defaults
        )

        XCTAssertNil(result)
    }

    func test_dailySummary_dedupResetsNextDay() {
        let today = dateAt(hour: 20, minute: 30)
        PrayerToastService.markDailySummaryShown(on: today, defaults: defaults)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let tomorrowSchedule = makeSchedule(dayOffset: 1)

        let result = PrayerToastService.dailySummary(
            now: tomorrow,
            schedule: tomorrowSchedule,
            loggedCount: 2,
            defaults: defaults
        )

        XCTAssertEqual(result, 2, "Dedup should reset for a new day")
    }

    // MARK: - Fire Date (Daily Summary)

    func test_nextDailySummaryFireDate_beforeIsha_returnsIshaTime() {
        let now = dateAt(hour: 18, minute: 0)

        let fireDate = PrayerToastService.nextDailySummaryFireDate(
            now: now,
            schedule: schedule,
            defaults: defaults
        )

        let ishaTime = schedule.first(where: { $0.type == .isha })!.time
        XCTAssertEqual(fireDate, ishaTime)
    }

    func test_nextDailySummaryFireDate_afterIsha_returnsNow() {
        let now = dateAt(hour: 21, minute: 0)

        let fireDate = PrayerToastService.nextDailySummaryFireDate(
            now: now,
            schedule: schedule,
            defaults: defaults
        )

        XCTAssertEqual(fireDate, now)
    }

    func test_nextDailySummaryFireDate_alreadyShown_returnsNil() {
        let now = dateAt(hour: 18, minute: 0)
        PrayerToastService.markDailySummaryShown(on: now, defaults: defaults)

        let fireDate = PrayerToastService.nextDailySummaryFireDate(
            now: now,
            schedule: schedule,
            defaults: defaults
        )

        XCTAssertNil(fireDate)
    }

    // MARK: - Wudhu Reminder Tests

    func test_wudhuReminder_withinThreshold_returnsPrayer() {
        // Dhuhr at 12:15, now is 12:00 — 15 min before
        let now = dateAt(hour: 12, minute: 0)

        let result = PrayerToastService.wudhuReminder(
            now: now,
            schedule: schedule,
            thresholdMinutes: 15,
            defaults: defaults
        )

        XCTAssertEqual(result, .dhuhr)
    }

    func test_wudhuReminder_outsideThreshold_returnsNil() {
        // Dhuhr at 12:15, now is 11:30 — 45 min before, threshold 15
        let now = dateAt(hour: 11, minute: 30)

        let result = PrayerToastService.wudhuReminder(
            now: now,
            schedule: schedule,
            thresholdMinutes: 15,
            defaults: defaults
        )

        XCTAssertNil(result)
    }

    func test_wudhuReminder_alreadyShown_skips() {
        let now = dateAt(hour: 12, minute: 0)
        PrayerToastService.markWudhuShown(for: .dhuhr, on: now, defaults: defaults)

        let result = PrayerToastService.wudhuReminder(
            now: now,
            schedule: schedule,
            thresholdMinutes: 15,
            defaults: defaults
        )

        // Dhuhr already shown, next would be Asr but too far away
        XCTAssertNil(result)
    }

    func test_wudhuReminder_prayerAlreadyStarted_skips() {
        // Dhuhr at 12:15, now is 12:20 — prayer already started
        let now = dateAt(hour: 12, minute: 20)

        let result = PrayerToastService.wudhuReminder(
            now: now,
            schedule: schedule,
            thresholdMinutes: 15,
            defaults: defaults
        )

        // Dhuhr started, Asr at 15:45 is 3+ hours away
        XCTAssertNil(result)
    }

    func test_wudhuReminder_earliestPrayerFirst() {
        // Fajr at 5:30, now is 5:15 — 15 min before
        let now = dateAt(hour: 5, minute: 15)

        let result = PrayerToastService.wudhuReminder(
            now: now,
            schedule: schedule,
            thresholdMinutes: 20,
            defaults: defaults
        )

        XCTAssertEqual(result, .fajr, "Should return earliest eligible prayer")
    }

    func test_nextWudhuFireDate_returnsCorrectDate() {
        // Now is 10:00, next prayer is Dhuhr at 12:15
        // Fire date = 12:15 - 15min = 12:00
        let now = dateAt(hour: 10, minute: 0)

        // Mark Fajr as shown (already passed)
        PrayerToastService.markWudhuShown(for: .fajr, on: now, defaults: defaults)

        let fireDate = PrayerToastService.nextWudhuFireDate(
            now: now,
            schedule: schedule,
            thresholdMinutes: 15,
            defaults: defaults
        )

        let expected = dateAt(hour: 12, minute: 0)
        XCTAssertNotNil(fireDate)
        XCTAssertEqual(
            Int(fireDate!.timeIntervalSince1970),
            Int(expected.timeIntervalSince1970)
        )
    }

    func test_nextWudhuFireDate_allPassed_returnsNil() {
        // Now is 22:00, all prayers have started
        let now = dateAt(hour: 22, minute: 0)

        let fireDate = PrayerToastService.nextWudhuFireDate(
            now: now,
            schedule: schedule,
            thresholdMinutes: 15,
            defaults: defaults
        )

        XCTAssertNil(fireDate)
    }

    // MARK: - Pruning Tests

    func test_pruneStaleKeys_removesOldKeys() {
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let oldKey = "\(AppConstants.StorageKeys.prayerEndingSoonPrefix)_fajr_\(PrayerToastService.dayKey(for: threeDaysAgo))"
        defaults.set(true, forKey: oldKey)

        PrayerToastService.pruneStaleKeys(defaults: defaults)

        XCTAssertFalse(defaults.bool(forKey: oldKey), "Old key should be pruned")
    }

    func test_pruneStaleKeys_removesOldWudhuKeys() {
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let oldKey = "\(AppConstants.StorageKeys.wudhuReminderToastPrefix)_dhuhr_\(PrayerToastService.dayKey(for: threeDaysAgo))"
        defaults.set(true, forKey: oldKey)

        PrayerToastService.pruneStaleKeys(defaults: defaults)

        XCTAssertFalse(defaults.bool(forKey: oldKey), "Old wudhu key should be pruned")
    }

    func test_pruneStaleKeys_preservesTodayKeys() {
        let todayKey = "\(AppConstants.StorageKeys.prayerEndingSoonPrefix)_fajr_\(PrayerToastService.dayKey(for: Date()))"
        defaults.set(true, forKey: todayKey)

        PrayerToastService.pruneStaleKeys(defaults: defaults)

        XCTAssertTrue(defaults.bool(forKey: todayKey), "Today's key should be preserved")
    }

    // MARK: - Scheduler Helper Tests

    func test_shouldSchedule_returnsFalseWhenNoCoordinates() {
        let prefs = UserPreferences(
            prayerEndingSoonToastEnabled: true,
            dailyPrayerSummaryToastEnabled: true
        )
        XCTAssertFalse(PrayerToastService.shouldSchedule(prefs: prefs, coordinates: nil))
    }

    func test_shouldSchedule_returnsFalseWhenAllDisabled() {
        let prefs = UserPreferences(
            wudhuReminderEnabled: false,
            prayerEndingSoonToastEnabled: false,
            dailyPrayerSummaryToastEnabled: false
        )
        let coords = Coordinates(latitude: 51.5, longitude: -0.1)
        XCTAssertFalse(PrayerToastService.shouldSchedule(prefs: prefs, coordinates: coords))
    }

    func test_shouldSchedule_returnsTrueWhenEnabledWithCoordinates() {
        let prefs = UserPreferences(
            wudhuReminderEnabled: true,
            prayerEndingSoonToastEnabled: false,
            dailyPrayerSummaryToastEnabled: false
        )
        let coords = Coordinates(latitude: 51.5, longitude: -0.1)
        XCTAssertTrue(PrayerToastService.shouldSchedule(prefs: prefs, coordinates: coords))
    }

    // MARK: - Helpers

    /// Creates a schedule for today (or offset day) with fixed prayer times.
    private func makeSchedule(dayOffset: Int = 0) -> [PrayerTime] {
        let calendar = Calendar.current
        let base = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: Date()))!

        return [
            PrayerTime(type: .fajr, time: calendar.date(bySettingHour: 5, minute: 30, second: 0, of: base)!),
            PrayerTime(type: .sunrise, time: calendar.date(bySettingHour: 6, minute: 45, second: 0, of: base)!),
            PrayerTime(type: .dhuhr, time: calendar.date(bySettingHour: 12, minute: 15, second: 0, of: base)!),
            PrayerTime(type: .asr, time: calendar.date(bySettingHour: 15, minute: 45, second: 0, of: base)!),
            PrayerTime(type: .maghrib, time: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: base)!),
            PrayerTime(type: .isha, time: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: base)!)
        ]
    }

    /// Creates a Date for today at the given hour/minute.
    private func dateAt(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today)!
    }
}
