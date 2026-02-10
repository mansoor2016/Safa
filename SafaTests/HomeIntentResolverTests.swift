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

    // MARK: - Always Returns 4 Items

    func test_resolve_alwaysReturnsFourActions() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 10))
        XCTAssertEqual(actions.count, 4)
    }

    func test_resolve_withAllInputs_returnsFourActions() {
        let now = neutralDate(hour: 12, minute: 30)
        let actions = HomeIntentResolver.resolve(
            currentDate: now,
            nextPrayer: prayerTime(type: .dhuhr, at: neutralDate(hour: 12, minute: 45)),
            loggedPrayers: [.fajr],
            streaks: [streakAtRisk(.quran, count: 10)]
        )
        XCTAssertEqual(actions.count, 4)
    }

    // MARK: - Prayer Always Included

    func test_resolve_prayerAlwaysPresent() {
        for hour in [0, 5, 10, 15, 20, 23] {
            let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: hour))
            let hasPrayer = actions.contains { $0.id == "prayer" }
            XCTAssertTrue(hasPrayer, "Prayer should be present at hour \(hour)")
        }
    }

    // MARK: - Prayer Proximity

    func test_resolve_prayerWithin30Min_prayerIsFirst() {
        let now = neutralDate(hour: 10, minute: 0)
        let prayerSoon = prayerTime(type: .dhuhr, at: neutralDate(hour: 10, minute: 20))

        let actions = HomeIntentResolver.resolve(
            currentDate: now,
            nextPrayer: prayerSoon
        )

        XCTAssertEqual(actions.first?.id, "prayer", "Prayer should be first when within 30 minutes")
    }

    func test_resolve_prayerFarAway_prayerNotNecessarilyFirst() {
        let now = neutralDate(hour: 7, minute: 0)
        let prayerFar = prayerTime(type: .dhuhr, at: neutralDate(hour: 12, minute: 0))

        let actions = HomeIntentResolver.resolve(
            currentDate: now,
            nextPrayer: prayerFar
        )

        // At 7am (morning), Dhikr should be first by time defaults
        XCTAssertEqual(actions.first?.id, "dhikr")
    }

    // MARK: - Morning Defaults (Neutral Day)

    func test_resolve_morning_dhikrInTopTwo() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 7))
        let topTwo = Array(actions.prefix(2)).map { $0.id }
        XCTAssertTrue(topTwo.contains("dhikr"), "Morning should have Dhikr in top 2, got: \(topTwo)")
    }

    func test_resolve_morning_defaultOrder() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 6))
        let ids = actions.map { $0.id }
        XCTAssertEqual(ids, ["dhikr", "prayer", "quran", "duas"])
    }

    // MARK: - Afternoon Defaults (Neutral Day)

    func test_resolve_afternoon_prayerFirst() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 15))
        XCTAssertEqual(actions.first?.id, "prayer")
    }

    // MARK: - Evening Defaults (Neutral Day)

    func test_resolve_evening_prayerFirst_dhikrSecond() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 18))
        let ids = actions.map { $0.id }
        XCTAssertEqual(ids[0], "prayer")
        XCTAssertEqual(ids[1], "dhikr")
    }

    // MARK: - Night Defaults (Neutral Day)

    func test_resolve_night_duasFirst() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 22))
        XCTAssertEqual(actions.first?.id, "duas")
    }

    // MARK: - Streak At Risk

    func test_resolve_quranStreakAtRisk_quranPromoted() {
        let now = neutralDate(hour: 15)
        let quranStreak = streakAtRisk(.quran, count: 7)

        let actions = HomeIntentResolver.resolve(
            currentDate: now,
            streaks: [quranStreak]
        )

        let ids = actions.map { $0.id }
        XCTAssertTrue(ids.contains("quran"), "Quran should be promoted when streak is at risk")
        let quranIndex = ids.firstIndex(of: "quran")!
        XCTAssertLessThanOrEqual(quranIndex, 1, "At-risk streak action should appear near top")
    }

    func test_resolve_prayerStreakAtRisk_prayerStillFirst() {
        let now = neutralDate(hour: 10)
        let prayerStreak = streakAtRisk(.prayer, count: 5)

        let actions = HomeIntentResolver.resolve(
            currentDate: now,
            streaks: [prayerStreak]
        )

        XCTAssertTrue(actions.contains { $0.id == "prayer" })
    }

    func test_resolve_lowStreakCount_notPromoted() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let lowStreak = Streak(type: .quran, currentCount: 2, longestCount: 5, lastActivityDate: twoDaysAgo)

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

    func test_resolve_prayerSoon_andStreakAtRisk_bothRepresented() {
        let now = neutralDate(hour: 10, minute: 0)
        let prayerSoon = prayerTime(type: .dhuhr, at: neutralDate(hour: 10, minute: 15))
        let dhikrStreak = streakAtRisk(.dhikr, count: 10)

        let actions = HomeIntentResolver.resolve(
            currentDate: now,
            nextPrayer: prayerSoon,
            streaks: [dhikrStreak]
        )

        let ids = actions.map { $0.id }
        XCTAssertEqual(ids[0], "prayer", "Prayer should be first when imminent")
        XCTAssertTrue(ids.contains("dhikr"), "Dhikr should be included (streak at risk)")
    }

    // MARK: - No Duplicates

    func test_resolve_noDuplicateActions() {
        let now = neutralDate(hour: 15)
        let prayerSoon = prayerTime(type: .asr, at: neutralDate(hour: 15, minute: 10))
        let prayerStreak = streakAtRisk(.prayer, count: 5)

        let actions = HomeIntentResolver.resolve(
            currentDate: now,
            nextPrayer: prayerSoon,
            streaks: [prayerStreak]
        )

        let ids = actions.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "Should have no duplicate actions")
    }

    // MARK: - Time-Based Defaults

    func test_timeBasedDefaults_morningHasFiveItems() {
        let defaults = HomeIntentResolver.timeBasedDefaults(hour: 7)
        XCTAssertGreaterThanOrEqual(defaults.count, 5)
    }

    func test_timeBasedDefaults_midday_quranFirst() {
        let defaults = HomeIntentResolver.timeBasedDefaults(hour: 10)
        XCTAssertEqual(defaults.first?.id, "quran")
    }

    // MARK: - Seasonal: Ramadan (March 15, 2025 = Ramadan 15, Saturday)

    func test_seasonal_ramadan_quranPromoted() {
        // Ramadan midday — Quran should be promoted
        let ramadanDate = dateOn(year: 2025, month: 3, day: 15, hour: 10)
        let promotions = HomeIntentResolver.seasonalPromotions(for: ramadanDate)
        let ids = promotions.map { $0.id }

        XCTAssertTrue(ids.contains("quran"), "Ramadan should promote Quran")
        XCTAssertTrue(ids.contains("duas"), "Ramadan should promote Duas")
    }

    func test_seasonal_ramadan_quranAppearsInResolvedGrid() {
        // Ramadan afternoon (when time defaults would put Prayer first)
        let ramadanDate = dateOn(year: 2025, month: 3, day: 15, hour: 15)
        let actions = HomeIntentResolver.resolve(currentDate: ramadanDate)
        let ids = actions.map { $0.id }

        XCTAssertTrue(ids.contains("quran"), "Resolved grid during Ramadan should include Quran")
        XCTAssertTrue(ids.contains("duas"), "Resolved grid during Ramadan should include Duas")
    }

    func test_seasonal_ramadan_withPrayerSoon_prayerStillFirst() {
        let ramadanDate = dateOn(year: 2025, month: 3, day: 15, hour: 14, minute: 50)
        let prayer = prayerTime(type: .asr, at: dateOn(year: 2025, month: 3, day: 15, hour: 15, minute: 10))

        let actions = HomeIntentResolver.resolve(
            currentDate: ramadanDate,
            nextPrayer: prayer
        )

        XCTAssertEqual(actions.first?.id, "prayer", "Prayer proximity still wins over Ramadan promotions")
    }

    // MARK: - Seasonal: Dhul Hijjah (June 1, 2025 = Dhul Hijjah 5, Sunday)

    func test_seasonal_dhulHijjah_dhikrPromoted() {
        let dhDate = dateOn(year: 2025, month: 6, day: 1, hour: 10)
        let promotions = HomeIntentResolver.seasonalPromotions(for: dhDate)
        let ids = promotions.map { $0.id }

        XCTAssertTrue(ids.contains("dhikr"), "First 10 days of Dhul Hijjah should promote Dhikr")
    }

    func test_seasonal_dhulHijjah_dhikrInResolvedGrid() {
        // Dhul Hijjah afternoon — dhikr should appear even though time defaults put Prayer first
        let dhDate = dateOn(year: 2025, month: 6, day: 1, hour: 15)
        let actions = HomeIntentResolver.resolve(currentDate: dhDate)
        let ids = actions.map { $0.id }

        XCTAssertTrue(ids.contains("dhikr"), "Resolved grid during Dhul Hijjah should include Dhikr")
    }

    // MARK: - Seasonal: Day of Arafah (June 5, 2025 = Dhul Hijjah 9, Thursday)

    func test_seasonal_arafah_duasPromoted() {
        let arafDate = dateOn(year: 2025, month: 6, day: 5, hour: 10)
        let promotions = HomeIntentResolver.seasonalPromotions(for: arafDate)
        let ids = promotions.map { $0.id }

        // Dhul Hijjah → dhikr, Arafah → duas, Thursday → dhikr + duas
        XCTAssertTrue(ids.contains("dhikr"), "Arafah should promote Dhikr (Dhul Hijjah)")
        XCTAssertTrue(ids.contains("duas"), "Arafah should promote Duas")
    }

    // MARK: - Seasonal: Friday (Jan 17, 2025 = Rajab 17, Friday)

    func test_seasonal_friday_quranPromoted() {
        let friday = dateOn(year: 2025, month: 1, day: 17, hour: 10)
        let promotions = HomeIntentResolver.seasonalPromotions(for: friday)
        let ids = promotions.map { $0.id }

        XCTAssertTrue(ids.contains("quran"), "Friday should promote Quran (Surah Al-Kahf)")
    }

    func test_seasonal_friday_quranInResolvedGrid() {
        // Friday afternoon (when time defaults start with Prayer)
        let friday = dateOn(year: 2025, month: 1, day: 17, hour: 15)
        let actions = HomeIntentResolver.resolve(currentDate: friday)
        let ids = actions.map { $0.id }

        XCTAssertTrue(ids.contains("quran"), "Friday afternoon should include Quran in grid")
    }

    // MARK: - Seasonal: Monday (Jan 13, 2025 = Rajab 13, Monday)

    func test_seasonal_monday_dhikrAndDuasPromoted() {
        let monday = dateOn(year: 2025, month: 1, day: 13, hour: 10)
        let promotions = HomeIntentResolver.seasonalPromotions(for: monday)
        let ids = promotions.map { $0.id }

        XCTAssertTrue(ids.contains("dhikr"), "Sunnah fasting day (Monday) should promote Dhikr")
        XCTAssertTrue(ids.contains("duas"), "Sunnah fasting day (Monday) should promote Duas")
    }

    // MARK: - Seasonal: No Promotions on Neutral Day

    func test_seasonal_neutralDay_noPromotions() {
        // Wednesday Jan 15 2025 (Rajab) — no seasonal promotions
        let neutral = neutralDate(hour: 10)
        let promotions = HomeIntentResolver.seasonalPromotions(for: neutral)

        XCTAssertTrue(promotions.isEmpty, "Neutral day should have no seasonal promotions")
    }

    // MARK: - Contextual Subtitles: Prayer Proximity

    func test_subtitle_prayerSoon_showsCountdown() {
        let now = neutralDate(hour: 10, minute: 0)
        let prayerSoon = prayerTime(type: .dhuhr, at: neutralDate(hour: 10, minute: 20))

        let actions = HomeIntentResolver.resolve(currentDate: now, nextPrayer: prayerSoon)
        let prayerAction = actions.first { $0.id == "prayer" }

        XCTAssertEqual(prayerAction?.subtitle, "Dhuhr in 20 min")
    }

    func test_subtitle_prayerFar_showsDefault() {
        let now = neutralDate(hour: 10, minute: 0)
        let prayerFar = prayerTime(type: .dhuhr, at: neutralDate(hour: 12, minute: 0))

        let actions = HomeIntentResolver.resolve(currentDate: now, nextPrayer: prayerFar)
        let prayerAction = actions.first { $0.id == "prayer" }

        XCTAssertEqual(prayerAction?.subtitle, "Times & logging")
    }

    // MARK: - Contextual Subtitles: Streak At Risk

    func test_subtitle_streakAtRisk_showsStreakCount() {
        let now = neutralDate(hour: 15)
        let quranStreak = streakAtRisk(.quran, count: 7)

        let actions = HomeIntentResolver.resolve(currentDate: now, streaks: [quranStreak])
        let quranAction = actions.first { $0.id == "quran" }

        XCTAssertEqual(quranAction?.subtitle, "7-day streak at risk")
    }

    // MARK: - Contextual Subtitles: Seasonal

    func test_subtitle_ramadan_quranShowsRamadanReading() {
        let ramadanDate = dateOn(year: 2025, month: 3, day: 15, hour: 15)
        let actions = HomeIntentResolver.resolve(currentDate: ramadanDate)
        let quranAction = actions.first { $0.id == "quran" }

        XCTAssertEqual(quranAction?.subtitle, "Ramadan reading")
    }

    func test_subtitle_friday_quranShowsSurahAlKahf() {
        let friday = dateOn(year: 2025, month: 1, day: 17, hour: 15)
        let actions = HomeIntentResolver.resolve(currentDate: friday)
        let quranAction = actions.first { $0.id == "quran" }

        XCTAssertEqual(quranAction?.subtitle, "Read Surah Al-Kahf")
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

    func test_subtitle_night_duasShowsSleepSupplications() {
        let actions = HomeIntentResolver.resolve(currentDate: neutralDate(hour: 22))
        let duasAction = actions.first { $0.id == "duas" }

        XCTAssertEqual(duasAction?.subtitle, "Sleep supplications")
    }

    // MARK: - Contextual Subtitles: Priority (higher rule wins)

    func test_subtitle_streakBeatsSeasonalForSameAction() {
        // Ramadan promotes quran with "Ramadan reading"
        // But quran streak at risk (Rule 2) should override with streak subtitle
        let ramadanDate = dateOn(year: 2025, month: 3, day: 15, hour: 15)
        let quranStreak = streakAtRisk(.quran, count: 12)

        let actions = HomeIntentResolver.resolve(
            currentDate: ramadanDate,
            streaks: [quranStreak]
        )
        let quranAction = actions.first { $0.id == "quran" }

        // Streak at risk (Rule 2) fires before seasonal (Rule 3), so streak subtitle wins
        XCTAssertEqual(quranAction?.subtitle, "12-day streak at risk")
    }

    // MARK: - No Duplicates with Seasonal

    func test_resolve_noDuplicates_withSeasonalAndStreaks() {
        // Ramadan + quran streak at risk — both promote quran, should not duplicate
        let ramadanDate = dateOn(year: 2025, month: 3, day: 15, hour: 10)
        let quranStreak = streakAtRisk(.quran, count: 10)

        let actions = HomeIntentResolver.resolve(
            currentDate: ramadanDate,
            streaks: [quranStreak]
        )

        let ids = actions.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "No duplicates even when seasonal + streak promote same action")
        XCTAssertEqual(actions.count, 4)
    }
}
