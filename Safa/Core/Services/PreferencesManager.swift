// MARK: - PreferencesManager.swift
// PURPOSE: Centralized preferences management to eliminate duplicate save patterns
// DEPENDENCIES: Foundation

import Foundation

/// Centralized manager for user preferences with type-safe updates
@Observable
final class PreferencesManager {

    // MARK: - Singleton

    static let shared = PreferencesManager()

    // MARK: - Dependencies

    private var userRepository: UserRepositoryProtocol?

    // MARK: - Init

    private init() {}

    /// Configure with dependencies (call from Dependencies.swift)
    func configure(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    // MARK: - Generic Update Method

    /// Update a single preference using KeyPath
    func update<T>(_ keyPath: WritableKeyPath<UserPreferences, T>, to value: T) async {
        guard let repo = userRepository else { return }
        var prefs = await repo.getPreferences()
        prefs[keyPath: keyPath] = value
        try? await repo.updatePreferences(prefs)
    }

    /// Update multiple preferences at once
    func update(_ updates: (inout UserPreferences) -> Void) async {
        guard let repo = userRepository else { return }
        var prefs = await repo.getPreferences()
        updates(&prefs)
        try? await repo.updatePreferences(prefs)
    }

    // MARK: - Convenience Methods for Common Updates

    /// Save calculation method
    func saveCalculationMethod(_ method: CalculationMethod) async {
        await update(\.calculationMethod, to: method)
    }

    /// Save madhab preference
    func saveMadhab(_ madhab: Madhab) async {
        await update(\.madhab, to: madhab)
    }

    /// Save notification setting
    func saveNotificationsEnabled(_ enabled: Bool) async {
        await update(\.notificationsEnabled, to: enabled)
    }

    /// Save haptic feedback setting
    func saveHapticFeedback(_ enabled: Bool) async {
        await update(\.hapticFeedbackEnabled, to: enabled)
    }

    /// Save translation language
    func saveTranslation(_ language: String) async {
        await update(\.selectedTranslation, to: language)
    }

    /// Save location settings
    func saveLocation(name: String, latitude: Double, longitude: Double, countryCode: String?) async {
        await update { prefs in
            prefs.savedLocationName = name
            prefs.savedLatitude = latitude
            prefs.savedLongitude = longitude
            prefs.savedCountryCode = countryCode
        }
    }

    /// Save all location-based settings at once
    func saveLocationSettings(method: CalculationMethod, madhab: Madhab, language: String) async {
        await update { prefs in
            prefs.calculationMethod = method
            prefs.madhab = madhab
            prefs.selectedTranslation = language
        }
    }

    /// Save accessibility settings
    func saveAccessibility(reduceMotion: Bool? = nil, largerText: Bool? = nil, highContrast: Bool? = nil) async {
        await update { prefs in
            if let reduceMotion = reduceMotion {
                prefs.reduceMotionEnabled = reduceMotion
            }
            if let largerText = largerText {
                prefs.largerArabicTextEnabled = largerText
            }
            if let highContrast = highContrast {
                prefs.highContrastEnabled = highContrast
            }
        }
    }

    /// Save Quran display settings
    func saveQuranSettings(showArabic: Bool? = nil, showTransliteration: Bool? = nil) async {
        await update { prefs in
            if let showArabic = showArabic {
                prefs.showArabicText = showArabic
            }
            if let showTransliteration = showTransliteration {
                prefs.showTransliteration = showTransliteration
            }
        }
    }

    // MARK: - Load Preferences

    /// Get current preferences
    func getPreferences() async -> UserPreferences {
        guard let repo = userRepository else {
            return UserPreferences()
        }
        return await repo.getPreferences()
    }
}
