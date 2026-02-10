// MARK: - DesignTokenTests.swift
// PURPOSE: Tests for motion and elevation design tokens
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

// MARK: - Motion Token Tests

final class MotionTokenTests: XCTestCase {

    func test_durations_areOrdered() {
        XCTAssertLessThan(SafaMotion.durationFast, SafaMotion.durationNormal)
        XCTAssertLessThan(SafaMotion.durationNormal, SafaMotion.durationSlow)
        XCTAssertLessThan(SafaMotion.durationSlow, SafaMotion.durationEmphasis)
    }

    func test_durationFast_is100ms() {
        XCTAssertEqual(SafaMotion.durationFast, 0.1)
    }

    func test_durationNormal_is250ms() {
        XCTAssertEqual(SafaMotion.durationNormal, 0.25)
    }

    func test_durationSlow_is400ms() {
        XCTAssertEqual(SafaMotion.durationSlow, 0.4)
    }

    func test_durationEmphasis_is600ms() {
        XCTAssertEqual(SafaMotion.durationEmphasis, 0.6)
    }
}

// MARK: - Elevation Token Tests

final class ElevationTokenTests: XCTestCase {

    func test_noneShadow_isClear() {
        XCTAssertEqual(SafaElevation.none.shadowRadius, 0)
        XCTAssertEqual(SafaElevation.none.shadowY, 0)
    }

    func test_elevationShadowRadius_increases() {
        XCTAssertLessThan(SafaElevation.low.shadowRadius, SafaElevation.medium.shadowRadius)
        XCTAssertLessThan(SafaElevation.medium.shadowRadius, SafaElevation.high.shadowRadius)
    }

    func test_elevationShadowY_increases() {
        XCTAssertLessThanOrEqual(SafaElevation.low.shadowY, SafaElevation.medium.shadowY)
        XCTAssertLessThanOrEqual(SafaElevation.medium.shadowY, SafaElevation.high.shadowY)
    }

    func test_mediumElevation_matchesCardShadow() {
        // medium elevation should produce the same values as the legacy cardShadow()
        XCTAssertEqual(SafaElevation.medium.shadowRadius, 8)
        XCTAssertEqual(SafaElevation.medium.shadowY, 2)
    }
}

// MARK: - Surface Token Tests

final class SurfaceTokenTests: XCTestCase {

    func test_allSurfaces_produceColors() {
        // Verify each surface returns a non-nil color (doesn't crash)
        _ = SafaSurface.primary.color
        _ = SafaSurface.secondary.color
        _ = SafaSurface.tertiary.color
    }
}
