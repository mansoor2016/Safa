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

    func test_justAfterSuhoor_showsSuhoorGrace() {
        // 5:31 AM, Suhoor was 5:30 AM — within 15-min grace window
        let now = date(hour: 5, minute: 31)
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        XCTAssertEqual(target, .suhoorGrace)
    }

    // MARK: - After Iftar

    func test_afterIftar_showsNextSuhoor() {
        // 8:00 PM, both times passed → should show tomorrow's suhoor
        let now = date(hour: 20)
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        let expectedTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: suhoor)!
        XCTAssertEqual(target, .nextSuhoor(time: expectedTomorrow))
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

    func test_exactlyAtSuhoor_showsSuhoorGrace() {
        // Exactly at Suhoor time — enters grace window
        let now = date(hour: 5, minute: 30)
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        XCTAssertEqual(target, .suhoorGrace)
    }

    // MARK: - Suhoor Grace Period

    func test_duringSuhoorGrace_showsSuhoorGrace() {
        // Suhoor + 5 min → still in 15-min grace
        let suhoor = date(hour: 5, minute: 30)
        let now = suhoor.addingTimeInterval(5 * 60)
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        XCTAssertEqual(target, .suhoorGrace)
    }

    func test_exactlyAtSuhoorGraceCutoff_showsIftar() {
        // Suhoor + 15 min exactly — half-open [0, grace) excludes exact cutoff
        let suhoor = date(hour: 5, minute: 30)
        let now = suhoor.addingTimeInterval(15 * 60)
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        XCTAssertEqual(target, .iftar(time: iftar))
    }

    func test_afterSuhoorGrace_showsIftar() {
        // Suhoor + 16 min → past grace, should show Iftar
        let suhoor = date(hour: 5, minute: 30)
        let now = suhoor.addingTimeInterval(16 * 60)
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        XCTAssertEqual(target, .iftar(time: iftar))
    }

    // MARK: - Iftar Grace Period

    func test_exactlyAtIftar_showsIftarGrace() {
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)
        let now = iftar

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        XCTAssertEqual(target, .iftarGrace)
    }

    func test_duringIftarGrace_showsIftarGrace() {
        // Iftar + 20 min → within 30-min iftar grace
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)
        let now = iftar.addingTimeInterval(20 * 60)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        XCTAssertEqual(target, .iftarGrace)
    }

    func test_exactlyAtIftarGraceCutoff_showsNextSuhoor() {
        // Iftar + 30 min exactly — half-open [0, grace) excludes exact cutoff
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)
        let now = iftar.addingTimeInterval(30 * 60)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        let expectedTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: suhoor)!
        XCTAssertEqual(target, .nextSuhoor(time: expectedTomorrow))
    }

    func test_afterIftarGrace_showsNextSuhoor() {
        // Iftar + 31 min → past 30-min iftar grace
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)
        let now = iftar.addingTimeInterval(31 * 60)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar
        )

        let expectedTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: suhoor)!
        XCTAssertEqual(target, .nextSuhoor(time: expectedTomorrow))
    }

    // MARK: - Custom Grace Interval

    func test_graceIntervalZero_noGrace() {
        // With both graces=0, exact Suhoor time falls through to Iftar
        let suhoor = date(hour: 5, minute: 30)
        let now = suhoor
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar,
            suhoorGraceInterval: 0, iftarGraceInterval: 0
        )

        XCTAssertEqual(target, .iftar(time: iftar))
    }

    func test_customSuhoorGraceInterval_respected() {
        // Suhoor + 25 min with suhoor grace=30 min → still in suhoor grace
        let suhoor = date(hour: 5, minute: 30)
        let now = suhoor.addingTimeInterval(25 * 60)
        let iftar = date(hour: 18, minute: 30)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar, suhoorGraceInterval: 30 * 60
        )

        XCTAssertEqual(target, .suhoorGrace)
    }

    func test_customIftarGraceInterval_respected() {
        // Iftar + 45 min with iftar grace=60 min → still in iftar grace
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)
        let now = iftar.addingTimeInterval(45 * 60)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: suhoor, iftarTime: iftar, iftarGraceInterval: 60 * 60
        )

        XCTAssertEqual(target, .iftarGrace)
    }

    // MARK: - Nil Time + Grace

    func test_nilSuhoor_iftarInGrace_showsIftarGrace() {
        let iftar = date(hour: 18, minute: 30)
        let now = iftar.addingTimeInterval(5 * 60)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: nil, iftarTime: iftar
        )

        XCTAssertEqual(target, .iftarGrace)
    }

    func test_nilSuhoor_iftarAfterGrace_showsComplete() {
        // Iftar + 31 min → past 30-min iftar grace, no suhoor → complete
        let iftar = date(hour: 18, minute: 30)
        let now = iftar.addingTimeInterval(31 * 60)

        let target = RamadanCountdownHelpers.resolveTarget(
            now: now, suhoorTime: nil, iftarTime: iftar
        )

        XCTAssertEqual(target, .complete)
    }

    // MARK: - Transition Sequence

    func test_transitionSequence_iftarToGraceToNextSuhoor() {
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)

        // 1 second before Iftar → countdown
        let beforeIftar = iftar.addingTimeInterval(-1)
        XCTAssertEqual(
            RamadanCountdownHelpers.resolveTarget(now: beforeIftar, suhoorTime: suhoor, iftarTime: iftar),
            .iftar(time: iftar)
        )

        // Exactly at Iftar → grace
        XCTAssertEqual(
            RamadanCountdownHelpers.resolveTarget(now: iftar, suhoorTime: suhoor, iftarTime: iftar),
            .iftarGrace
        )

        // At grace cutoff (30 min) → next suhoor
        let atCutoff = iftar.addingTimeInterval(30 * 60)
        let expectedTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: suhoor)!
        XCTAssertEqual(
            RamadanCountdownHelpers.resolveTarget(now: atCutoff, suhoorTime: suhoor, iftarTime: iftar),
            .nextSuhoor(time: expectedTomorrow)
        )
    }

    func test_transitionSequence_suhoorToGraceToIftar() {
        let suhoor = date(hour: 5, minute: 30)
        let iftar = date(hour: 18, minute: 30)

        // 1 second before Suhoor → countdown
        let beforeSuhoor = suhoor.addingTimeInterval(-1)
        XCTAssertEqual(
            RamadanCountdownHelpers.resolveTarget(now: beforeSuhoor, suhoorTime: suhoor, iftarTime: iftar),
            .suhoor(time: suhoor)
        )

        // Exactly at Suhoor → grace
        XCTAssertEqual(
            RamadanCountdownHelpers.resolveTarget(now: suhoor, suhoorTime: suhoor, iftarTime: iftar),
            .suhoorGrace
        )

        // At suhoor grace cutoff (15 min) → iftar countdown
        let atCutoff = suhoor.addingTimeInterval(15 * 60)
        XCTAssertEqual(
            RamadanCountdownHelpers.resolveTarget(now: atCutoff, suhoorTime: suhoor, iftarTime: iftar),
            .iftar(time: iftar)
        )
    }

    // MARK: - Default Grace Intervals

    func test_defaultSuhoorGrace_is15Minutes() {
        XCTAssertEqual(RamadanCountdownHelpers.suhoorGraceDefault, 15 * 60)
    }

    func test_defaultIftarGrace_is30Minutes() {
        XCTAssertEqual(RamadanCountdownHelpers.iftarGraceDefault, 30 * 60)
    }
}
