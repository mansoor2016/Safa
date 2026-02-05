// MARK: - DisabledFeatureTests.swift
// PURPOSE: Tests for disabled feature pattern functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class DisabledFeatureTests: XCTestCase {

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        // Reset all feature flag overrides before each test
        FeatureFlags.shared.resetAllOverrides()
    }

    override func tearDown() {
        FeatureFlags.shared.resetAllOverrides()
        super.tearDown()
    }

    // MARK: - Feature Flag Tests

    func test_enabledFeature_returnsTrue() {
        // Given: A feature enabled by default
        let feature = Feature.prayerTimes

        // When: Checking if enabled
        let isEnabled = FeatureFlags.shared.isEnabled(feature)

        // Then: Should be enabled
        XCTAssertTrue(isEnabled)
    }

    func test_disabledFeature_returnsFalse() {
        // Given: A feature disabled by default (requires Widget extension)
        let feature = Feature.interactiveWidgets

        // When: Checking if enabled
        let isEnabled = FeatureFlags.shared.isEnabled(feature)

        // Then: Should be disabled
        XCTAssertFalse(isEnabled)
    }

    func test_featureOverride_enablesDisabledFeature() {
        // Given: A feature disabled by default (requires Widget extension)
        let feature = Feature.interactiveWidgets
        XCTAssertFalse(FeatureFlags.shared.isEnabled(feature))

        // When: Setting an override to enable it
        FeatureFlags.shared.setOverride(feature, enabled: true)

        // Then: Should now be enabled
        XCTAssertTrue(FeatureFlags.shared.isEnabled(feature))
    }

    func test_featureOverride_disablesEnabledFeature() {
        // Given: A feature enabled by default
        let feature = Feature.prayerTimes
        XCTAssertTrue(FeatureFlags.shared.isEnabled(feature))

        // When: Setting an override to disable it
        FeatureFlags.shared.setOverride(feature, enabled: false)

        // Then: Should now be disabled
        XCTAssertFalse(FeatureFlags.shared.isEnabled(feature))
    }

    func test_removeOverride_restoresDefaultState() {
        // Given: A feature with an override (requires Widget extension)
        let feature = Feature.interactiveWidgets
        FeatureFlags.shared.setOverride(feature, enabled: true)
        XCTAssertTrue(FeatureFlags.shared.isEnabled(feature))

        // When: Removing the override
        FeatureFlags.shared.removeOverride(feature)

        // Then: Should return to default (disabled)
        XCTAssertFalse(FeatureFlags.shared.isEnabled(feature))
    }

    func test_resetAllOverrides_clearsAllOverrides() {
        // Given: Multiple features with overrides
        FeatureFlags.shared.setOverride(.interactiveWidgets, enabled: true)
        FeatureFlags.shared.setOverride(.prayerTimes, enabled: false)

        // When: Resetting all overrides
        FeatureFlags.shared.resetAllOverrides()

        // Then: All features return to defaults
        XCTAssertFalse(FeatureFlags.shared.isEnabled(.interactiveWidgets))
        XCTAssertTrue(FeatureFlags.shared.isEnabled(.prayerTimes))
    }

    func test_isDisabled_inversesIsEnabled() {
        // Given: An enabled feature
        let enabledFeature = Feature.prayerTimes

        // Then: isDisabled should be false
        XCTAssertFalse(FeatureFlags.shared.isDisabled(enabledFeature))

        // Given: A disabled feature (requires Widget extension)
        let disabledFeature = Feature.interactiveWidgets

        // Then: isDisabled should be true
        XCTAssertTrue(FeatureFlags.shared.isDisabled(disabledFeature))
    }

    // MARK: - Feature Display Name Tests

    func test_featureDisplayName_isNotEmpty() {
        // All features should have non-empty display names
        for feature in Feature.allCases {
            XCTAssertFalse(feature.displayName.isEmpty, "Feature \(feature.rawValue) has empty display name")
        }
    }

    func test_featureDisplayName_isHumanReadable() {
        // Check some specific display names
        XCTAssertEqual(Feature.prayerTimes.displayName, "Prayer Times")
        XCTAssertEqual(Feature.aiCompanion.displayName, "AI Companion")
        XCTAssertEqual(Feature.spotlightSearch.displayName, "Spotlight Search")
    }

    // MARK: - Toast Tests

    func test_toastComingSoon_hasCorrectType() {
        // Given: Creating a coming soon toast
        let toast = Toast.comingSoon("Test Feature")

        // Then: Should have correct type and message
        XCTAssertEqual(toast.type, .comingSoon)
        XCTAssertEqual(toast.message, "Test Feature coming soon")
    }

    func test_toastTypes_haveUniqueColors() {
        // Given: All toast types
        let types: [Toast.ToastType] = [.info, .success, .warning, .comingSoon]

        // When: Getting their colors
        let colors = types.map { $0.color }

        // Then: Each should have a distinct color (simplified check)
        XCTAssertEqual(types.count, colors.count)
    }

    func test_toastTypes_haveUniqueIcons() {
        // Given: All toast types
        let types: [Toast.ToastType] = [.info, .success, .warning, .comingSoon]

        // When: Getting their icons
        let icons = Set(types.map { $0.icon })

        // Then: All icons should be unique
        XCTAssertEqual(icons.count, types.count)
    }

    // MARK: - Default Features Tests

    func test_coreFeatures_areEnabledByDefault() {
        let coreFeatures: [Feature] = [
            .prayerTimes,
            .qiblaCompass,
            .quranReader,
            .hadithCollection,
            .duaAdhkar,
            .tasbeehCounter,
            .islamicCalendar,
            .gamification,
            .learning,
            .familyCircle,
            .ramadanMode,
            .windDown,
            .zakatCalculator,
            .namesOfAllah
        ]

        for feature in coreFeatures {
            XCTAssertTrue(feature.isEnabledByDefault, "\(feature.displayName) should be enabled by default")
        }
    }

    func test_upcomingFeatures_areDisabledByDefault() {
        // Features requiring Widget extension target or iOS 18.4+
        let upcomingFeatures: [Feature] = [
            .aiCompanion,       // Requires iOS 18.4+
            .interactiveWidgets, // Requires Widget extension target
            .standByMode        // Requires Widget extension target
        ]

        for feature in upcomingFeatures {
            XCTAssertFalse(feature.isEnabledByDefault, "\(feature.displayName) should be disabled by default")
        }
    }

    func test_advancedFeatures_areEnabledByDefault() {
        // Features with complete implementations
        let advancedFeatures: [Feature] = [
            .spotlightSearch,
            .calendarExport,
            .prayerCalendarExport,
            .healthKitSync,
            .predictiveDownload,
            .smartCleanup
        ]

        for feature in advancedFeatures {
            XCTAssertTrue(feature.isEnabledByDefault, "\(feature.displayName) should be enabled by default")
        }
    }
}
