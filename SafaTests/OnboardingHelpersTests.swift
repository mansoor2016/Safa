import XCTest
import CoreLocation
import UserNotifications
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

    // MARK: - resolveLocationPermissionState

    // -- Behavior: context always trumps status --
    // If the user denied but we later obtained location (e.g. retry, or they toggled
    // in Settings and came back), showing the denied UI would be wrong.

    func test_resolveState_userDeniedButLocationObtained_showsSuccess() {
        // Real scenario: user denied, went to Settings, enabled, came back → context populated
        // If the guard is removed, they'd see "Permission Denied" despite having location.
        let context = makeContext(city: "London", country: "UK", countryCode: "GB")
        let result = OnboardingHelpers.resolveLocationPermissionState(
            locationContext: context,
            locationStatus: .denied
        )
        XCTAssertEqual(result, .contextDetected,
            "User who denied but later got location should see success, not denied UI")
    }

    func test_resolveState_restrictedButLocationObtained_showsSuccess() {
        // Edge case: device restriction was lifted, context arrived
        let context = makeContext(city: "Riyadh", country: "Saudi Arabia", countryCode: "SA")
        let result = OnboardingHelpers.resolveLocationPermissionState(
            locationContext: context,
            locationStatus: .restricted
        )
        XCTAssertEqual(result, .contextDetected)
    }

    // -- Behavior: denied ≠ restricted (different UI treatments) --
    // Denied → "Open Settings" button (user can fix it)
    // Restricted → no button (Screen Time/MDM, user can't fix it)

    func test_resolveState_deniedAndRestricted_areDistinctStates() {
        let denied = OnboardingHelpers.resolveLocationPermissionState(
            locationContext: nil, locationStatus: .denied
        )
        let restricted = OnboardingHelpers.resolveLocationPermissionState(
            locationContext: nil, locationStatus: .restricted
        )
        XCTAssertEqual(denied, .denied)
        XCTAssertEqual(restricted, .restricted)
        XCTAssertNotEqual(denied, restricted,
            "Denied must differ from restricted — denied shows 'Open Settings', restricted doesn't")
    }

    // -- Behavior: both authorized variants produce identical UX --
    // Users should never see different UI based on "when in use" vs "always"

    func test_resolveState_authorizedVariants_behaveSame() {
        let whenInUse = OnboardingHelpers.resolveLocationPermissionState(
            locationContext: nil, locationStatus: .authorizedWhenInUse
        )
        let always = OnboardingHelpers.resolveLocationPermissionState(
            locationContext: nil, locationStatus: .authorizedAlways
        )
        XCTAssertEqual(whenInUse, always,
            "Both authorized variants should show same loading/retry UI")
        XCTAssertEqual(whenInUse, .authorizedNoContext)
    }

    // -- Behavior: fresh install shows permission CTA --

    func test_resolveState_freshInstall_showsPermissionCTA() {
        let result = OnboardingHelpers.resolveLocationPermissionState(
            locationContext: nil, locationStatus: .notDetermined
        )
        XCTAssertEqual(result, .notDetermined,
            "Fresh install should show 'Enable Location' CTA, not denied/error UI")
    }

    // -- Behavior: denied without context must NOT show "Enable Location" --
    // iOS won't re-prompt after denial, so showing "Enable Location" is misleading.

    func test_resolveState_deniedWithoutContext_doesNotShowEnableCTA() {
        let result = OnboardingHelpers.resolveLocationPermissionState(
            locationContext: nil, locationStatus: .denied
        )
        XCTAssertNotEqual(result, .notDetermined,
            "Denied must not show 'Enable Location' — iOS won't re-prompt after denial")
        XCTAssertNotEqual(result, .authorizedNoContext,
            "Denied must not show retry/loading UI")
        XCTAssertEqual(result, .denied)
    }

    // MARK: - Test Helpers

    private func makeContext(
        city: String, country: String, countryCode: String
    ) -> LocationContext {
        LocationContext(
            coordinates: Coordinates(latitude: 51.5, longitude: -0.1),
            city: city, country: country, countryCode: countryCode,
            timezone: .current,
            recommendedMethod: .muslimWorldLeague,
            recommendedMadhab: .hanafi,
            recommendedLanguage: "English",
            regionName: "\(city), \(country)"
        )
    }

    // MARK: - shouldRequestNotificationAuth

    func test_shouldRequestNotificationAuth_allConditionsMet_returnsTrue() {
        XCTAssertTrue(OnboardingHelpers.shouldRequestNotificationAuth(
            currentPage: 2,
            notificationsEnabled: true,
            notificationAuthStatus: .notDetermined,
            isRequestingAuth: false
        ))
    }

    func test_shouldRequestNotificationAuth_alreadyDenied_returnsFalse() {
        XCTAssertFalse(OnboardingHelpers.shouldRequestNotificationAuth(
            currentPage: 2,
            notificationsEnabled: true,
            notificationAuthStatus: .denied,
            isRequestingAuth: false
        ), "iOS won't re-prompt after denial — requesting again is pointless")
    }

    func test_shouldRequestNotificationAuth_alreadyAuthorized_returnsFalse() {
        XCTAssertFalse(OnboardingHelpers.shouldRequestNotificationAuth(
            currentPage: 2,
            notificationsEnabled: true,
            notificationAuthStatus: .authorized,
            isRequestingAuth: false
        ), "Already authorized — no need to request again")
    }

    func test_shouldRequestNotificationAuth_inFlight_returnsFalse() {
        XCTAssertFalse(OnboardingHelpers.shouldRequestNotificationAuth(
            currentPage: 2,
            notificationsEnabled: true,
            notificationAuthStatus: .notDetermined,
            isRequestingAuth: true
        ), "Should not fire duplicate requests")
    }

    func test_shouldRequestNotificationAuth_wrongPage_returnsFalse() {
        XCTAssertFalse(OnboardingHelpers.shouldRequestNotificationAuth(
            currentPage: 0,
            notificationsEnabled: true,
            notificationAuthStatus: .notDetermined,
            isRequestingAuth: false
        ), "Should only prompt on the notification page (page 2)")
    }

    func test_shouldRequestNotificationAuth_toggleOff_returnsFalse() {
        XCTAssertFalse(OnboardingHelpers.shouldRequestNotificationAuth(
            currentPage: 2,
            notificationsEnabled: false,
            notificationAuthStatus: .notDetermined,
            isRequestingAuth: false
        ), "Should not prompt when user has opted out of notifications")
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
