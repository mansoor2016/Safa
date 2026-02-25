// MARK: - CommunitySupportCard.swift
// PURPOSE: Adaptive inline card combining share, support CTA, and subscriber thank-you
// DEPENDENCIES: SwiftUI, StoreKit, SupportPromptService, SubscriptionService, ShareBanner

import SwiftUI
import StoreKit

struct CommunitySupportCard: View {
    let showShare: Bool
    let showSupport: Bool
    let isSubscriber: Bool
    let onShareComplete: () -> Void
    var onSupportDismiss: (() -> Void)? = nil

    @State private var showShareSheet = false
    @State private var showSubscriptionSheet = false

    private var mode: HomeBannerResolver.CommunityCardMode {
        HomeBannerResolver.resolveCommunityCard(
            shareVisible: showShare,
            supportVisible: showSupport,
            isSubscriber: isSubscriber
        )
    }

    var body: some View {
        VStack(spacing: SafaSpacing.sm) {
            // Icon + text row
            HStack(spacing: SafaSpacing.md) {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(.pink)
                    .frame(width: 40, height: 40)
                    .background(Color.pink.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text(titleText)
                        .font(SafaTypography.titleSmall)
                        .foregroundStyle(SafaColors.Fallback.text)
                    Text(subtitleText)
                        .font(SafaTypography.bodySmall)
                        .foregroundStyle(SafaColors.Fallback.secondaryText)
                }
                Spacer()
            }

            // Button row
            if showShareButton || showSupportButton {
                HStack(spacing: SafaSpacing.sm) {
                    if showShareButton {
                        Button { showShareSheet = true } label: {
                            HStack(spacing: SafaSpacing.xs) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Share Safa")
                                    .font(SafaTypography.labelLarge)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, SafaSpacing.sm)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
                        }
                    }

                    if showSupportButton {
                        Button { showSubscriptionSheet = true } label: {
                            Text("See Plans")
                                .font(SafaTypography.labelLarge)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, SafaSpacing.sm)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
                        }
                    }
                }
            }

            // Opt-out row (only when support CTA is shown for non-subscribers)
            if showSupportButton {
                HStack {
                    Button("Not now") { onSupportDismiss?() }
                        .font(SafaTypography.bodySmall)
                        .foregroundStyle(SafaColors.Fallback.secondaryText)
                        .frame(minHeight: 44)

                    if SupportPromptService.promptCount() >= 2 {
                        Spacer()
                        Button("Don't show again") {
                            SupportPromptService.optOut()
                            onSupportDismiss?()
                        }
                        .font(SafaTypography.bodySmall)
                        .foregroundStyle(SafaColors.Fallback.tertiaryText)
                        .frame(minHeight: 44)
                    }
                }
            }
        }
        .padding(SafaSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
        .sheet(isPresented: $showShareSheet) {
            AppShareSheet { completed in
                if completed {
                    ShareBanner.markDismissed()
                    onShareComplete()
                }
            }
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionStoreView(productIDs: SubscriptionService.productIDs)
                .subscriptionStoreControlStyle(.automatic)
                .storeButton(.visible, for: .restorePurchases)
        }
    }

    // MARK: - Computed Helpers

    private var showShareButton: Bool {
        switch mode {
        case .shareOnly, .shareAndSupport, .thankYouWithShare: return true
        default: return false
        }
    }

    private var showSupportButton: Bool {
        switch mode {
        case .supportOnly, .shareAndSupport: return true
        default: return false
        }
    }

    private var titleText: String {
        isSubscriber ? "Thank you for supporting Safa" : "Support Safa"
    }

    private var subtitleText: String {
        switch mode {
        case .thankYou:
            return "Your subscription helps fund development."
        case .thankYouWithShare:
            return "Share the app with friends and family."
        case .shareOnly:
            return "Share the app with friends and family."
        case .supportOnly:
            return "All features are free. Subscribers help fund development and get custom app icons."
        case .shareAndSupport:
            return "All features are free. Subscribers help fund development and get custom app icons."
        case .hidden:
            return ""
        }
    }
}
