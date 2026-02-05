// MARK: - IslamicEventTests.swift
// PURPOSE: Unit tests for Islamic calendar events

import XCTest
@testable import Safa

final class IslamicEventTests: XCTestCase {

    // MARK: - IslamicEventType Tests

    func testIslamicEventTypeAllCases() {
        XCTAssertEqual(IslamicEventType.allCases.count, 13)
        XCTAssertTrue(IslamicEventType.allCases.contains(.ramadanStart))
        XCTAssertTrue(IslamicEventType.allCases.contains(.eidAlFitr))
        XCTAssertTrue(IslamicEventType.allCases.contains(.eidAlAdha))
        XCTAssertTrue(IslamicEventType.allCases.contains(.laylatAlQadr))
    }

    func testIslamicEventTypeDisplayNames() {
        XCTAssertEqual(IslamicEventType.ramadanStart.displayName, "Ramadan Begins")
        XCTAssertEqual(IslamicEventType.ramadanEnd.displayName, "Ramadan Ends")
        XCTAssertEqual(IslamicEventType.eidAlFitr.displayName, "Eid al-Fitr")
        XCTAssertEqual(IslamicEventType.eidAlAdha.displayName, "Eid al-Adha")
        XCTAssertEqual(IslamicEventType.ashura.displayName, "Ashura")
        XCTAssertEqual(IslamicEventType.mawlidAlNabi.displayName, "Mawlid al-Nabi")
        XCTAssertEqual(IslamicEventType.isra.displayName, "Isra")
        XCTAssertEqual(IslamicEventType.miraj.displayName, "Mi'raj")
        XCTAssertEqual(IslamicEventType.laylatAlQadr.displayName, "Laylat al-Qadr")
        XCTAssertEqual(IslamicEventType.arafah.displayName, "Day of Arafah")
        XCTAssertEqual(IslamicEventType.hijriNewYear.displayName, "Islamic New Year")
        XCTAssertEqual(IslamicEventType.whiteDays.displayName, "White Days")
        XCTAssertEqual(IslamicEventType.jumuah.displayName, "Jumu'ah")
    }

    func testIslamicEventTypeIcons() {
        // Ramadan events
        XCTAssertEqual(IslamicEventType.ramadanStart.iconName, "moon.stars")
        XCTAssertEqual(IslamicEventType.ramadanEnd.iconName, "moon.stars")

        // Eid events
        XCTAssertEqual(IslamicEventType.eidAlFitr.iconName, "star.fill")
        XCTAssertEqual(IslamicEventType.eidAlAdha.iconName, "star.fill")

        // Other events have icons
        XCTAssertFalse(IslamicEventType.ashura.iconName.isEmpty)
        XCTAssertFalse(IslamicEventType.laylatAlQadr.iconName.isEmpty)
        XCTAssertFalse(IslamicEventType.arafah.iconName.isEmpty)
    }

    func testIslamicEventTypeRawValues() {
        XCTAssertEqual(IslamicEventType.ramadanStart.rawValue, "ramadan_start")
        XCTAssertEqual(IslamicEventType.eidAlFitr.rawValue, "eid_al_fitr")
        XCTAssertEqual(IslamicEventType.eidAlAdha.rawValue, "eid_al_adha")
        XCTAssertEqual(IslamicEventType.laylatAlQadr.rawValue, "laylat_al_qadr")
        XCTAssertEqual(IslamicEventType.hijriNewYear.rawValue, "hijri_new_year")
    }

