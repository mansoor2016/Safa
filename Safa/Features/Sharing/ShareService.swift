// MARK: - ShareService.swift
// PURPOSE: Service for sharing content (verses, progress, etc.)
// DEPENDENCIES: Foundation, UIKit, SwiftUI

import Foundation
import SwiftUI
import UIKit

// MARK: - Shareable Content Types

/// Content types that can be shared from the app
enum ShareableContent {
    case quranVerse(surah: String, ayah: Int, arabicText: String, translation: String)
    case hadith(collection: String, narrator: String, text: String)
    case dailyProgress(hasanat: Int, streak: Int)
    case dua(title: String, arabic: String, translation: String)
    case inviteLink(code: String)
    case eidGreeting(eidType: EidType, message: String)
}

// MARK: - Share Card Style

struct ShareCardStyle {
    let backgroundColor: Color
    let textColor: Color
    let accentColor: Color

    static let quran = ShareCardStyle(
        backgroundColor: Color(red: 0.05, green: 0.25, blue: 0.20),
        textColor: .white,
        accentColor: Color(red: 0.4, green: 0.8, blue: 0.6)
    )

    static let hadith = ShareCardStyle(
        backgroundColor: Color(red: 0.15, green: 0.10, blue: 0.25),
        textColor: .white,
        accentColor: Color(red: 0.7, green: 0.5, blue: 0.9)
    )

    static let progress = ShareCardStyle(
        backgroundColor: Color(red: 0.10, green: 0.30, blue: 0.50),
        textColor: .white,
        accentColor: Color(red: 0.3, green: 0.7, blue: 1.0)
    )

    static let dua = ShareCardStyle(
        backgroundColor: Color(red: 0.05, green: 0.20, blue: 0.35),
        textColor: .white,
        accentColor: Color(red: 0.4, green: 0.7, blue: 0.9)
    )

    static let eidFitr = ShareCardStyle(
        backgroundColor: Color(red: 0.11, green: 0.37, blue: 0.13),
        textColor: .white,
        accentColor: Color(red: 0.75, green: 0.88, blue: 0.75)
    )

    static let eidAdha = ShareCardStyle(
        backgroundColor: Color(red: 0.90, green: 0.32, blue: 0.0),
        textColor: .white,
        accentColor: Color(red: 0.95, green: 0.82, blue: 0.65)
    )
}

// MARK: - Share Service

@Observable
final class ShareService {

    // MARK: - Properties

    private let userState: UserStateManager?

    // MARK: - Initialization

    init(userState: UserStateManager? = nil) {
        self.userState = userState
    }

    // MARK: - Public Methods

    /// Generate shareable text for content
    func generateShareText(for content: ShareableContent) -> String {
        switch content {
        case .quranVerse(let surah, let ayah, let arabicText, let translation):
            return """
            \(arabicText)

            "\(translation)"

            — Quran, \(surah):\(ayah)

            Shared via Safa - Your Islamic Companion
            """

        case .hadith(let collection, let narrator, let text):
            return """
            "\(text)"

            — Narrated by \(narrator)
            (\(collection))

            Shared via Safa - Your Islamic Companion
            """

        case .dailyProgress(let hasanat, let streak):
            return """
            📊 My Progress Today

            🌟 \(hasanat) Hasanat earned
            🔥 \(streak) day streak

            Track your Islamic journey with Safa
            """

        case .dua(let title, let arabic, let translation):
            return """
            \(title)

            \(arabic)

            "\(translation)"

            Shared via Safa - Your Islamic Companion
            """

        case .inviteLink(let code):
            return """
            Join my family circle on Safa!

            Use invite code: \(code)

            Or download Safa - Your Islamic Companion:
            \(AppConstants.URLs.downloadURL.absoluteString)
            """

        case .eidGreeting(let eidType, let message):
            return """
            \(message)

            \(eidType.acceptanceDuaArabic)
            \(eidType.acceptanceDua)

            Shared via Safa - Your Islamic Companion
            \(AppConstants.URLs.downloadURL.absoluteString)
            """
        }
    }

