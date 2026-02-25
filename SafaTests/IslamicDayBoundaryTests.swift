// MARK: - IslamicDayBoundaryTests.swift
// PURPOSE: Tests for Maghrib-aware Islamic day boundary logic
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa
import SafaShared

final class IslamicDayBoundaryTests: XCTestCase {

    private let converter = HijriDateConverter.shared
    private var gregorianCalendar: Calendar!
    private var islamicCalendar: Calendar!

    override func setUp() {
        super.setUp()
        // Pin timezone to avoid flakiness across machines
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(identifier: "Europe/London")!
        gregorianCalendar = gregorian

        var islamic = Calendar(identifier: .islamicUmmAlQura)
        islamic.timeZone = TimeZone(identifier: "Europe/London")!
        islamicCalendar = islamic
    }

    // MARK: - Helpers

    /// Creates a Date from Gregorian components in Europe/London timezone.
    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0, second: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.timeZone = TimeZone(identifier: "Europe/London")
        return gregorianCalendar.date(from: components)!
    }

    /// Creates a Maghrib time on the same civil day at the given hour:minute.
    private func maghrib(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        date(year: year, month: month, day: day, hour: hour, minute: minute)
    }

    /// Returns Islamic date components (month, day) for a given Date using midnight-based calendar.
    private func midnightHijri(_ d: Date) -> (month: Int, day: Int) {
        let c = islamicCalendar.dateComponents([.month, .day], from: d)
        return (c.month ?? 0, c.day ?? 0)
    }

    // MARK: - Core: islamicDate(from:adjustedFor:)

    func test_beforeMaghrib_sameAsStandardCalendar() {
        // 2pm, Maghrib at 6pm — before Maghrib, should be same as midnight-based
        let now = date(year: 2025, month: 3, day: 15, hour: 14)
        let maghribTime = maghrib(year: 2025, month: 3, day: 15, hour: 18)

        let adjusted = converter.islamicDate(from: now, adjustedFor: maghribTime)
        let standard = midnightHijri(now)

        XCTAssertEqual(adjusted.month, standard.month)
        XCTAssertEqual(adjusted.day, standard.day)
    }

    func test_afterMaghrib_advancesToNextDay() {
        // 7pm, Maghrib at 6pm — after Maghrib, should advance to next Islamic day
        let now = date(year: 2025, month: 3, day: 15, hour: 19)
        let maghribTime = maghrib(year: 2025, month: 3, day: 15, hour: 18)

        let adjusted = converter.islamicDate(from: now, adjustedFor: maghribTime)
        let standard = midnightHijri(now)

        // Should be one day ahead of midnight-based
        XCTAssertEqual(adjusted.day, standard.day + 1,
                       "After Maghrib, Islamic day should be tomorrow")
    }

    func test_nilMaghrib_fallsBackToMidnight() {
        let now = date(year: 2025, month: 3, day: 15, hour: 19)
        let adjusted = converter.islamicDate(from: now, adjustedFor: nil)
        let standard = midnightHijri(now)

        XCTAssertEqual(adjusted.month, standard.month)
        XCTAssertEqual(adjusted.day, standard.day,
                       "Nil Maghrib should use midnight-based date")
    }

    func test_staleMaghrib_differentDay_rejected() {
        // Now is March 16, but Maghrib is from March 15 — stale, should be rejected
        let now = date(year: 2025, month: 3, day: 16, hour: 19)
        let staleMaghrib = maghrib(year: 2025, month: 3, day: 15, hour: 18)

        let adjusted = converter.islamicDate(from: now, adjustedFor: staleMaghrib)
        let standard = midnightHijri(now)

        XCTAssertEqual(adjusted.month, standard.month)
        XCTAssertEqual(adjusted.day, standard.day,
                       "Stale Maghrib from different day should be ignored")
    }

    func test_futureMaghrib_differentDay_rejected() {
        // Now is March 14, but Maghrib is from March 15 — future, should be rejected
        let now = date(year: 2025, month: 3, day: 14, hour: 19)
        let futureMaghrib = maghrib(year: 2025, month: 3, day: 15, hour: 18)

        let adjusted = converter.islamicDate(from: now, adjustedFor: futureMaghrib)
        let standard = midnightHijri(now)

        XCTAssertEqual(adjusted.month, standard.month)
        XCTAssertEqual(adjusted.day, standard.day,
                       "Future-day Maghrib should be ignored")
    }

    // MARK: - Ramadan Boundary

    func test_ramadan30_beforeMaghrib_isRamadan() {
        // Ramadan 30, 1446 AH ≈ March 29, 2025
        let ramadan30 = date(year: 2025, month: 3, day: 29, hour: 14)
        let maghribTime = maghrib(year: 2025, month: 3, day: 29, hour: 18, minute: 15)

        let result = converter.isRamadan(on: ramadan30, maghribTime: maghribTime)
        XCTAssertTrue(result, "Before Maghrib on Ramadan 30 should still be Ramadan")
    }

    func test_ramadan30_afterMaghrib_isNotRamadan() {
        // After Maghrib on Ramadan 30, it's now Shawwal 1
        let ramadan30Evening = date(year: 2025, month: 3, day: 29, hour: 19)
        let maghribTime = maghrib(year: 2025, month: 3, day: 29, hour: 18, minute: 15)

        let result = converter.isRamadan(on: ramadan30Evening, maghribTime: maghribTime)
        XCTAssertFalse(result, "After Maghrib on Ramadan 30 should be Shawwal (not Ramadan)")
    }

    func test_shabanLastDay_afterMaghrib_isRamadan() {
        // The day before Ramadan 1, after Maghrib = Ramadan 1
        // Sha'ban last day 1446 ≈ Feb 28, 2025
        let shabanEvening = date(year: 2025, month: 2, day: 28, hour: 19)
        let maghribTime = maghrib(year: 2025, month: 2, day: 28, hour: 17, minute: 30)

        let result = converter.isRamadan(on: shabanEvening, maghribTime: maghribTime)
        XCTAssertTrue(result, "After Maghrib on last day of Sha'ban should be Ramadan")
    }

    // MARK: - Eid Boundary

    func test_ramadan30_afterMaghrib_isEidAlFitr() {
        let ramadan30Evening = date(year: 2025, month: 3, day: 29, hour: 19)
        let maghribTime = maghrib(year: 2025, month: 3, day: 29, hour: 18, minute: 15)

        let result = converter.isEidAlFitr(on: ramadan30Evening, maghribTime: maghribTime)
        XCTAssertTrue(result, "After Maghrib on Ramadan 30 should be Eid al-Fitr")
    }

    func test_dhulHijjah9_afterMaghrib_isEidAlAdha() {
        // Dhul Hijjah 9 (Day of Arafah) 1446 ≈ June 5, 2025
        let arafahEvening = date(year: 2025, month: 6, day: 5, hour: 21)
        let maghribTime = maghrib(year: 2025, month: 6, day: 5, hour: 20, minute: 30)

        let result = converter.isEidAlAdha(on: arafahEvening, maghribTime: maghribTime)
        XCTAssertTrue(result, "After Maghrib on Dhul Hijjah 9 should be Eid al-Adha")
    }

    // MARK: - Blessed Night

    func test_ramadan26_afterMaghrib_isBlessedNight() {
        // Ramadan 26 after Maghrib = night of 27th (odd night in last 10)
        // Ramadan 26, 1446 ≈ March 26, 2025
        let ramadan26Evening = date(year: 2025, month: 3, day: 26, hour: 20)
        let maghribTime = maghrib(year: 2025, month: 3, day: 26, hour: 18, minute: 10)

        let result = converter.isBlessedNight(on: ramadan26Evening, maghribTime: maghribTime)
        XCTAssertTrue(result, "Ramadan 26 after Maghrib = night of 27th, should be blessed")
    }

    // MARK: - daysUntil Boundary

    func test_daysUntil_eventLessThan24hAway_returnsNotNil() {
        // When the event is <24h away — start-of-day normalization should still return a result
        let now = date(year: 2025, month: 3, day: 29, hour: 23, minute: 59)
        // Eid al-Fitr is Shawwal 1, 1446 ≈ March 30, 2025
        let result = converter.daysUntilEidAlFitr(from: now)
        XCTAssertNotNil(result, "daysUntil should not return nil for an event <24h away")
    }

    // MARK: - Iftar Adhan Regression

    func test_ramadan30_justBeforeMaghrib_isRamadan() {
        // 1 second before Maghrib on Ramadan 30 — still Ramadan (for iftar adhan)
        let maghribTime = maghrib(year: 2025, month: 3, day: 29, hour: 18, minute: 15)
        let justBefore = maghribTime.addingTimeInterval(-1)

        let result = converter.isRamadan(on: justBefore, maghribTime: maghribTime)
        XCTAssertTrue(result, "1 second before Maghrib on Ramadan 30 should still be Ramadan (iftar adhan)")
    }

    func test_ramadan30_atMaghrib_isNotRamadan() {
        // At exact Maghrib on Ramadan 30 — Ramadan is over
        let maghribTime = maghrib(year: 2025, month: 3, day: 29, hour: 18, minute: 15)

        let result = converter.isRamadan(on: maghribTime, maghribTime: maghribTime)
        XCTAssertFalse(result, "At Maghrib on Ramadan 30, it's now Shawwal 1")
    }

    // MARK: - hijriDateString with Maghrib

    func test_hijriDateString_afterMaghrib_showsTomorrow() {
        let evening = date(year: 2025, month: 3, day: 15, hour: 20)
        let maghribTime = maghrib(year: 2025, month: 3, day: 15, hour: 18)

        let withMaghrib = converter.hijriDateString(from: evening, style: .dayMonth, maghribTime: maghribTime)
        let withoutMaghrib = converter.hijriDateString(from: evening, style: .dayMonth, maghribTime: nil)

        XCTAssertNotEqual(withMaghrib, withoutMaghrib,
                          "After Maghrib, the displayed Hijri date should differ from midnight-based")
    }

    func test_hijriDateString_beforeMaghrib_sameDateBothWays() {
        let afternoon = date(year: 2025, month: 3, day: 15, hour: 14)
        let maghribTime = maghrib(year: 2025, month: 3, day: 15, hour: 18)

        let withMaghrib = converter.hijriDateString(from: afternoon, style: .dayMonth, maghribTime: maghribTime)
        let withoutMaghrib = converter.hijriDateString(from: afternoon, style: .dayMonth, maghribTime: nil)

        XCTAssertEqual(withMaghrib, withoutMaghrib,
                        "Before Maghrib, both methods should show the same date")
    }

    // MARK: - currentEidType with Maghrib

    func test_currentEidType_afterMaghrib_ramadan30_isFitr() {
        let evening = date(year: 2025, month: 3, day: 29, hour: 19)
        let maghribTime = maghrib(year: 2025, month: 3, day: 29, hour: 18, minute: 15)

        let eidType = converter.currentEidType(on: evening, maghribTime: maghribTime)
        XCTAssertEqual(eidType, .fitr, "After Maghrib on Ramadan 30 → Eid al-Fitr")
    }

    func test_eidDayNumber_afterMaghrib_ramadan30_isDay1() {
        let evening = date(year: 2025, month: 3, day: 29, hour: 19)
        let maghribTime = maghrib(year: 2025, month: 3, day: 29, hour: 18, minute: 15)

        let dayNumber = converter.eidDayNumber(on: evening, maghribTime: maghribTime)
        XCTAssertEqual(dayNumber, 1, "After Maghrib on Ramadan 30 → Eid Day 1")
    }

    // MARK: - daysUntilRamadan with Maghrib

    func test_daysUntilRamadan_duringRamadan_returnsZero() {
        // During Ramadan 15
        let ramadan15 = date(year: 2025, month: 3, day: 15, hour: 14)
        let maghribTime = maghrib(year: 2025, month: 3, day: 15, hour: 18)

        let result = converter.daysUntilRamadan(from: ramadan15, maghribTime: maghribTime)
        XCTAssertEqual(result, 0, "During Ramadan, daysUntilRamadan should be 0")
    }

    func test_daysUntilRamadan_shabanEvening_returnsZero() {
        // After Maghrib on last Sha'ban → effectively Ramadan 1
        let shabanEvening = date(year: 2025, month: 2, day: 28, hour: 19)
        let maghribTime = maghrib(year: 2025, month: 2, day: 28, hour: 17, minute: 30)

        let result = converter.daysUntilRamadan(from: shabanEvening, maghribTime: maghribTime)
        XCTAssertEqual(result, 0, "After Maghrib on last Sha'ban = Ramadan 1 → 0 days until Ramadan")
    }

    // MARK: - HomeIntentResolver Seasonal with Maghrib

    func test_seasonal_ramadan_withMaghrib_dhikrPromoted() {
        // March 15, 2025 at 7pm = after Maghrib → Ramadan 16 (still Ramadan, dhikr promoted)
        let ramadanEvening = date(year: 2025, month: 3, day: 15, hour: 19)
        let maghribTime = maghrib(year: 2025, month: 3, day: 15, hour: 18)

        let promotions = HomeIntentResolver.seasonalPromotions(for: ramadanEvening, maghribTime: maghribTime)
        let ids = promotions.map { $0.id }
        XCTAssertTrue(ids.contains("dhikr"), "Ramadan evening with Maghrib → dhikr promoted")
    }

    func test_seasonal_ramadan30Evening_withMaghrib_noRamadanPromotion() {
        // March 29, 2025 at 7pm = after Maghrib on Ramadan 30 → Shawwal 1
        // Ramadan dhikr should NOT be promoted (Ramadan is over)
        let ramadan30Evening = date(year: 2025, month: 3, day: 29, hour: 19)
        let maghribTime = maghrib(year: 2025, month: 3, day: 29, hour: 18, minute: 15)

        let promotions = HomeIntentResolver.seasonalPromotions(for: ramadan30Evening, maghribTime: maghribTime)
        let hasRamadanDhikr = promotions.contains { $0.subtitle == "Ramadan dhikr" }
        XCTAssertFalse(hasRamadanDhikr, "After Maghrib on Ramadan 30 = Shawwal → no Ramadan dhikr")
    }

    func test_seasonal_shabanEvening_withMaghrib_ramadanPromotionAppears() {
        // Feb 28, 2025 at 7pm = after Maghrib on last Sha'ban → Ramadan 1
        // Ramadan dhikr SHOULD be promoted
        let shabanEvening = date(year: 2025, month: 2, day: 28, hour: 19)
        let maghribTime = maghrib(year: 2025, month: 2, day: 28, hour: 17, minute: 30)

        let promotions = HomeIntentResolver.seasonalPromotions(for: shabanEvening, maghribTime: maghribTime)
        let hasRamadanDhikr = promotions.contains { $0.subtitle == "Ramadan dhikr" }
        XCTAssertTrue(hasRamadanDhikr, "After Maghrib on last Sha'ban = Ramadan 1 → Ramadan dhikr promoted")
    }

    func test_resolve_withMaghrib_passesThrough() {
        // Verify resolve() correctly passes maghribTime to seasonalPromotions
        let ramadanEvening = date(year: 2025, month: 3, day: 15, hour: 19)
        let maghribTime = maghrib(year: 2025, month: 3, day: 15, hour: 18)

        let actions = HomeIntentResolver.resolve(
            currentDate: ramadanEvening,
            maghribTime: maghribTime
        )
        let ids = actions.map { $0.id }
        XCTAssertTrue(ids.contains("dhikr"), "resolve() with Maghrib during Ramadan → dhikr in grid")
    }

    // MARK: - Boundary Crossing Consistency

    func test_isRamadan_beforeAndAfterMaghrib_produceDifferentResults() {
        // Same civil day, different Islamic day
        let maghribTime = maghrib(year: 2025, month: 3, day: 29, hour: 18, minute: 15)
        let before = date(year: 2025, month: 3, day: 29, hour: 14)
        let after = date(year: 2025, month: 3, day: 29, hour: 19)

        XCTAssertTrue(converter.isRamadan(on: before, maghribTime: maghribTime))
        XCTAssertFalse(converter.isRamadan(on: after, maghribTime: maghribTime))
    }

    func test_hijriDateString_consistentAcrossStyles() {
        // After Maghrib, both .dayMonth and full format should reflect the same advanced date
        let evening = date(year: 2025, month: 3, day: 15, hour: 20)
        let maghribTime = maghrib(year: 2025, month: 3, day: 15, hour: 18)

        let dayMonth = converter.hijriDateString(from: evening, style: .dayMonth, maghribTime: maghribTime)
        let components = converter.islamicDate(from: evening, adjustedFor: maghribTime)

        // The day in the string should match the components day
        XCTAssertTrue(dayMonth.contains("\(components.day ?? 0)"),
                       "hijriDateString should match islamicDate components after Maghrib")
    }

    // MARK: - HijriDateHelper (SafaShared) parity

    func test_hijriDateHelper_afterMaghrib_matchesConverter() {
        let helper = HijriDateHelper()
        let evening = date(year: 2025, month: 3, day: 15, hour: 20)
        let maghribTime = maghrib(year: 2025, month: 3, day: 15, hour: 18)

        let helperComponents = helper.islamicDate(from: evening, adjustedFor: maghribTime)
        let converterComponents = converter.islamicDate(from: evening, adjustedFor: maghribTime)

        XCTAssertEqual(helperComponents.day, converterComponents.day,
                       "HijriDateHelper and HijriDateConverter should produce the same adjusted day")
        XCTAssertEqual(helperComponents.month, converterComponents.month,
                       "HijriDateHelper and HijriDateConverter should produce the same adjusted month")
    }

    // MARK: - Dhul Hijjah boundary with Maghrib

    func test_seasonal_dhulHijjah10Evening_withMaghrib_noBlessedDaysPromotion() {
        // After Maghrib on Dhul Hijjah 10 → Dhul Hijjah 11
        // First 10 blessed days are over → no "Blessed days" promotion
        let dhEvening = date(year: 2025, month: 6, day: 6, hour: 21)
        let maghribTime = maghrib(year: 2025, month: 6, day: 6, hour: 20, minute: 30)

        let promotions = HomeIntentResolver.seasonalPromotions(for: dhEvening, maghribTime: maghribTime)
        let hasBlessedDays = promotions.contains { $0.subtitle == "Blessed days of Dhul Hijjah" }
        XCTAssertFalse(hasBlessedDays, "After Maghrib on Dhul Hijjah 10 → day 11, blessed days over")
    }

    // MARK: - Widget Hijri Per-Entry Date

    func test_widgetHijriHelper_differentDatesProduceDifferentResults() {
        let helper = HijriDateHelper()
        let maghribTime = maghrib(year: 2025, month: 3, day: 15, hour: 18)

        // Before Maghrib entry
        let beforeEntry = date(year: 2025, month: 3, day: 15, hour: 14)
        let beforeHijri = helper.hijriDateString(from: beforeEntry, maghribTime: maghribTime)

        // After Maghrib entry (simulates future timeline entry)
        let afterEntry = date(year: 2025, month: 3, day: 15, hour: 19)
        let afterHijri = helper.hijriDateString(from: afterEntry, maghribTime: maghribTime)

        XCTAssertNotEqual(beforeHijri, afterHijri,
                          "Widget entries before/after Maghrib should show different Hijri dates")
    }

    // MARK: - Qada Reminder Maghrib Boundary

    func test_qadaReminder_afterMaghrib_usesAdjustedDate() {
        // After Maghrib on Shawwal 3 → should be Shawwal 4 (eligible)
        // Shawwal 3, 1446 ≈ April 1, 2025
        let shawwal3Evening = date(year: 2025, month: 4, day: 1, hour: 20)
        let maghribTime = maghrib(year: 2025, month: 4, day: 1, hour: 18, minute: 30)

        // Without Maghrib: Shawwal 3 (not eligible)
        let midnightComponents = converter.islamicDate(from: shawwal3Evening, adjustedFor: nil)
        let midnightDay = midnightComponents.day ?? 0

        // With Maghrib: Shawwal 4 (eligible)
        let adjustedComponents = converter.islamicDate(from: shawwal3Evening, adjustedFor: maghribTime)
        let adjustedDay = adjustedComponents.day ?? 0

        XCTAssertEqual(adjustedDay, midnightDay + 1,
                       "After Maghrib on Shawwal 3 → day should advance to 4")
    }
}
