import XCTest
@testable import Safa

final class NotificationSchedulerHelpersTests: XCTestCase {

    // MARK: - Kill Switch (notificationsEnabled = false)

    func test_determineAction_cancelsAll_whenNotificationsDisabled() {
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: false,
            isAuthorized: true,
            lastScheduledDate: nil,
            isForceReschedule: false
        )
        XCTAssertEqual(action, .cancelAll)
    }

    func test_determineAction_cancelsAll_whenDisabled_evenIfNotAuthorized() {
        // Kill switch must fire even when system auth is revoked
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: false,
            isAuthorized: false,
            lastScheduledDate: nil,
            isForceReschedule: false
        )
        XCTAssertEqual(action, .cancelAll)
    }

    func test_determineAction_cancelsAll_whenDisabled_evenIfAlreadyScheduledToday() {
        // "Already scheduled today" must NOT bypass the kill switch
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: false,
            isAuthorized: true,
            lastScheduledDate: Date(),
            isForceReschedule: false
        )
        XCTAssertEqual(action, .cancelAll)
    }

    func test_determineAction_cancelsAll_whenDisabled_onForceReschedule() {
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: false,
            isAuthorized: true,
            lastScheduledDate: nil,
            isForceReschedule: true
        )
        XCTAssertEqual(action, .cancelAll)
    }

    // MARK: - Authorization

    func test_determineAction_skipsNotAuthorized_whenEnabledButNotAuthorized() {
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: true,
            isAuthorized: false,
            lastScheduledDate: nil,
            isForceReschedule: false
        )
        XCTAssertEqual(action, .skipNotAuthorized)
    }

    // MARK: - Daily Dedup

    func test_determineAction_skipsAlreadyScheduled_whenScheduledToday() {
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: true,
            isAuthorized: true,
            lastScheduledDate: Date(),
            isForceReschedule: false
        )
        XCTAssertEqual(action, .skipAlreadyScheduled)
    }

    func test_determineAction_schedules_whenForceReschedule_ignoresLastScheduledDate() {
        // forceReschedule must bypass the daily dedup
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: true,
            isAuthorized: true,
            lastScheduledDate: Date(),
            isForceReschedule: true
        )
        XCTAssertEqual(action, .schedule)
    }

    // MARK: - Happy Path

    func test_determineAction_schedules_whenEnabledAndAuthorizedAndNotScheduledToday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: true,
            isAuthorized: true,
            lastScheduledDate: yesterday,
            isForceReschedule: false
        )
        XCTAssertEqual(action, .schedule)
    }

    func test_determineAction_schedules_whenNeverScheduledBefore() {
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: true,
            isAuthorized: true,
            lastScheduledDate: nil,
            isForceReschedule: false
        )
        XCTAssertEqual(action, .schedule)
    }

    // MARK: - Notification Identifier

    func test_notificationIdentifier_includesDateSuffix() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2026, month: 2, day: 14))!

        let identifier = NotificationSchedulerHelpers.notificationIdentifier(for: .fajr, on: date)

        XCTAssertEqual(identifier, "prayer_at_fajr_2026-02-14")
    }

    func test_notificationIdentifier_uniquePerPrayerAndDate() {
        let calendar = Calendar.current
        let feb14 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 14))!
        let feb15 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 15))!

        let fajr14 = NotificationSchedulerHelpers.notificationIdentifier(for: .fajr, on: feb14)
        let fajr15 = NotificationSchedulerHelpers.notificationIdentifier(for: .fajr, on: feb15)
        let dhuhr14 = NotificationSchedulerHelpers.notificationIdentifier(for: .dhuhr, on: feb14)

        // Same prayer, different days → different identifiers
        XCTAssertNotEqual(fajr14, fajr15)
        // Different prayers, same day → different identifiers
        XCTAssertNotEqual(fajr14, dhuhr14)
    }

    func test_notificationIdentifier_allObligatoryPrayers() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let obligatory: [PrayerType] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

        let identifiers = obligatory.map {
            NotificationSchedulerHelpers.notificationIdentifier(for: $0, on: date)
        }

        // All must be unique
        XCTAssertEqual(identifiers.count, Set(identifiers).count)
        // All must contain the date
        for id in identifiers {
            XCTAssertTrue(id.contains("2026-03-01"), "Identifier '\(id)' should contain date")
        }
    }

    // MARK: - Prayer Filtering

    func test_prayersToSchedule_filtersNonObligatory() {
        let now = Date()
        let future = now.addingTimeInterval(3600) // 1 hour from now

        let prayers = [
            PrayerTime(type: .fajr, time: future),
            PrayerTime(type: .sunrise, time: future), // non-obligatory
            PrayerTime(type: .dhuhr, time: future)
        ]
        let enabled: Set<PrayerType> = [.fajr, .sunrise, .dhuhr]

        let result = NotificationSchedulerHelpers.prayersToSchedule(
            from: prayers, enabledPrayers: enabled, after: now
        )

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.type.isObligatory })
        XCTAssertFalse(result.contains(where: { $0.type == .sunrise }))
    }

    func test_prayersToSchedule_filtersDisabledPrayers() {
        let now = Date()
        let future = now.addingTimeInterval(3600)

        let prayers = [
            PrayerTime(type: .fajr, time: future),
            PrayerTime(type: .dhuhr, time: future),
            PrayerTime(type: .asr, time: future),
            PrayerTime(type: .maghrib, time: future),
            PrayerTime(type: .isha, time: future)
        ]
        // User only wants fajr and isha
        let enabled: Set<PrayerType> = [.fajr, .isha]

        let result = NotificationSchedulerHelpers.prayersToSchedule(
            from: prayers, enabledPrayers: enabled, after: now
        )

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(Set(result.map(\.type)), [.fajr, .isha])
    }

    func test_prayersToSchedule_filtersPastPrayers() {
        let now = Date()
        let past = now.addingTimeInterval(-3600) // 1 hour ago
        let future = now.addingTimeInterval(3600)

        let prayers = [
            PrayerTime(type: .fajr, time: past),    // already passed
            PrayerTime(type: .dhuhr, time: past),    // already passed
            PrayerTime(type: .asr, time: future),    // still upcoming
            PrayerTime(type: .maghrib, time: future),
            PrayerTime(type: .isha, time: future)
        ]
        let enabled: Set<PrayerType> = Set(PrayerType.obligatoryPrayers)

        let result = NotificationSchedulerHelpers.prayersToSchedule(
            from: prayers, enabledPrayers: enabled, after: now
        )

        XCTAssertEqual(result.count, 3)
        XCTAssertFalse(result.contains(where: { $0.type == .fajr }))
        XCTAssertFalse(result.contains(where: { $0.type == .dhuhr }))
    }

    func test_prayersToSchedule_returnsEmpty_whenAllPast() {
        let now = Date()
        let past = now.addingTimeInterval(-3600)

        let prayers = PrayerType.obligatoryPrayers.map {
            PrayerTime(type: $0, time: past)
        }
        let enabled: Set<PrayerType> = Set(PrayerType.obligatoryPrayers)

        let result = NotificationSchedulerHelpers.prayersToSchedule(
            from: prayers, enabledPrayers: enabled, after: now
        )

        XCTAssertTrue(result.isEmpty)
    }

    func test_prayersToSchedule_returnsEmpty_whenNoEnabledPrayers() {
        let now = Date()
        let future = now.addingTimeInterval(3600)

        let prayers = PrayerType.obligatoryPrayers.map {
            PrayerTime(type: $0, time: future)
        }
        let enabled: Set<PrayerType> = []

        let result = NotificationSchedulerHelpers.prayersToSchedule(
            from: prayers, enabledPrayers: enabled, after: now
        )

        XCTAssertTrue(result.isEmpty)
    }

    func test_prayersToSchedule_exactBoundary_excludesPrayerAtExactlyNow() {
        let now = Date()
        // Prayer at exactly `now` should NOT be scheduled (> now, not >= now)
        let prayers = [PrayerTime(type: .fajr, time: now)]
        let enabled: Set<PrayerType> = [.fajr]

        let result = NotificationSchedulerHelpers.prayersToSchedule(
            from: prayers, enabledPrayers: enabled, after: now
        )

        XCTAssertTrue(result.isEmpty, "Prayer at exactly 'now' should be excluded (strict >)")
    }

    // MARK: - Cancel Logic (Identifier Matching)

    func test_isPrayerNotificationIdentifier_currentFormat() {
        XCTAssertTrue(
            NotificationSchedulerHelpers.isPrayerNotificationIdentifier("prayer_at_fajr_2026-02-14")
        )
    }

    func test_isPrayerNotificationIdentifier_legacyFormat_prayerAt() {
        XCTAssertTrue(
            NotificationSchedulerHelpers.isPrayerNotificationIdentifier("prayer_at_fajr")
        )
    }

    func test_isPrayerNotificationIdentifier_legacyFormat_prayerBefore() {
        XCTAssertTrue(
            NotificationSchedulerHelpers.isPrayerNotificationIdentifier("prayer_before_dhuhr")
        )
    }

    func test_isPrayerNotificationIdentifier_legacyFormat_prayerUnderscore() {
        // Legacy format: prayer_fajr (from old PrayerViewModel)
        XCTAssertTrue(
            NotificationSchedulerHelpers.isPrayerNotificationIdentifier("prayer_fajr")
        )
    }

    func test_isPrayerNotificationIdentifier_legacyFormat_timestampBased() {
        // Legacy format: prayer_fajr_1707234000.123
        XCTAssertTrue(
            NotificationSchedulerHelpers.isPrayerNotificationIdentifier("prayer_fajr_1707234000.123")
        )
    }

    func test_isPrayerNotificationIdentifier_rejectsNonPrayer() {
        XCTAssertFalse(
            NotificationSchedulerHelpers.isPrayerNotificationIdentifier("streak_reminder_prayer")
        )
        XCTAssertFalse(
            NotificationSchedulerHelpers.isPrayerNotificationIdentifier("general_reminder_123")
        )
        XCTAssertFalse(
            NotificationSchedulerHelpers.isPrayerNotificationIdentifier("morning_dhikr_reminder")
        )
        XCTAssertFalse(
            NotificationSchedulerHelpers.isPrayerNotificationIdentifier("suhoor_reminder")
        )
    }

    func test_prayerNotificationIdentifiers_filtersCorrectly() {
        let allIDs = [
            "prayer_at_fajr_2026-02-14",
            "prayer_at_dhuhr_2026-02-14",
            "streak_reminder_prayer",
            "general_reminder_123",
            "prayer_before_asr",
            "morning_dhikr_reminder",
            "prayer_fajr_1707234000.123"
        ]

        let filtered = NotificationSchedulerHelpers.prayerNotificationIdentifiers(from: allIDs)

        XCTAssertEqual(filtered.count, 4)
        XCTAssertTrue(filtered.contains("prayer_at_fajr_2026-02-14"))
        XCTAssertTrue(filtered.contains("prayer_at_dhuhr_2026-02-14"))
        XCTAssertTrue(filtered.contains("prayer_before_asr"))
        XCTAssertTrue(filtered.contains("prayer_fajr_1707234000.123"))
        XCTAssertFalse(filtered.contains("streak_reminder_prayer"))
    }

    // MARK: - Date Range

    func test_scheduleDates_returns14Days() {
        let today = Date()
        let dates = NotificationSchedulerHelpers.scheduleDates(from: today, daysAhead: 14)

        XCTAssertEqual(dates.count, 14)
    }

    func test_scheduleDates_startsFromStartOfDay() {
        let calendar = Calendar.current
        // Pass a date at 3 PM — result should start at midnight
        let afternoon = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: Date())!

        let dates = NotificationSchedulerHelpers.scheduleDates(from: afternoon, daysAhead: 3)

        for date in dates {
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            XCTAssertEqual(hour, 0, "Date should start at midnight")
            XCTAssertEqual(minute, 0, "Date should start at midnight")
        }
    }

    func test_scheduleDates_consecutiveDays() {
        let calendar = Calendar.current
        let dates = NotificationSchedulerHelpers.scheduleDates(from: Date(), daysAhead: 14)

        for i in 1..<dates.count {
            let diff = calendar.dateComponents([.day], from: dates[i - 1], to: dates[i])
            XCTAssertEqual(diff.day, 1, "Days should be consecutive")
        }
    }

    func test_scheduleDates_zeroDays_returnsEmpty() {
        let dates = NotificationSchedulerHelpers.scheduleDates(from: Date(), daysAhead: 0)
        XCTAssertTrue(dates.isEmpty)
    }

    func test_scheduleDates_oneDay_returnsToday() {
        let calendar = Calendar.current
        let dates = NotificationSchedulerHelpers.scheduleDates(from: Date(), daysAhead: 1)

        XCTAssertEqual(dates.count, 1)
        XCTAssertTrue(calendar.isDateInToday(dates[0]))
    }

    // MARK: - Background Refresh Date

    func test_nextBackgroundRefreshDate_beforeTwoAM_returnsTodayTwoAM() {
        let calendar = Calendar.current
        // 1:00 AM today
        let oneAM = calendar.date(bySettingHour: 1, minute: 0, second: 0, of: Date())!

        let result = NotificationSchedulerHelpers.nextBackgroundRefreshDate(after: oneAM)

        let components = calendar.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(components.hour, 2)
        XCTAssertEqual(components.minute, 0)
        // Should be today (same day as input)
        XCTAssertTrue(calendar.isDate(result, inSameDayAs: oneAM))
    }

    func test_nextBackgroundRefreshDate_afterTwoAM_returnsTomorrowTwoAM() {
        let calendar = Calendar.current
        // 10:00 AM today
        let tenAM = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!

        let result = NotificationSchedulerHelpers.nextBackgroundRefreshDate(after: tenAM)

        let components = calendar.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(components.hour, 2)
        XCTAssertEqual(components.minute, 0)
        // Should be tomorrow
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: tenAM)!
        XCTAssertTrue(calendar.isDate(result, inSameDayAs: tomorrow))
    }

    func test_nextBackgroundRefreshDate_atExactlyTwoAM_returnsTomorrowTwoAM() {
        let calendar = Calendar.current
        let twoAM = calendar.date(bySettingHour: 2, minute: 0, second: 0, of: Date())!

        let result = NotificationSchedulerHelpers.nextBackgroundRefreshDate(after: twoAM)

        // At exactly 2 AM, `twoAMToday > now` is false, so it should schedule tomorrow
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: twoAM)!
        XCTAssertTrue(calendar.isDate(result, inSameDayAs: tomorrow))
    }

    func test_nextBackgroundRefreshDate_atMidnight_returnsTodayTwoAM() {
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date())

        let result = NotificationSchedulerHelpers.nextBackgroundRefreshDate(after: midnight)

        let components = calendar.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(components.hour, 2)
        XCTAssertEqual(components.minute, 0)
        XCTAssertTrue(calendar.isDate(result, inSameDayAs: midnight))
    }

    func test_nextBackgroundRefreshDate_at1159PM_returnsTomorrowTwoAM() {
        let calendar = Calendar.current
        let lateNight = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: Date())!

        let result = NotificationSchedulerHelpers.nextBackgroundRefreshDate(after: lateNight)

        let components = calendar.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(components.hour, 2)
        XCTAssertEqual(components.minute, 0)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: lateNight)!
        XCTAssertTrue(calendar.isDate(result, inSameDayAs: tomorrow))
    }

    func test_nextBackgroundRefreshDate_alwaysInFuture() {
        let now = Date()
        let result = NotificationSchedulerHelpers.nextBackgroundRefreshDate(after: now)
        XCTAssertTrue(result > now, "Background refresh date must be in the future")
    }

    // MARK: - Multi-Day Integration (Identifier Uniqueness Across Days)

    func test_14DaysOfIdentifiers_areAllUnique() {
        let dates = NotificationSchedulerHelpers.scheduleDates(from: Date(), daysAhead: 14)
        let obligatory: [PrayerType] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

        var allIdentifiers: [String] = []
        for date in dates {
            for prayer in obligatory {
                allIdentifiers.append(
                    NotificationSchedulerHelpers.notificationIdentifier(for: prayer, on: date)
                )
            }
        }

        // 14 days × 5 prayers = 70 unique identifiers
        XCTAssertEqual(allIdentifiers.count, 70)
        XCTAssertEqual(Set(allIdentifiers).count, 70, "All identifiers must be unique across 14 days")
    }

    func test_allGeneratedIdentifiers_matchPrayerPrefix() {
        let dates = NotificationSchedulerHelpers.scheduleDates(from: Date(), daysAhead: 14)
        let obligatory: [PrayerType] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

        for date in dates {
            for prayer in obligatory {
                let id = NotificationSchedulerHelpers.notificationIdentifier(for: prayer, on: date)
                XCTAssertTrue(
                    NotificationSchedulerHelpers.isPrayerNotificationIdentifier(id),
                    "Generated identifier '\(id)' must be recognized as a prayer notification"
                )
            }
        }
    }

    // MARK: - Wudhu Notification Identifier

    func test_wudhuIdentifier_format() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 14))!
        let identifier = NotificationSchedulerHelpers.wudhuNotificationIdentifier(for: .fajr, on: date)
        XCTAssertEqual(identifier, "prayer_wudhu_fajr_2026-02-14")
    }

    func test_wudhuIdentifier_matchesPrayerPrefix() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 14))!
        let identifier = NotificationSchedulerHelpers.wudhuNotificationIdentifier(for: .dhuhr, on: date)
        XCTAssertTrue(
            NotificationSchedulerHelpers.isPrayerNotificationIdentifier(identifier),
            "Wudhu identifier '\(identifier)' must start with prayer_ for cancellation coverage"
        )
    }

    // MARK: - Wudhu Prayer Filtering

    func test_wudhuPrayersToSchedule_filtersDisabledPrayers() {
        let now = Date()
        let future = now.addingTimeInterval(3600) // 1 hour from now

        let prayers = PrayerType.obligatoryPrayers.map { PrayerTime(type: $0, time: future) }
        let enabled: Set<PrayerType> = [.fajr, .isha]

        let result = NotificationSchedulerHelpers.wudhuPrayersToSchedule(
            from: prayers, enabledPrayers: enabled, minutesBefore: 15, after: now
        )

        XCTAssertEqual(Set(result.map(\.type)), [.fajr, .isha])
    }

    func test_wudhuPrayersToSchedule_filtersPastReminders() {
        let now = Date()
        // Prayer is 5 minutes away, but wudhu offset is 15 min → reminder time is in the past
        let fiveMinAway = now.addingTimeInterval(5 * 60)
        let prayers = [PrayerTime(type: .fajr, time: fiveMinAway)]
        let enabled: Set<PrayerType> = [.fajr]

        let result = NotificationSchedulerHelpers.wudhuPrayersToSchedule(
            from: prayers, enabledPrayers: enabled, minutesBefore: 15, after: now
        )

        XCTAssertTrue(result.isEmpty, "Reminder time already passed — should be excluded")
    }

    func test_wudhuPrayersToSchedule_includesUpcomingReminders() {
        let now = Date()
        // Prayer 30 minutes away, wudhu offset 15 min → reminder 15 min from now → future
        let thirtyMinAway = now.addingTimeInterval(30 * 60)
        let prayers = [PrayerTime(type: .asr, time: thirtyMinAway)]
        let enabled: Set<PrayerType> = [.asr]

        let result = NotificationSchedulerHelpers.wudhuPrayersToSchedule(
            from: prayers, enabledPrayers: enabled, minutesBefore: 15, after: now
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.type, .asr)
    }

    func test_wudhuPrayersToSchedule_filtersNonObligatory() {
        let now = Date()
        let future = now.addingTimeInterval(3600)
        let prayers = [
            PrayerTime(type: .sunrise, time: future),
            PrayerTime(type: .fajr, time: future)
        ]
        let enabled: Set<PrayerType> = [.sunrise, .fajr]

        let result = NotificationSchedulerHelpers.wudhuPrayersToSchedule(
            from: prayers, enabledPrayers: enabled, minutesBefore: 15, after: now
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.type, .fajr)
    }

    // MARK: - Effective Days Ahead

    func test_effectiveDaysAhead_allPrayersNoWudhu() {
        // 5 prayers / day → 64 / 5 = 12
        let days = NotificationSchedulerHelpers.effectiveDaysAhead(enabledPrayerCount: 5, wudhuEnabled: false)
        XCTAssertEqual(days, 12)
    }

    func test_effectiveDaysAhead_allPrayersWithWudhu() {
        // 5 prayers × 2 = 10 / day → 64 / 10 = 6
        let days = NotificationSchedulerHelpers.effectiveDaysAhead(enabledPrayerCount: 5, wudhuEnabled: true)
        XCTAssertEqual(days, 6)
    }

    func test_effectiveDaysAhead_twoPrayersWithWudhu() {
        // 2 prayers × 2 = 4 / day → 64 / 4 = 16 → capped at 14
        let days = NotificationSchedulerHelpers.effectiveDaysAhead(enabledPrayerCount: 2, wudhuEnabled: true)
        XCTAssertEqual(days, 14)
    }

    func test_effectiveDaysAhead_zeroPrayers() {
        let days = NotificationSchedulerHelpers.effectiveDaysAhead(enabledPrayerCount: 0, wudhuEnabled: false)
        XCTAssertEqual(days, 14)
    }
}
