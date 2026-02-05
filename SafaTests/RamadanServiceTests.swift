// MARK: - RamadanServiceTests.swift
// PURPOSE: Unit tests for Ramadan service functionality
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class RamadanServiceTests: XCTestCase {

    var sut: RamadanService!

    override func setUp() {
        super.setUp()
        sut = RamadanService()

        // Clear stored data
        clearRamadanData()
    }

    override func tearDown() {
        clearRamadanData()
        sut = nil
        super.tearDown()
    }

    private func clearRamadanData() {
        UserDefaults.standard.removeObject(forKey: "com.safa.ramadan.enabled")
        UserDefaults.standard.removeObject(forKey: "com.safa.ramadan.suhoorReminder")
        UserDefaults.standard.removeObject(forKey: "com.safa.ramadan.iftarReminder")
        UserDefaults.standard.removeObject(forKey: "com.safa.ramadan.taraweehReminder")
        UserDefaults.standard.removeObject(forKey: "com.safa.ramadan.suhoorMinutes")
        UserDefaults.standard.removeObject(forKey: "com.safa.ramadan.iftarMinutes")
        UserDefaults.standard.removeObject(forKey: "com.safa.ramadan.fastingDays")
        UserDefaults.standard.removeObject(forKey: "com.safa.ramadan.taraweehDays")
    }

    // MARK: - Mode Activation Tests

    func testActivateRamadanMode() {
        XCTAssertFalse(sut.isRamadanMode)

        sut.activateRamadanMode()

        XCTAssertTrue(sut.isRamadanMode)
    }

    func testDeactivateRamadanMode() {
        sut.activateRamadanMode()
        XCTAssertTrue(sut.isRamadanMode)

        sut.deactivateRamadanMode()

        XCTAssertFalse(sut.isRamadanMode)
    }

    func testToggleRamadanMode() {
        XCTAssertFalse(sut.isRamadanMode)

        sut.toggleRamadanMode()
        XCTAssertTrue(sut.isRamadanMode)

        sut.toggleRamadanMode()
        XCTAssertFalse(sut.isRamadanMode)
    }

    // MARK: - Settings Tests

    func testDefaultReminderSettings() {
        XCTAssertTrue(sut.suhoorReminderEnabled)
        XCTAssertTrue(sut.iftarReminderEnabled)
        XCTAssertTrue(sut.taraweehReminderEnabled)
    }

    func testDefaultReminderMinutes() {
        XCTAssertEqual(sut.suhoorReminderMinutesBefore, 30)
        XCTAssertEqual(sut.iftarReminderMinutesBefore, 15)
    }

    func testSaveAndLoadSettings() {
        sut.suhoorReminderEnabled = false
        sut.iftarReminderMinutesBefore = 20
        sut.saveSettings()

        // Create new instance to test loading
        let newService = RamadanService()

        XCTAssertFalse(newService.suhoorReminderEnabled)
        XCTAssertEqual(newService.iftarReminderMinutesBefore, 20)
    }

    // MARK: - Fasting Tracking Tests

    func testGetFastingDaysInitiallyEmpty() {
        let days = sut.getFastingDays()

        XCTAssertTrue(days.isEmpty)
    }

    func testMarkDayFasted() {
        sut.markDayFasted(1)
        sut.markDayFasted(2)
        sut.markDayFasted(3)

        let days = sut.getFastingDays()

        XCTAssertEqual(days.count, 3)
        XCTAssertTrue(days.contains(1))
        XCTAssertTrue(days.contains(2))
        XCTAssertTrue(days.contains(3))
    }

    func testUnmarkDayFasted() {
        sut.markDayFasted(1)
        sut.markDayFasted(2)

        sut.unmarkDayFasted(1)

        let days = sut.getFastingDays()
        XCTAssertEqual(days.count, 1)
        XCTAssertFalse(days.contains(1))
        XCTAssertTrue(days.contains(2))
    }

    func testMarkSameDayTwice() {
        sut.markDayFasted(5)
        sut.markDayFasted(5)

        let days = sut.getFastingDays()
        XCTAssertEqual(days.count, 1)
    }

    // MARK: - Taraweeh Tracking Tests

    func testGetTaraweehDaysInitiallyEmpty() {
        let days = sut.getTaraweehDays()

        XCTAssertTrue(days.isEmpty)
    }

    func testSaveTaraweeh() {
        sut.saveTaraweeh(day: 1, rakaahs: 8)
        sut.saveTaraweeh(day: 2, rakaahs: 20)

        let days = sut.getTaraweehDays()

        XCTAssertEqual(days.count, 2)
        XCTAssertEqual(days[1], 8)
        XCTAssertEqual(days[2], 20)
    }

    func testUpdateTaraweehSameDay() {
        sut.saveTaraweeh(day: 1, rakaahs: 8)
        sut.saveTaraweeh(day: 1, rakaahs: 20)

        let days = sut.getTaraweehDays()

        XCTAssertEqual(days.count, 1)
        XCTAssertEqual(days[1], 20) // Should be updated
    }

    func testTotalTaraweehRakaahs() {
        sut.saveTaraweeh(day: 1, rakaahs: 8)
        sut.saveTaraweeh(day: 2, rakaahs: 8)
        sut.saveTaraweeh(day: 3, rakaahs: 20)

        XCTAssertEqual(sut.totalTaraweehRakaahs, 36)
    }

    // MARK: - Progress Tests

    func testFastingProgressEmpty() {
        XCTAssertEqual(sut.fastingProgress, 0)
    }

    func testFastingProgressPartial() {
        // Set total days manually for testing
        sut.totalRamadanDays = 30

        sut.markDayFasted(1)
        sut.markDayFasted(2)
        sut.markDayFasted(3)

        XCTAssertEqual(sut.fastingProgress, 0.1, accuracy: 0.01)
    }

    func testTaraweehProgressEmpty() {
        XCTAssertEqual(sut.taraweehProgress, 0)
    }

    func testTaraweehProgressPartial() {
        sut.totalRamadanDays = 30

        sut.saveTaraweeh(day: 1, rakaahs: 8)
        sut.saveTaraweeh(day: 2, rakaahs: 8)
        sut.saveTaraweeh(day: 3, rakaahs: 8)

        XCTAssertEqual(sut.taraweehProgress, 0.1, accuracy: 0.01)
    }
}

