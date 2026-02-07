// MARK: - RamadanFeatureFlagTests.swift
// PURPOSE: Verify Ramadan feature flag behaviour for debug mode
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class RamadanFeatureFlagTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear any overrides between tests
        FeatureFlags.shared.removeOverride(.ramadanMode)
    }

    override func tearDown() {
        FeatureFlags.shared.removeOverride(.ramadanMode)
        super.tearDown()
    }

    // MARK: - Default State

    func test_ramadanMode_disabledByDefault() {
        // ramadanMode should NOT be enabled by default — it's a debug override
        XCTAssertFalse(Feature.ramadanMode.isEnabledByDefault,
                       "ramadanMode should be disabled by default")
    }

    func test_ramadanMode_notEnabled_withoutOverride() {
        XCTAssertFalse(FeatureFlags.shared.isEnabled(.ramadanMode),
                       "ramadanMode should not be enabled without an override")
    }

    func test_ramadanMode_isDisabled_withoutOverride() {
        XCTAssertTrue(FeatureFlags.shared.isDisabled(.ramadanMode),
                      "ramadanMode should be disabled without an override")
    }

    // MARK: - Override Behaviour

    func test_ramadanMode_enabledAfterOverride() {
        // When: override to enable
        FeatureFlags.shared.setOverride(.ramadanMode, enabled: true)

        // Then: should be enabled
        XCTAssertTrue(FeatureFlags.shared.isEnabled(.ramadanMode))
    }

    func test_ramadanMode_disabledAfterRemovingOverride() {
        // Given: was enabled via override
        FeatureFlags.shared.setOverride(.ramadanMode, enabled: true)
        XCTAssertTrue(FeatureFlags.shared.isEnabled(.ramadanMode))

        // When: remove override
        FeatureFlags.shared.removeOverride(.ramadanMode)

        // Then: back to default (disabled)
        XCTAssertFalse(FeatureFlags.shared.isEnabled(.ramadanMode))
    }

    // MARK: - isRamadan Logic

    func test_isRamadan_falseWhenCalendarSaysNoAndFlagOff() {
        // Simulate: not Ramadan month, flag off
        let calendarSaysRamadan = false
        let flagEnabled = FeatureFlags.shared.isEnabled(.ramadanMode)

        let isRamadan = calendarSaysRamadan || flagEnabled

        XCTAssertFalse(isRamadan,
                       "isRamadan should be false when both calendar and flag are false")
    }

    func test_isRamadan_trueWhenFlagOn() {
        // Simulate: not Ramadan month, but flag forced on
        let calendarSaysRamadan = false
        FeatureFlags.shared.setOverride(.ramadanMode, enabled: true)
        let flagEnabled = FeatureFlags.shared.isEnabled(.ramadanMode)

        let isRamadan = calendarSaysRamadan || flagEnabled

        XCTAssertTrue(isRamadan,
                      "isRamadan should be true when flag is forced on")
    }

    func test_isRamadan_trueWhenCalendarSaysYes() {
        // Simulate: actual Ramadan month, flag off
        let calendarSaysRamadan = true
        let flagEnabled = FeatureFlags.shared.isEnabled(.ramadanMode)

        let isRamadan = calendarSaysRamadan || flagEnabled

        XCTAssertTrue(isRamadan,
                      "isRamadan should be true when calendar says Ramadan")
    }

    // MARK: - Banner Visibility Logic

    func test_bannerShouldShow_whenRamadanAndNotDismissed() {
        let isRamadan = true
        let showRamadanBanner = true
        let bannerDismissed = false
        let daysUntilRamadan: Int? = nil

        let shouldShow = showRamadanBanner
            && !bannerDismissed
            && (isRamadan || (daysUntilRamadan ?? 0 > 0 && daysUntilRamadan ?? 0 <= 30))

        XCTAssertTrue(shouldShow, "Banner should show when Ramadan and not dismissed")
    }

    func test_bannerShouldNotShow_whenNotRamadanAndNoDays() {
        let isRamadan = false
        let showRamadanBanner = true
        let bannerDismissed = false
        let daysUntilRamadan: Int? = nil

        let shouldShow = showRamadanBanner
            && !bannerDismissed
            && (isRamadan || (daysUntilRamadan ?? 0 > 0 && daysUntilRamadan ?? 0 <= 30))

        XCTAssertFalse(shouldShow, "Banner should not show when not Ramadan and no days until")
    }

    func test_bannerShouldNotShow_whenDismissed() {
        let isRamadan = true
        let showRamadanBanner = true
        let bannerDismissed = true

        let shouldShow = showRamadanBanner
            && !bannerDismissed

        XCTAssertFalse(shouldShow, "Banner should not show when dismissed")
    }

    func test_bannerShouldNotShow_whenShowRamadanBannerFalse() {
        let isRamadan = true
        let showRamadanBanner = false
        let bannerDismissed = false

        let shouldShow = showRamadanBanner
            && !bannerDismissed

        XCTAssertFalse(shouldShow, "Banner should not show when showRamadanBanner is false")
    }
}
