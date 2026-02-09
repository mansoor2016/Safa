// MARK: - ErrorView.swift
// PURPOSE: Error state view component for when content fails to load
// DEPENDENCIES: SwiftUI, PrimaryButton

import SwiftUI

struct ErrorView: View {
    let icon: String
    let title: String
    let message: String
    var retryTitle: String = "Try Again"
    var retry: (() async -> Void)?

    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: SafaSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: SafaSpacing.IconSize.xxl))
                .foregroundColor(SafaColors.Fallback.error)

            VStack(spacing: SafaSpacing.xs) {
                Text(title)
                    .font(SafaTypography.titleLarge)
                    .foregroundColor(SafaColors.Fallback.text)

                Text(message)
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let retry {
                PrimaryButton(title: retryTitle, action: {
                    guard !isRetrying else { return }
                    isRetrying = true
                    Task {
                        await retry()
                        isRetrying = false
                    }
                }, isLoading: isRetrying, fullWidth: false)
                    .padding(.top, SafaSpacing.sm)
            }
        }
        .padding(SafaSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preset Error States

extension ErrorView {
    static func loadFailed(retry: (() async -> Void)? = nil) -> ErrorView {
        ErrorView(
            icon: "exclamationmark.triangle",
            title: "Something Went Wrong",
            message: "We couldn't load this content. Please try again.",
            retry: retry
        )
    }

    static func networkError(retry: (() async -> Void)? = nil) -> ErrorView {
        ErrorView(
            icon: "wifi.exclamationmark",
            title: "Connection Issue",
            message: "Please check your internet connection and try again.",
            retry: retry
        )
    }

    static func prayerTimesError(retry: (() async -> Void)? = nil) -> ErrorView {
        ErrorView(
            icon: "clock.badge.exclamationmark",
            title: "Couldn't Load Prayer Times",
            message: "We couldn't calculate prayer times. Please check your location settings.",
            retry: retry
        )
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ErrorView.loadFailed {
            try? await Task.sleep(for: .seconds(1))
        }
    }
}
