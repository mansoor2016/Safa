import XCTest
@testable import Safa

final class QiblaCompassHelpersTests: XCTestCase {

    // MARK: - normalizeDegrees

    func test_normalizeDegrees_alreadyNormalized() {
        XCTAssertEqual(QiblaCompassHelpers.normalizeDegrees(180), 180)
    }

    func test_normalizeDegrees_zero() {
        XCTAssertEqual(QiblaCompassHelpers.normalizeDegrees(0), 0)
    }

    func test_normalizeDegrees_negative() {
        XCTAssertEqual(QiblaCompassHelpers.normalizeDegrees(-90), 270)
    }

    func test_normalizeDegrees_over360() {
        XCTAssertEqual(QiblaCompassHelpers.normalizeDegrees(450), 90)
    }

    func test_normalizeDegrees_exactlyAt360() {
        XCTAssertEqual(QiblaCompassHelpers.normalizeDegrees(360), 0)
    }

    func test_normalizeDegrees_largeNegative() {
        XCTAssertEqual(QiblaCompassHelpers.normalizeDegrees(-720), 0, accuracy: 0.001)
    }

    // MARK: - smoothHeading (wrap-around)

    func test_smoothHeading_simpleInterpolation() {
        // From 10° to 50° with factor 0.5 → should move halfway = 30°
        let result = QiblaCompassHelpers.smoothHeading(from: 10, to: 50, factor: 0.5)
        XCTAssertEqual(result, 30, accuracy: 0.001)
    }

    func test_smoothHeading_wrapAround_clockwise() {
        // From 350° to 10° — shortest path is +20° clockwise
        // With factor 0.5 → 350 + 10 = 360 → 0°
        let result = QiblaCompassHelpers.smoothHeading(from: 350, to: 10, factor: 0.5)
        XCTAssertEqual(result, 0, accuracy: 0.001)
    }

    func test_smoothHeading_wrapAround_counterclockwise() {
        // From 10° to 350° — shortest path is -20° counterclockwise
        // With factor 0.5 → 10 - 10 = 0°
        let result = QiblaCompassHelpers.smoothHeading(from: 10, to: 350, factor: 0.5)
        XCTAssertEqual(result, 0, accuracy: 0.001)
    }

    func test_smoothHeading_factor1_snapsToTarget() {
        let result = QiblaCompassHelpers.smoothHeading(from: 100, to: 200, factor: 1.0)
        XCTAssertEqual(result, 200, accuracy: 0.001)
    }

    func test_smoothHeading_factor0_staysAtCurrent() {
        let result = QiblaCompassHelpers.smoothHeading(from: 100, to: 200, factor: 0)
        XCTAssertEqual(result, 100, accuracy: 0.001)
    }

    // MARK: - relativeAngle

    func test_relativeAngle_sameDirection() {
        let result = QiblaCompassHelpers.relativeAngle(qiblaDirection: 45, deviceHeading: 45)
        XCTAssertEqual(result, 0, accuracy: 0.001)
    }

    func test_relativeAngle_qiblaAhead() {
        let result = QiblaCompassHelpers.relativeAngle(qiblaDirection: 90, deviceHeading: 45)
        XCTAssertEqual(result, 45, accuracy: 0.001)
    }

    func test_relativeAngle_wrapAround() {
        // Qibla at 10°, device pointing 350° → qibla is 20° to the right
        let result = QiblaCompassHelpers.relativeAngle(qiblaDirection: 10, deviceHeading: 350)
        XCTAssertEqual(result, 20, accuracy: 0.001)
    }

    // MARK: - AlignmentZone

    func test_alignmentZone_perfect_at0() {
        XCTAssertEqual(QiblaCompassHelpers.AlignmentZone.from(angle: 0), .perfect)
    }

    func test_alignmentZone_perfect_at4() {
        XCTAssertEqual(QiblaCompassHelpers.AlignmentZone.from(angle: 4), .perfect)
    }

    func test_alignmentZone_perfect_at356() {
        // 360 - 356 = 4° from other direction → perfect
        XCTAssertEqual(QiblaCompassHelpers.AlignmentZone.from(angle: 356), .perfect)
    }

    func test_alignmentZone_close_at10() {
        XCTAssertEqual(QiblaCompassHelpers.AlignmentZone.from(angle: 10), .close)
    }

    func test_alignmentZone_near_at20() {
        XCTAssertEqual(QiblaCompassHelpers.AlignmentZone.from(angle: 20), .near)
    }

    func test_alignmentZone_far_at45() {
        XCTAssertEqual(QiblaCompassHelpers.AlignmentZone.from(angle: 45), .far)
    }

    func test_alignmentZone_far_at180() {
        XCTAssertEqual(QiblaCompassHelpers.AlignmentZone.from(angle: 180), .far)
    }

    // MARK: - compassAccuracy

    func test_compassAccuracy_good() {
        XCTAssertEqual(QiblaCompassHelpers.compassAccuracy(for: 10), .good)
    }

    func test_compassAccuracy_good_at25() {
        XCTAssertEqual(QiblaCompassHelpers.compassAccuracy(for: 25), .good)
    }

    func test_compassAccuracy_low() {
        XCTAssertEqual(QiblaCompassHelpers.compassAccuracy(for: 30), .low)
    }

    func test_compassAccuracy_unreliable() {
        XCTAssertEqual(QiblaCompassHelpers.compassAccuracy(for: -1), .unreliable)
    }

    // MARK: - compassSize(forContainerWidth:)

    func test_compassSize_iPhoneSE_375pt() {
        // Card interior on SE ≈ 375 - 32 (padding) - 32 (card insets) = 311pt
        let size = QiblaCompassHelpers.compassSize(forContainerWidth: 311)
        XCTAssertGreaterThanOrEqual(size, 200)
        XCTAssertLessThanOrEqual(size, 320)
        XCTAssertEqual(size, 247, accuracy: 1)
    }

    func test_compassSize_iPhoneProMax_430pt() {
        // Card interior on Pro Max ≈ 430 - 32 - 32 = 366pt
        let size = QiblaCompassHelpers.compassSize(forContainerWidth: 366)
        XCTAssertEqual(size, 302, accuracy: 1)
    }

    func test_compassSize_narrowContainer_200pt() {
        let size = QiblaCompassHelpers.compassSize(forContainerWidth: 200)
        XCTAssertEqual(size, 200, "Should clamp to minimum of 200")
    }

    func test_compassSize_wideContainer_500pt() {
        let size = QiblaCompassHelpers.compassSize(forContainerWidth: 500)
        XCTAssertEqual(size, 320, "Should clamp to maximum of 320")
    }

    func test_compassSize_neverExceedsContainerWidth() {
        // For containers wide enough to fit breathing room, size + breathing ≤ width
        for width in stride(from: 264.0, through: 500.0, by: 20.0) {
            let size = QiblaCompassHelpers.compassSize(forContainerWidth: width)
            XCTAssertLessThanOrEqual(size + 64, width, "Compass size + breathing room should not exceed container width")
        }
    }
}
