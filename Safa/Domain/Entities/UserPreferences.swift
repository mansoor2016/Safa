// MARK: - UserPreferences.swift
// PURPOSE: User preferences for prayer settings, notifications, appearance, and accessibility
// DEPENDENCIES: Foundation

import Foundation

// MARK: - User Preferences

struct UserPreferences: Codable, Hashable {
    // MARK: - Prayer Settings
    var calculationMethod: CalculationMethod
    var madhab: Madhab

    // MARK: - Content Settings
    var selectedTranslation: String
    var showArabicText: Bool
    var showTransliteration: Bool

    // MARK: - Notification Settings
    var notificationsEnabled: Bool
    var notificationEnabledPrayers: [String]  // Prayer rawValues, e.g. ["fajr", "dhuhr", ...]

    // MARK: - Adhan Settings
    var adhanEnabled: Bool
    var selectedAdhan: String
    var selectedFajrAdhan: String
    var smartAdhanEnabled: Bool
    var iftarAdhanEnabled: Bool  // Play adhan for Maghrib during Ramadan even if adhanEnabled is off

    // MARK: - Appearance Settings
    var accentColorName: String
    var hapticFeedbackEnabled: Bool

    // MARK: - Location Settings
    var savedLocationName: String?
    var savedLatitude: Double?
    var savedLongitude: Double?
    var savedCountryCode: String?
    var useLocationBasedDefaults: Bool
    var autoUpdateLocationForPrayers: Bool

    // MARK: - Accessibility Settings
    var reduceMotionEnabled: Bool
    var largerArabicTextEnabled: Bool
    var highContrastEnabled: Bool

    // MARK: - Quran Reader Settings
    var autoScrollEnabled: Bool

    // MARK: - Prayer Time Adjustments (minutes offset per prayer)
    var prayerAdjustments: [String: Int]

    // MARK: - App State
    var hasCompletedOnboarding: Bool

    // MARK: - Init

    init(
        calculationMethod: CalculationMethod = AppDefaults.calculationMethod,
        madhab: Madhab = AppDefaults.madhab,
        notificationsEnabled: Bool = AppDefaults.notificationsEnabled,
        hapticFeedbackEnabled: Bool = AppDefaults.hapticFeedbackEnabled,
        hasCompletedOnboarding: Bool = false,
        selectedTranslation: String = AppDefaults.translationLanguage,
        showArabicText: Bool = AppDefaults.showArabicText,
        showTransliteration: Bool = AppDefaults.showTransliteration,
        accentColorName: String = AppDefaults.accentColorName,
        savedLocationName: String? = nil,
        savedLatitude: Double? = nil,
        savedLongitude: Double? = nil,
        savedCountryCode: String? = nil,
        useLocationBasedDefaults: Bool = AppDefaults.useLocationBasedDefaults,
        autoUpdateLocationForPrayers: Bool = true,
        adhanEnabled: Bool = false,
        selectedAdhan: String = AdhanSound.misharyAlafasy.rawValue,
        selectedFajrAdhan: String = AdhanSound.misharyAlafasyFajr.rawValue,
        smartAdhanEnabled: Bool = false,
        iftarAdhanEnabled: Bool = false,
        notificationEnabledPrayers: [String] = PrayerType.obligatoryPrayers.map { $0.rawValue },
        reduceMotionEnabled: Bool = false,
        largerArabicTextEnabled: Bool = false,
        highContrastEnabled: Bool = false,
        autoScrollEnabled: Bool = false,
        prayerAdjustments: [String: Int] = [:]
    ) {
        self.calculationMethod = calculationMethod
        self.madhab = madhab
        self.notificationsEnabled = notificationsEnabled
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.selectedTranslation = selectedTranslation
        self.showArabicText = showArabicText
        self.showTransliteration = showTransliteration
        self.accentColorName = accentColorName
        self.savedLocationName = savedLocationName
        self.savedLatitude = savedLatitude
        self.savedLongitude = savedLongitude
        self.savedCountryCode = savedCountryCode
        self.useLocationBasedDefaults = useLocationBasedDefaults
        self.autoUpdateLocationForPrayers = autoUpdateLocationForPrayers
        self.adhanEnabled = adhanEnabled
        self.selectedAdhan = selectedAdhan
        self.selectedFajrAdhan = selectedFajrAdhan
        self.smartAdhanEnabled = smartAdhanEnabled
        self.iftarAdhanEnabled = iftarAdhanEnabled
        self.notificationEnabledPrayers = notificationEnabledPrayers
        self.reduceMotionEnabled = reduceMotionEnabled
        self.largerArabicTextEnabled = largerArabicTextEnabled
        self.highContrastEnabled = highContrastEnabled
        self.autoScrollEnabled = autoScrollEnabled
        self.prayerAdjustments = prayerAdjustments
    }

    // MARK: - Prayer Adjustment Helpers

    /// Get the minute offset for a specific prayer type (0 if none set)
    func adjustment(for prayer: PrayerType) -> Int {
        prayerAdjustments[prayer.rawValue] ?? 0
    }

    /// Set the minute offset for a specific prayer type
    mutating func setAdjustment(_ minutes: Int, for prayer: PrayerType) {
        if minutes == 0 {
            prayerAdjustments.removeValue(forKey: prayer.rawValue)
        } else {
            prayerAdjustments[prayer.rawValue] = minutes
        }
    }

    // MARK: - Location Helpers

    /// Apply location context to preferences
    mutating func applyLocationDefaults(from context: LocationContext) {
        calculationMethod = context.recommendedMethod
        madhab = context.recommendedMadhab
        selectedTranslation = context.recommendedLanguage
        savedLocationName = context.regionName
        savedLatitude = context.coordinates.latitude
        savedLongitude = context.coordinates.longitude
        savedCountryCode = context.countryCode
    }

    /// Check if saved location exists
    var hasSavedLocation: Bool {
        savedLatitude != nil && savedLongitude != nil
    }

    /// Get saved coordinates if available
    var savedCoordinates: Coordinates? {
        guard let lat = savedLatitude, let lng = savedLongitude else { return nil }
        return Coordinates(latitude: lat, longitude: lng)
    }
}
