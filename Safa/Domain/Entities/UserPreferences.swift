// MARK: - UserPreferences.swift
// PURPOSE: User preferences for prayer settings, notifications, appearance, and accessibility
// DEPENDENCIES: Foundation

import Foundation

// MARK: - User Preferences

struct UserPreferences: Codable, Hashable {
    // MARK: - Prayer Settings
    var calculationMethod: CalculationMethod
    var madhab: Madhab

    // MARK: - Language Settings
    var appLanguageCode: String?

    // MARK: - Content Settings
    var selectedTranslation: String
    var quranTranslation: QuranTranslation
    var showArabicText: Bool
    var showTransliteration: Bool

    // MARK: - Notification Settings
    var notificationsEnabled: Bool
    var notificationEnabledPrayers: [String]  // Prayer rawValues, e.g. ["fajr", "dhuhr", ...]

    // MARK: - Wudhu Reminder Settings
    var wudhuReminderEnabled: Bool
    var wudhuReminderMinutesBefore: Int

    // MARK: - Live Activity Settings
    var liveActivityEnabled: Bool

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

    // MARK: - Prayer Display Settings
    var showSunnahTimes: Bool

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
        appLanguageCode: String? = AppDefaults.appLanguageCode,
        selectedTranslation: String = AppDefaults.translationLanguage,
        quranTranslation: QuranTranslation = AppDefaults.quranTranslation,
        showArabicText: Bool = AppDefaults.showArabicText,
        showTransliteration: Bool = AppDefaults.showTransliteration,
        accentColorName: String = AppDefaults.accentColorName,
        savedLocationName: String? = nil,
        savedLatitude: Double? = nil,
        savedLongitude: Double? = nil,
        savedCountryCode: String? = nil,
        useLocationBasedDefaults: Bool = AppDefaults.useLocationBasedDefaults,
        autoUpdateLocationForPrayers: Bool = true,
        adhanEnabled: Bool = AppDefaults.adhanEnabled,
        selectedAdhan: String = AdhanSound.misharyAlafasy.rawValue,
        selectedFajrAdhan: String = AdhanSound.misharyAlafasyFajr.rawValue,
        smartAdhanEnabled: Bool = false,
        iftarAdhanEnabled: Bool = false,
        notificationEnabledPrayers: [String] = PrayerType.obligatoryPrayers.map { $0.rawValue },
        wudhuReminderEnabled: Bool = AppDefaults.wudhuReminderEnabled,
        wudhuReminderMinutesBefore: Int = AppDefaults.wudhuReminderMinutesBefore,
        liveActivityEnabled: Bool = AppDefaults.liveActivityEnabled,
        reduceMotionEnabled: Bool = false,
        largerArabicTextEnabled: Bool = false,
        highContrastEnabled: Bool = false,
        autoScrollEnabled: Bool = false,
        showSunnahTimes: Bool = false,
        prayerAdjustments: [String: Int] = [:]
    ) {
        self.calculationMethod = calculationMethod
        self.madhab = madhab
        self.notificationsEnabled = notificationsEnabled
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.appLanguageCode = appLanguageCode
        self.selectedTranslation = selectedTranslation
        self.quranTranslation = quranTranslation
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
        self.wudhuReminderEnabled = wudhuReminderEnabled
        self.wudhuReminderMinutesBefore = wudhuReminderMinutesBefore
        self.liveActivityEnabled = liveActivityEnabled
        self.reduceMotionEnabled = reduceMotionEnabled
        self.largerArabicTextEnabled = largerArabicTextEnabled
        self.highContrastEnabled = highContrastEnabled
        self.autoScrollEnabled = autoScrollEnabled
        self.showSunnahTimes = showSunnahTimes
        self.prayerAdjustments = prayerAdjustments
    }

    // MARK: - Codable (backward-compatible decoder for new fields)

    enum CodingKeys: String, CodingKey {
        case calculationMethod, madhab
        case appLanguageCode
        case selectedTranslation, quranTranslation, showArabicText, showTransliteration
        case notificationsEnabled, notificationEnabledPrayers
        case wudhuReminderEnabled, wudhuReminderMinutesBefore
        case liveActivityEnabled
        case adhanEnabled, selectedAdhan, selectedFajrAdhan, smartAdhanEnabled, iftarAdhanEnabled
        case accentColorName, hapticFeedbackEnabled
        case savedLocationName, savedLatitude, savedLongitude, savedCountryCode
        case useLocationBasedDefaults, autoUpdateLocationForPrayers
        case reduceMotionEnabled, largerArabicTextEnabled, highContrastEnabled
        case autoScrollEnabled, showSunnahTimes
        case prayerAdjustments
        case hasCompletedOnboarding
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        calculationMethod = try container.decode(CalculationMethod.self, forKey: .calculationMethod)
        madhab = try container.decode(Madhab.self, forKey: .madhab)
        let rawAppLanguage = try container.decodeIfPresent(String.self, forKey: .appLanguageCode)
        appLanguageCode = AppLanguageManager.sanitize(rawAppLanguage)
        selectedTranslation = try container.decode(String.self, forKey: .selectedTranslation)
        let rawQuranTranslation = try? container.decodeIfPresent(String.self, forKey: .quranTranslation)
        quranTranslation = rawQuranTranslation.flatMap { QuranTranslation(rawValue: $0) } ?? AppDefaults.quranTranslation
        showArabicText = try container.decode(Bool.self, forKey: .showArabicText)
        showTransliteration = try container.decode(Bool.self, forKey: .showTransliteration)
        notificationsEnabled = try container.decode(Bool.self, forKey: .notificationsEnabled)
        notificationEnabledPrayers = try container.decode([String].self, forKey: .notificationEnabledPrayers)
        wudhuReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .wudhuReminderEnabled) ?? AppDefaults.wudhuReminderEnabled
        let rawMinutes = try container.decodeIfPresent(Int.self, forKey: .wudhuReminderMinutesBefore) ?? AppDefaults.wudhuReminderMinutesBefore
        wudhuReminderMinutesBefore = [5, 10, 15, 20].contains(rawMinutes) ? rawMinutes : AppDefaults.wudhuReminderMinutesBefore
        liveActivityEnabled = try container.decodeIfPresent(Bool.self, forKey: .liveActivityEnabled) ?? AppDefaults.liveActivityEnabled
        adhanEnabled = try container.decode(Bool.self, forKey: .adhanEnabled)
        selectedAdhan = try container.decode(String.self, forKey: .selectedAdhan)
        selectedFajrAdhan = try container.decode(String.self, forKey: .selectedFajrAdhan)
        smartAdhanEnabled = try container.decode(Bool.self, forKey: .smartAdhanEnabled)
        iftarAdhanEnabled = try container.decode(Bool.self, forKey: .iftarAdhanEnabled)
        accentColorName = try container.decode(String.self, forKey: .accentColorName)
        hapticFeedbackEnabled = try container.decode(Bool.self, forKey: .hapticFeedbackEnabled)
        savedLocationName = try container.decodeIfPresent(String.self, forKey: .savedLocationName)
        savedLatitude = try container.decodeIfPresent(Double.self, forKey: .savedLatitude)
        savedLongitude = try container.decodeIfPresent(Double.self, forKey: .savedLongitude)
        savedCountryCode = try container.decodeIfPresent(String.self, forKey: .savedCountryCode)
        useLocationBasedDefaults = try container.decode(Bool.self, forKey: .useLocationBasedDefaults)
        autoUpdateLocationForPrayers = try container.decode(Bool.self, forKey: .autoUpdateLocationForPrayers)
        reduceMotionEnabled = try container.decode(Bool.self, forKey: .reduceMotionEnabled)
        largerArabicTextEnabled = try container.decode(Bool.self, forKey: .largerArabicTextEnabled)
        highContrastEnabled = try container.decode(Bool.self, forKey: .highContrastEnabled)
        autoScrollEnabled = try container.decode(Bool.self, forKey: .autoScrollEnabled)
        showSunnahTimes = try container.decodeIfPresent(Bool.self, forKey: .showSunnahTimes) ?? false
        prayerAdjustments = try container.decode([String: Int].self, forKey: .prayerAdjustments)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
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
