// MARK: - Theme.swift
// PURPOSE: Theme manager for the Safa app
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Theme Manager

@Observable
final class ThemeManager {
    // MARK: - Properties
    var colorScheme: ColorScheme?
    var accentColor: AccentColorOption

    // MARK: - Storage Keys
    private let colorSchemeKey = AppConstants.StorageKeys.themeColorScheme
    private let accentColorKey = AppConstants.StorageKeys.themeAccentColor

    // MARK: - Init
    init() {
        // Load saved preferences
        if let savedScheme = UserDefaults.standard.string(forKey: colorSchemeKey) {
            colorScheme = savedScheme == "light" ? .light : savedScheme == "dark" ? .dark : nil
        } else {
            colorScheme = nil // System default
        }

        if let savedAccent = UserDefaults.standard.string(forKey: accentColorKey),
           let accent = AccentColorOption(rawValue: savedAccent) {
            accentColor = accent
        } else {
            accentColor = .green // Default
        }
    }

    // MARK: - Methods

    func setColorScheme(_ scheme: ColorScheme?) {
        colorScheme = scheme
        if let scheme = scheme {
            UserDefaults.standard.set(scheme == .light ? "light" : "dark", forKey: colorSchemeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: colorSchemeKey)
        }
    }

    func setAccentColor(_ color: AccentColorOption) {
        accentColor = color
        UserDefaults.standard.set(color.rawValue, forKey: accentColorKey)
    }
}

// MARK: - Theme Modifier

struct SafaTheme: ViewModifier {
    let themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
            .tint(themeManager.accentColor.color)
    }
}

extension View {
    func safaTheme(_ themeManager: ThemeManager) -> some View {
        modifier(SafaTheme(themeManager: themeManager))
    }
}

// MARK: - Appearance Option

enum AppearanceOption: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}