    /// Share content using system share sheet
    @MainActor
    func share(_ content: ShareableContent) {
        let text = generateShareText(for: content)
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        // Get the current window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {

            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }

            rootVC.present(activityVC, animated: true)

            // Award hasanat for sharing
            awardSharingHasanat(for: content)
        }
    }

    /// Share content with an image card
    @MainActor
    func shareWithCard(_ content: ShareableContent, card: UIImage?) {
        var items: [Any] = [generateShareText(for: content)]

        if let card = card {
            items.insert(card, at: 0)
        }

        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }

            rootVC.present(activityVC, animated: true)

            // Award hasanat
            awardSharingHasanat(for: content)
        }
    }

    /// Share an Eid greeting card with a selected message
    @MainActor
    func shareEidGreeting(eidType: EidType, message: String, hijriYear: Int) {
        let card = EidGreetingCard(eidType: eidType, message: message, hijriYear: hijriYear)
        let image = card.renderImage()
        let content = ShareableContent.eidGreeting(eidType: eidType, message: message)
        shareWithCard(content, card: image)
    }

    // MARK: - Private Methods

    private func awardSharingHasanat(for content: ShareableContent) {
        guard let userState else { return }

        Task {
            let dateString = {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                return f.string(from: Date())
            }()

            switch content {
            case .quranVerse:
                await HasanatTracker.awardOnce(.share, key: "share_verse_\(dateString)", via: userState)
            case .inviteLink:
                await HasanatTracker.awardOnce(.share, key: "share_invite_\(dateString)", via: userState)
            case .eidGreeting:
                await HasanatTracker.awardOnce(.share, key: "share_eid_\(dateString)", via: userState)
            default:
                await HasanatTracker.awardOnce(.share, key: "share_other_\(dateString)", via: userState)
            }
        }
    }
}

// MARK: - Share Card Layout

struct ShareCardLayout<Content: View>: View {
    let style: ShareCardStyle
    let headerIcon: String
    let headerTitle: String
    let headerDetail: String?
    let footerText: String
    let width: CGFloat
    let height: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        style: ShareCardStyle,
        headerIcon: String,
        headerTitle: String,
        headerDetail: String? = nil,
        footerText: String,
        width: CGFloat,
        height: CGFloat,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.headerIcon = headerIcon
        self.headerTitle = headerTitle
        self.headerDetail = headerDetail
        self.footerText = footerText
        self.width = width
        self.height = height
        self.content = content
    }

    var body: some View {
        VStack(spacing: SafaSpacing.md) {
            // Header
            HStack {
                Image(systemName: headerIcon)
                    .font(SafaTypography.titleSmall)
                Text(headerTitle)
                    .font(SafaTypography.titleMedium)
                Spacer()
                if let detail = headerDetail {
                    Text(detail)
                        .font(SafaTypography.bodySmall)
                }
            }
            .foregroundStyle(style.accentColor)

            Divider()
                .background(style.accentColor.opacity(0.3))

            // Content slot
            content()

            Spacer()

            // Footer
            HStack {
                Image(systemName: "sparkles")
                    .font(SafaTypography.labelSmall)
                Text(footerText)
                    .font(SafaTypography.labelSmall)
            }
            .foregroundStyle(style.accentColor.opacity(0.7))
        }
        .padding(SafaSpacing.lg)
        .frame(width: width, height: height)
        .background(style.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.xl))
    }
}

// MARK: - Share Card Views

struct QuranShareCard: View {
    let surahName: String
    let ayahNumber: Int
    let arabicText: String
    let translation: String

    var body: some View {
        ShareCardLayout(
            style: .quran,
            headerIcon: "book.fill",
            headerTitle: "Quran",
            headerDetail: "\(surahName):\(ayahNumber)",
            footerText: "Shared via صفا",
            width: 350,
            height: 450
        ) {
            Text(arabicText)
                .font(SafaTypography.arabicLarge)
                .multilineTextAlignment(.center)
                .foregroundStyle(ShareCardStyle.quran.textColor)

            Text("\"\(translation)\"")
                .font(SafaTypography.readingSmall)
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(ShareCardStyle.quran.textColor.opacity(0.9))
        }
    }
}

