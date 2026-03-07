// MARK: - WidgetPrayerStateTests.swift
// PURPOSE: Tests for contextual widget state machine

import XCTest
@testable import SafaShared

final class WidgetPrayerStateTests: XCTestCase {

    // MARK: - Helpers

    private let prayerIds = ["fajr", "dhuhr", "asr", "maghrib", "isha"]

    private func makePrayers(relativeTo now: Date = Date()) -> [PrayerInfo] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let times: [(String, String, Int, Int)] = [
            ("fajr", "Fajr", 5, 0),
            ("dhuhr", "Dhuhr", 12, 30),
            ("asr", "Asr", 15, 45),
            ("maghrib", "Maghrib", 18, 30),
            ("isha", "Isha", 20, 0)
        ]
        return times.map { id, name, h, m in
            PrayerInfo(id: id, name: name, time: cal.date(bySettingHour: h, minute: m, second: 0, of: today)!)
        }
    }

    private func date(hour: Int, minute: Int, relativeTo prayers: [PrayerInfo]) -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: prayers[0].time)
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: today)!
    }

    // MARK: - Pre-Adhan State

    func test_preAdhan_beforeAnyPrayer() {
        let prayers = makePrayers()
        let now = date(hour: 4, minute: 0, relativeTo: prayers)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .preAdhan(prayerName: "Fajr", prayerTime: prayers[0].time, prayerId: "fajr"))
    }

    func test_preAdhan_betweenPrayers() {
        let prayers = makePrayers()
        // 11:00 — well past Fajr's 45min window, before Dhuhr
        let now = date(hour: 11, minute: 0, relativeTo: prayers)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .preAdhan(prayerName: "Dhuhr", prayerTime: prayers[1].time, prayerId: "dhuhr"))
    }

    // MARK: - Prayer Window State (0–15 min, unlogged)

    func test_prayerWindow_atExactPrayerTime() {
        let prayers = makePrayers()
        let now = prayers[1].time // Exactly at Dhuhr

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .prayerWindow(prayerName: "Dhuhr", prayerTime: prayers[1].time, prayerId: "dhuhr"))
    }

    func test_prayerWindow_fiveMinutesAfterPrayer() {
        let prayers = makePrayers()
        let now = prayers[2].time.addingTimeInterval(5 * 60) // Asr + 5min

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .prayerWindow(prayerName: "Asr", prayerTime: prayers[2].time, prayerId: "asr"))
    }

    func test_prayerWindow_fourteenMinutesAfterPrayer() {
        let prayers = makePrayers()
        let now = prayers[0].time.addingTimeInterval(14 * 60) // Fajr + 14min

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .prayerWindow(prayerName: "Fajr", prayerTime: prayers[0].time, prayerId: "fajr"))
    }

    // MARK: - Post-Prayer State (logged in grace window)

    func test_postPrayer_loggedDuringGrace() {
        let prayers = makePrayers()
        let now = prayers[1].time.addingTimeInterval(5 * 60) // Dhuhr + 5min

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: ["dhuhr"], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .postPrayer(prayerId: "dhuhr"))
    }

    func test_postPrayer_loggedAfterGrace() {
        let prayers = makePrayers()
        // Dhuhr + 20 min — past grace, but logged and within 45 min window
        let now = prayers[1].time.addingTimeInterval(20 * 60)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: ["dhuhr"], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .postPrayer(prayerId: "dhuhr"))
    }

    func test_postPrayer_expiresAfter45Minutes() {
        let prayers = makePrayers()
        // Fajr + 46 min — past the 45 min post-prayer window
        let now = prayers[0].time.addingTimeInterval(46 * 60)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: ["fajr"], streakCount: 0, at: now
        )

        // Should fall through to pre-adhan for Dhuhr
        XCTAssertEqual(state, .preAdhan(prayerName: "Dhuhr", prayerTime: prayers[1].time, prayerId: "dhuhr"))
    }

    // MARK: - Grace Prompt State (15–30 min, unlogged)

    func test_gracePrompt_fifteenMinutesAfterPrayer() {
        let prayers = makePrayers()
        let now = prayers[2].time.addingTimeInterval(15 * 60) // Asr + 15min (grace just ended)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .gracePrompt(prayerName: "Asr", prayerId: "asr"))
    }

    func test_gracePrompt_twentyFiveMinutesAfterPrayer() {
        let prayers = makePrayers()
        let now = prayers[3].time.addingTimeInterval(25 * 60) // Maghrib + 25min

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .gracePrompt(prayerName: "Maghrib", prayerId: "maghrib"))
    }

    func test_gracePrompt_expiresAtThirtyMinutes() {
        let prayers = makePrayers()
        // Asr + 31 min — past grace prompt window
        let now = prayers[2].time.addingTimeInterval(31 * 60)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        // Should fall through to pre-adhan for Maghrib
        XCTAssertEqual(state, .preAdhan(prayerName: "Maghrib", prayerTime: prayers[3].time, prayerId: "maghrib"))
    }

    // MARK: - Imminent Pre-Adhan Priority

    func test_postPrayer_yieldsToPreadhanWhenNextPrayerImminent() {
        let prayers = makePrayers()
        // Asr at 15:45, Maghrib at 18:30
        // Set now = Asr + 20 min = 16:05 — logged, within 45 min
        // But that's hours before Maghrib, so postPrayer should win
        let now = prayers[2].time.addingTimeInterval(20 * 60)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: ["asr"], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .postPrayer(prayerId: "asr"))
    }

    func test_postPrayer_yieldsToPreadhanWhenNextPrayerWithin15Min() {
        // Create prayers where Dhuhr is at 12:30 and Asr is at 12:55 (25 min gap)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let prayers = [
            PrayerInfo(id: "fajr", name: "Fajr", time: cal.date(bySettingHour: 5, minute: 0, second: 0, of: today)!),
            PrayerInfo(id: "dhuhr", name: "Dhuhr", time: cal.date(bySettingHour: 12, minute: 30, second: 0, of: today)!),
            PrayerInfo(id: "asr", name: "Asr", time: cal.date(bySettingHour: 12, minute: 55, second: 0, of: today)!),
            PrayerInfo(id: "maghrib", name: "Maghrib", time: cal.date(bySettingHour: 18, minute: 30, second: 0, of: today)!),
            PrayerInfo(id: "isha", name: "Isha", time: cal.date(bySettingHour: 20, minute: 0, second: 0, of: today)!)
        ]

        // Dhuhr + 20 min = 12:50. Asr at 12:55 is only 5 min away → imminent
        let now = prayers[1].time.addingTimeInterval(20 * 60)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: ["dhuhr"], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .preAdhan(prayerName: "Asr", prayerTime: prayers[2].time, prayerId: "asr"))
    }

    // MARK: - All Complete State

    func test_allComplete_allPrayersLoggedAndPast() {
        let prayers = makePrayers()
        let now = date(hour: 23, minute: 0, relativeTo: prayers) // Late night

        let allLogged: Set<String> = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: allLogged, streakCount: 7, at: now
        )

        XCTAssertEqual(state, .allComplete(streakCount: 7))
    }

    func test_allComplete_withZeroStreak() {
        let prayers = makePrayers()
        let now = date(hour: 23, minute: 0, relativeTo: prayers)

        let allLogged: Set<String> = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: allLogged, streakCount: 0, at: now
        )

        XCTAssertEqual(state, .allComplete(streakCount: 0))
    }

    // MARK: - Day Ended State

    func test_dayEnded_allPrayersPastSomeNotLogged() {
        let prayers = makePrayers()
        let now = date(hour: 23, minute: 0, relativeTo: prayers)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: ["fajr", "asr"], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .dayEnded)
    }

    func test_dayEnded_noPrayersLogged() {
        let prayers = makePrayers()
        let now = date(hour: 23, minute: 0, relativeTo: prayers)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .dayEnded)
    }

    // MARK: - Boundary Conditions

    func test_exactlyAtGraceEnd_transitionsToGracePrompt() {
        let prayers = makePrayers()
        // Exactly 15 min after Dhuhr = grace boundary
        let now = prayers[1].time.addingTimeInterval(15 * 60)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .gracePrompt(prayerName: "Dhuhr", prayerId: "dhuhr"))
    }

    func test_exactlyAtGracePromptEnd_fallsToPreAdhan() {
        let prayers = makePrayers()
        // Exactly 30 min after Dhuhr = grace prompt boundary
        let now = prayers[1].time.addingTimeInterval(30 * 60)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        // 30 min past = gracePromptEnd (15+15), elapsed < gracePromptEnd is false
        // Falls through to preAdhan for Asr
        XCTAssertEqual(state, .preAdhan(prayerName: "Asr", prayerTime: prayers[2].time, prayerId: "asr"))
    }

    func test_exactlyAt45MinPostPrayer_fallsToPreAdhan() {
        let prayers = makePrayers()
        // Exactly 45 min after Fajr
        let now = prayers[0].time.addingTimeInterval(45 * 60)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: ["fajr"], streakCount: 0, at: now
        )

        // 45 min = postPrayerInterval, elapsed < postPrayerInterval is false
        XCTAssertEqual(state, .preAdhan(prayerName: "Dhuhr", prayerTime: prayers[1].time, prayerId: "dhuhr"))
    }

    // MARK: - Empty/Edge Cases

    func test_emptyPrayers_returnsDayEnded() {
        let state = WidgetPrayerStateResolver.resolve(
            prayers: [], loggedPrayerIds: [], streakCount: 0, at: Date()
        )

        XCTAssertEqual(state, .dayEnded)
    }

    func test_allPrayersInFuture_returnsPreAdhanForFirst() {
        let now = Date()
        let prayers = [
            PrayerInfo(id: "fajr", name: "Fajr", time: now.addingTimeInterval(3600)),
            PrayerInfo(id: "dhuhr", name: "Dhuhr", time: now.addingTimeInterval(7200)),
        ]

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .preAdhan(prayerName: "Fajr", prayerTime: prayers[0].time, prayerId: "fajr"))
    }

    // MARK: - Isha (Last Prayer) Edge Cases

    func test_isha_prayerWindow_noFuturePrayersExist() {
        let prayers = makePrayers()
        // Isha at 20:00, now = 20:05 — in grace, no future prayers
        let now = prayers[4].time.addingTimeInterval(5 * 60)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .prayerWindow(prayerName: "Isha", prayerTime: prayers[4].time, prayerId: "isha"))
    }

    func test_isha_gracePrompt_noFuturePrayersExist() {
        let prayers = makePrayers()
        // Isha at 20:00, now = 20:20 — past grace, in prompt window
        let now = prayers[4].time.addingTimeInterval(20 * 60)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .gracePrompt(prayerName: "Isha", prayerId: "isha"))
    }

    func test_isha_postPrayer_loggedAndNoFuturePrayers() {
        let prayers = makePrayers()
        // Isha at 20:00, now = 20:25 — logged, within 45 min, no future prayers
        let now = prayers[4].time.addingTimeInterval(25 * 60)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: ["isha"], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .postPrayer(prayerId: "isha"))
    }

    func test_isha_postPrayer_expires_thenDayEnded() {
        let prayers = makePrayers()
        // Isha at 20:00, now = 20:50 — past 45 min window, not all logged
        let now = prayers[4].time.addingTimeInterval(50 * 60)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: ["isha"], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .dayEnded)
    }

    func test_isha_postPrayer_expires_thenAllComplete() {
        let prayers = makePrayers()
        // Isha at 20:00, now = 20:50 — past 45 min window, all logged
        let now = prayers[4].time.addingTimeInterval(50 * 60)

        let allLogged: Set<String> = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: allLogged, streakCount: 5, at: now
        )

        XCTAssertEqual(state, .allComplete(streakCount: 5))
    }

    // MARK: - 30-45 min Unlogged Dead Zone

    func test_unlogged_at35MinAfterPrayer_fallsToPreAdhan() {
        let prayers = makePrayers()
        // Dhuhr at 12:30, now = 13:05 — 35 min past, unlogged
        // Past grace prompt (30 min), past grace (15 min)
        // Should fall through to preAdhan for Asr
        let now = prayers[1].time.addingTimeInterval(35 * 60)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .preAdhan(prayerName: "Asr", prayerTime: prayers[2].time, prayerId: "asr"))
    }

    func test_unlogged_at40MinAfterIsha_dayEnded() {
        let prayers = makePrayers()
        // Isha at 20:00, now = 20:40 — 40 min past, unlogged, no future prayers
        let now = prayers[4].time.addingTimeInterval(40 * 60)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers, loggedPrayerIds: [], streakCount: 0, at: now
        )

        XCTAssertEqual(state, .dayEnded)
    }

    // MARK: - Timeline Boundary Tests

    func test_contextualBoundaries_includesPostPrayerExpiry() {
        let calculator = NextPrayerCalculator()
        let now = Date()
        let prayers = [
            PrayerInfo(id: "fajr", name: "Fajr", time: now.addingTimeInterval(3600)),
        ]

        let boundaries = calculator.contextualTimelineBoundaries(from: prayers, startingAt: now)

        // Should include: now, prayer time, +15m, +30m, +45m
        XCTAssertEqual(boundaries.count, 5)
        XCTAssertEqual(boundaries[0], now)
        XCTAssertEqual(boundaries[1], prayers[0].time)
        XCTAssertEqual(boundaries[2], prayers[0].time.addingTimeInterval(15 * 60))
        XCTAssertEqual(boundaries[3], prayers[0].time.addingTimeInterval(30 * 60))
        XCTAssertEqual(boundaries[4], prayers[0].time.addingTimeInterval(45 * 60))
    }
}
