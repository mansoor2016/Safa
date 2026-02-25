import XCTest
import CoreLocation
@testable import Safa

final class OnboardingHelpersTests: XCTestCase {

    // MARK: - buildSkipPreferences

    func test_buildSkipPreferences_withLocation_usesInferredValues() {
        // Given: a location context with non-default recommendations
        let context = LocationContext(
            coordinates: Coordinates(latitude: 24.7136, longitude: 46.6753),
            city: "Riyadh",
            country: "Saudi Arabia",
            countryCode: "SA",
            timezone: .current,
            recommendedMethod: .makkah,
            recommendedMadhab: .hanafi,
            recommendedLanguage: "Arabic",
            regionName: "Riyadh, Saudi Arabia"
        )
        let current = UserPreferences()

        // When
        let result = OnboardingHelpers.buildSkipPreferences(
            current: current,
            locationContext: context
        )

        // Then: inferred values are applied, not AppDefaults
        XCTAssertEqual(result.calculationMethod, .makkah)
        XCTAssertEqual(result.madhab, .hanafi)
        XCTAssertEqual(result.selectedTranslation, "Arabic")
        XCTAssertEqual(result.savedLocationName, "Riyadh, Saudi Arabia")
        XCTAssertEqual(result.savedCountryCode, "SA")
        XCTAssertEqual(result.savedLatitude, 24.7136)
        XCTAssertEqual(result.savedLongitude, 46.6753)
        XCTAssertTrue(result.useLocationBasedDefaults)
        XCTAssertTrue(result.hasCompletedOnboarding)
    }

    func test_buildSkipPreferences_withoutLocation_usesDefaults() {
        // Given: no location context
        let current = UserPreferences()

        // When
        let result = OnboardingHelpers.buildSkipPreferences(
            current: current,
            locationContext: nil
        )

        // Then: AppDefaults are used
        XCTAssertEqual(result.calculationMethod, AppDefaults.calculationMethod)
        XCTAssertEqual(result.madhab, AppDefaults.madhab)
        XCTAssertEqual(result.selectedTranslation, AppDefaults.translationLanguage)
        XCTAssertNil(result.savedLocationName)
        XCTAssertTrue(result.hasCompletedOnboarding)
    }

    func test_buildSkipPreferences_notificationsMatchDefault() {
        // Given
        let current = UserPreferences(notificationsEnabled: false)

        // When: skip always sets notificationsEnabled to AppDefaults value
        let result = OnboardingHelpers.buildSkipPreferences(
            current: current,
            locationContext: nil
        )

        // Then: notifications match AppDefaults regardless of current value
        XCTAssertEqual(result.notificationsEnabled, AppDefaults.notificationsEnabled)
    }

    func test_buildSkipPreferences_preservesExistingPrefsNotOverridden() {
        // Given: a current prefs with custom adhan settings
        var current = UserPreferences()
        current.adhanEnabled = true
        current.selectedAdhan = "custom_adhan"

        // When
        let result = OnboardingHelpers.buildSkipPreferences(
            current: current,
            locationContext: nil
        )

        // Then: fields not touched by skip logic are preserved
        XCTAssertTrue(result.adhanEnabled)
        XCTAssertEqual(result.selectedAdhan, "custom_adhan")
    }

    // MARK: - shouldShowSettingsLink

    func test_shouldShowSettingsLink_denied_returnsTrue() {
        XCTAssertTrue(OnboardingHelpers.shouldShowSettingsLink(locationStatus: .denied))
    }

    func test_shouldShowSettingsLink_restricted_returnsTrue() {
        XCTAssertTrue(OnboardingHelpers.shouldShowSettingsLink(locationStatus: .restricted))
    }

    func test_shouldShowSettingsLink_notDetermined_returnsFalse() {
        XCTAssertFalse(OnboardingHelpers.shouldShowSettingsLink(locationStatus: .notDetermined))
    }

    func test_shouldShowSettingsLink_authorizedWhenInUse_returnsFalse() {
        XCTAssertFalse(OnboardingHelpers.shouldShowSettingsLink(locationStatus: .authorizedWhenInUse))
    }

    func test_shouldShowSettingsLink_authorizedAlways_returnsFalse() {
        XCTAssertFalse(OnboardingHelpers.shouldShowSettingsLink(locationStatus: .authorizedAlways))
    }

    // MARK: - shouldAllowForwardNavigation

    func test_forwardNavigation_page0ToPage1_alwaysAllowed() {
        // About → Location is always allowed regardless of location state
        XCTAssertTrue(OnboardingHelpers.shouldAllowForwardNavigation(
            from: 0, to: 1, locationPermissionResolved: false
        ))
        XCTAssertTrue(OnboardingHelpers.shouldAllowForwardNavigation(
            from: 0, to: 1, locationPermissionResolved: true
        ))
    }

    func test_forwardNavigation_page1ToPage2_blockedWhenLocationUnresolved() {
        // Location → Notifications blocked until permission resolved
        XCTAssertFalse(OnboardingHelpers.shouldAllowForwardNavigation(
            from: 1, to: 2, locationPermissionResolved: false
        ))
    }

    func test_forwardNavigation_page1ToPage2_allowedWhenLocationResolved() {
        XCTAssertTrue(OnboardingHelpers.shouldAllowForwardNavigation(
            from: 1, to: 2, locationPermissionResolved: true
        ))
    }

    func test_backwardNavigation_page2ToPage1_alwaysAllowed() {
        // Backward navigation is never blocked
        XCTAssertTrue(OnboardingHelpers.shouldAllowForwardNavigation(
            from: 2, to: 1, locationPermissionResolved: false
        ))
    }

    func test_backwardNavigation_page1ToPage0_alwaysAllowed() {
        XCTAssertTrue(OnboardingHelpers.shouldAllowForwardNavigation(
            from: 1, to: 0, locationPermissionResolved: false
        ))
    }
}
