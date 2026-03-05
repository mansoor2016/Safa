// MARK: - QuranTranslation.swift
// PURPOSE: Available Quran translation editions for the reader
// DEPENDENCIES: Foundation

import Foundation

enum QuranTranslation: String, CaseIterable, Codable, Hashable, Identifiable {
    case sahihInternational = "sahih_international"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sahihInternational: return "Sahih International"
        }
    }

    var localizedDisplayName: String {
        String(localized: String.LocalizationValue(displayName))
    }

    var language: String {
        switch self {
        case .sahihInternational: return "English"
        }
    }

    var fullDisplayName: String {
        "\(displayName) (\(language))"
    }
}
