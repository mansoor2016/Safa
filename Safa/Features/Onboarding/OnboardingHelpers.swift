// MARK: - OnboardingHelpers.swift
// PURPOSE: Testable pure-function helpers for onboarding preference logic
// DEPENDENCIES: Foundation, UserPreferences, LocationContext, AppDefaults

import Foundation
import CoreLocation
import UserNotifications

/// Resolved permission state for the onboarding location page.
/// Drives the UI: each case maps to a distinct visual treatment.
enum LocationPermissionState: Equatable {
    /// Location detected — green checkmark + region name.
    case contextDetected
    /// Permission not yet requested — show "Enable Location" CTA.
    case notDetermined
    /// User denied location — warning + prominent "Open Settings" + fallback notice.
    case denied
    /// Parental/MDM restriction — warning + fallback notice (no Settings button).
    case restricted
    /// Authorized but no context yet — error/retry or loading spinner.
    case authorizedNoContext
}

enum OnboardingHelpers {

    /// Resolves the current location permission state for UI display.
    /// `locationContext != nil` always wins (even if status is `.denied`).
    static func resolveLocationPermissionState(
        locationContext: LocationContext?,
        locationStatus: CLAuthorizationStatus
    ) -> LocationPermissionState {
        if locationContext != nil { return .contextDetected }
        switch locationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .restricted: return .restricted
        default: return .authorizedNoContext
        }
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

    /// Whether the system notification authorization prompt should be triggered.
    /// Returns `true` only when ALL conditions are met:
    /// - On the notification page (page 2)
    /// - Notifications toggle is ON
    /// - Auth status is `.notDetermined` (iOS won't re-prompt after grant/deny)
    /// - No request already in flight
    static func shouldRequestNotificationAuth(
        currentPage: Int,
        notificationsEnabled: Bool,
        notificationAuthStatus: UNAuthorizationStatus,
        isRequestingAuth: Bool
    ) -> Bool {
        currentPage == 2
            && notificationsEnabled
            && notificationAuthStatus == .notDetermined
            && !isRequestingAuth
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
