// MARK: - Typography.swift
// PURPOSE: Design system typography styles for the Safa app
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Typography

enum SafaTypography {
    // MARK: - Display Styles
    static let displayLarge = Font.system(size: 57, weight: .regular, design: .rounded)
    static let displayMedium = Font.system(size: 45, weight: .regular, design: .rounded)
    static let displaySmall = Font.system(size: 36, weight: .regular, design: .rounded)

    // MARK: - Headline Styles
    static let headlineLarge = Font.system(size: 32, weight: .semibold, design: .rounded)
    static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .rounded)

    // MARK: - Title Styles
    static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)
    static let titleMedium = Font.system(size: 16, weight: .semibold, design: .default)
    static let titleSmall = Font.system(size: 14, weight: .semibold, design: .default)

    // MARK: - Body Styles
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: - Label Styles
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Arabic Text Styles
    static let arabicLarge = Font.custom("AmiriQuran", size: 32)
    static let arabicMedium = Font.custom("AmiriQuran", size: 24)
    static let arabicSmall = Font.custom("AmiriQuran", size: 18)

    // MARK: - Arabic Fallback (System Arabic)
    static let arabicLargeFallback = Font.system(size: 32, weight: .regular, design: .serif)
    static let arabicMediumFallback = Font.system(size: 24, weight: .regular, design: .serif)
    static let arabicSmallFallback = Font.system(size: 18, weight: .regular, design: .serif)

    // MARK: - Counter Display
    static let counterLarge = Font.system(size: 72, weight: .bold, design: .rounded)
    static let counterMedium = Font.system(size: 48, weight: .bold, design: .rounded)
    static let counterSmall = Font.system(size: 36, weight: .bold, design: .rounded)
}

// MARK: - Text Style Modifier

struct SafaTextStyle: ViewModifier {
    let font: Font
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
    }
}

extension View {
    func safaTextStyle(_ font: Font, color: Color = SafaColors.Fallback.text) -> some View {
        modifier(SafaTextStyle(font: font, color: color))
    }
}

// MARK: - Arabic Text Modifier

struct ArabicTextStyle: ViewModifier {
    let size: ArabicTextSize

    enum ArabicTextSize {
        case large
        case medium
        case small
    }

    func body(content: Content) -> some View {
        content
            .font(arabicFont)
            .environment(\.layoutDirection, .rightToLeft)
            .multilineTextAlignment(.trailing)
    }

    private var arabicFont: Font {
        switch size {
        case .large: return SafaTypography.arabicLargeFallback
        case .medium: return SafaTypography.arabicMediumFallback
        case .small: return SafaTypography.arabicSmallFallback
        }
    }
}

extension View {
    func arabicStyle(_ size: ArabicTextStyle.ArabicTextSize = .medium) -> some View {
        modifier(ArabicTextStyle(size: size))
    }
}
