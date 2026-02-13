import XCTest
@testable import Safa

final class NotificationToggleHandlerTests: XCTestCase {

    // MARK: - Mocks

    final class MockScheduler: NotificationScheduling {
        var authorizationResult = true
        var requestAuthorizationCallCount = 0
        var forceRescheduleCallCount = 0
        private(set) var callOrder: [String] = []

        func requestAuthorization() async -> Bool {
            requestAuthorizationCallCount += 1
            callOrder.append("requestAuthorization")
            return authorizationResult
        }

        func forceReschedule() async {
            forceRescheduleCallCount += 1
            callOrder.append("forceReschedule")
        }
    }

    final class MockPrefsSaver: NotificationPreferencesSaving {
        private(set) var savedValues: [Bool] = []
        private(set) var callOrder: [String] = []

        func saveNotificationsEnabled(_ enabled: Bool) async {
            savedValues.append(enabled)
            callOrder.append("savePrefs")
        }
    }

    // MARK: - Toggle OFF

    func test_handleOff_savesThenCancels_showsToast() async {
        let scheduler = MockScheduler()
        let saver = MockPrefsSaver()

        let result = await NotificationToggleHandler.handle(
            enabled: false,
            preferenceSaver: saver,
            scheduler: scheduler
        )

        // Prefs saved with false
        XCTAssertEqual(saver.savedValues, [false])
        // forceReschedule called (which triggers cancel via kill switch)
        XCTAssertEqual(scheduler.forceRescheduleCallCount, 1)
        // Authorization not requested when turning OFF
        XCTAssertEqual(scheduler.requestAuthorizationCallCount, 0)
        // Toast shown
        XCTAssertTrue(result.showDisabledToast)
        XCTAssertFalse(result.authorizationRequested)
    }

    func test_handleOff_savesBeforeReschedule() async {
        let scheduler = MockScheduler()
        let saver = MockPrefsSaver()

        _ = await NotificationToggleHandler.handle(
            enabled: false,
            preferenceSaver: saver,
            scheduler: scheduler
        )

        // Save must happen before reschedule reads prefs
        XCTAssertEqual(saver.callOrder + scheduler.callOrder, ["savePrefs", "forceReschedule"])
    }

    // MARK: - Toggle ON + Auth Granted

    func test_handleOn_authGranted_requestsAuthThenReschedules() async {
        let scheduler = MockScheduler()
        scheduler.authorizationResult = true
        let saver = MockPrefsSaver()

        let result = await NotificationToggleHandler.handle(
            enabled: true,
            preferenceSaver: saver,
            scheduler: scheduler
        )

        XCTAssertEqual(saver.savedValues, [true])
        XCTAssertEqual(scheduler.requestAuthorizationCallCount, 1)
        XCTAssertEqual(scheduler.forceRescheduleCallCount, 1)
        XCTAssertTrue(result.authorizationGranted)
        XCTAssertTrue(result.rescheduled)
        XCTAssertFalse(result.showDisabledToast)
    }

    func test_handleOn_authGranted_correctOrder() async {
        let scheduler = MockScheduler()
        scheduler.authorizationResult = true
        let saver = MockPrefsSaver()

        _ = await NotificationToggleHandler.handle(
            enabled: true,
            preferenceSaver: saver,
            scheduler: scheduler
        )

        // Save → auth → reschedule
        XCTAssertEqual(saver.callOrder, ["savePrefs"])
        XCTAssertEqual(scheduler.callOrder, ["requestAuthorization", "forceReschedule"])
    }

    // MARK: - Toggle ON + Auth Denied

    func test_handleOn_authDenied_stillReschedulesButNotGranted() async {
        let scheduler = MockScheduler()
        scheduler.authorizationResult = false
        let saver = MockPrefsSaver()

        let result = await NotificationToggleHandler.handle(
            enabled: true,
            preferenceSaver: saver,
            scheduler: scheduler
        )

        // Auth requested but denied
        XCTAssertTrue(result.authorizationRequested)
        XCTAssertFalse(result.authorizationGranted)
        // Reschedule still called (scheduler's auth guard will handle it)
        XCTAssertTrue(result.rescheduled)
        // No toast since user turned ON (not OFF)
        XCTAssertFalse(result.showDisabledToast)
    }
}
