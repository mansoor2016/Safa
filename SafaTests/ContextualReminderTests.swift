// MARK: - ContextualReminderTests.swift
// PURPOSE: Unit tests for contextual reminder service
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class ContextualReminderTests: XCTestCase {

    var sut: ContextualReminderService!

    override func setUp() {
        super.setUp()
        sut = ContextualReminderService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func dateAt(hour: Int, minute: Int = 0, weekday: Int? = nil) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute

        var date = Calendar.current.date(from: components)!

        // Adjust to specific weekday if needed
        if let weekday = weekday {
            let currentWeekday = Calendar.current.component(.weekday, from: date)
            let daysToAdd = (weekday - currentWeekday + 7) % 7
            date = Calendar.current.date(byAdding: .day, value: daysToAdd, to: date)!
        }

        return date
    }

    // MARK: - Time-Based Reminder Tests

    func testTahajjudReminderEarlyMorning() {
        let date = dateAt(hour: 4)
        let reminders = sut.getReminders(currentDate: date)

        let tahajjudReminder = reminders.first { $0.actionType == .tahajjud }
        XCTAssertNotNil(tahajjudReminder, "Should show tahajjud reminder at 4 AM")
    }

    func testMorningAdhkarReminderAfterFajr() {
        let date = dateAt(hour: 6)
        let reminders = sut.getReminders(currentDate: date)

        let morningReminder = reminders.first { $0.actionType == .morningAdhkar }
        XCTAssertNotNil(morningReminder, "Should show morning adhkar reminder at 6 AM")
    }

    func testEveningAdhkarReminderAfternoon() {
        let date = dateAt(hour: 17)
        let reminders = sut.getReminders(currentDate: date)

        let eveningReminder = reminders.first { $0.actionType == .eveningAdhkar }
        XCTAssertNotNil(eveningReminder, "Should show evening adhkar reminder at 5 PM")
    }

    func testSleepAdhkarReminderAtNight() {
        let date = dateAt(hour: 22)
        let reminders = sut.getReminders(currentDate: date)

        let sleepReminder = reminders.first { $0.actionType == .sleepAdhkar }
        XCTAssertNotNil(sleepReminder, "Should show sleep adhkar reminder at 10 PM")
    }

    func testQuranReadingReminderMorning() {
        let date = dateAt(hour: 9)
        let reminders = sut.getReminders(currentDate: date)

        let quranReminder = reminders.first { $0.actionType == .quranReading }
        XCTAssertNotNil(quranReminder, "Should show Quran reading reminder at 9 AM")
    }

    // MARK: - Day-Specific Reminder Tests

    func testFridayReminderOnFriday() {
        let friday = dateAt(hour: 10, weekday: 6) // 6 = Friday
        let reminders = sut.getReminders(currentDate: friday)

        let fridayReminder = reminders.first { $0.actionType == .fridayPreparation }
        XCTAssertNotNil(fridayReminder, "Should show Friday preparation reminder on Friday morning")
    }

    func testNoFridayReminderOnOtherDays() {
        let monday = dateAt(hour: 10, weekday: 2) // 2 = Monday
        let reminders = sut.getReminders(currentDate: monday)

        let fridayReminder = reminders.first { $0.actionType == .fridayPreparation }
        XCTAssertNil(fridayReminder, "Should not show Friday reminder on Monday")
    }

    // MARK: - Streak-Based Reminder Tests

    func testStreakAtRiskReminder() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let atRiskStreak = Streak(
            type: .prayer,
            currentCount: 10,
            longestCount: 15,
            lastActivityDate: twoDaysAgo
        )

        let reminders = sut.getReminders(streaks: [atRiskStreak])

        let streakReminder = reminders.first { reminder in
            if case .streakAtRisk = reminder.actionType {
                return true
            }
            return false
        }

        XCTAssertNotNil(streakReminder, "Should show streak at risk reminder for 10-day streak about to break")
    }

    func testNoStreakReminderForShortStreak() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let shortStreak = Streak(
            type: .prayer,
            currentCount: 2, // Short streak
            longestCount: 5,
            lastActivityDate: twoDaysAgo
        )

        let reminders = sut.getReminders(streaks: [shortStreak])

        let streakReminder = reminders.first { reminder in
            if case .streakAtRisk = reminder.actionType {
                return true
            }
            return false
        }

        XCTAssertNil(streakReminder, "Should not show streak warning for short streaks")
    }

    // MARK: - Priority Tests

    func testHighPriorityComesFirst() {
        let date = dateAt(hour: 4) // Tahajjud time (high priority)
        let reminders = sut.getReminders(currentDate: date)

        guard let first = reminders.first else {
            XCTFail("Should have at least one reminder")
            return
        }

        XCTAssertGreaterThanOrEqual(
            first.priority,
            .high,
            "First reminder should be high priority or above"
        )
    }

    func testRemindersAreLimitedToThree() {
        let date = dateAt(hour: 17, weekday: 6) // Friday evening - multiple reminders
        let reminders = sut.getReminders(currentDate: date)

        XCTAssertLessThanOrEqual(reminders.count, 3, "Should return at most 3 reminders")
    }

    // MARK: - Primary Reminder Tests

    func testPrimaryReminderReturnsFirst() {
        let date = dateAt(hour: 6)
        let primary = sut.getPrimaryReminder(currentDate: date)

        XCTAssertNotNil(primary, "Should return a primary reminder")
    }

    func testPrimaryReminderMatchesFirstOfAll() {
        let date = dateAt(hour: 6)
        let allReminders = sut.getReminders(currentDate: date)
        let primary = sut.getPrimaryReminder(currentDate: date)

        XCTAssertEqual(primary?.id, allReminders.first?.id)
    }

    // MARK: - Reminder Content Tests

    func testReminderHasRequiredFields() {
        let date = dateAt(hour: 6)
        let reminders = sut.getReminders(currentDate: date)

        for reminder in reminders {
            XCTAssertFalse(reminder.id.isEmpty, "Reminder should have an ID")
            XCTAssertFalse(reminder.title.isEmpty, "Reminder should have a title")
            XCTAssertFalse(reminder.subtitle.isEmpty, "Reminder should have a subtitle")
            XCTAssertFalse(reminder.iconName.isEmpty, "Reminder should have an icon name")
        }
    }

    // MARK: - Sunnah Fasting Tests

    func testMondayFastingReminder() {
        let monday = dateAt(hour: 7, weekday: 2) // 2 = Monday
        let reminders = sut.getReminders(currentDate: monday)

        let fastingReminder = reminders.first { $0.actionType == .fasting }
        XCTAssertNotNil(fastingReminder, "Should show fasting reminder on Monday morning")
    }

    func testThursdayFastingReminder() {
        let thursday = dateAt(hour: 7, weekday: 5) // 5 = Thursday
        let reminders = sut.getReminders(currentDate: thursday)

        let fastingReminder = reminders.first { $0.actionType == .fasting }
        XCTAssertNotNil(fastingReminder, "Should show fasting reminder on Thursday morning")
    }

    func testNoFastingReminderAfterMorning() {
        let mondayAfternoon = dateAt(hour: 14, weekday: 2)
        let reminders = sut.getReminders(currentDate: mondayAfternoon)

        let fastingReminder = reminders.first { reminder in
            // Only check for sunnah fasting, not other fasting reminders
            reminder.id == "sunnah_fasting"
        }
        XCTAssertNil(fastingReminder, "Should not show fasting reminder after morning")
    }
}

