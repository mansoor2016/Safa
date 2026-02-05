// MARK: - ShareBanner.swift
// PURPOSE: Card row on home page prompting users to share the app, permanently dismissed after sharing
// DEPENDENCIES: SwiftUI

import SwiftUI

struct ShareBanner: View {
    let onDismiss: () -> Void
    @State private var showingShareSheet = false

    private static let dismissedKey = "share_banner_dismissed"

    static var isDismissed: Bool {
        UserDefaults.standard.bool(forKey: dismissedKey)
    }

    private static func markDismissed() {
        UserDefaults.standard.set(true, forKey: dismissedKey)
    }

    var body: some View {
        VStack(spacing: SafaSpacing.sm) {
            HStack(spacing: SafaSpacing.md) {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(.pink)
                    .frame(width: 40, height: 40)
                    .background(Color.pink.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text("Enjoying Safa?")
                        .font(SafaTypography.titleSmall)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text("Share the app with friends and family")
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                Spacer()
            }

            Button {
                showingShareSheet = true
            } label: {
                HStack(spacing: SafaSpacing.xs) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Share Safa")
                        .font(SafaTypography.labelLarge)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, SafaSpacing.sm)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
            }
        }
        .padding(SafaSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
        .sheet(isPresented: $showingShareSheet, onDismiss: {
            ShareBanner.markDismissed()
            onDismiss()
        }) {
            AppShareSheet()
        }
    }
}

// MARK: - Share Sheet

private struct AppShareSheet: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let appStoreURL = "https://apps.apple.com/app/safa"
        let shareText = "Check out Safa - an Islamic companion app for prayer times, Quran, and more!"
        let items: [Any] = [shareText, URL(string: appStoreURL) as Any]
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Share Banner") {
    VStack {
        Spacer()
        ShareBanner(onDismiss: {})
            .padding()
    }
}