    func testIslamicEventTypeCodable() throws {
        let original = IslamicEventType.eidAlFitr

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(IslamicEventType.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    // MARK: - IslamicEvent Tests

    func testIslamicEventCreation() {
        let event = IslamicEvent(
            id: "ramadan_start_1446",
            name: "Ramadan Begins",
            nameArabic: "بداية رمضان",
            description: "The holy month of fasting begins",
            type: .ramadanStart,
            hijriMonth: 9,
            hijriDay: 1,
            gregorianDate: nil
        )

        XCTAssertEqual(event.id, "ramadan_start_1446")
        XCTAssertEqual(event.name, "Ramadan Begins")
        XCTAssertEqual(event.nameArabic, "بداية رمضان")
        XCTAssertEqual(event.type, .ramadanStart)
        XCTAssertEqual(event.hijriMonth, 9) // Ramadan is month 9
        XCTAssertEqual(event.hijriDay, 1)
        XCTAssertNil(event.gregorianDate)
    }

    func testIslamicEventWithGregorianDate() {
        var event = IslamicEvent(
            id: "eid_fitr_1446",
            name: "Eid al-Fitr",
            nameArabic: "عيد الفطر",
            description: "Festival of Breaking the Fast",
            type: .eidAlFitr,
            hijriMonth: 10,
            hijriDay: 1,
            gregorianDate: Date()
        )

        XCTAssertNotNil(event.gregorianDate)

        // Test mutability of gregorianDate
        event.gregorianDate = nil
        XCTAssertNil(event.gregorianDate)
    }

    func testIslamicEventEquality() {
        let event1 = IslamicEvent(
            id: "test_event",
            name: "Test Event",
            nameArabic: "حدث اختبار",
            description: "Test",
            type: .ashura,
            hijriMonth: 1,
            hijriDay: 10,
            gregorianDate: nil
        )

        let event2 = IslamicEvent(
            id: "test_event",
            name: "Different Name",
            nameArabic: "اسم مختلف",
            description: "Different description",
            type: .mawlidAlNabi,
            hijriMonth: 3,
            hijriDay: 12,
            gregorianDate: nil
        )

        // Events are equal if IDs match
        XCTAssertEqual(event1, event2)
    }

    func testIslamicEventInequalityDifferentIds() {
        let event1 = IslamicEvent(
            id: "event_1",
            name: "Event",
            nameArabic: "حدث",
            description: "Test",
            type: .ashura,
            hijriMonth: 1,
            hijriDay: 10,
            gregorianDate: nil
        )

        let event2 = IslamicEvent(
            id: "event_2",
            name: "Event",
            nameArabic: "حدث",
            description: "Test",
            type: .ashura,
            hijriMonth: 1,
            hijriDay: 10,
            gregorianDate: nil
        )

        XCTAssertNotEqual(event1, event2)
    }

    func testIslamicEventNextOccurrence() {
        let event = IslamicEvent(
            id: "ramadan_start",
            name: "Ramadan Begins",
            nameArabic: "بداية رمضان",
            description: "Test",
            type: .ramadanStart,
            hijriMonth: 9,
            hijriDay: 1,
            gregorianDate: nil
        )

        let nextOccurrence = event.nextOccurrence(from: Date())

        // Should return a date (Ramadan happens every year)
        XCTAssertNotNil(nextOccurrence)

        // Date should be in the future or today
        if let date = nextOccurrence {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            XCTAssertGreaterThanOrEqual(date, today)
        }
    }

    func testIslamicEventHijriMonths() {
        // Test correct Hijri months for major events

        // Ramadan is month 9
        let ramadan = IslamicEvent(
            id: "ramadan",
            name: "Ramadan",
            nameArabic: "رمضان",
            description: "",
            type: .ramadanStart,
            hijriMonth: 9,
            hijriDay: 1,
            gregorianDate: nil
        )
        XCTAssertEqual(ramadan.hijriMonth, 9)

        // Shawwal (Eid al-Fitr) is month 10
        let eidFitr = IslamicEvent(
            id: "eid_fitr",
            name: "Eid al-Fitr",
            nameArabic: "عيد الفطر",
            description: "",
            type: .eidAlFitr,
            hijriMonth: 10,
            hijriDay: 1,
            gregorianDate: nil
        )
        XCTAssertEqual(eidFitr.hijriMonth, 10)

        // Dhul Hijjah (Eid al-Adha) is month 12
        let eidAdha = IslamicEvent(
            id: "eid_adha",
            name: "Eid al-Adha",
            nameArabic: "عيد الأضحى",
            description: "",
            type: .eidAlAdha,
            hijriMonth: 12,
            hijriDay: 10,
            gregorianDate: nil
        )
        XCTAssertEqual(eidAdha.hijriMonth, 12)

        // Muharram (Ashura, New Year) is month 1
        let ashura = IslamicEvent(
            id: "ashura",
            name: "Ashura",
            nameArabic: "عاشوراء",
            description: "",
            type: .ashura,
            hijriMonth: 1,
            hijriDay: 10,
            gregorianDate: nil
        )
        XCTAssertEqual(ashura.hijriMonth, 1)
    }

    // MARK: - EventAction Tests

    func testEventActionCreation() {
        let action = EventAction(
            title: "Open Fasting Guide",
            action: .openFastingGuide
        )

        XCTAssertFalse(action.title.isEmpty)
        XCTAssertNotNil(action.id)
    }

    func testEventActionTypes() {
        // Test various action types exist
        _ = EventAction(title: "Fasting", action: .openFastingGuide)
        _ = EventAction(title: "Suhoor", action: .setSuhoorReminder)
        _ = EventAction(title: "Iftar", action: .setIftarReminder)
        _ = EventAction(title: "Eid Prayers", action: .openEidPrayers)
        _ = EventAction(title: "Share", action: .shareGreeting)
        _ = EventAction(title: "Zakat", action: .openZakatCalculator)
        _ = EventAction(title: "Learning", action: .openLearning)
        _ = EventAction(title: "Seerah", action: .openSeerah)
        _ = EventAction(title: "Dhikr", action: .openDhikr)
        _ = EventAction(title: "Night Prayers", action: .openNightPrayers)
        _ = EventAction(title: "Laylat al-Qadr", action: .openLaylatAlQadrDuas)
        _ = EventAction(title: "Arafah", action: .openArafahDuas)
        _ = EventAction(title: "Reflection", action: .openReflection)
        _ = EventAction(title: "Goals", action: .openGoals)
        _ = EventAction(title: "Surah Kahf", action: .openSurahKahf)
        _ = EventAction(title: "Friday", action: .openFridayDuas)

        // If we get here without errors, all action types exist
        XCTAssertTrue(true)
    }

    func testEventActionUniqueIds() {
        let action1 = EventAction(title: "Test 1", action: .openFastingGuide)
        let action2 = EventAction(title: "Test 2", action: .openFastingGuide)

        XCTAssertNotEqual(action1.id, action2.id)
    }

    // MARK: - Static Events Tests

    func testAllEventsContainsRequired() {
        let allEvents = IslamicEvent.allEvents

        // Should have events defined
        XCTAssertGreaterThan(allEvents.count, 0)

        // Should include major events
        let eventTypes = Set(allEvents.map { $0.type })
        XCTAssertTrue(eventTypes.contains(.ramadanStart) || eventTypes.contains(.eidAlFitr))
    }
}