// MARK: - Reminder Priority Tests

final class ReminderPriorityTests: XCTestCase {

    func testPriorityComparison() {
        XCTAssertTrue(ContextualReminder.ReminderPriority.urgent > .high)
        XCTAssertTrue(ContextualReminder.ReminderPriority.high > .medium)
        XCTAssertTrue(ContextualReminder.ReminderPriority.medium > .low)
    }

    func testPriorityRawValues() {
        XCTAssertEqual(ContextualReminder.ReminderPriority.low.rawValue, 1)
        XCTAssertEqual(ContextualReminder.ReminderPriority.medium.rawValue, 2)
        XCTAssertEqual(ContextualReminder.ReminderPriority.high.rawValue, 3)
        XCTAssertEqual(ContextualReminder.ReminderPriority.urgent.rawValue, 4)
    }
}

// MARK: - Reminder Action Type Tests

final class ReminderActionTypeTests: XCTestCase {

    func testActionTypeEquality() {
        XCTAssertEqual(ReminderActionType.morningAdhkar, ReminderActionType.morningAdhkar)
        XCTAssertEqual(ReminderActionType.prayer(.fajr), ReminderActionType.prayer(.fajr))
        XCTAssertNotEqual(ReminderActionType.prayer(.fajr), ReminderActionType.prayer(.dhuhr))
    }

    func testStreakAtRiskEquality() {
        XCTAssertEqual(
            ReminderActionType.streakAtRisk(.daily),
            ReminderActionType.streakAtRisk(.daily)
        )
        XCTAssertNotEqual(
            ReminderActionType.streakAtRisk(.daily),
            ReminderActionType.streakAtRisk(.prayer)
        )
    }
}
