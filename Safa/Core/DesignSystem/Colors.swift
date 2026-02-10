// MARK: - Colors.swift
// PURPOSE: Design system color palette for the Safa app
// DEPENDENCIES: SwiftUI

import SwiftUI
import UIKit

// MARK: - Color Palette

enum SafaColors {
    // MARK: - Primary Colors
    static let primary = Color("SafaPrimary", bundle: .main)
    static let primaryLight = Color("SafaPrimaryLight", bundle: .main)
    static let primaryDark = Color("SafaPrimaryDark", bundle: .main)

    // MARK: - Accent Colors (User Configurable)
    static let accent = Color.accentColor

    // MARK: - Semantic Colors
    static let background = Color("Background", bundle: .main)
    static let secondaryBackground = Color("SecondaryBackground", bundle: .main)
    static let tertiaryBackground = Color("TertiaryBackground", bundle: .main)

    static let text = Color("Text", bundle: .main)
    static let secondaryText = Color("SecondaryText", bundle: .main)
    static let tertiaryText = Color("TertiaryText", bundle: .main)

    // MARK: - Status Colors
    static let success = Color("Success", bundle: .main)
    static let warning = Color("Warning", bundle: .main)
    static let error = Color("Error", bundle: .main)
    static let info = Color("Info", bundle: .main)

    // MARK: - Prayer Colors
    static let fajr = Color("Fajr", bundle: .main)
    static let sunrise = Color("Sunrise", bundle: .main)
    static let dhuhr = Color("Dhuhr", bundle: .main)
    static let asr = Color("Asr", bundle: .main)
    static let maghrib = Color("Maghrib", bundle: .main)
    static let isha = Color("Isha", bundle: .main)

    // MARK: - Fallback Colors (Used if asset not found)
    enum Fallback {
        static let primary = Color(hex: "2E7D32")
        static let primaryLight = Color(hex: "60AD5E")
        static let primaryDark = Color(hex: "005005")

        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)

        static let text = Color(UIColor.label)
        static let secondaryText = Color(UIColor.secondaryLabel)
        static let tertiaryText = Color(UIColor.tertiaryLabel)

        static let success = Color(hex: "4CAF50")
        static let warning = Color(hex: "FF9800")
        static let error = Color(hex: "F44336")
        static let info = Color(hex: "2196F3")

        static let fajr = Color(hex: "1A237E")
        static let sunrise = Color(hex: "FF8F00")
        static let dhuhr = Color(hex: "FDD835")
        static let asr = Color(hex: "FB8C00")
        static let maghrib = Color(hex: "E65100")
        static let isha = Color(hex: "311B92")
    }
}

// MARK: - Accent Color Options

enum AccentColorOption: String, CaseIterable, Identifiable {
    case green = "Green"
    case teal = "Teal"
    case blue = "Blue"
    case purple = "Purple"
    case gold = "Gold"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .green:
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.40, green: 0.73, blue: 0.42, alpha: 1) // #66BB6A
                : UIColor(red: 0.18, green: 0.49, blue: 0.20, alpha: 1) // #2E7D32
            })
        case .teal:
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.30, green: 0.71, blue: 0.67, alpha: 1) // #4DB6AC
                : UIColor(red: 0.00, green: 0.41, blue: 0.36, alpha: 1) // #00695C
            })
        case .blue:
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.26, green: 0.65, blue: 0.96, alpha: 1) // #42A5F5
                : UIColor(red: 0.08, green: 0.40, blue: 0.75, alpha: 1) // #1565C0
            })
        case .purple:
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.67, green: 0.28, blue: 0.74, alpha: 1) // #AB47BC
                : UIColor(red: 0.42, green: 0.11, blue: 0.60, alpha: 1) // #6A1B9A
            })
        case .gold:
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 1.00, green: 0.93, blue: 0.35, alpha: 1) // #FFEE58
                : UIColor(red: 0.98, green: 0.66, blue: 0.15, alpha: 1) // #F9A825
            })
        }
    }

    var displayName: String { rawValue }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Prayer Type Color Extension

extension PrayerType {
    var color: Color {
        switch self {
        case .fajr: return SafaColors.fajr
        case .sunrise: return SafaColors.sunrise
        case .dhuhr: return SafaColors.dhuhr
        case .asr: return SafaColors.asr
        case .maghrib: return SafaColors.maghrib
        case .isha: return SafaColors.isha
        }
    }
}
