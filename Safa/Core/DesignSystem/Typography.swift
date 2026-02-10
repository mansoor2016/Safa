// MARK: - Typography.swift
// PURPOSE: Design system typography styles for the Safa app
// DEPENDENCIES: SwiftUI

import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Font Configuration
// ============================================================================
// SINGLE SOURCE OF TRUTH FOR ALL FONTS
// Change these values to update fonts throughout the entire app
// ============================================================================

enum FontConfig {
    // MARK: - Quranic Arabic (Uthmanic Script)
    // Used for: Quran text, Ayahs
    // Options: "KFGQPCUthmanicScriptHAFS", "AmiriQuran", "Scheherazade"
    static let quranFontName: String? = nil  // nil = use system Arabic

    // MARK: - General Arabic
    // Used for: Duas, Dhikr, Hadith Arabic text, UI labels
    // Options: "NotoNaskhArabic", "Amiri", nil (system SF Arabic)
    static let arabicFontName: String? = nil  // nil = use system Arabic

    // MARK: - English UI
    // Used for: Navigation, buttons, labels
    // Options: "Inter", "Nunito", nil (system SF Pro)
    static let englishUIFontName: String? = nil  // nil = use system SF Pro

    // MARK: - English Reading
    // Used for: Translations, long-form content
    // Options: "Lora", "SourceSerifPro", nil (system SF Pro Text)
    static let englishReadingFontName: String? = nil  // nil = use system

    // MARK: - Font Design Styles
    static let displayDesign: Font.Design = .rounded
    static let headlineDesign: Font.Design = .rounded
    static let bodyDesign: Font.Design = .default
    static let counterDesign: Font.Design = .rounded
}

// MARK: - Typography Styles

enum SafaTypography {
    // MARK: - Display Styles (Large headers, prayer times)
    static var displayLarge: Font { makeFont(size: 57, weight: .regular, design: FontConfig.displayDesign, relativeTo: .largeTitle) }
    static var displayMedium: Font { makeFont(size: 45, weight: .regular, design: FontConfig.displayDesign, relativeTo: .largeTitle) }
    static var displaySmall: Font { makeFont(size: 36, weight: .regular, design: FontConfig.displayDesign, relativeTo: .largeTitle) }

    // MARK: - Headline Styles (Section headers)
    static var headlineLarge: Font { makeFont(size: 32, weight: .semibold, design: FontConfig.headlineDesign, relativeTo: .title1) }
    static var headlineMedium: Font { makeFont(size: 28, weight: .semibold, design: FontConfig.headlineDesign, relativeTo: .title2) }
    static var headlineSmall: Font { makeFont(size: 24, weight: .semibold, design: FontConfig.headlineDesign, relativeTo: .title3) }

    // MARK: - Title Styles (Card titles, list headers)
    static var titleLarge: Font { makeFont(size: 22, weight: .semibold, design: FontConfig.bodyDesign, relativeTo: .headline) }
    static var titleMedium: Font { makeFont(size: 16, weight: .semibold, design: FontConfig.bodyDesign, relativeTo: .headline) }
    static var titleSmall: Font { makeFont(size: 14, weight: .semibold, design: FontConfig.bodyDesign, relativeTo: .subheadline) }

    // MARK: - Body Styles (General text)
    static var bodyLarge: Font { makeFont(size: 16, weight: .regular, design: FontConfig.bodyDesign, relativeTo: .body) }
    static var bodyMedium: Font { makeFont(size: 14, weight: .regular, design: FontConfig.bodyDesign, relativeTo: .callout) }
    static var bodySmall: Font { makeFont(size: 12, weight: .regular, design: FontConfig.bodyDesign, relativeTo: .footnote) }

    // MARK: - Label Styles (Buttons, captions)
    static var labelLarge: Font { makeFont(size: 14, weight: .medium, design: FontConfig.bodyDesign, relativeTo: .callout) }
    static var labelMedium: Font { makeFont(size: 12, weight: .medium, design: FontConfig.bodyDesign, relativeTo: .footnote) }
    static var labelSmall: Font { makeFont(size: 11, weight: .medium, design: FontConfig.bodyDesign, relativeTo: .caption1) }

    // MARK: - Quran Arabic Styles (Uthmanic script)
    static var quranLarge: Font { makeArabicFont(size: 36, forQuran: true, relativeTo: .title1) }
    static var quranMedium: Font { makeArabicFont(size: 28, forQuran: true, relativeTo: .title2) }
    static var quranSmall: Font { makeArabicFont(size: 22, forQuran: true, relativeTo: .title3) }

    // MARK: - General Arabic Styles (Duas, Hadith, UI)
    static var arabicLarge: Font { makeArabicFont(size: 32, forQuran: false, relativeTo: .title1) }
    static var arabicMedium: Font { makeArabicFont(size: 24, forQuran: false, relativeTo: .title3) }
    static var arabicSmall: Font { makeArabicFont(size: 18, forQuran: false, relativeTo: .headline) }

