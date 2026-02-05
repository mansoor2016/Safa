// MARK: - ShareService.swift
// PURPOSE: Service for sharing content (verses, achievements, etc.)
// DEPENDENCIES: Foundation, UIKit, SwiftUI

import Foundation
import SwiftUI
import UIKit

// MARK: - Shareable Content Types

/// Content types that can be shared from the app
enum ShareableContent {
    case quranVerse(surah: String, ayah: Int, arabicText: String, translation: String)
    case hadith(collection: String, narrator: String, text: String)
    case achievement(title: String, description: String)
    case dailyProgress(hasanat: Int, streak: Int)
    case dua(title: String, arabic: String, translation: String)
    case inviteLink(code: String)
}

// MARK: - Share Card Style

struct ShareCardStyle {
    let backgroundColor: Color
    let textColor: Color
    let accentColor: Color
    let fontName: String

    static let quran = ShareCardStyle(
        backgroundColor: Color(red: 0.05, green: 0.25, blue: 0.20),
        textColor: .white,
        accentColor: Color(red: 0.4, green: 0.8, blue: 0.6),
        fontName: "Amiri"
    )

    static let hadith = ShareCardStyle(
        backgroundColor: Color(red: 0.15, green: 0.10, blue: 0.25),
        textColor: .white,
        accentColor: Color(red: 0.7, green: 0.5, blue: 0.9),
        fontName: "Amiri"
    )

    static let achievement = ShareCardStyle(
        backgroundColor: Color(red: 0.95, green: 0.85, blue: 0.30),
        textColor: Color(red: 0.2, green: 0.15, blue: 0.0),
        accentColor: Color(red: 0.6, green: 0.45, blue: 0.0),
        fontName: "System"
    )

    static let progress = ShareCardStyle(
        backgroundColor: Color(red: 0.10, green: 0.30, blue: 0.50),
        textColor: .white,
        accentColor: Color(red: 0.3, green: 0.7, blue: 1.0),
        fontName: "System"
    )

    static let dua = ShareCardStyle(
        backgroundColor: Color(red: 0.05, green: 0.20, blue: 0.35),
        textColor: .white,
        accentColor: Color(red: 0.4, green: 0.7, blue: 0.9),
        fontName: "Amiri"
    )
}

// MARK: - Share Service

@Observable
final class ShareService {

    // MARK: - Properties

    private let hasanatService: HasanatService?

    // MARK: - Initialization

    init(hasanatService: HasanatService? = nil) {
        self.hasanatService = hasanatService
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

        case .achievement(let title, let description):
            return """
            🏆 Achievement Unlocked!

            \(title)
            \(description)

            Join me on Safa - Your Islamic Companion
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
            [App Store Link]
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

    // MARK: - Private Methods

    private func awardSharingHasanat(for content: ShareableContent) {
        guard let service = hasanatService else { return }

        switch content {
        case .quranVerse:
            service.award(for: .sharedVerse)
        case .achievement:
            service.award(for: .sharedAchievement)
        case .inviteLink:
            service.award(for: .invitedFriend)
        default:
            break
        }
    }
}

// MARK: - Share Card View

struct QuranShareCard: View {
    let surahName: String
    let ayahNumber: Int
    let arabicText: String
    let translation: String

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "book.fill")
                    .font(.title3)
                Text("Quran")
                    .font(.headline)
                Spacer()
                Text("\(surahName):\(ayahNumber)")
                    .font(.subheadline)
            }
            .foregroundStyle(ShareCardStyle.quran.accentColor)

            Divider()
                .background(ShareCardStyle.quran.accentColor.opacity(0.3))

            // Arabic text
            Text(arabicText)
                .font(.system(size: 28, weight: .medium, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(ShareCardStyle.quran.textColor)

            // Translation
            Text("\"\(translation)\"")
                .font(.body)
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(ShareCardStyle.quran.textColor.opacity(0.9))

            Spacer()

            // Footer
            HStack {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text("Shared via صفا")
                    .font(.caption)
            }
            .foregroundStyle(ShareCardStyle.quran.accentColor.opacity(0.7))
        }
        .padding(24)
        .frame(width: 350, height: 450)
        .background(ShareCardStyle.quran.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct AchievementShareCard: View {
    let title: String
    let description: String
    let iconName: String

    var body: some View {
        VStack(spacing: 16) {
            // Trophy icon
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(ShareCardStyle.achievement.accentColor)

            Text("Achievement Unlocked!")
                .font(.headline)
                .foregroundStyle(ShareCardStyle.achievement.accentColor)

            Divider()
                .background(ShareCardStyle.achievement.accentColor.opacity(0.3))

            // Achievement icon
            Image(systemName: iconName)
                .font(.system(size: 64))
                .foregroundStyle(ShareCardStyle.achievement.textColor)

            // Title
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(ShareCardStyle.achievement.textColor)

            // Description
            Text(description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(ShareCardStyle.achievement.textColor.opacity(0.8))

            Spacer()

            // Footer
            HStack {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text("Achieved with صفا")
                    .font(.caption)
            }
            .foregroundStyle(ShareCardStyle.achievement.accentColor)
        }
        .padding(24)
        .frame(width: 300, height: 400)
        .background(ShareCardStyle.achievement.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct ProgressShareCard: View {
    let hasanat: Int
    let streak: Int
    let level: Int
    let levelTitle: String

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                Text("My Progress")
                    .font(.headline)
                Spacer()
            }
            .foregroundStyle(ShareCardStyle.progress.accentColor)

            Divider()
                .background(ShareCardStyle.progress.accentColor.opacity(0.3))

            // Stats
            HStack(spacing: 24) {
                VStack {
                    Text("\(hasanat)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("Hasanat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(streak)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                    }
                    Text("Day Streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(ShareCardStyle.progress.textColor)

            // Level
            VStack(spacing: 4) {
                Text("Level \(level)")
                    .font(.title3.weight(.semibold))
                Text(levelTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(ShareCardStyle.progress.textColor)

            Spacer()

            // Footer
            HStack {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text("Track your journey with صفا")
                    .font(.caption)
            }
            .foregroundStyle(ShareCardStyle.progress.accentColor.opacity(0.7))
        }
        .padding(24)
        .frame(width: 300, height: 350)
        .background(ShareCardStyle.progress.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Share Button View

struct ShareButton: View {
    let content: ShareableContent
    @State private var shareService = ShareService()

    var body: some View {
        Button {
            shareService.share(content)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
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

#Preview("Achievement Share Card") {
    AchievementShareCard(
        title: "First Prayer",
        description: "Logged your first prayer in Safa",
        iconName: "moon.stars.fill"
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
