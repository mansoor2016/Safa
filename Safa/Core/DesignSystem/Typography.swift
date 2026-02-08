// MARK: - Typography.swift
// PURPOSE: Design system typography styles for the Safa app
// DEPENDENCIES: SwiftUI

import SwiftUI

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
    static let displayLarge = makeFont(size: 57, weight: .regular, design: FontConfig.displayDesign)
    static let displayMedium = makeFont(size: 45, weight: .regular, design: FontConfig.displayDesign)
    static let displaySmall = makeFont(size: 36, weight: .regular, design: FontConfig.displayDesign)

    // MARK: - Headline Styles (Section headers)
    static let headlineLarge = makeFont(size: 32, weight: .semibold, design: FontConfig.headlineDesign)
    static let headlineMedium = makeFont(size: 28, weight: .semibold, design: FontConfig.headlineDesign)
    static let headlineSmall = makeFont(size: 24, weight: .semibold, design: FontConfig.headlineDesign)

    // MARK: - Title Styles (Card titles, list headers)
    static let titleLarge = makeFont(size: 22, weight: .semibold, design: FontConfig.bodyDesign)
    static let titleMedium = makeFont(size: 16, weight: .semibold, design: FontConfig.bodyDesign)
    static let titleSmall = makeFont(size: 14, weight: .semibold, design: FontConfig.bodyDesign)

    // MARK: - Body Styles (General text)
    static let bodyLarge = makeFont(size: 16, weight: .regular, design: FontConfig.bodyDesign)
    static let bodyMedium = makeFont(size: 14, weight: .regular, design: FontConfig.bodyDesign)
    static let bodySmall = makeFont(size: 12, weight: .regular, design: FontConfig.bodyDesign)

    // MARK: - Label Styles (Buttons, captions)
    static let labelLarge = makeFont(size: 14, weight: .medium, design: FontConfig.bodyDesign)
    static let labelMedium = makeFont(size: 12, weight: .medium, design: FontConfig.bodyDesign)
    static let labelSmall = makeFont(size: 11, weight: .medium, design: FontConfig.bodyDesign)

    // MARK: - Quran Arabic Styles (Uthmanic script)
    static let quranLarge = makeArabicFont(size: 36, forQuran: true)
    static let quranMedium = makeArabicFont(size: 28, forQuran: true)
    static let quranSmall = makeArabicFont(size: 22, forQuran: true)

    // MARK: - General Arabic Styles (Duas, Hadith, UI)
    static let arabicLarge = makeArabicFont(size: 32, forQuran: false)
    static let arabicMedium = makeArabicFont(size: 24, forQuran: false)
    static let arabicSmall = makeArabicFont(size: 18, forQuran: false)

    // MARK: - Counter Display (Tasbeeh, streaks)
    static let counterLarge = makeFont(size: 72, weight: .bold, design: FontConfig.counterDesign)
    static let counterMedium = makeFont(size: 48, weight: .bold, design: FontConfig.counterDesign)
    static let counterSmall = makeFont(size: 36, weight: .bold, design: FontConfig.counterDesign)

    // MARK: - Reading Styles (Translations, long content)
    static let readingLarge = makeReadingFont(size: 18)
    static let readingMedium = makeReadingFont(size: 16)
    static let readingSmall = makeReadingFont(size: 14)

    // MARK: - Font Builders

    private static func makeFont(size: CGFloat, weight: Font.Weight, design: Font.Design) -> Font {
        if let fontName = FontConfig.englishUIFontName {
            return Font.custom(fontName, size: size).weight(weight)
        }
        return Font.system(size: size, weight: weight, design: design)
    }

    private static func makeArabicFont(size: CGFloat, forQuran: Bool) -> Font {
        let fontName = forQuran ? FontConfig.quranFontName : FontConfig.arabicFontName
        if let name = fontName {
            return Font.custom(name, size: size)
        }
        // System Arabic with serif design for elegance
        return Font.system(size: size, weight: .regular, design: .serif)
    }

    private static func makeReadingFont(size: CGFloat) -> Font {
        if let fontName = FontConfig.englishReadingFontName {
            return Font.custom(fontName, size: size)
        }
        return Font.system(size: size, weight: .regular, design: .default)
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
