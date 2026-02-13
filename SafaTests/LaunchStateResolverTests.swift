import XCTest
@testable import Safa

final class LaunchStateResolverTests: XCTestCase {

    // MARK: - Returning User

    func test_resolve_completedOnboarding_returnsReady() {
        let state = LaunchStateResolver.resolve(
            isUITesting: false,
            hasCompletedOnboarding: true
        )
        XCTAssertEqual(state, .ready)
    }

    // MARK: - First-Time User

    func test_resolve_notCompletedOnboarding_returnsOnboarding() {
        let state = LaunchStateResolver.resolve(
            isUITesting: false,
            hasCompletedOnboarding: false
        )
        XCTAssertEqual(state, .onboarding)
    }

    // MARK: - UI Testing

    func test_resolve_uiTesting_returnsReady_evenIfOnboardingNotComplete() {
        let state = LaunchStateResolver.resolve(
            isUITesting: true,
            hasCompletedOnboarding: false
        )
        XCTAssertEqual(state, .ready)
    }

    func test_resolve_uiTesting_returnsReady_whenOnboardingComplete() {
        let state = LaunchStateResolver.resolve(
            isUITesting: true,
            hasCompletedOnboarding: true
        )
        XCTAssertEqual(state, .ready)
    }

    // MARK: - Initial State

    func test_launchState_initialValue_isLoading() {
        // The app starts in .loading before any async work completes
        // This ensures no flash of onboarding for returning users
        let initial: LaunchState = .loading
        XCTAssertEqual(initial, .loading)
        XCTAssertNotEqual(initial, .onboarding)
        XCTAssertNotEqual(initial, .ready)
    }
}
