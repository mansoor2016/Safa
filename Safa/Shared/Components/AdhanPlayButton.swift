// MARK: - AdhanPlayButton.swift
// PURPOSE: Reusable adhan play/stop button with consistent state management
// DEPENDENCIES: SwiftUI, AudioPlayerService, PreferencesManager

import SwiftUI

/// Shared adhan play/stop button used on Prayer, Ramadan, and Home banner.
/// Manages its own isPlaying state to avoid @Published/@Observable propagation issues.
struct AdhanPlayButton: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var isPlaying = false

    /// Visual style variants
    enum Style {
        case quickAction   // Vertical icon + label (Prayer/Ramadan page)
        case banner        // Compact for Ramadan banner (white on dark)
    }

    let style: Style
    var isFajr: Bool = false  // Use Fajr-specific adhan

    var body: some View {
        switch style {
        case .quickAction:
            quickActionBody
        case .banner:
            bannerBody
        }
    }

    // MARK: - Quick Action Style (Prayer + Ramadan pages)

    private var quickActionBody: some View {
        Button {
            toggleAdhan()
        } label: {
            VStack(spacing: SafaSpacing.xs) {
                Image(systemName: isPlaying ? "stop.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                Text(isPlaying ? "Stop Adhan" : "Adhan")
                    .font(SafaTypography.labelSmall)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SafaSpacing.sm)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Banner Style (Ramadan banner on Home)

    private var bannerBody: some View {
        Button {
            toggleAdhan()
        } label: {
            VStack(spacing: SafaSpacing.xxs) {
                Image(systemName: isPlaying ? "stop.fill" : "speaker.wave.2.fill")
                    .font(.body)
                    .foregroundColor(.white)
                Text(isPlaying ? "Stop Adhan" : "Adhan")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SafaSpacing.xs)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.sm))
        }
    }

    // MARK: - Toggle Logic (single source of truth)

    private func toggleAdhan() {
        if isPlaying {
            dependencies.audioPlayerService.stop()
            isPlaying = false
            HapticFeedbackService.shared.play(.tap)
            return
        }

        HapticFeedbackService.shared.play(.commit)
        Task {
            let prefs = await PreferencesManager.shared.getPreferences()
            let fileName = isFajr ? prefs.selectedFajrAdhan : prefs.selectedAdhan
            let adhanSound = AdhanSound(rawValue: fileName) ?? .misharyAlafasy

            guard adhanSound != .defaultSound else { return }

            do {
                try dependencies.audioPlayerService.playBundled(
                    fileName: adhanSound.rawValue,
                    fileExtension: "caf"
                )
                isPlaying = true
            } catch {
                ToastService.shared.show(Toast(
                    message: String(localized: "Could not play adhan."),
                    type: .warning
                ))
            }
        }
    }
}
