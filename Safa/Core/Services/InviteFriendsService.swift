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
    private let inviteCountKey = "com.safa.invite.count"
    private let wasInvitedKey = "com.safa.invite.wasInvited"
    private let hasanatAwardedKey = "com.safa.invite.hasanatAwarded"

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
        \(AppConstants.URLs.appStore.absoluteString)
        """
    }

    /// Get a shorter share message for social media
    var shortShareMessage: String {
        "Check out Safa - a beautiful, ad-free Islamic companion app! 🌙 \(AppConstants.URLs.appStore.absoluteString)"
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

    /// Get App Store URL for the app
    var appStoreURL: URL {
        AppConstants.URLs.appStore
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
    @State private var toastService = ToastService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header illustration
                    headerSection

                    // Main content
                    contentSection

                    // Share button
                    shareButton

                    // Stats
                    if service.inviteCount > 0 {
                        statsSection
                    }
                }
                .padding()
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
                ShareSheet(items: service.shareItems) {
                    service.recordInviteShared()
                    toastService.show(Toast(
                        message: "Thanks for sharing!",
                        type: .success
                    ))
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)
                .padding()
                .background {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                }

            Text("Share Safa with Friends & Family")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                description: "+\(InviteFriendsService.hasanatPerInvite) Hasanat when friends join (honor system)"
            )
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        }
    }

    private var shareButton: some View {
        Button {
            showShareSheet = true
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share Safa")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var statsSection: some View {
        HStack {
            Image(systemName: "paperplane.fill")
                .foregroundStyle(.secondary)

            Text("You've shared \(service.inviteCount) time\(service.inviteCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let onComplete: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                onComplete()
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
