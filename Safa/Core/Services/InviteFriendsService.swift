// MARK: - InviteFriendsService.swift
// PURPOSE: Service for inviting friends to download Safa via App Store link
// DEPENDENCIES: Foundation, UIKit

import Foundation
import UIKit

// MARK: - Invite Friends Service

@Observable
final class InviteFriendsService {
    static let shared = InviteFriendsService()

    // MARK: - Properties

    private let userDefaults = UserDefaults.standard

    // Storage Keys
    private let inviteCountKey = AppConstants.StorageKeys.inviteCount
    private let wasInvitedKey = AppConstants.StorageKeys.inviteWasInvited
    private let hasanatAwardedKey = AppConstants.StorageKeys.inviteHasanatAwarded

    // MARK: - Configuration

    /// Number of times user has shared the invite
    var inviteCount: Int {
        get { userDefaults.integer(forKey: inviteCountKey) }
        set { userDefaults.set(newValue, forKey: inviteCountKey) }
    }

    /// Whether user indicated they were invited by someone
    var wasInvited: Bool {
        get { userDefaults.bool(forKey: wasInvitedKey) }
        set {
            userDefaults.set(newValue, forKey: wasInvitedKey)
            if newValue && !hasanatAwardedForInvite {
                awardHasanatForBeingInvited()
            }
        }
    }

    /// Whether Hasanat has been awarded for being invited (one-time)
    private var hasanatAwardedForInvite: Bool {
        get { userDefaults.bool(forKey: hasanatAwardedKey) }
        set { userDefaults.set(newValue, forKey: hasanatAwardedKey) }
    }

    // MARK: - Constants

    static let hasanatPerInvite = 25 // Honor system reward

    // MARK: - Init

    private init() {}

    // MARK: - Share Message

    /// Get the share message with App Store link
    var shareMessage: String {
        """
        Safa - Your Islamic Companion

        I've been using Safa for prayer times, Quran reading, and more. It's beautiful, ad-free, and private.

        Download it here:
        \(AppConstants.URLs.downloadURL.absoluteString)
        """
    }

    /// Get a shorter share message for social media
    var shortShareMessage: String {
        "Check out Safa - a beautiful, ad-free Islamic companion app! 🌙 \(AppConstants.URLs.downloadURL.absoluteString)"
    }

    /// Get share items for UIActivityViewController
    var shareItems: [Any] {
        var items: [Any] = [shareMessage]

        // Add app icon if available
        if let appIcon = UIImage(named: "AppIcon") {
            items.append(appIcon)
        }

        return items
    }

    // MARK: - Actions

    /// Record that user shared an invite
    func recordInviteShared() {
        inviteCount += 1
    }

    /// Award Hasanat for being invited (honor system)
    private func awardHasanatForBeingInvited() {
        // Award Hasanat through UserStateManager
        // This is done via honor system - user indicates they were invited
        hasanatAwardedForInvite = true

        // Post notification for UserStateManager to handle
        NotificationCenter.default.post(
            name: .inviteHasanatAwarded,
            object: nil,
            userInfo: ["hasanat": Self.hasanatPerInvite]
        )
    }

    /// Get the best available download URL (App Store or TestFlight)
    var appStoreURL: URL {
        AppConstants.URLs.downloadURL
    }

    /// Get TestFlight URL (for beta)
    var testFlightURL: URL {
        AppConstants.URLs.testFlight
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let inviteHasanatAwarded = Notification.Name("com.safa.inviteHasanatAwarded")
}

// MARK: - Invite Friends View

import SwiftUI

struct InviteFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var service = InviteFriendsService.shared
    @State private var showShareSheet = false
    @State private var showConfirmation = false
    @State private var toastService = ToastService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SafaSpacing.lg) {
                    // Header illustration
                    headerSection

                    // Main content
                    contentSection

                    // Share button
                    shareButton

                    // Stats
                    if service.inviteCount > 0 {
                        statsSection
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(SafaSpacing.md)
            }
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: service.shareItems) { activityType in
                    handleShareCompleted(activityType: activityType)
                }
            }
        }
    }

    // MARK: - Actions

    private func handleShareCompleted(activityType: UIActivity.ActivityType?) {
        withAnimation(.easeInOut(duration: 0.3)) {
            service.recordInviteShared()
            showConfirmation = true
        }

        let count = service.inviteCount
        let message = platformPrefix(for: activityType) + milestoneMessage(for: count)
        toastService.show(Toast(message: message, type: .success))

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeInOut(duration: 0.3)) {
                showConfirmation = false
            }
        }
    }

    private func milestoneMessage(for count: Int) -> String {
        switch count {
        case 1: return "First share! May it reach someone who benefits"
        case 5: return "5 shares! Your generosity is inspiring"
        case 10: return "10 shares! You're spreading light"
        case 25: return "25 shares! A true ambassador of good"
        default: return "Thanks for sharing! (\(count) total)"
        }
    }

    private func platformPrefix(for activityType: UIActivity.ActivityType?) -> String {
        guard let activityType else { return "" }
        switch activityType.rawValue {
        case "com.apple.UIKit.activity.Message":
            return "Sent via Messages! "
        case let raw where raw.contains("whatsapp"):
            return "Sent via WhatsApp! "
        default:
            return ""
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: SafaSpacing.md) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)
                .padding(SafaSpacing.md)
                .background {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                }

            Text("Share Safa with Friends & Family")
                .font(SafaTypography.headlineSmall)
                .multilineTextAlignment(.center)
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.md) {
            FeatureRow(
                icon: "heart.fill",
                title: "Help Others Connect",
                description: "Share the gift of a beautiful Islamic companion app"
            )

            FeatureRow(
                icon: "nosign",
                title: "No Ads, No Tracking",
                description: "Your friends will love the privacy-first approach"
            )

            FeatureRow(
                icon: "star.fill",
                title: "Earn Hasanat",
                description: "+\(InviteFriendsService.hasanatPerInvite) Hasanat when friends join"
            )
        }
        .padding(SafaSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.xl, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        }
    }

    private var shareButton: some View {
        Button {
            showShareSheet = true
        } label: {
            HStack {
                Image(systemName: showConfirmation ? "checkmark" : "square.and.arrow.up")
                Text(showConfirmation ? "Shared!" : "Share Safa")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(SafaSpacing.md)
            .background(showConfirmation ? Color.green : Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg, style: .continuous))
            .animation(.easeInOut(duration: 0.3), value: showConfirmation)
        }
        .disabled(showConfirmation)
    }

    private var statsSection: some View {
        HStack {
            Image(systemName: "paperplane.fill")
                .foregroundStyle(.secondary)

            Text("You've shared \(service.inviteCount) time\(service.inviteCount == 1 ? "" : "s")")
                .font(SafaTypography.bodyMedium)
                .foregroundStyle(.secondary)
        }
        .padding(SafaSpacing.md)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: SafaSpacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: SafaSpacing.IconSize.lg)

            VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                Text(title)
                    .font(SafaTypography.titleSmall)

                Text(description)
                    .font(SafaTypography.bodySmall)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let onComplete: (_ activityType: UIActivity.ActivityType?) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        controller.completionWithItemsHandler = { activityType, completed, _, _ in
            if completed {
                onComplete(activityType)
            }
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    InviteFriendsView()
}
