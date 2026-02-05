// MARK: - NotificationTests.swift
// PURPOSE: Unit tests for notification scheduling functionality
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class NotificationSchedulerTests: XCTestCase {

    var sut: NotificationScheduler!

    override func setUp() {
        super.setUp()
        sut = NotificationScheduler()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Authorization Tests

    func testInitialAuthorizationStatus() {
        XCTAssertEqual(sut.authorizationStatus, .notDetermined)
    }

    func testIsAuthorizedInitiallyFalse() {
        // Initially, isAuthorized should be false
        // It gets updated asynchronously on init
        XCTAssertFalse(sut.isAuthorized)
    }

    // MARK: - Prayer Notification Tests

    func testCancelPrayerNotificationsDoesNotThrow() async {
        // Should not throw even when no notifications exist
        await sut.cancelPrayerNotifications()
        // If we get here without crashing, test passes
    }

    // MARK: - Streak Reminder Tests

    func testCancelStreakReminderDoesNotThrow() {
        // Should not throw even when no reminders exist
        sut.cancelStreakReminder(for: .prayer)
        sut.cancelStreakReminder(for: .quran)
        sut.cancelStreakReminder(for: .dhikr)
        // If we get here without crashing, test passes
    }

    // MARK: - Notification Management Tests

    func testCancelNotificationDoesNotThrow() {
        sut.cancelNotification(identifier: "nonexistent")
        // Should not throw
    }

    func testCancelAllNotificationsDoesNotThrow() {
        sut.cancelAllNotifications()
        // Should not throw
    }

    func testRemoveDeliveredNotificationsDoesNotThrow() {
        sut.removeDeliveredNotifications()
        // Should not throw
    }
}

// MARK: - Focus Mode Service Tests

final class FocusModeServiceTests: XCTestCase {

    var sut: FocusModeService!

    override func setUp() {
        super.setUp()
        sut = FocusModeService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Category Tests

    func testAllCategoriesExist() {
        let categories = FocusModeService.NotificationCategory.allCases

        XCTAssertFalse(categories.isEmpty)
        XCTAssertTrue(categories.contains(.prayerTime))
        XCTAssertTrue(categories.contains(.prayerReminder))
        XCTAssertTrue(categories.contains(.streakReminder))
    }

    func testCategoryRawValues() {
        XCTAssertEqual(FocusModeService.NotificationCategory.prayerTime.rawValue, "prayerTime")
        XCTAssertEqual(FocusModeService.NotificationCategory.prayerReminder.rawValue, "prayerReminder")
    }

    func testPrayerTimeInterruptionLevel() {
        let category = FocusModeService.NotificationCategory.prayerTime
        XCTAssertEqual(category.interruptionLevel, .timeSensitive)
    }

    func testPrayerReminderInterruptionLevel() {
        let category = FocusModeService.NotificationCategory.prayerReminder
        XCTAssertEqual(category.interruptionLevel, .active)
    }

    func testStreakReminderInterruptionLevel() {
        let category = FocusModeService.NotificationCategory.streakReminder
        XCTAssertEqual(category.interruptionLevel, .passive)
    }

    func testAchievementInterruptionLevel() {
        let category = FocusModeService.NotificationCategory.achievementUnlocked
        XCTAssertEqual(category.interruptionLevel, .passive)
    }
}

// MARK: - Notification Response Handler Tests

final class NotificationResponseHandlerTests: XCTestCase {

    func testSharedInstanceExists() {
        let shared = NotificationResponseHandler.shared

        XCTAssertNotNil(shared)
    }

    func testSharedInstanceIsSingleton() {
        let instance1 = NotificationResponseHandler.shared
        let instance2 = NotificationResponseHandler.shared

        XCTAssertTrue(instance1 === instance2)
    }
}

// MARK: - Notification Names Tests

final class NotificationNamesTests: XCTestCase {

    func testLogPrayerNotificationName() {
        let name = Notification.Name.logPrayerFromNotification
        XCTAssertEqual(name.rawValue, "logPrayerFromNotification")
    }

    func testOpenQiblaNotificationName() {
        let name = Notification.Name.openQiblaFromNotification
        XCTAssertEqual(name.rawValue, "openQiblaFromNotification")
    }

    func testOpenPrayerNotificationName() {
        let name = Notification.Name.openPrayerFromNotification
        XCTAssertEqual(name.rawValue, "openPrayerFromNotification")
    }

    func testOpenProgressNotificationName() {
        let name = Notification.Name.openProgressFromNotification
        XCTAssertEqual(name.rawValue, "openProgressFromNotification")
    }

    func testOpenAchievementsNotificationName() {
        let name = Notification.Name.openAchievementsFromNotification
        XCTAssertEqual(name.rawValue, "openAchievementsFromNotification")
    }
}

// MARK: - Prayer Time Notification Content Tests

final class PrayerNotificationContentTests: XCTestCase {

    func testPrayerTypeDisplayNames() {
        XCTAssertEqual(PrayerType.fajr.displayName, "Fajr")
        XCTAssertEqual(PrayerType.dhuhr.displayName, "Dhuhr")
        XCTAssertEqual(PrayerType.asr.displayName, "Asr")
        XCTAssertEqual(PrayerType.maghrib.displayName, "Maghrib")
        XCTAssertEqual(PrayerType.isha.displayName, "Isha")
    }

    func testPrayerTypeRawValues() {
        XCTAssertEqual(PrayerType.fajr.rawValue, "fajr")
        XCTAssertEqual(PrayerType.dhuhr.rawValue, "dhuhr")
        XCTAssertEqual(PrayerType.asr.rawValue, "asr")
        XCTAssertEqual(PrayerType.maghrib.rawValue, "maghrib")
        XCTAssertEqual(PrayerType.isha.rawValue, "isha")
    }

    func testAllPrayerTypesCount() {
        XCTAssertEqual(PrayerType.allCases.count, 5)
    }
}
