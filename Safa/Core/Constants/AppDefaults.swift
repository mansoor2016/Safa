// MARK: - AppDefaults.swift
// PURPOSE: Single source of truth for app-wide default values
// DEPENDENCIES: Foundation

import Foundation

/// Centralized default values for the app
/// Change these values here to update defaults across the entire app
enum AppDefaults {

    // MARK: - Prayer Settings

    /// Default calculation method when location is unknown
    static let calculationMethod: CalculationMethod = .muslimWorldLeague

    /// Default madhab for Asr calculation
    static let madhab: Madhab = .hanafi

    // MARK: - Language & Content

    /// Default translation language
    static let translationLanguage: String = "English"

    /// Show Arabic text by default
    static let showArabicText: Bool = true

    /// Show transliteration by default
    static let showTransliteration: Bool = false

    // MARK: - Notifications

    /// Enable notifications by default
    static let notificationsEnabled: Bool = true

    // MARK: - UI Preferences

    /// Enable haptic feedback by default
    static let hapticFeedbackEnabled: Bool = true

    /// Default accent color
    static let accentColorName: String = "Teal"

    // MARK: - CloudKit & iCloud Sync
    // Requires a paid Apple Developer account ($99/year).
    // When false: Core Data works locally, no cross-device sync. All features work normally.
    // When true: Enables NSPersistentCloudKitContainer for iCloud sync.
    // To enable: set to true AND ensure CloudKit entitlements are configured in Xcode.
    static let useCloudKit: Bool = false

    // MARK: - Location

    /// Use location-based recommendations by default
    static let useLocationBasedDefaults: Bool = true

    /// Default location: London, UK
    static let defaultLatitude: Double = 51.5074
    static let defaultLongitude: Double = -0.1278
    static let defaultLocationName: String = "London, UK"

    /// Default coordinates when location is unavailable
    static var defaultCoordinates: Coordinates {
        Coordinates(latitude: defaultLatitude, longitude: defaultLongitude)
    }
}
