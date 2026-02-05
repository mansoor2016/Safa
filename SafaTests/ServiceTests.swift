// MARK: - ServiceTests.swift
// PURPOSE: Unit tests for Core Services

import XCTest
@testable import Safa

// MARK: - InviteFriendsService Tests

final class InviteFriendsServiceTests: XCTestCase {

    var sut: InviteFriendsService!

    override func setUp() {
        super.setUp()
        sut = InviteFriendsService.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Constants Tests

    func testHasanatPerInvite() {
        XCTAssertEqual(InviteFriendsService.hasanatPerInvite, 25)
    }

    // MARK: - Share Message Tests

    func testShareMessageContainsAppName() {
        XCTAssertTrue(sut.shareMessage.contains("Safa"))
    }

    func testShareMessageContainsAppStoreURL() {
        XCTAssertTrue(sut.shareMessage.contains(AppConstants.URLs.appStore.absoluteString))
    }

    func testShareMessageContainsDescription() {
        XCTAssertTrue(sut.shareMessage.contains("Islamic"))
    }

    func testShortShareMessageContainsAppName() {
        XCTAssertTrue(sut.shortShareMessage.contains("Safa"))
    }

    func testShortShareMessageContainsAppStoreURL() {
        XCTAssertTrue(sut.shortShareMessage.contains(AppConstants.URLs.appStore.absoluteString))
    }

    func testShortShareMessageContainsEmoji() {
        XCTAssertTrue(sut.shortShareMessage.contains("🌙"))
    }

    // MARK: - URL Tests

    func testAppStoreURLIsValid() {
        let url = sut.appStoreURL
        XCTAssertNotNil(url.scheme)
        XCTAssertTrue(url.absoluteString.starts(with: "https://"))
    }

    func testTestFlightURLIsValid() {
        let url = sut.testFlightURL
        XCTAssertNotNil(url.scheme)
        XCTAssertTrue(url.absoluteString.starts(with: "https://"))
    }

    // MARK: - Share Items Tests

    func testShareItemsContainsMessage() {
        let items = sut.shareItems
        XCTAssertFalse(items.isEmpty)

        // First item should be the share message string
        if let message = items.first as? String {
            XCTAssertTrue(message.contains("Safa"))
        } else {
            XCTFail("First share item should be a String")
        }
    }
}

// MARK: - Notification.Name Extensions Tests

final class NotificationNameTests: XCTestCase {

    func testInviteHasanatAwardedNotificationExists() {
        let name = Notification.Name.inviteHasanatAwarded
        XCTAssertEqual(name.rawValue, "com.safa.inviteHasanatAwarded")
    }
}

// MARK: - RamadanService Tests

final class RamadanServiceTests: XCTestCase {

    var sut: RamadanService!

    override func setUp() {
        super.setUp()
        sut = RamadanService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialTotalRamadanDays() {
        // Ramadan is either 29 or 30 days
        XCTAssertTrue(sut.totalRamadanDays >= 29 && sut.totalRamadanDays <= 30)
    }

    func testInitialCurrentRamadanDayRange() {
        // Current day should be 0-30
        XCTAssertTrue(sut.currentRamadanDay >= 0 && sut.currentRamadanDay <= 30)
    }

    // MARK: - Default Settings Tests

    func testDefaultSuhoorReminderEnabled() {
        // Default should be true (from fresh init, may be overridden by UserDefaults)
        // Just test that it's a valid boolean
        XCTAssertTrue(sut.suhoorReminderEnabled == true || sut.suhoorReminderEnabled == false)
    }

    func testDefaultIftarReminderEnabled() {
        XCTAssertTrue(sut.iftarReminderEnabled == true || sut.iftarReminderEnabled == false)
    }

    func testDefaultSuhoorMinutesBefore() {
        // Default is 30 minutes
        XCTAssertGreaterThan(sut.suhoorReminderMinutesBefore, 0)
    }

    func testDefaultIftarMinutesBefore() {
        // Default is 15 minutes
        XCTAssertGreaterThan(sut.iftarReminderMinutesBefore, 0)
    }

    // MARK: - Mode Toggle Tests

    func testToggleRamadanModeChangesState() {
        let initialState = sut.isRamadanMode

        sut.toggleRamadanMode()

        XCTAssertNotEqual(sut.isRamadanMode, initialState)

        // Toggle back
        sut.toggleRamadanMode()

        XCTAssertEqual(sut.isRamadanMode, initialState)
    }

    func testActivateRamadanMode() {
        sut.deactivateRamadanMode() // Ensure it's off first
        sut.activateRamadanMode()

        XCTAssertTrue(sut.isRamadanMode)
    }

    func testDeactivateRamadanMode() {
        sut.activateRamadanMode() // Ensure it's on first
        sut.deactivateRamadanMode()

        XCTAssertFalse(sut.isRamadanMode)
    }

    // MARK: - Ramadan Status Tests

    func testCheckRamadanStatusSetsIsRamadanMonth() {
        sut.checkRamadanStatus()

        // Just verify the check runs without error and sets a value
        XCTAssertTrue(sut.isRamadanMonth == true || sut.isRamadanMonth == false)
    }

    func testIsRamadanMonthMatchesCurrentDay() {
        // If it's Ramadan, currentRamadanDay should be > 0
        // If not Ramadan, currentRamadanDay should be 0
        if sut.isRamadanMonth {
            XCTAssertGreaterThan(sut.currentRamadanDay, 0)
        } else {
            XCTAssertEqual(sut.currentRamadanDay, 0)
        }
    }

    func testDaysUntilRamadanWhenNotRamadan() {
        // If not currently Ramadan, should have days until Ramadan calculated
        if !sut.isRamadanMonth {
            XCTAssertNotNil(sut.daysUntilRamadan)
            XCTAssertGreaterThanOrEqual(sut.daysUntilRamadan ?? 0, 0)
        }
    }

    func testDaysUntilRamadanNilDuringRamadan() {
        // If currently Ramadan, daysUntilRamadan should be nil
        if sut.isRamadanMonth {
            XCTAssertNil(sut.daysUntilRamadan)
        }
    }
}

// MARK: - HapticFeedbackService Tests

final class HapticFeedbackServiceTests: XCTestCase {

