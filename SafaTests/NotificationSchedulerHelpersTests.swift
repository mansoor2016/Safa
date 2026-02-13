import XCTest
@testable import Safa

final class NotificationSchedulerHelpersTests: XCTestCase {

    // MARK: - Kill Switch (notificationsEnabled = false)

    func test_determineAction_cancelsAll_whenNotificationsDisabled() {
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: false,
            isAuthorized: true,
            lastScheduledDate: nil,
            isForceReschedule: false
        )
        XCTAssertEqual(action, .cancelAll)
    }

    func test_determineAction_cancelsAll_whenDisabled_evenIfNotAuthorized() {
        // Kill switch must fire even when system auth is revoked
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: false,
            isAuthorized: false,
            lastScheduledDate: nil,
            isForceReschedule: false
        )
        XCTAssertEqual(action, .cancelAll)
    }

    func test_determineAction_cancelsAll_whenDisabled_evenIfAlreadyScheduledToday() {
        // "Already scheduled today" must NOT bypass the kill switch
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: false,
            isAuthorized: true,
            lastScheduledDate: Date(),
            isForceReschedule: false
        )
        XCTAssertEqual(action, .cancelAll)
    }

    func test_determineAction_cancelsAll_whenDisabled_onForceReschedule() {
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: false,
            isAuthorized: true,
            lastScheduledDate: nil,
            isForceReschedule: true
        )
        XCTAssertEqual(action, .cancelAll)
    }

    // MARK: - Authorization

    func test_determineAction_skipsNotAuthorized_whenEnabledButNotAuthorized() {
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: true,
            isAuthorized: false,
            lastScheduledDate: nil,
            isForceReschedule: false
        )
        XCTAssertEqual(action, .skipNotAuthorized)
    }

    // MARK: - Daily Dedup

    func test_determineAction_skipsAlreadyScheduled_whenScheduledToday() {
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: true,
            isAuthorized: true,
            lastScheduledDate: Date(),
            isForceReschedule: false
        )
        XCTAssertEqual(action, .skipAlreadyScheduled)
    }

    func test_determineAction_schedules_whenForceReschedule_ignoresLastScheduledDate() {
        // forceReschedule must bypass the daily dedup
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: true,
            isAuthorized: true,
            lastScheduledDate: Date(),
            isForceReschedule: true
        )
        XCTAssertEqual(action, .schedule)
    }

    // MARK: - Happy Path

    func test_determineAction_schedules_whenEnabledAndAuthorizedAndNotScheduledToday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: true,
            isAuthorized: true,
            lastScheduledDate: yesterday,
            isForceReschedule: false
        )
        XCTAssertEqual(action, .schedule)
    }

    func test_determineAction_schedules_whenNeverScheduledBefore() {
        let action = NotificationSchedulerHelpers.determineAction(
            notificationsEnabled: true,
            isAuthorized: true,
            lastScheduledDate: nil,
            isForceReschedule: false
        )
        XCTAssertEqual(action, .schedule)
    }
}
