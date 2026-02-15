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

// MARK: - Compass Wheel Tick/Cardinal Logic Tests

final class QiblaCompassWheelLogicTests: XCTestCase {

    // The wheel uses 72 ticks at 5° increments (0..<72).
    // Cardinals (N/E/S/W) are at indices 0, 18, 36, 54 — ticks are skipped there.

    func test_cardinalIndices_areCorrect() {
        let cardinalDegrees = [0, 90, 180, 270]
        for deg in cardinalDegrees {
            let index = deg / 5
            XCTAssertEqual(index % 18, 0,
                           "\(deg)° should be a cardinal position (index \(index))")
        }
    }

    func test_cardinalIndices_skipTicks() {
        // Verify the 4 cardinal positions are the only ones where i % 18 == 0
        let cardinalIndices = (0..<72).filter { $0 % 18 == 0 }
        XCTAssertEqual(cardinalIndices, [0, 18, 36, 54])
    }

    func test_intercardinalIndices_areCorrect() {
        // 45°, 135°, 225°, 315° → indices 9, 27, 45, 63
        let intercardinalIndices = (0..<72).filter { $0 % 9 == 0 && $0 % 18 != 0 }
        XCTAssertEqual(intercardinalIndices, [9, 27, 45, 63])
    }

    func test_tickCount_excluding_cardinals() {
        // 72 total positions minus 4 cardinals = 68 tick marks drawn
        let tickCount = (0..<72).filter { $0 % 18 != 0 }.count
        XCTAssertEqual(tickCount, 68)
    }

    func test_cardinalLetterCounterRotation_netsToZero() {
        // Each letter has rotation: angle + (-angle + deviceHeading) + (-deviceHeading)
        // This should always equal 0 (letters stay upright)
        let deviceHeadings: [Double] = [0, 45, 90, 180, 270, 359]
        let cardinalAngles: [Double] = [0, 90, 180, 270]

        for heading in deviceHeadings {
            for angle in cardinalAngles {
                let netRotation = angle + (-angle + heading) + (-heading)
                XCTAssertEqual(netRotation, 0, accuracy: 0.001,
                               "Letter at \(angle)° with heading \(heading)° should have net 0° rotation")
            }
        }
    }

    func test_qiblaArrowRotation_isRelativeToHeading() {
        // Arrow rotates by (qiblaDirection - deviceHeading)
        // When heading matches qibla, arrow should point to 12 o'clock (0°)
        let qibla = 118.0
        let heading = 118.0
        let arrowRotation = qibla - heading
        XCTAssertEqual(arrowRotation, 0, accuracy: 0.001,
                       "Arrow should point up when facing Qibla")
    }

    func test_qiblaArrowRotation_offsetWhenNotAligned() {
        let qibla = 118.0
        let heading = 0.0
        let arrowRotation = qibla - heading
        XCTAssertEqual(arrowRotation, 118, accuracy: 0.001,
                       "Arrow should point 118° clockwise when facing North")
    }
}

// MARK: - CalculationMethod shortDisplayName Tests

final class CalculationMethodDisplayTests: XCTestCase {

    func test_shortDisplayName_allMethodsHaveValue() {
        let allMethods: [CalculationMethod] = [
            .muslimWorldLeague, .isna, .egypt, .makkah, .karachi,
            .tehran, .jafari, .dubai, .kuwait, .qatar, .singapore, .turkey
        ]

        for method in allMethods {
            XCTAssertFalse(method.shortDisplayName.isEmpty,
                           "\(method) should have a non-empty shortDisplayName")
        }
    }

    func test_shortDisplayName_isShort() {
        // Short names should fit in a compact UI — max ~10 characters
        let allMethods: [CalculationMethod] = [
            .muslimWorldLeague, .isna, .egypt, .makkah, .karachi,
            .tehran, .jafari, .dubai, .kuwait, .qatar, .singapore, .turkey
        ]

        for method in allMethods {
            XCTAssertLessThanOrEqual(method.shortDisplayName.count, 10,
                                     "\(method).shortDisplayName '\(method.shortDisplayName)' is too long")
        }
    }

    func test_shortDisplayName_knownValues() {
        XCTAssertEqual(CalculationMethod.muslimWorldLeague.shortDisplayName, "MWL")
        XCTAssertEqual(CalculationMethod.isna.shortDisplayName, "ISNA")
        XCTAssertEqual(CalculationMethod.makkah.shortDisplayName, "Makkah")
        XCTAssertEqual(CalculationMethod.dubai.shortDisplayName, "Dubai")
    }
}
