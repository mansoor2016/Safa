// MARK: - SupportedAppLanguage.swift
// PURPOSE: Enum of languages Safa ships translations for (app UI language)
// DEPENDENCIES: Foundation

import Foundation

enum SupportedAppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case arabic = "ar"
    case indonesian = "id"
    case urdu = "ur"
    case bengali = "bn"
    case french = "fr"
    case malay = "ms"
    case turkish = "tr"
    case persian = "fa"

    var id: String { rawValue }

    /// English name (e.g. "Arabic")
    var displayName: String {
        switch self {
        case .english: return "English"
        case .arabic: return "Arabic"
        case .indonesian: return "Indonesian"
        case .urdu: return "Urdu"
        case .bengali: return "Bengali"
        case .french: return "French"
        case .malay: return "Malay"
        case .turkish: return "Turkish"
        case .persian: return "Persian"
        }
    }

    /// Native script name (e.g. "العربية")
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .arabic: return "العربية"
        case .indonesian: return "Bahasa Indonesia"
        case .urdu: return "اردو"
        case .bengali: return "বাংলা"
        case .french: return "Français"
        case .malay: return "Bahasa Melayu"
        case .turkish: return "Türkçe"
        case .persian: return "فارسی"
        }
    }
}
