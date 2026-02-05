// MARK: - DisabledFeatureModifier.swift
// PURPOSE: View modifier for showing disabled/coming soon features
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Disabled Feature Modifier

struct DisabledFeatureModifier: ViewModifier {
    let feature: Feature
    let showLabel: Bool
    let onTap: (() -> Void)?

    @State private var toastService = ToastService.shared

    private var isDisabled: Bool {
        FeatureFlags.shared.isDisabled(feature)
    }

    func body(content: Content) -> some View {
        if isDisabled {
            disabledContent(content)
        } else {
            content
        }
    }

    @ViewBuilder
    private func disabledContent(_ content: Content) -> some View {
        content
            .opacity(0.5)
            .overlay {
                if showLabel {
                    comingSoonLabel
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if let onTap {
                    onTap()
                } else {
                    toastService.showComingSoon(feature.displayName)
                }

                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            .allowsHitTesting(true)
    }

    private var comingSoonLabel: some View {
        Text("Coming soon")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(Color.purple.opacity(0.9))
            }
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Simple Disabled Modifier (without feature flag)

struct SimpleDisabledModifier: ViewModifier {
    let isDisabled: Bool
    let featureName: String
    let showLabel: Bool

    @State private var toastService = ToastService.shared

    func body(content: Content) -> some View {
        if isDisabled {
            content
                .opacity(0.5)
                .overlay {
                    if showLabel {
                        comingSoonLabel
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toastService.showComingSoon(featureName)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
                .allowsHitTesting(true)
        } else {
            content
        }
    }

    private var comingSoonLabel: some View {
        Text("Coming soon")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(Color.purple.opacity(0.9))
            }
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - View Extensions

extension View {
    /// Marks a view as a disabled/coming soon feature using FeatureFlags
    func disabledFeature(
        _ feature: Feature,
        showLabel: Bool = true,
        onTap: (() -> Void)? = nil
    ) -> some View {
        modifier(DisabledFeatureModifier(
            feature: feature,
            showLabel: showLabel,
            onTap: onTap
        ))
    }

    /// Marks a view as disabled with a custom feature name
    func disabledFeature(
        isDisabled: Bool,
        name: String,
        showLabel: Bool = true
    ) -> some View {
        modifier(SimpleDisabledModifier(
            isDisabled: isDisabled,
            featureName: name,
            showLabel: showLabel
        ))
    }
}

// MARK: - Disabled Row Component

struct DisabledFeatureRow: View {
    let title: String
    let icon: String
    let feature: Feature
    var subtitle: String? = nil

    @State private var toastService = ToastService.shared

    private var isDisabled: Bool {
        FeatureFlags.shared.isDisabled(feature)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isDisabled ? .secondary : .primary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(isDisabled ? .secondary : .primary)

                    if isDisabled {
                        Text("Coming soon")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.purple))
                    }
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !isDisabled {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if isDisabled {
                toastService.showComingSoon(feature.displayName)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
}

// MARK: - Preview

#Preview("Disabled Modifier") {
    VStack(spacing: 20) {
        Button("AI Chat") {}
            .buttonStyle(.borderedProminent)
            .disabledFeature(.aiCompanion)

        DisabledFeatureRow(
            title: "Spotlight Search",
            icon: "magnifyingglass",
            feature: .spotlightSearch,
            subtitle: "Search from iOS Spotlight"
        )
        .padding(.horizontal)
    }
    .toastContainer()
}
