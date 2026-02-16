// MARK: - EmptyStateView.swift
// PURPOSE: Empty state view component for when no content is available
// DEPENDENCIES: SwiftUI

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: SafaSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: SafaSpacing.IconSize.xxl))
                .foregroundColor(SafaColors.Fallback.tertiaryText)

            VStack(spacing: SafaSpacing.xs) {
                Text(title)
                    .font(SafaTypography.titleLarge)
                    .foregroundColor(SafaColors.Fallback.text)

                Text(message)
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(title: actionTitle, action: action, fullWidth: false)
                    .padding(.top, SafaSpacing.sm)
            }
        }
        .padding(SafaSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    static var noBookmarks: EmptyStateView {
        EmptyStateView(
            icon: "bookmark",
            title: "No Bookmarks",
            message: "Bookmark your favorite ayahs and hadiths to find them easily later."
        )
    }

    static var noConversations: EmptyStateView {
        EmptyStateView(
            icon: "bubble.left.and.bubble.right",
            title: "No Conversations",
            message: "Start a conversation with the AI companion to get answers to your Islamic questions."
        )
    }

    static var noSearchResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "Try searching with different keywords."
        )
    }

    static var noFamily: EmptyStateView {
        EmptyStateView(
            icon: "person.3",
            title: "No Family Circle",
            message: "Create or join a family circle to share your progress with loved ones."
        )
    }

    static var offline: EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "You're Offline",
            message: "Connect to the internet to access this feature."
        )
    }

    static func noPrayerHistory(onLogPrayer: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "calendar.badge.clock",
            title: "No Prayer History",
            message: "Start logging your daily prayers to track your consistency.",
            actionTitle: "Go to Prayer Times",
            action: onLogPrayer
        )
    }

    static var noDhikr: EmptyStateView {
        EmptyStateView(
            icon: "text.book.closed",
            title: "No Dhikr Yet",
            message: "Morning and evening adhkar will appear here. Use the tasbeeh counter to get started."
        )
    }
}

// MARK: - Preview

#Preview {
    VStack {
        EmptyStateView(
            icon: "bookmark",
            title: "No Bookmarks",
            message: "Bookmark your favorite ayahs to find them easily later.",
            actionTitle: "Browse Quran"
        ) { }
    }
}