struct ProgressShareCard: View {
    let hasanat: Int
    let streak: Int
    let level: Int
    let levelTitle: String

    var body: some View {
        ShareCardLayout(
            style: .progress,
            headerIcon: "chart.line.uptrend.xyaxis",
            headerTitle: "My Progress",
            footerText: "Track your journey with صفا",
            width: 300,
            height: 350
        ) {
            HStack(spacing: SafaSpacing.lg) {
                VStack {
                    Text("\(hasanat)")
                        .font(SafaTypography.counterMedium)
                    Text("Hasanat")
                        .font(SafaTypography.labelSmall)
                        .foregroundStyle(.secondary)
                }

                VStack {
                    HStack(spacing: SafaSpacing.xxs) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(streak)")
                            .font(SafaTypography.counterMedium)
                    }
                    Text("Day Streak")
                        .font(SafaTypography.labelSmall)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(ShareCardStyle.progress.textColor)

            VStack(spacing: SafaSpacing.xxs) {
                Text("Level \(level)")
                    .font(SafaTypography.titleSmall)
                    .fontWeight(.semibold)
                Text(levelTitle)
                    .font(SafaTypography.labelSmall)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(ShareCardStyle.progress.textColor)
        }
    }
}

struct HadithShareCard: View {
    let collection: String
    let narrator: String
    let text: String

    var body: some View {
        ShareCardLayout(
            style: .hadith,
            headerIcon: "text.quote",
            headerTitle: "Hadith",
            headerDetail: collection,
            footerText: "Shared via صفا",
            width: 350,
            height: 450
        ) {
            Text(text)
                .font(SafaTypography.readingSmall)
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(ShareCardStyle.hadith.textColor)

            Text("— Narrated by \(narrator)")
                .font(SafaTypography.bodySmall)
                .foregroundStyle(ShareCardStyle.hadith.textColor.opacity(0.7))
        }
    }
}

struct DuaShareCard: View {
    let title: String
    let arabicText: String
    let translation: String

    var body: some View {
        ShareCardLayout(
            style: .dua,
            headerIcon: "hands.sparkles.fill",
            headerTitle: "Dua",
            headerDetail: title,
            footerText: "Shared via صفا",
            width: 350,
            height: 420
        ) {
            Text(arabicText)
                .font(SafaTypography.arabicMedium)
                .multilineTextAlignment(.center)
                .foregroundStyle(ShareCardStyle.dua.textColor)

            Text("\"\(translation)\"")
                .font(SafaTypography.readingSmall)
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(ShareCardStyle.dua.textColor.opacity(0.9))
        }
    }
}

// MARK: - Share Button View

struct ShareButton: View {
    @Environment(Dependencies.self) private var dependencies
    let content: ShareableContent
    @State private var shareService: ShareService?

    var body: some View {
        Button {
            let service = shareService ?? ShareService(userState: dependencies.userState)
            service.share(content)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .task {
            if shareService == nil {
                shareService = ShareService(userState: dependencies.userState)
            }
        }
    }
}

// MARK: - Preview

#Preview("Quran Share Card") {
    QuranShareCard(
        surahName: "Al-Fatiha",
        ayahNumber: 1,
        arabicText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
        translation: "In the name of Allah, the Most Gracious, the Most Merciful"
    )
}

#Preview("Progress Share Card") {
    ProgressShareCard(
        hasanat: 1250,
        streak: 14,
        level: 5,
        levelTitle: "Consistent"
    )
}

#Preview("Hadith Share Card") {
    HadithShareCard(
        collection: "Sahih Bukhari",
        narrator: "Abu Hurairah",
        text: "The Prophet (peace be upon him) said: \"The best of you are those who learn the Quran and teach it.\""
    )
}

#Preview("Dua Share Card") {
    DuaShareCard(
        title: "Morning Remembrance",
        arabicText: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
        translation: "In the name of Allah, with whose name nothing on earth or in heaven can cause harm, and He is the All-Hearing, the All-Knowing."
    )
}
