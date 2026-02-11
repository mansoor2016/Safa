// MARK: - HomeBannerResolverTests.swift
// PURPOSE: Tests for HomeBannerResolver pure-function banner visibility logic
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class HomeBannerResolverTests: XCTestCase {

    // MARK: - Helpers

    private func makeCalendar(
        isRamadan: Bool = false,
        currentRamadanDay: Int = 0,
        isLastTenNights: Bool = false,
        daysUntilRamadan: Int? = nil,
        currentEidType: EidType? = nil,
        eidDayNumber: Int = 0,
        nextEidType: EidType? = nil,
        daysUntilNextEid: Int? = nil,
        isForceRamadanMode: Bool = false,
        isForceEidAlFitr: Bool = false,
        isForceEidAlAdha: Bool = false
    ) -> HomeBannerResolver.IslamicCalendarState {
        HomeBannerResolver.IslamicCalendarState(
            isRamadan: isRamadan,
            currentRamadanDay: currentRamadanDay,
            isLastTenNights: isLastTenNights,
            daysUntilRamadan: daysUntilRamadan,
            currentEidType: currentEidType,
            eidDayNumber: eidDayNumber,
            nextEidType: nextEidType,
            daysUntilNextEid: daysUntilNextEid,
            isForceRamadanMode: isForceRamadanMode,
            isForceEidAlFitr: isForceEidAlFitr,
            isForceEidAlAdha: isForceEidAlAdha
        )
    }

    private func makeDismiss(
        ramadan: Bool = false,
        eid: Bool = false,
        share: Bool = false,
        resume: Bool = false
    ) -> HomeBannerResolver.DismissState {
        HomeBannerResolver.DismissState(
            isRamadanBannerDismissedToday: ramadan,
            isEidBannerDismissedToday: eid,
            isShareBannerDismissedPermanently: share,
            isResumeCardDismissedToday: resume
        )
    }

    private func makeQuran(
        lastSurah: Int = 0,
        lastAyah: Int = 0
    ) -> HomeBannerResolver.QuranState {
        HomeBannerResolver.QuranState(lastSurah: lastSurah, lastAyah: lastAyah)
    }

    // MARK: - Ramadan Banner Tests

    func test_ramadan_duringRamadanDay1() {
        let cal = makeCalendar(isRamadan: true, currentRamadanDay: 1)
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringRamadan(day: 1, isLastTenNights: false))
    }

    func test_ramadan_duringRamadanDay15() {
        let cal = makeCalendar(isRamadan: true, currentRamadanDay: 15)
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringRamadan(day: 15, isLastTenNights: false))
    }

    func test_ramadan_duringRamadanDay20_notLastTen() {
        let cal = makeCalendar(isRamadan: true, currentRamadanDay: 20)
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringRamadan(day: 20, isLastTenNights: false))
    }

    func test_ramadan_duringRamadanDay21_lastTenNightsStart() {
        let cal = makeCalendar(isRamadan: true, currentRamadanDay: 21)
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringRamadan(day: 21, isLastTenNights: true))
    }

    func test_ramadan_duringRamadanDay27_lastTenNights() {
        let cal = makeCalendar(isRamadan: true, currentRamadanDay: 27)
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringRamadan(day: 27, isLastTenNights: true))
    }

    func test_ramadan_duringRamadanDay30_lastTenNights() {
        let cal = makeCalendar(isRamadan: true, currentRamadanDay: 30)
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringRamadan(day: 30, isLastTenNights: true))
    }

    func test_ramadan_preRamadan1Day() {
        let cal = makeCalendar(daysUntilRamadan: 1)
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .preRamadan(daysUntil: 1))
    }

    func test_ramadan_preRamadan30Days() {
        let cal = makeCalendar(daysUntilRamadan: 30)
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .preRamadan(daysUntil: 30))
    }

    func test_ramadan_preRamadan31Days_hidden() {
        let cal = makeCalendar(daysUntilRamadan: 31)
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .hidden)
    }

    func test_ramadan_noRamadanNoDays_hidden() {
        let cal = makeCalendar()
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .hidden)
    }

    func test_ramadan_dismissed_hidden() {
        let cal = makeCalendar(isRamadan: true, currentRamadanDay: 15)
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss(ramadan: true))
        XCTAssertEqual(result, .hidden)
    }

    func test_ramadan_forceMode() {
        let cal = makeCalendar(currentRamadanDay: 10, isForceRamadanMode: true)
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringRamadan(day: 10, isLastTenNights: false))
    }

    func test_ramadan_forceModeDay0_clampedTo1() {
        let cal = makeCalendar(currentRamadanDay: 0, isForceRamadanMode: true)
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringRamadan(day: 1, isLastTenNights: false))
    }

    func test_ramadan_negativeDaysUntil_hidden() {
        let cal = makeCalendar(daysUntilRamadan: -5)
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .hidden)
    }

    func test_ramadan_zeroDaysUntil_hidden() {
        let cal = makeCalendar(daysUntilRamadan: 0)
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .hidden)
    }

    // MARK: - Eid Banner Tests

    func test_eid_duringFitrDay1() {
        let cal = makeCalendar(currentEidType: .fitr, eidDayNumber: 1)
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringEid(type: .fitr, dayNumber: 1))
    }

    func test_eid_duringFitrDay3() {
        let cal = makeCalendar(currentEidType: .fitr, eidDayNumber: 3)
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringEid(type: .fitr, dayNumber: 3))
    }

    func test_eid_duringAdhaDay1() {
        let cal = makeCalendar(currentEidType: .adha, eidDayNumber: 1)
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringEid(type: .adha, dayNumber: 1))
    }

    func test_eid_duringAdhaDay4() {
        let cal = makeCalendar(currentEidType: .adha, eidDayNumber: 4)
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringEid(type: .adha, dayNumber: 4))
    }

    func test_eid_preEid1Day() {
        let cal = makeCalendar(nextEidType: .fitr, daysUntilNextEid: 1)
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .preEid(type: .fitr, daysUntil: 1))
    }

    func test_eid_preEid3Days() {
        let cal = makeCalendar(nextEidType: .adha, daysUntilNextEid: 3)
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .preEid(type: .adha, daysUntil: 3))
    }

    func test_eid_preEid7Days() {
        let cal = makeCalendar(nextEidType: .fitr, daysUntilNextEid: 7)
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .preEid(type: .fitr, daysUntil: 7))
    }

    func test_eid_preEid8Days_hidden() {
        let cal = makeCalendar(nextEidType: .fitr, daysUntilNextEid: 8)
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .hidden)
    }

    func test_eid_noEid_hidden() {
        let cal = makeCalendar()
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .hidden)
    }

    func test_eid_dismissed_hidden() {
        let cal = makeCalendar(currentEidType: .fitr, eidDayNumber: 1)
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss(eid: true))
        XCTAssertEqual(result, .hidden)
    }

    func test_eid_forceFitr() {
        let cal = makeCalendar(isForceEidAlFitr: true)
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringEid(type: .fitr, dayNumber: 1))
    }

    func test_eid_forceAdha() {
        let cal = makeCalendar(isForceEidAlAdha: true)
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringEid(type: .adha, dayNumber: 1))
    }

    func test_eid_forceFitrTakesPrecedenceOverForceAdha() {
        let cal = makeCalendar(isForceEidAlFitr: true, isForceEidAlAdha: true)
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringEid(type: .fitr, dayNumber: 1))
    }

    func test_eid_forceTakesPrecedenceOverNatural() {
        let cal = makeCalendar(currentEidType: .adha, eidDayNumber: 3, isForceEidAlFitr: true)
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringEid(type: .fitr, dayNumber: 1))
    }

    func test_eid_zeroDaysUntil_hidden() {
        let cal = makeCalendar(nextEidType: .fitr, daysUntilNextEid: 0)
        let result = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .hidden)
    }

    // MARK: - Share Banner Tests

    func test_share_notDismissed_visible() {
        let result = HomeBannerResolver.resolveShareBanner(dismiss: makeDismiss(share: false))
        XCTAssertEqual(result, .visible)
    }

    func test_share_dismissed_hidden() {
        let result = HomeBannerResolver.resolveShareBanner(dismiss: makeDismiss(share: true))
        XCTAssertEqual(result, .hidden)
    }

    func test_share_defaultState_visible() {
        let result = HomeBannerResolver.resolveShareBanner(dismiss: makeDismiss())
        XCTAssertEqual(result, .visible)
    }

    // MARK: - Resume Card Tests

    func test_resume_hasProgress_visible() {
        let result = HomeBannerResolver.resolveResumeCard(
            quran: makeQuran(lastSurah: 2, lastAyah: 50),
            dismiss: makeDismiss()
        )
        XCTAssertEqual(result, .visible(lastSurah: 2, lastAyah: 50))
    }

    func test_resume_noProgress_hidden() {
        let result = HomeBannerResolver.resolveResumeCard(
            quran: makeQuran(lastSurah: 0, lastAyah: 0),
            dismiss: makeDismiss()
        )
        XCTAssertEqual(result, .hidden)
    }

    func test_resume_dismissed_hidden() {
        let result = HomeBannerResolver.resolveResumeCard(
            quran: makeQuran(lastSurah: 5, lastAyah: 10),
            dismiss: makeDismiss(resume: true)
        )
        XCTAssertEqual(result, .hidden)
    }

    func test_resume_surah114_visible() {
        let result = HomeBannerResolver.resolveResumeCard(
            quran: makeQuran(lastSurah: 114, lastAyah: 6),
            dismiss: makeDismiss()
        )
        XCTAssertEqual(result, .visible(lastSurah: 114, lastAyah: 6))
    }

    func test_resume_surah0WithAyah_hidden() {
        let result = HomeBannerResolver.resolveResumeCard(
            quran: makeQuran(lastSurah: 0, lastAyah: 5),
            dismiss: makeDismiss()
        )
        XCTAssertEqual(result, .hidden)
    }

    // MARK: - Pinned Hijri Date Integration Tests

    /// Helper: build a Date for a specific Hijri date using Umm al-Qura calendar
    private func hijriDate(year: Int, month: Int, day: Int) -> Date? {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)
    }

    /// Helper: build IslamicCalendarState from a Hijri date using HijriDateConverter
    private func calendarStateFromHijriDate(
        year: Int, month: Int, day: Int
    ) -> HomeBannerResolver.IslamicCalendarState? {
        guard let date = hijriDate(year: year, month: month, day: day) else { return nil }
        let converter = HijriDateConverter.shared
        let isRamadan = converter.isRamadan(on: date)
        let ramadanDay = isRamadan ? day : 0
        let daysUntilRamadan = isRamadan ? nil : converter.daysUntilRamadan(from: date)
        let currentEid = converter.currentEidType(on: date)
        let eidDay = converter.eidDayNumber(on: date) ?? 0
        let nearest = currentEid == nil ? converter.nearestUpcomingEid(from: date) : nil

        return HomeBannerResolver.IslamicCalendarState(
            isRamadan: isRamadan,
            currentRamadanDay: ramadanDay,
            isLastTenNights: ramadanDay >= 21 && ramadanDay <= 30,
            daysUntilRamadan: daysUntilRamadan,
            currentEidType: currentEid,
            eidDayNumber: eidDay,
            nextEidType: nearest?.type,
            daysUntilNextEid: nearest?.daysUntil,
            isForceRamadanMode: false,
            isForceEidAlFitr: false,
            isForceEidAlAdha: false
        )
    }

    func test_pinnedHijri_ramadan1_duringRamadan() {
        guard let cal = calendarStateFromHijriDate(year: 1447, month: 9, day: 1) else {
            return XCTFail("Could not construct Hijri date")
        }
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringRamadan(day: 1, isLastTenNights: false))
    }

    func test_pinnedHijri_shaban30_preRamadan() {
        guard let cal = calendarStateFromHijriDate(year: 1447, month: 8, day: 30) else {
            // Sha'ban may have 29 days — try day 29
            guard let cal = calendarStateFromHijriDate(year: 1447, month: 8, day: 29) else {
                return XCTFail("Could not construct Hijri date for late Sha'ban")
            }
            let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
            // Should be pre-Ramadan with small daysUntil
            if case .preRamadan(let days) = result {
                XCTAssertLessThanOrEqual(days, 2, "Should be 1-2 days before Ramadan")
            } else if case .duringRamadan = result {
                // Calendar edge case — acceptable
            } else {
                XCTFail("Expected preRamadan or duringRamadan, got \(result)")
            }
            return
        }
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        if case .preRamadan(let days) = result {
            XCTAssertLessThanOrEqual(days, 2, "Should be ~1 day before Ramadan")
        } else if case .duringRamadan = result {
            // Calendar edge case — acceptable
        } else {
            XCTFail("Expected preRamadan or duringRamadan, got \(result)")
        }
    }

    func test_pinnedHijri_ramadan21_lastTenNights() {
        guard let cal = calendarStateFromHijriDate(year: 1447, month: 9, day: 21) else {
            return XCTFail("Could not construct Hijri date")
        }
        let result = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(result, .duringRamadan(day: 21, isLastTenNights: true))
    }

    func test_pinnedHijri_shawwal1_eidFitrVisible_ramadanHidden() {
        guard let cal = calendarStateFromHijriDate(year: 1447, month: 10, day: 1) else {
            return XCTFail("Could not construct Hijri date")
        }
        let dismiss = makeDismiss()
        let ramadan = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: dismiss)
        let eid = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: dismiss)

        XCTAssertEqual(ramadan, .hidden, "Ramadan banner should be hidden on Shawwal 1")
        XCTAssertEqual(eid, .duringEid(type: .fitr, dayNumber: 1))
    }

    func test_pinnedHijri_shawwal4_eidHidden() {
        guard let cal = calendarStateFromHijriDate(year: 1447, month: 10, day: 4) else {
            return XCTFail("Could not construct Hijri date")
        }
        let eid = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        // Shawwal 4 is past Eid al-Fitr (1-3), but may show pre-Eid Adha if within 7 days
        XCTAssertNotEqual(eid, .duringEid(type: .fitr, dayNumber: 1), "Should not be during Fitr on Shawwal 4")
        if case .duringEid(type: .fitr, dayNumber: _) = eid {
            XCTFail("Shawwal 4 should not show Eid al-Fitr banner")
        }
    }

    func test_pinnedHijri_dhulHijjah10_eidAdha() {
        guard let cal = calendarStateFromHijriDate(year: 1447, month: 12, day: 10) else {
            return XCTFail("Could not construct Hijri date")
        }
        let eid = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        XCTAssertEqual(eid, .duringEid(type: .adha, dayNumber: 1))
    }

    func test_pinnedHijri_dhulHijjah14_eidHidden() {
        guard let cal = calendarStateFromHijriDate(year: 1447, month: 12, day: 14) else {
            return XCTFail("Could not construct Hijri date")
        }
        let eid = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: makeDismiss())
        if case .duringEid(type: .adha, dayNumber: _) = eid {
            XCTFail("Dhu al-Hijjah 14 is past Eid al-Adha (10-13)")
        }
    }

    func test_pinnedHijri_rajab15_allHidden() {
        guard let cal = calendarStateFromHijriDate(year: 1447, month: 7, day: 15) else {
            return XCTFail("Could not construct Hijri date")
        }
        let dismiss = makeDismiss()
        let ramadan = HomeBannerResolver.resolveRamadanBanner(calendar: cal, dismiss: dismiss)
        let eid = HomeBannerResolver.resolveEidBanner(calendar: cal, dismiss: dismiss)

        // Rajab is month 7 — Ramadan is ~2 months away (>30 days), no Eid nearby
        XCTAssertEqual(ramadan, .hidden, "Ramadan banner should be hidden in Rajab")
        if case .duringEid = eid {
            XCTFail("Should not be during any Eid in Rajab")
        }
    }

    // MARK: - Boundary Tests

    func test_boundary_day20To21_lastTenNightsTransition() {
        let day20 = makeCalendar(isRamadan: true, currentRamadanDay: 20)
        let day21 = makeCalendar(isRamadan: true, currentRamadanDay: 21)

        let result20 = HomeBannerResolver.resolveRamadanBanner(calendar: day20, dismiss: makeDismiss())
        let result21 = HomeBannerResolver.resolveRamadanBanner(calendar: day21, dismiss: makeDismiss())

        XCTAssertEqual(result20, .duringRamadan(day: 20, isLastTenNights: false))
        XCTAssertEqual(result21, .duringRamadan(day: 21, isLastTenNights: true))
    }

    func test_boundary_preEid7To8_cutoff() {
        let within = makeCalendar(nextEidType: .fitr, daysUntilNextEid: 7)
        let outside = makeCalendar(nextEidType: .fitr, daysUntilNextEid: 8)

        let resultWithin = HomeBannerResolver.resolveEidBanner(calendar: within, dismiss: makeDismiss())
        let resultOutside = HomeBannerResolver.resolveEidBanner(calendar: outside, dismiss: makeDismiss())

        XCTAssertEqual(resultWithin, .preEid(type: .fitr, daysUntil: 7))
        XCTAssertEqual(resultOutside, .hidden)
    }

    func test_boundary_preRamadan30To31_cutoff() {
        let within = makeCalendar(daysUntilRamadan: 30)
        let outside = makeCalendar(daysUntilRamadan: 31)

        let resultWithin = HomeBannerResolver.resolveRamadanBanner(calendar: within, dismiss: makeDismiss())
        let resultOutside = HomeBannerResolver.resolveRamadanBanner(calendar: outside, dismiss: makeDismiss())

        XCTAssertEqual(resultWithin, .preRamadan(daysUntil: 30))
        XCTAssertEqual(resultOutside, .hidden)
    }

    func test_boundary_fitrDay3ToShawwal4_eidEnds() {
        let day3 = makeCalendar(currentEidType: .fitr, eidDayNumber: 3)
        let day4 = makeCalendar() // Shawwal 4 — no Eid

        let resultDay3 = HomeBannerResolver.resolveEidBanner(calendar: day3, dismiss: makeDismiss())
        let resultDay4 = HomeBannerResolver.resolveEidBanner(calendar: day4, dismiss: makeDismiss())

        XCTAssertEqual(resultDay3, .duringEid(type: .fitr, dayNumber: 3))
        XCTAssertEqual(resultDay4, .hidden)
    }
}
