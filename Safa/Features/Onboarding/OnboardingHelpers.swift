// MARK: - OnboardingHelpers.swift
// PURPOSE: Testable pure-function helpers for onboarding preference logic
// DEPENDENCIES: Foundation, UserPreferences, LocationContext, AppDefaults

import Foundation
import CoreLocation

enum OnboardingHelpers {

    /// Whether the "Open Settings" link should appear on the location page.
    /// True when location access was denied/restricted and an error message is showing.
    static func shouldShowSettingsLink(
        locationStatus: CLAuthorizationStatus
    ) -> Bool {
        locationStatus == .denied || locationStatus == .restricted
    }

    /// Whether forward navigation from `from` to `to` is allowed.
    /// Used by both the swipe guard and the footer Next button.
    static func shouldAllowForwardNavigation(
        from page: Int,
        to target: Int,
        locationPermissionResolved: Bool
    ) -> Bool {
        // Block forward past page 1 (location) when location unresolved
        if page == 1 && target > 1 && !locationPermissionResolved { return false }
        return true
    }

    /// Builds the preferences to save when the user taps "Skip" on onboarding.
    /// If location was already detected, inferred values are preserved; otherwise AppDefaults are used.
    static func buildSkipPreferences(
        current: UserPreferences,
        locationContext: LocationContext?
    ) -> UserPreferences {
        var prefs = current

        if let context = locationContext {
            prefs.applyLocationDefaults(from: context)
            prefs.useLocationBasedDefaults = true
        } else {
            prefs.calculationMethod = AppDefaults.calculationMethod
            prefs.madhab = AppDefaults.madhab
            prefs.selectedTranslation = AppDefaults.translationLanguage
        }

        prefs.notificationsEnabled = AppDefaults.notificationsEnabled
        prefs.hasCompletedOnboarding = true
        return prefs
    }
}
