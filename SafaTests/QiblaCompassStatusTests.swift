import XCTest
@testable import Safa

final class QiblaCompassStatusTests: XCTestCase {

    // MARK: - Priority Resolution

    func test_permissionDenied_overridesAll() {
        let status = QiblaCompassStatus.resolve(
            isPermissionDenied: true,
            headingTimedOut: true,
            accuracy: .unreliable,
            isSimulated: true
        )
        XCTAssertEqual(status, .permissionDenied)
    }

    func test_headingTimeout_overridesAccuracyAndSimulated() {
        let status = QiblaCompassStatus.resolve(
            isPermissionDenied: false,
            headingTimedOut: true,
            accuracy: .unreliable,
            isSimulated: true
        )
        XCTAssertEqual(status, .headingTimedOut)
    }

    func test_unreliable_overridesLowAndSimulated() {
        let status = QiblaCompassStatus.resolve(
            isPermissionDenied: false,
            headingTimedOut: false,
            accuracy: .unreliable,
            isSimulated: true
        )
        XCTAssertEqual(status, .unreliable)
    }

    func test_lowAccuracy_overridesSimulated() {
        let status = QiblaCompassStatus.resolve(
            isPermissionDenied: false,
            headingTimedOut: false,
            accuracy: .low,
            isSimulated: true
        )
        XCTAssertEqual(status, .lowAccuracy)
    }

    func test_simulated_whenNoOtherIssues() {
        let status = QiblaCompassStatus.resolve(
            isPermissionDenied: false,
            headingTimedOut: false,
            accuracy: .good,
            isSimulated: true
        )
        XCTAssertEqual(status, .simulated)
    }

    func test_normal_whenEverythingGood() {
        let status = QiblaCompassStatus.resolve(
            isPermissionDenied: false,
            headingTimedOut: false,
            accuracy: .good,
            isSimulated: false
        )
        XCTAssertEqual(status, .normal)
    }

    func test_normal_withGoodAccuracy() {
        // Good accuracy + no other flags → normal
        let status = QiblaCompassStatus.resolve(
            isPermissionDenied: false,
            headingTimedOut: false,
            accuracy: .good,
            isSimulated: false
        )
        XCTAssertEqual(status, .normal)
    }

    func test_permissionDenied_isHighestPriority() {
        // Even with good accuracy and no timeout, permission denied wins
        let status = QiblaCompassStatus.resolve(
            isPermissionDenied: true,
            headingTimedOut: false,
            accuracy: .good,
            isSimulated: false
        )
        XCTAssertEqual(status, .permissionDenied)
    }
}