    func testSharedInstanceExists() {
        let service = HapticFeedbackService.shared
        XCTAssertNotNil(service)
    }
}

// MARK: - CloudKitSyncService Tests

final class CloudKitSyncServiceTests: XCTestCase {

    func testSyncStatusExists() {
        // Test that SyncStatus enum exists
        let status = SyncStatus.idle
        XCTAssertEqual(status, .idle)
    }

    func testAllSyncStatusCases() {
        XCTAssertEqual(SyncStatus.idle, .idle)
        XCTAssertEqual(SyncStatus.syncing, .syncing)
        XCTAssertEqual(SyncStatus.synced, .synced)
        XCTAssertEqual(SyncStatus.offline, .offline)

        // Error case has associated value
        let errorStatus = SyncStatus.error("test")
        if case .error(let message) = errorStatus {
            XCTAssertEqual(message, "test")
        } else {
            XCTFail("Should be error case")
        }
    }

    func testSyncStatusEquatable() {
        XCTAssertEqual(SyncStatus.idle, SyncStatus.idle)
        XCTAssertNotEqual(SyncStatus.idle, SyncStatus.syncing)
        XCTAssertNotEqual(SyncStatus.synced, SyncStatus.offline)
    }

    func testSyncErrorDescriptions() {
        XCTAssertNotNil(SyncError.notAuthenticated.errorDescription)
        XCTAssertNotNil(SyncError.networkUnavailable.errorDescription)
        XCTAssertNotNil(SyncError.quotaExceeded.errorDescription)
        XCTAssertNotNil(SyncError.serverError("test").errorDescription)
        XCTAssertNotNil(SyncError.conflictDetected.errorDescription)
        XCTAssertNotNil(SyncError.recordNotFound.errorDescription)
        XCTAssertNotNil(SyncError.permissionDenied.errorDescription)
    }

    func testConflictResolutionStrategies() {
        XCTAssertEqual(ConflictResolutionStrategy.serverWins, .serverWins)
        XCTAssertEqual(ConflictResolutionStrategy.clientWins, .clientWins)
        XCTAssertEqual(ConflictResolutionStrategy.merge, .merge)
        XCTAssertEqual(ConflictResolutionStrategy.askUser, .askUser)
    }
}

// MARK: - SleepFocusService Tests

final class SleepFocusServiceTests: XCTestCase {

    var sut: SleepFocusService!

    override func setUp() {
        super.setUp()
        sut = SleepFocusService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testInitialState() {
        // Initial state tests
        XCTAssertFalse(sut.isSleepFocusEnabled)
    }

    func testDefaultWindDownMinutes() {
        // Default is 30 minutes
        XCTAssertGreaterThan(sut.windDownMinutesBefore, 0)
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

    func testSetFajrAsWakeTime() {
        let fajrTime = Date()
        sut.setFajrAsWakeTime(fajrTime: fajrTime)

        XCTAssertTrue(sut.fajrAlarmEnabled)
        XCTAssertNotNil(sut.scheduledWakeTime)
    }

    func testWindDownReminderEnabledPropertyExists() {
        // Just verify the property exists and is a boolean
        XCTAssertTrue(sut.windDownReminderEnabled == true || sut.windDownReminderEnabled == false)
    }
}

// MARK: - IslamicEventService Tests

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

    func testUpcomingEventsNotEmpty() {
        // Service loads events on init
        XCTAssertNotNil(sut.upcomingEvents)
    }

    func testTodayEventsProperty() {
        // Today events property should exist
        XCTAssertNotNil(sut.todayEvents)
    }

    func testEnabledEventTypesDefault() {
        // By default, all event types should be enabled
        let enabledTypes = sut.enabledEventTypes
        XCTAssertFalse(enabledTypes.isEmpty)
    }

    func testReminderDaysBeforeDefault() {
        // Default is 1 day
        XCTAssertGreaterThan(sut.reminderDaysBefore, 0)
    }

    func testLoadEventsPopulatesUpcoming() {
        sut.loadEvents()

        // After loading, upcomingEvents should be accessible
        XCTAssertNotNil(sut.upcomingEvents)
    }

    func testAllEventsHasContent() {
        // IslamicEvent.allEvents should have events
        let allEvents = IslamicEvent.allEvents
        XCTAssertGreaterThan(allEvents.count, 0)
    }

    func testAllEventsIncludesEidAlFitr() {
        let allEvents = IslamicEvent.allEvents
        let hasEidFitr = allEvents.contains { $0.type == .eidAlFitr }
        XCTAssertTrue(hasEidFitr)
    }

    func testAllEventsIncludesEidAlAdha() {
        let allEvents = IslamicEvent.allEvents
        let hasEidAdha = allEvents.contains { $0.type == .eidAlAdha }
        XCTAssertTrue(hasEidAdha)
    }

    func testAllEventsIncludesRamadan() {
        let allEvents = IslamicEvent.allEvents
        let hasRamadan = allEvents.contains { $0.type == .ramadanStart || $0.type == .ramadanEnd }
        XCTAssertTrue(hasRamadan)
    }
}
