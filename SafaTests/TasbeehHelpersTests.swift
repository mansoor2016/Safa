import XCTest
@testable import Safa

final class TasbeehHelpersTests: XCTestCase {

    // MARK: - progress(count:target:)

    func test_progress_zero() {
        XCTAssertEqual(TasbeehHelpers.progress(count: 0, target: 33), 0.0, accuracy: 0.001)
    }

    func test_progress_halfway() {
        XCTAssertEqual(TasbeehHelpers.progress(count: 50, target: 100), 0.5, accuracy: 0.001)
    }

    func test_progress_complete() {
        XCTAssertEqual(TasbeehHelpers.progress(count: 33, target: 33), 1.0, accuracy: 0.001)
    }

    func test_progress_overcounted_clampedTo1() {
        XCTAssertEqual(TasbeehHelpers.progress(count: 40, target: 33), 1.0, accuracy: 0.001)
    }

    func test_progress_zeroTarget_returnsZero() {
        XCTAssertEqual(TasbeehHelpers.progress(count: 10, target: 0), 0.0, accuracy: 0.001)
    }

    func test_progress_oneThird() {
        XCTAssertEqual(TasbeehHelpers.progress(count: 11, target: 33), 11.0 / 33.0, accuracy: 0.001)
    }

    // MARK: - isComplete(count:target:)

    func test_isComplete_false_whenBelow() {
        XCTAssertFalse(TasbeehHelpers.isComplete(count: 10, target: 33))
    }

    func test_isComplete_true_whenEqual() {
        XCTAssertTrue(TasbeehHelpers.isComplete(count: 33, target: 33))
    }

    func test_isComplete_true_whenAbove() {
        XCTAssertTrue(TasbeehHelpers.isComplete(count: 34, target: 33))
    }

    func test_isComplete_false_whenZeroCount() {
        XCTAssertFalse(TasbeehHelpers.isComplete(count: 0, target: 33))
    }

    func test_isComplete_false_whenZeroTarget() {
        XCTAssertFalse(TasbeehHelpers.isComplete(count: 5, target: 0))
    }

    // MARK: - accessibilityLabel

    func test_accessibilityLabel_atZero() {
        let label = TasbeehHelpers.accessibilityLabel(dhikrName: "SubhanAllah", count: 0, target: 33)
        XCTAssertEqual(label, "SubhanAllah counter, 33 remaining")
    }

    func test_accessibilityLabel_inProgress() {
        let label = TasbeehHelpers.accessibilityLabel(dhikrName: "SubhanAllah", count: 16, target: 33)
        XCTAssertTrue(label.contains("16 of 33"))
        XCTAssertTrue(label.contains("48 percent"))
    }

    func test_accessibilityLabel_complete() {
        let label = TasbeehHelpers.accessibilityLabel(dhikrName: "SubhanAllah", count: 33, target: 33)
        XCTAssertEqual(label, "SubhanAllah counter complete, 33 repetitions")
    }

    func test_accessibilityLabel_overcounted() {
        let label = TasbeehHelpers.accessibilityLabel(dhikrName: "SubhanAllah", count: 40, target: 33)
        XCTAssertTrue(label.contains("complete"))
        XCTAssertTrue(label.contains("40 repetitions"))
    }
}
