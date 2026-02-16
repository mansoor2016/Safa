// MARK: - LanguageDisplayHelpers.swift
// PURPOSE: Pure helpers for formatting language codes into readable names
// DEPENDENCIES: Foundation

import Foundation

enum LanguageDisplayHelpers {
    /// Formats a BCP 47 language code (e.g. "en", "en-US", "ar") into a readable name.
    /// Tries `forIdentifier:` first (preserves region detail like "English (United States)"),
    /// then `forLanguageCode:` as fallback. Returns the code itself if neither resolves.
    static func displayName(forLanguageCode code: String, locale: Locale = .current) -> String {
        if let name = locale.localizedString(forIdentifier: code), !name.isEmpty {
            return name
        }
        return locale.localizedString(forLanguageCode: code) ?? code
    }

    /// Resolves the current app language code from the bundle.
    /// Treats "Base" as the development language (typically "en").
    static func currentAppLanguageCode(bundle: Bundle = .main) -> String {
        resolveLanguageCode(
            preferred: bundle.preferredLocalizations.first,
            developmentLanguage: bundle.developmentLocalization
        )
    }

    /// Pure logic for resolving a language code — testable without Bundle subclassing.
    static func resolveLanguageCode(preferred: String?, developmentLanguage: String?) -> String {
        let code = preferred ?? "en"
        if code.caseInsensitiveCompare("Base") == .orderedSame {
            return developmentLanguage ?? "en"
        }
        return code
    }
}
