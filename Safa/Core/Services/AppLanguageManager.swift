// MARK: - AppLanguageManager.swift
// PURPOSE: Reactive language source for the app — stores override, exposes current locale
// DEPENDENCIES: Foundation, SupportedAppLanguage, PreferencesManager, LanguageDisplayHelpers

import Foundation

@Observable
final class AppLanguageManager {
    static let shared = AppLanguageManager()

    /// Current effective locale. When override is nil, returns .current (iOS-resolved).
    /// When override is set, returns Locale for that code.
    private(set) var currentLocale: Locale

    /// The stored override code, or nil for device default
    private(set) var appLanguageCode: String?

    private init() {
        let prefs = PreferencesManager.loadPreferencesSync()
        let code = Self.sanitize(prefs.appLanguageCode)
        self.appLanguageCode = code
        self.currentLocale = code.map { Locale(identifier: $0) } ?? .current
    }

    func setLanguage(_ code: String?) {
        let sanitized = Self.sanitize(code)
        appLanguageCode = sanitized
        currentLocale = sanitized.map { Locale(identifier: $0) } ?? .current

        if let sanitized {
            UserDefaults.standard.set([sanitized, "en"], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }

    /// Sanitize: nil if code not in supported set
    static func sanitize(_ code: String?) -> String? {
        guard let code, SupportedAppLanguage(rawValue: code) != nil else { return nil }
        return code
    }

    /// Display name for "Device Default" row — uses the true device language,
    /// ignoring any in-app AppleLanguages override we may have set.
    static var deviceLanguageDisplayName: String {
        let code = deviceLanguageCode
        return LanguageDisplayHelpers.displayName(forLanguageCode: code)
    }

    /// The device's actual language code, ignoring in-app AppleLanguages override.
    /// Reads the system language from Locale.preferredLanguages, then checks if
    /// we injected an override — if so, returns the second entry (the real device language)
    /// or falls back to Locale.current.
    static var deviceLanguageCode: String {
        let preferred = Locale.preferredLanguages
        let override = UserDefaults.standard.stringArray(forKey: "AppleLanguages")

        // If we set AppleLanguages, the first entry in preferredLanguages is our override.
        // The real device language follows it (iOS appends device languages after the override).
        if let override, !override.isEmpty,
           preferred.count > override.count {
            let deviceCode = preferred[override.count]
            return Locale(identifier: deviceCode).language.languageCode?.identifier ?? "en"
        }

        // No override set — first preferred language is the device language
        if let first = preferred.first {
            return Locale(identifier: first).language.languageCode?.identifier ?? "en"
        }

        return "en"
    }
}
