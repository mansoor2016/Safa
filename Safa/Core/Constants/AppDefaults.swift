// MARK: - AppDefaults.swift
// PURPOSE: Single source of truth for app-wide default values
// DEPENDENCIES: Foundation

import Foundation

/// Centralized default values for the app
/// Change these values here to update defaults across the entire app
enum AppDefaults {

    // MARK: - Prayer Settings

    /// Default calculation method when location is unknown
    static let calculationMethod: CalculationMethod = .makkah

    /// Default madhab for Asr calculation
    static let madhab: Madhab = .hanafi

    // MARK: - Language & Content

    /// Default translation language (region-inferred, used by recommendation sheet)
    static let translationLanguage: String = "English"

    /// Default Quran translation edition
    static let quranTranslation: QuranTranslation = .sahihInternational

    /// Show Arabic text by default
    static let showArabicText: Bool = true

    /// Show transliteration by default
    static let showTransliteration: Bool = false

    // MARK: - Notifications

    /// Enable notifications by default
    static let notificationsEnabled: Bool = true

    /// Adhan sound off by default (presented as opt-in during onboarding)
    static let adhanEnabled: Bool = false

    /// Wudhu reminder off by default (opt-in)
    static let wudhuReminderEnabled: Bool = false

    /// Default minutes before prayer for wudhu reminder
    static let wudhuReminderMinutesBefore: Int = 15

    // MARK: - Live Activity

    /// Enable Live Activity (lock screen countdown) by default
    static let liveActivityEnabled: Bool = true

    // MARK: - UI Preferences

    /// Enable haptic feedback by default
    static let hapticFeedbackEnabled: Bool = true

    /// Default accent color
    static let accentColorName: String = "Teal"

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
