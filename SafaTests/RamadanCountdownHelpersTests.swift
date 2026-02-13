import XCTest
@testable import Safa

final class RamadanCountdownHelpersTests: XCTestCase {

    // MARK: - Helpers

    private func date(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())!
    }

    // MARK: - Before Suhoor Ends

    func test_beforeSuhoor_showsSuhoor() {
        // 4:00 AM, Suhoor at 5:30 AM, Iftar at 6:30 PM
        let now = date(hour: 4)
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        // Must show Suhoor, NOT Iftar — even though both are in the future
        XCTAssertEqual(target, .suhoor(time: suhoor))
    }

    func test_justBeforeSuhoor_stillShowsSuhoor() {
        // 5:29 AM, Suhoor at 5:30 AM
        let now = date(hour: 5, minute: 29)
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        XCTAssertEqual(target, .suhoor(time: suhoor))
    }

    // MARK: - After Suhoor, Before Iftar

    func test_afterSuhoor_beforeIftar_showsIftar() {
        // 12:00 PM, Suhoor was 5:30 AM, Iftar at 6:30 PM
        let now = date(hour: 12)
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        XCTAssertEqual(target, .iftar(time: iftar))
    }

    func test_justAfterSuhoor_showsIftar() {
        // 5:31 AM, Suhoor was 5:30 AM
        let now = date(hour: 5, minute: 31)
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        XCTAssertEqual(target, .iftar(time: iftar))
    }

    // MARK: - After Iftar

    func test_afterIftar_showsComplete() {
        // 8:00 PM, both times passed
        let now = date(hour: 20)
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        XCTAssertEqual(target, .complete)
    }

    // MARK: - Edge Cases

    func test_nilSuhoor_showsIftar() {
        let now = date(hour: 12)
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: nil, iftarTime: iftar
        )

        XCTAssertEqual(target, .iftar(time: iftar))
    }

    func test_nilIftar_suhoorInFuture_showsSuhoor() {
        let now = date(hour: 4)
        let suhoor = date(hour: 5, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: nil
        )

        XCTAssertEqual(target, .suhoor(time: suhoor))
    }

    func test_bothNil_showsComplete() {
        let now = date(hour: 12)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: nil, iftarTime: nil
        )

        XCTAssertEqual(target, .complete)
    }

    func test_exactlyAtSuhoor_showsIftar() {
        // Exactly at Suhoor time (not > now, so falls through)
        let now = date(hour: 5, minute: 30)
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        // At exact Suhoor time, suhoor is NOT > now, so shows Iftar
        XCTAssertEqual(target, .iftar(time: iftar))
    }
}
