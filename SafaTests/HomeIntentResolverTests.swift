// MARK: - HomeIntentResolverTests.swift
// PURPOSE: Tests for HomeIntentResolver context-aware quick action prioritization
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class HomeIntentResolverTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a date at the given hour on a neutral day (Wed Jan 15 2025 — Rajab 15, 1446).
    /// No seasonal promotions apply: not Ramadan, not Dhul Hijjah, not Friday/Monday/Thursday.
    private func neutralDate(hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.hour = hour
        components.minute = minute
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    /// Creates a date at the given hour on a specific Gregorian date.
    private func dateOn(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    private func prayerTime(type: PrayerType, at date: Date) -> PrayerTime {
        PrayerTime(type: type, time: date)
    }

    private func streakAtRisk(_ type: StreakType, count: Int) -> Streak {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        return Streak(type: type, currentCount: count, longestCount: count, lastActivityDate: twoDaysAgo)
    }

    // MARK: - Always Returns 2 Items

    func test_resolve_alwaysReturnsTwoActions() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 10))
        XCTAssertEqual(actions.count, 2)
    }

    func test_resolve_withAllInputs_returnsTwoActions() {
        let now = neutralDate(hour: 12, minute: 30)
        let actions = HomeIntentResolver.resolve(
            currentDate: now,
            nextPrayer: prayerTime(type: .dhuhr, at: neutralDate(hour: 12, minute: 45)),
            loggedPrayers: [.fajr],
            streaks: [streakAtRisk(.dhikr, count: 10)]
        )
        XCTAssertEqual(actions.count, 2)
    }

    // MARK: - Tab Bar Actions Not in Default Grid

    func test_resolve_neutralDay_noTabBarActionsInGrid() {
        // Prayer, Quran, and Duas are accessible via tab bar — should not appear in default grid
        for hour in [0, 10, 15, 22] {
            let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: hour))
            let ids = actions.map { $0.id }
            XCTAssertFalse(ids.contains("prayer"), "Prayer should not be in default grid at hour \(hour)")
            XCTAssertFalse(ids.contains("quran"), "Quran should not be in default grid at hour \(hour)")
            XCTAssertFalse(ids.contains("duas"), "Duas should not be in default grid at hour \(hour)")
        }
    }

    // MARK: - Prayer Not in Quick Actions (Tab Bar Item)

    func test_resolve_prayerNeverInGrid() {
        // Prayer is always accessible via tab bar — never in quick actions, even when imminent
        let now = neutralDate(hour: 10, minute: 0)
        let prayerSoon = prayerTime(type: .dhuhr, at: neutralDate(hour: 10, minute: 20))

        let actions = HomeIntentResolver.resolve(
            currentDate: now,
            nextPrayer: prayerSoon
        )

        let ids = actions.map { $0.id }
        XCTAssertFalse(ids.contains("prayer"), "Prayer should never appear — it's a tab bar item")
        XCTAssertEqual(actions.count, 2, "Should return exactly 2 quick actions")
    }

    // MARK: - Morning Defaults (Neutral Day)

    func test_resolve_morning_dhikrFirst() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 7))
        XCTAssertEqual(actions.first?.id, "dhikr")
    }

    func test_resolve_morning_defaultOrder() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 6))
        let ids = actions.map { $0.id }
        XCTAssertEqual(ids, ["dhikr", "hadith"])
    }

    // MARK: - Afternoon Defaults (Neutral Day)

    func test_resolve_afternoon_hadithFirst() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 15))
        XCTAssertEqual(actions.first?.id, "hadith")
    }

    // MARK: - Evening Defaults (Neutral Day)

    func test_resolve_evening_dhikrFirst() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 18))
        let ids = actions.map { $0.id }
        XCTAssertEqual(ids[0], "dhikr")
        XCTAssertEqual(ids[1], "hadith")
    }

    // MARK: - Night Defaults (Neutral Day)

    func test_resolve_night_dhikrFirst() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 22))
        XCTAssertEqual(actions.first?.id, "dhikr")
    }

    // MARK: - Non-Tab Features in Grid

    func test_resolve_onlyNonTabFeaturesInGrid() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 10))
        let ids = Set(actions.map { $0.id })
        let tabBarIds: Set<String> = ["prayer", "quran", "duas"]
        XCTAssertTrue(ids.isDisjoint(with: tabBarIds), "Grid should only contain non-tab-bar features")
    }

    // MARK: - Ask Safa Availability

    func test_resolve_aiUnavailable_askSafaExcluded() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 10), isAIAvailable: false)
        let ids = actions.map { $0.id }
        XCTAssertFalse(ids.contains("askSafa"), "Ask Safa should not appear when AI is unavailable")
    }

    func test_resolve_aiAvailable_askSafaInPool() {
        // Ask Safa is in the time-based pool when AI is available
        let allCandidates = HomeIntentResolver.timeBasedDefaults(hour: 10)
        XCTAssertTrue(allCandidates.contains { $0.id == "askSafa" }, "Ask Safa should be in candidate pool")
    }

    func test_resolve_aiUnavailable_askSafaFilteredFromDefaults() {
        // Even though timeBasedDefaults includes askSafa, resolve filters it out
        // At hour 10 defaults: [hadith, dhikr, askSafa, qibla]
        // With AI unavailable and no streaks, top 2 = hadith + dhikr (askSafa skipped)
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 10), isAIAvailable: false)
        let ids = actions.map { $0.id }
        XCTAssertEqual(ids, ["hadith", "dhikr"])
    }

    func test_resolve_aiAvailable_sameDefaultsWhenHigherPriorityFills() {
        // With AI available but no streaks at hour 10: hadith + dhikr still win (askSafa is 3rd)
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 10), isAIAvailable: true)
        let ids = actions.map { $0.id }
        XCTAssertEqual(ids, ["hadith", "dhikr"], "Top 2 unchanged — askSafa is lower priority")
    }

    // MARK: - Streak At Risk

    func test_resolve_dhikrStreakAtRisk_dhikrPromoted() {
        let now = neutralDate(hour: 15)
        let dhikrStreak = streakAtRisk(.dhikr, count: 7)

        let actions = HomeIntentResolver.resolve(
            currentDate: now,
            streaks: [dhikrStreak]
        )

        let ids = actions.map { $0.id }
        XCTAssertTrue(ids.contains("dhikr"), "Dhikr should be promoted when streak is at risk")
        let dhikrIndex = ids.firstIndex(of: "dhikr")!
        XCTAssertLessThanOrEqual(dhikrIndex, 1, "At-risk streak action should appear near top")
    }

    func test_resolve_tabBarStreakAtRisk_notPromoted() {
        // Prayer and Quran streaks at risk should NOT promote tab-bar items
        let now = neutralDate(hour: 10)
        let prayerStreak = streakAtRisk(.prayer, count: 5)
        let quranStreak = streakAtRisk(.quran, count: 7)

        let baseActions = HomeIntentResolver.resolve(currentDate: now)
        let baseIds = baseActions.map { $0.id }

        let actionsWithStreaks = HomeIntentResolver.resolve(
            currentDate: now,
            streaks: [prayerStreak, quranStreak]
        )
        let streakIds = actionsWithStreaks.map { $0.id }

        XCTAssertEqual(baseIds, streakIds, "Tab-bar streaks should not change the grid")
    }

    func test_resolve_lowStreakCount_notPromoted() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let lowStreak = Streak(type: .dhikr, currentCount: 2, longestCount: 5, lastActivityDate: twoDaysAgo)

        let baseActions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 6))
        let baseIds = baseActions.map { $0.id }

        let actionsWithStreak = HomeIntentResolver.resolve(
            currentDate: neutralDate(hour: 6),
            streaks: [lowStreak]
        )
        let streakIds = actionsWithStreak.map { $0.id }

        XCTAssertEqual(baseIds, streakIds)
    }

    // MARK: - Combined Scenarios

    func test_resolve_streakAtRisk_promoted() {
        let now = neutralDate(hour: 10, minute: 0)
        let dhikrStreak = streakAtRisk(.dhikr, count: 10)

        let actions = HomeIntentResolver.resolve(
            currentDate: now,
            streaks: [dhikrStreak]
        )

        let ids = actions.map { $0.id }
        XCTAssertTrue(ids.contains("dhikr"), "Dhikr should be included (streak at risk)")
    }

    // MARK: - No Duplicates

    func test_resolve_noDuplicateActions() {
        let now = neutralDate(hour: 15)
        let dhikrStreak = streakAtRisk(.dhikr, count: 5)

        let actions = HomeIntentResolver.resolve(
            currentDate: now,
            streaks: [dhikrStreak]
        )

        let ids = actions.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "Should have no duplicate actions")
    }

    // MARK: - Time-Based Defaults

    func test_timeBasedDefaults_morningHasFullPool() {
        let defaults = HomeIntentResolver.timeBasedDefaults(hour: 7)
        XCTAssertGreaterThanOrEqual(defaults.count, 2, "Pool should have enough candidates")
    }

    func test_timeBasedDefaults_midday_hadithFirst() {
        let defaults = HomeIntentResolver.timeBasedDefaults(hour: 10)
        XCTAssertEqual(defaults.first?.id, "hadith")
    }

    // MARK: - Seasonal: Ramadan (March 15, 2025 = Ramadan 15, Saturday)

    func test_seasonal_ramadan_dhikrPromoted() {
        // Ramadan midday — dhikr promoted, but Quran/Duas excluded (tab bar items)
        let ramadanDate = dateOn(year: 2025, month: 3, day: 15, hour: 10)
        let promotions = HomeIntentResolver.seasonalPromotions(for: ramadanDate)
        let ids = promotions.map { $0.id }

        XCTAssertTrue(ids.contains("dhikr"), "Ramadan should promote Dhikr")
        XCTAssertFalse(ids.contains("quran"), "Quran is a tab bar item — not in quick actions")
        XCTAssertFalse(ids.contains("duas"), "Duas is a tab bar item — not in quick actions")
    }

    func test_seasonal_ramadan_noTabBarItemsInGrid() {
        let ramadanDate = dateOn(year: 2025, month: 3, day: 15, hour: 15)
        let actions = HomeIntentResolver.resolve(currentDate: ramadanDate)
        let ids = actions.map { $0.id }

        XCTAssertFalse(ids.contains("quran"), "Quran should not be in grid — accessible via tab bar")
        XCTAssertFalse(ids.contains("duas"), "Duas should not be in grid — accessible via tab bar")
        XCTAssertTrue(ids.contains("dhikr"), "Dhikr should be in Ramadan grid")
    }

    // MARK: - Seasonal: Dhul Hijjah (June 1, 2025 = Dhul Hijjah 5, Sunday)

    func test_seasonal_dhulHijjah_dhikrPromoted() {
        let dhDate = dateOn(year: 2025, month: 6, day: 1, hour: 10)
        let promotions = HomeIntentResolver.seasonalPromotions(for: dhDate)
        let ids = promotions.map { $0.id }

        XCTAssertTrue(ids.contains("dhikr"), "First 10 days of Dhul Hijjah should promote Dhikr")
    }

    func test_seasonal_dhulHijjah_dhikrInResolvedGrid() {
        // Dhul Hijjah afternoon — dhikr should appear
        let dhDate = dateOn(year: 2025, month: 6, day: 1, hour: 15)
        let actions = HomeIntentResolver.resolve(currentDate: dhDate)
        let ids = actions.map { $0.id }

        XCTAssertTrue(ids.contains("dhikr"), "Resolved grid during Dhul Hijjah should include Dhikr")
    }

    // MARK: - Seasonal: Day of Arafah (June 5, 2025 = Dhul Hijjah 9, Thursday)

    func test_seasonal_arafah_dhikrPromoted() {
        let arafDate = dateOn(year: 2025, month: 6, day: 5, hour: 10)
        let promotions = HomeIntentResolver.seasonalPromotions(for: arafDate)
        let ids = promotions.map { $0.id }

        XCTAssertTrue(ids.contains("dhikr"), "Arafah should promote Dhikr (Dhul Hijjah + sunnah fasting)")
        XCTAssertFalse(ids.contains("duas"), "Duas is a tab bar item — not in quick actions")
    }

    // MARK: - Seasonal: Friday (Jan 17, 2025 = Rajab 17, Friday)

    func test_seasonal_friday_hadithPromoted() {
        let friday = dateOn(year: 2025, month: 1, day: 17, hour: 10)
        let promotions = HomeIntentResolver.seasonalPromotions(for: friday)
        let ids = promotions.map { $0.id }

        XCTAssertTrue(ids.contains("hadith"), "Friday should promote Hadith")
        XCTAssertFalse(ids.contains("quran"), "Quran is a tab bar item — not in quick actions")
    }

    func test_seasonal_friday_hadithInResolvedGrid() {
        let friday = dateOn(year: 2025, month: 1, day: 17, hour: 15)
        let actions = HomeIntentResolver.resolve(currentDate: friday)
        let ids = actions.map { $0.id }

        XCTAssertTrue(ids.contains("hadith"), "Friday afternoon should include Hadith in grid")
    }

    // MARK: - Seasonal: Monday (Jan 13, 2025 = Rajab 13, Monday)

    func test_seasonal_monday_dhikrPromoted() {
        let monday = dateOn(year: 2025, month: 1, day: 13, hour: 10)
        let promotions = HomeIntentResolver.seasonalPromotions(for: monday)
        let ids = promotions.map { $0.id }

        XCTAssertTrue(ids.contains("dhikr"), "Sunnah fasting day (Monday) should promote Dhikr")
        XCTAssertFalse(ids.contains("duas"), "Duas is a tab bar item — not in quick actions")
    }

    // MARK: - Seasonal: No Promotions on Neutral Day

    func test_seasonal_neutralDay_noPromotions() {
        // Wednesday Jan 15 2025 (Rajab) — no seasonal promotions
        let neutral = neutralDate(hour: 10)
        let promotions = HomeIntentResolver.seasonalPromotions(for: neutral)

        XCTAssertTrue(promotions.isEmpty, "Neutral day should have no seasonal promotions")
    }

    // MARK: - Contextual Subtitles: Streak At Risk

    func test_subtitle_streakAtRisk_showsStreakCount() {
        let now = neutralDate(hour: 15)
        let dhikrStreak = streakAtRisk(.dhikr, count: 7)

        let actions = HomeIntentResolver.resolve(currentDate: now, streaks: [dhikrStreak])
        let dhikrAction = actions.first { $0.id == "dhikr" }

        XCTAssertEqual(dhikrAction?.subtitle, "7-day streak at risk")
    }

    // MARK: - Contextual Subtitles: Seasonal

    func test_subtitle_ramadan_dhikrShowsRamadanDhikr() {
        let ramadanDate = dateOn(year: 2025, month: 3, day: 15, hour: 15)
        let actions = HomeIntentResolver.resolve(currentDate: ramadanDate)
        let dhikrAction = actions.first { $0.id == "dhikr" }

        XCTAssertEqual(dhikrAction?.subtitle, "Ramadan dhikr")
    }

    func test_subtitle_friday_hadithShowsJumuah() {
        let friday = dateOn(year: 2025, month: 1, day: 17, hour: 15)
        let actions = HomeIntentResolver.resolve(currentDate: friday)
        let hadithAction = actions.first { $0.id == "hadith" }

        XCTAssertEqual(hadithAction?.subtitle, "Jumu'ah reading")
    }

    func test_subtitle_dhulHijjah_dhikrShowsBlessedDays() {
        let dhDate = dateOn(year: 2025, month: 6, day: 1, hour: 15)
        let actions = HomeIntentResolver.resolve(currentDate: dhDate)
        let dhikrAction = actions.first { $0.id == "dhikr" }

        XCTAssertEqual(dhikrAction?.subtitle, "Blessed days of Dhul Hijjah")
    }

    // MARK: - Contextual Subtitles: Time-Based

    func test_subtitle_morning_dhikrShowsMorningAdhkar() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 6))
        let dhikrAction = actions.first { $0.id == "dhikr" }

        XCTAssertEqual(dhikrAction?.subtitle, "Morning adhkar")
    }

    func test_subtitle_evening_dhikrShowsEveningAdhkar() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 18))
        let dhikrAction = actions.first { $0.id == "dhikr" }

        XCTAssertEqual(dhikrAction?.subtitle, "Evening adhkar")
    }

    func test_subtitle_night_hadithShowsDefault() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 22))
        let hadithAction = actions.first { $0.id == "hadith" }

        XCTAssertEqual(hadithAction?.subtitle, "Prophetic traditions")
    }

    // MARK: - Contextual Subtitles: Priority (higher rule wins)

    func test_subtitle_streakBeatsSeasonalForSameAction() {
        // Ramadan promotes dhikr with "Ramadan dhikr"
        // But dhikr streak at risk (Rule 2) should override with streak subtitle
        let ramadanDate = dateOn(year: 2025, month: 3, day: 15, hour: 15)
        let dhikrStreak = streakAtRisk(.dhikr, count: 12)

        let actions = HomeIntentResolver.resolve(
            currentDate: ramadanDate,
            streaks: [dhikrStreak]
        )
        let dhikrAction = actions.first { $0.id == "dhikr" }

        // Streak at risk (Rule 2) fires before seasonal (Rule 3), so streak subtitle wins
        XCTAssertEqual(dhikrAction?.subtitle, "12-day streak at risk")
    }

    // MARK: - No Duplicates with Seasonal

    func test_resolve_noDuplicates_withSeasonalAndStreaks() {
        // Ramadan + dhikr streak at risk — both promote dhikr, should not duplicate
        let ramadanDate = dateOn(year: 2025, month: 3, day: 15, hour: 10)
        let dhikrStreak = streakAtRisk(.dhikr, count: 10)

        let actions = HomeIntentResolver.resolve(
            currentDate: ramadanDate,
            streaks: [dhikrStreak]
        )

        let ids = actions.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "No duplicates even when seasonal + streak promote same action")
        XCTAssertEqual(actions.count, 2)
    }
}
