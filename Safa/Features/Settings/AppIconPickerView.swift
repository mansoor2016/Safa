// MARK: - AppIconPickerView.swift
// PURPOSE: Subscriber-only custom app icon picker
// DEPENDENCIES: SwiftUI, UIKit, SubscriptionService

import SwiftUI
import StoreKit

struct AppIconPickerView: View {
    // MARK: - Properties
    let isSubscriber: Bool

    // MARK: - State
    @State private var selectedIcon: AppIcon = .primary
    @State private var showSubscriptionSheet = false

    // MARK: - Body
    var body: some View {
        List {
            Section {
                ForEach(AppIcon.allCases) { icon in
                    iconRow(icon)
                }
            } footer: {
                if !isSubscriber {
                    Text("Subscribe to unlock custom app icons.")
                        .font(SafaTypography.bodySmall)
                        .foregroundStyle(SafaColors.Fallback.tertiaryText)
                }
            }
        }
        .navigationTitle("App Icon")
        .onAppear {
            selectedIcon = AppIcon.current
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            subscriptionStoreSheet
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func iconRow(_ icon: AppIcon) -> some View {
        Button {
            if isSubscriber || icon == .primary {
                selectIcon(icon)
            } else {
                showSubscriptionSheet = true
            }
        } label: {
            HStack(spacing: SafaSpacing.md) {
                Image(icon.previewAsset)
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 13.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13.5)
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )

                Text(icon.displayName)
                    .font(SafaTypography.bodyLarge)
                    .foregroundStyle(SafaColors.Fallback.text)

                Spacer()

                if selectedIcon == icon {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                } else if !isSubscriber && icon != .primary {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(SafaColors.Fallback.tertiaryText)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var subscriptionStoreSheet: some View {
        SubscriptionStoreView(productIDs: SubscriptionService.productIDs)
            .subscriptionStoreControlStyle(.automatic)
            .storeButton(.visible, for: .restorePurchases)
    }

    // MARK: - Actions

    private func selectIcon(_ icon: AppIcon) {
        guard UIApplication.shared.supportsAlternateIcons else { return }

        let previousIcon = selectedIcon
        selectedIcon = icon
        Task { @MainActor in
            do {
                try await UIApplication.shared.setAlternateIconName(icon.alternateIconName)
            } catch {
                selectedIcon = previousIcon
                ToastService.shared.show(Toast(
                    message: "Couldn't change icon. Please try again.",
                    type: .warning
                ))
            }
        }
    }
}

// MARK: - AppIcon

extension AppIconPickerView {
    enum AppIcon: String, CaseIterable, Identifiable {
        case primary = "Default"
        case gold = "AppIcon-Gold"
        case midnight = "AppIcon-Midnight"
        case minimal = "AppIcon-Minimal"

        var id: String { rawValue }

        var displayName: String { rawValue == "Default" ? "Default" : String(rawValue.dropFirst("AppIcon-".count)) }

        /// Returns nil for primary (system default), icon name string for alternates.
        var alternateIconName: String? {
            self == .primary ? nil : rawValue
        }

        /// Asset catalog image name for the preview thumbnail.
        var previewAsset: String {
            self == .primary ? "AppIcon-Preview" : "\(rawValue)-Preview"
        }

        /// Detects the currently active icon.
        static var current: AppIcon {
            guard let name = UIApplication.shared.alternateIconName else { return .primary }
            return AppIcon(rawValue: name) ?? .primary
        }
    }
}
