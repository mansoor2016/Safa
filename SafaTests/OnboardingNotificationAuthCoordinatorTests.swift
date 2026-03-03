import XCTest
import UserNotifications
@testable import Safa

@MainActor
final class OnboardingNotificationAuthCoordinatorTests: XCTestCase {

    // MARK: - Mock

    final class MockScheduler: NotificationScheduling {
        var authorizationResult = true
        var requestAuthorizationCallCount = 0

        func requestAuthorization() async -> Bool {
            requestAuthorizationCallCount += 1
            return authorizationResult
        }

        func forceReschedule() async {}
    }

    // MARK: - Tests

    func test_requestIfNeeded_firesOnceForValidState() async {
        let mock = MockScheduler()
        let sut = OnboardingNotificationAuthCoordinator(scheduler: mock)

        let result = await sut.requestIfNeeded(
            currentPage: 2,
            notificationsEnabled: true,
            notificationAuthStatus: .notDetermined
        )

        XCTAssertTrue(result, "Should fire for valid state")
        XCTAssertEqual(mock.requestAuthorizationCallCount, 1)
    }

    func test_requestIfNeeded_doesNotRefireAfterAuthorized() async {
        let mock = MockScheduler()
        let sut = OnboardingNotificationAuthCoordinator(scheduler: mock)

        // First call succeeds
        let first = await sut.requestIfNeeded(
            currentPage: 2,
            notificationsEnabled: true,
            notificationAuthStatus: .notDetermined
        )
        XCTAssertTrue(first)

        // Second call with .authorized — should not fire again
        let second = await sut.requestIfNeeded(
            currentPage: 2,
            notificationsEnabled: true,
            notificationAuthStatus: .authorized
        )
        XCTAssertFalse(second, "Should not re-request after authorization granted")
        XCTAssertEqual(mock.requestAuthorizationCallCount, 1)
    }

    func test_requestIfNeeded_doesNotFireOnWrongPage() async {
        let mock = MockScheduler()
        let sut = OnboardingNotificationAuthCoordinator(scheduler: mock)

        let result = await sut.requestIfNeeded(
            currentPage: 0,
            notificationsEnabled: true,
            notificationAuthStatus: .notDetermined
        )

        XCTAssertFalse(result, "Should not fire on non-notification page")
        XCTAssertEqual(mock.requestAuthorizationCallCount, 0)
    }

    func test_requestIfNeeded_doesNotFireWhenToggleOff() async {
        let mock = MockScheduler()
        let sut = OnboardingNotificationAuthCoordinator(scheduler: mock)

        let result = await sut.requestIfNeeded(
            currentPage: 2,
            notificationsEnabled: false,
            notificationAuthStatus: .notDetermined
        )

        XCTAssertFalse(result, "Should not fire when user opted out of notifications")
        XCTAssertEqual(mock.requestAuthorizationCallCount, 0)
    }
}