    // MARK: - Counter Display (Tasbeeh, streaks)
    static var counterLarge: Font { makeFont(size: 72, weight: .bold, design: FontConfig.counterDesign, relativeTo: .largeTitle) }
    static var counterMedium: Font { makeFont(size: 48, weight: .bold, design: FontConfig.counterDesign, relativeTo: .largeTitle) }
    static var counterSmall: Font { makeFont(size: 36, weight: .bold, design: FontConfig.counterDesign, relativeTo: .largeTitle) }

    // MARK: - Reading Styles (Translations, long content)
    static var readingLarge: Font { makeReadingFont(size: 18, relativeTo: .body) }
    static var readingMedium: Font { makeReadingFont(size: 16, relativeTo: .callout) }
    static var readingSmall: Font { makeReadingFont(size: 14, relativeTo: .footnote) }

    // MARK: - Font Builders

    private static func makeFont(size: CGFloat, weight: Font.Weight, design: Font.Design, relativeTo textStyle: UIFont.TextStyle = .body) -> Font {
        if let fontName = FontConfig.englishUIFontName {
            return Font.custom(fontName, size: size, relativeTo: mapTextStyle(textStyle))
                .weight(weight)
        }
        let uiWeight = weightMapping[weight] ?? .regular
        var uiFont = UIFont.systemFont(ofSize: size, weight: uiWeight)
        if let descriptor = uiFont.fontDescriptor.withDesign(designMapping[design] ?? .default) {
            uiFont = UIFont(descriptor: descriptor, size: size)
        }
        return Font(UIFontMetrics(forTextStyle: textStyle).scaledFont(for: uiFont))
    }

    private static func makeArabicFont(size: CGFloat, forQuran: Bool, relativeTo textStyle: UIFont.TextStyle = .body) -> Font {
        if let name = (forQuran ? FontConfig.quranFontName : FontConfig.arabicFontName) {
            return Font.custom(name, size: size, relativeTo: mapTextStyle(textStyle))
        }
        // System Arabic with serif design for elegance
        var uiFont = UIFont.systemFont(ofSize: size, weight: .regular)
        if let descriptor = uiFont.fontDescriptor.withDesign(.serif) {
            uiFont = UIFont(descriptor: descriptor, size: size)
        }
        return Font(UIFontMetrics(forTextStyle: textStyle).scaledFont(for: uiFont))
    }

    private static func makeReadingFont(size: CGFloat, relativeTo textStyle: UIFont.TextStyle = .body) -> Font {
        if let fontName = FontConfig.englishReadingFontName {
            return Font.custom(fontName, size: size, relativeTo: mapTextStyle(textStyle))
        }
        let uiFont = UIFont.systemFont(ofSize: size, weight: .regular)
        return Font(UIFontMetrics(forTextStyle: textStyle).scaledFont(for: uiFont))
    }

    // MARK: - Mapping Helpers

    private static let weightMapping: [Font.Weight: UIFont.Weight] = [
        .ultraLight: .ultraLight,
        .thin: .thin,
        .light: .light,
        .regular: .regular,
        .medium: .medium,
        .semibold: .semibold,
        .bold: .bold,
        .heavy: .heavy,
        .black: .black,
    ]

    private static let designMapping: [Font.Design: UIFontDescriptor.SystemDesign] = [
        .default: .default,
        .rounded: .rounded,
        .serif: .serif,
        .monospaced: .monospaced,
    ]

    private static func mapTextStyle(_ uiStyle: UIFont.TextStyle) -> Font.TextStyle {
        switch uiStyle {
        case .largeTitle: return .largeTitle
        case .title1: return .title
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption1: return .caption
        case .caption2: return .caption2
        default: return .body
        }
    }
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
    let isQuran: Bool

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
        if isQuran {
            switch size {
            case .large: return SafaTypography.quranLarge
            case .medium: return SafaTypography.quranMedium
            case .small: return SafaTypography.quranSmall
            }
        } else {
            switch size {
            case .large: return SafaTypography.arabicLarge
            case .medium: return SafaTypography.arabicMedium
            case .small: return SafaTypography.arabicSmall
            }
        }
    }
}

extension View {
    /// Apply Arabic text styling for general Arabic content (duas, hadith, etc.)
    func arabicStyle(_ size: ArabicTextStyle.ArabicTextSize = .medium) -> some View {
        modifier(ArabicTextStyle(size: size, isQuran: false))
    }

    /// Apply Quranic text styling with Uthmanic script font
    func quranStyle(_ size: ArabicTextStyle.ArabicTextSize = .medium) -> some View {
        modifier(ArabicTextStyle(size: size, isQuran: true))
    }
}

// MARK: - Reading Text Modifier

struct ReadingTextStyle: ViewModifier {
    let size: ReadingSize

    enum ReadingSize {
        case large
        case medium
        case small
    }

    func body(content: Content) -> some View {
        content
            .font(readingFont)
            .lineSpacing(4)
    }

    private var readingFont: Font {
        switch size {
        case .large: return SafaTypography.readingLarge
        case .medium: return SafaTypography.readingMedium
        case .small: return SafaTypography.readingSmall
        }
    }
}

extension View {
    /// Apply reading-optimized styling for translations and long content
    func readingStyle(_ size: ReadingTextStyle.ReadingSize = .medium) -> some View {
        modifier(ReadingTextStyle(size: size))
    }
}
