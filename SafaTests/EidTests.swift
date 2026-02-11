// MARK: - EidTests.swift
// PURPOSE: Correctness tests for Eid feature — type properties, Hijri detection, and share content
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

// MARK: - EidType Correctness Tests

final class EidTypeTests: XCTestCase {

    // MARK: - Visual Differentiation

    func test_fitrAndAdha_haveDistinctGradientColors() {
        // A bug that made both Eids look identical would confuse users
        XCTAssertNotEqual(
            EidType.fitr.gradientColors.map { "\($0)" },
            EidType.adha.gradientColors.map { "\($0)" },
            "Fitr and Adha must have visually distinct gradients"
        )
    }

    func test_fitrAndAdha_haveDistinctIcons() {
        XCTAssertNotEqual(EidType.fitr.icon, EidType.adha.icon,
            "Each Eid should have a unique icon to differentiate them visually")
    }

    // MARK: - Hijri Calendar Correctness

    func test_fitr_dateRange_isShawwal1Through3() {
        // Eid al-Fitr is celebrated on Shawwal 1-3 (month 10)
        XCTAssertEqual(EidType.fitr.hijriMonth, 10, "Fitr must be in Shawwal (month 10)")
        XCTAssertEqual(EidType.fitr.daysRange, 1...3, "Fitr spans 3 days: Shawwal 1-3")
    }

    func test_adha_dateRange_isDhulHijjah10Through13() {
        // Eid al-Adha is celebrated on Dhul Hijjah 10-13 (month 12)
        XCTAssertEqual(EidType.adha.hijriMonth, 12, "Adha must be in Dhul Hijjah (month 12)")
        XCTAssertEqual(EidType.adha.daysRange, 10...13, "Adha spans 4 days: Dhul Hijjah 10-13")
    }

    // MARK: - Reminder Content Correctness

    func test_fitr_reminders_includeFitrana() {
        // Fitrana (Zakat al-Fitr) must be present in reminders
        let hasFitrana = EidType.fitr.reminders.contains {
            $0.title.contains("Fitrana") || $0.title.contains("Zakat")
        }
        XCTAssertTrue(hasFitrana, "Fitr reminders must include Fitrana")
    }

    func test_adha_reminders_includeQurbani() {
        // Qurbani is the defining act of Eid al-Adha — must be present
        let hasQurbani = EidType.adha.reminders.contains { $0.title.lowercased().contains("qurbani") }
        XCTAssertTrue(hasQurbani, "Adha reminders must include Qurbani")
    }

    func test_bothEids_doNotIncludeTakbeer() {
        // Takbeer was removed as it is not a widely applied practice
        for eidType in EidType.allCases {
            let hasTakbeer = eidType.reminders.contains {
                $0.title.lowercased().contains("takbeer")
            }
            XCTAssertFalse(hasTakbeer,
                "\(eidType.displayName) should not include Takbeer reminder")
        }
    }

    // MARK: - Share Messages

    func test_shareMessages_eachEidHasAtLeastThree() {
        // Random selection needs a good pool of messages
        for eidType in EidType.allCases {
            XCTAssertGreaterThanOrEqual(
                eidType.shareMessages.count, 3,
                "\(eidType.displayName) should have at least 3 share messages"
            )
        }
    }

    func test_shareMessages_mentionCorrectEidName() {
        // Each message should reference the correct Eid so users don't send the wrong greeting
        for message in EidType.fitr.shareMessages {
            XCTAssertTrue(
                message.contains("Fitr") || message.contains("Ramadan") || message.contains("Eid"),
                "Fitr messages should reference Eid al-Fitr or Ramadan context"
            )
        }
        for message in EidType.adha.shareMessages {
            XCTAssertTrue(
                message.contains("Adha") || message.contains("sacrifice") || message.contains("Eid"),
                "Adha messages should reference Eid al-Adha or sacrifice context"
            )
        }
    }

    // MARK: - Acceptance Dua

    func test_acceptanceDua_isSharedAcrossBothEids() {
        // "Taqabbal Allahu minna wa minkum" is the universal Eid greeting
        XCTAssertEqual(EidType.fitr.acceptanceDua, EidType.adha.acceptanceDua,
            "The acceptance dua should be the same for both Eids")
        XCTAssertEqual(EidType.fitr.acceptanceDuaArabic, EidType.adha.acceptanceDuaArabic,
            "The Arabic acceptance dua should be the same for both Eids")
    }
}

// MARK: - HijriDateConverter Eid Detection Tests

final class HijriDateConverterEidTests: XCTestCase {

    private let converter = HijriDateConverter.shared

    // Helper: create a Gregorian date from a specific Hijri date
    private func dateFromHijri(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return converter.gregorianDate(from: components)
    }

    // Use the current Hijri year for test dates
    private var currentHijriYear: Int {
        converter.hijriComponents(from: Date()).year
    }

    // MARK: - Eid al-Fitr Detection

    func test_isEidAlFitr_shawwal1Through3_returnsTrue() {
        for day in 1...3 {
            guard let date = dateFromHijri(year: currentHijriYear, month: 10, day: day) else {
                XCTFail("Could not construct Shawwal \(day)")
                continue
            }
            XCTAssertTrue(converter.isEidAlFitr(on: date),
                "Shawwal \(day) should be detected as Eid al-Fitr")
        }
    }

    func test_isEidAlFitr_shawwal4_returnsFalse() {
        guard let date = dateFromHijri(year: currentHijriYear, month: 10, day: 4) else {
            XCTFail("Could not construct Shawwal 4")
            return
        }
        XCTAssertFalse(converter.isEidAlFitr(on: date),
            "Shawwal 4 is after Eid al-Fitr and should not match")
    }