// MARK: - Islamic Event Service Tests

final class IslamicEventServiceTests: XCTestCase {

    var sut: IslamicEventService!

    override func setUp() {
        super.setUp()
        sut = IslamicEventService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Event Loading Tests

    func testLoadEventsPopulatesUpcoming() {
        sut.loadEvents()

        // Should have some upcoming events (depends on current date)
        // At minimum, there should be major Islamic events
        XCTAssertFalse(sut.upcomingEvents.isEmpty || IslamicEvent.allEvents.isEmpty)
    }

    func testAllEventsExist() {
        let events = IslamicEvent.allEvents

        XCTAssertFalse(events.isEmpty)
        XCTAssertTrue(events.contains { $0.type == .eidAlFitr })
        XCTAssertTrue(events.contains { $0.type == .eidAlAdha })
        XCTAssertTrue(events.contains { $0.type == .ramadanStart })
    }

    // MARK: - Event Type Tests

    func testAllEventTypesHaveDisplayName() {
        for type in IslamicEventType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
        }
    }

    func testAllEventTypesHaveIcon() {
        for type in IslamicEventType.allCases {
            XCTAssertFalse(type.iconName.isEmpty)
        }
    }

    // MARK: - Recommended Actions Tests

    func testEidRecommendedActions() {
        let event = IslamicEvent(
            id: "test_eid",
            name: "Test Eid",
            nameArabic: "عيد",
            description: "Test",
            type: .eidAlFitr,
            hijriMonth: 10,
            hijriDay: 1
        )

        let actions = sut.getRecommendedActions(for: event)

        XCTAssertFalse(actions.isEmpty)
        XCTAssertTrue(actions.contains { $0.action == .openEidPrayers })
    }

    func testRamadanRecommendedActions() {
        let event = IslamicEvent(
            id: "test_ramadan",
            name: "Test Ramadan",
            nameArabic: "رمضان",
            description: "Test",
            type: .ramadanStart,
            hijriMonth: 9,
            hijriDay: 1
        )

        let actions = sut.getRecommendedActions(for: event)

        XCTAssertFalse(actions.isEmpty)
        XCTAssertTrue(actions.contains { $0.action == .openFastingGuide })
    }

    // MARK: - Settings Tests

    func testDefaultEnabledEventTypes() {
        // All event types should be enabled by default
        XCTAssertEqual(sut.enabledEventTypes.count, IslamicEventType.allCases.count)
    }

    func testDefaultReminderDays() {
        XCTAssertEqual(sut.reminderDaysBefore, 1)
    }
}

// MARK: - Sleep Focus Service Tests

final class SleepFocusServiceTests: XCTestCase {

    var sut: SleepFocusService!

    override func setUp() {
        super.setUp()
        sut = SleepFocusService()

        clearSleepData()
    }

    override func tearDown() {
        clearSleepData()
        sut = nil
        super.tearDown()
    }

    private func clearSleepData() {
        UserDefaults.standard.removeObject(forKey: "com.safa.sleep.bedtime")
        UserDefaults.standard.removeObject(forKey: "com.safa.sleep.waketime")
        UserDefaults.standard.removeObject(forKey: "com.safa.sleep.fajrAlarm")
        UserDefaults.standard.removeObject(forKey: "com.safa.sleep.windDownReminder")
        UserDefaults.standard.removeObject(forKey: "com.safa.sleep.windDownMinutes")
    }

    // MARK: - Settings Tests

    func testDefaultWindDownMinutes() {
        XCTAssertEqual(sut.windDownMinutesBefore, 30)
    }

    func testDefaultWindDownReminderEnabled() {
        XCTAssertTrue(sut.windDownReminderEnabled)
    }

    func testSetBedtime() {
        let bedtime = Date()

        sut.setBedtime(bedtime)

        XCTAssertNotNil(sut.scheduledBedtime)
    }

    func testSetWakeTime() {
        let wakeTime = Date()

        sut.setWakeTime(wakeTime)

        XCTAssertNotNil(sut.scheduledWakeTime)
    }

    // MARK: - Fajr Alarm Tests

    func testFajrAlarmInitiallyDisabled() {
        XCTAssertFalse(sut.fajrAlarmEnabled)
    }

    func testSetFajrAsWakeTimeEnablesAlarm() {
        let fajrTime = Date().addingTimeInterval(3600) // 1 hour from now

        sut.setFajrAsWakeTime(fajrTime: fajrTime)

        XCTAssertTrue(sut.fajrAlarmEnabled)
        XCTAssertNotNil(sut.scheduledWakeTime)
    }

    // MARK: - Sleep Duration Tests

    func testGetSleepDurationReturnsNilWhenNotSet() {
        let duration = sut.getSleepDuration()

        XCTAssertNil(duration)
    }

    func testGetFormattedSleepDurationWhenNotSet() {
        let formatted = sut.getFormattedSleepDuration()

        XCTAssertEqual(formatted, "Not set")
    }
}