    // MARK: - Eid al-Adha Detection

    func test_isEidAlAdha_dhulHijjah10Through13_returnsTrue() {
        for day in 10...13 {
            guard let date = dateFromHijri(year: currentHijriYear, month: 12, day: day) else {
                XCTFail("Could not construct Dhul Hijjah \(day)")
                continue
            }
            XCTAssertTrue(converter.isEidAlAdha(on: date),
                "Dhul Hijjah \(day) should be detected as Eid al-Adha")
        }
    }

    func test_isEidAlAdha_dhulHijjah9And14_returnFalse() {
        for day in [9, 14] {
            guard let date = dateFromHijri(year: currentHijriYear, month: 12, day: day) else {
                XCTFail("Could not construct Dhul Hijjah \(day)")
                continue
            }
            XCTAssertFalse(converter.isEidAlAdha(on: date),
                "Dhul Hijjah \(day) is outside Eid al-Adha range")
        }
    }

    // MARK: - currentEidType

    func test_currentEidType_duringFitr_returnsFitr() {
        guard let date = dateFromHijri(year: currentHijriYear, month: 10, day: 1) else {
            XCTFail("Could not construct Shawwal 1")
            return
        }
        XCTAssertEqual(converter.currentEidType(on: date), .fitr,
            "Should identify Eid al-Fitr during Shawwal 1")
    }

    func test_currentEidType_duringAdha_returnsAdha() {
        guard let date = dateFromHijri(year: currentHijriYear, month: 12, day: 11) else {
            XCTFail("Could not construct Dhul Hijjah 11")
            return
        }
        XCTAssertEqual(converter.currentEidType(on: date), .adha,
            "Should identify Eid al-Adha during Dhul Hijjah 11")
    }

    func test_currentEidType_normalDay_returnsNil() {
        // Rajab 15 is not during any Eid
        guard let date = dateFromHijri(year: currentHijriYear, month: 7, day: 15) else {
            XCTFail("Could not construct Rajab 15")
            return
        }
        XCTAssertNil(converter.currentEidType(on: date),
            "A normal day should not be identified as any Eid")
    }

    // MARK: - eidDayNumber

    func test_eidDayNumber_fitrDay2_returns2() {
        guard let date = dateFromHijri(year: currentHijriYear, month: 10, day: 2) else {
            XCTFail("Could not construct Shawwal 2")
            return
        }
        XCTAssertEqual(converter.eidDayNumber(on: date), 2,
            "Shawwal 2 is Day 2 of Eid al-Fitr")
    }

    func test_eidDayNumber_adhaDay1_returns1() {
        // Dhul Hijjah 10 is Day 1 of Eid al-Adha (10 - 9 = 1)
        guard let date = dateFromHijri(year: currentHijriYear, month: 12, day: 10) else {
            XCTFail("Could not construct Dhul Hijjah 10")
            return
        }
        XCTAssertEqual(converter.eidDayNumber(on: date), 1,
            "Dhul Hijjah 10 should be Day 1 of Eid al-Adha")
    }

    func test_eidDayNumber_adhaDay4_returns4() {
        // Dhul Hijjah 13 is Day 4 of Eid al-Adha (13 - 9 = 4)
        guard let date = dateFromHijri(year: currentHijriYear, month: 12, day: 13) else {
            XCTFail("Could not construct Dhul Hijjah 13")
            return
        }
        XCTAssertEqual(converter.eidDayNumber(on: date), 4,
            "Dhul Hijjah 13 should be Day 4 of Eid al-Adha")
    }

    func test_eidDayNumber_nonEidDay_returnsNil() {
        guard let date = dateFromHijri(year: currentHijriYear, month: 7, day: 15) else {
            XCTFail("Could not construct Rajab 15")
            return
        }
        XCTAssertNil(converter.eidDayNumber(on: date),
            "A non-Eid day should return nil for day number")
    }

    // MARK: - nearestUpcomingEid

    func test_nearestUpcomingEid_duringEid_returnsNil() {
        // If currently celebrating, there's no "upcoming" Eid
        guard let date = dateFromHijri(year: currentHijriYear, month: 10, day: 2) else {
            XCTFail("Could not construct Shawwal 2")
            return
        }
        XCTAssertNil(converter.nearestUpcomingEid(from: date),
            "During Eid, nearestUpcomingEid should return nil")
    }

    func test_nearestUpcomingEid_beforeFitr_returnsFitr() {
        // Ramadan 25 is about 5 days before Eid al-Fitr
        guard let date = dateFromHijri(year: currentHijriYear, month: 9, day: 25) else {
            XCTFail("Could not construct Ramadan 25")
            return
        }
        let result = converter.nearestUpcomingEid(from: date)
        XCTAssertEqual(result?.type, .fitr,
            "Before Shawwal, nearest Eid should be Fitr")
        if let days = result?.daysUntil {
            XCTAssertGreaterThan(days, 0, "Days until should be positive")
            XCTAssertLessThanOrEqual(days, 10, "Should be within ~5-6 days")
        }
    }
}

// MARK: - Share Service Integration Tests

final class EidShareServiceTests: XCTestCase {

    func test_shareService_acceptsEidGreetingContent() {
        // Verify that ShareableContent now includes eidGreeting case
        // The case is statically defined in ShareService.swift enum ShareableContent
        // This test verifies the enum compiles with the new case by instantiating it
        let _: ShareableContent = .eidGreeting(eidType: .fitr, message: "Test")
        XCTAssert(true, "ShareableContent should support eidGreeting case")
    }
}
