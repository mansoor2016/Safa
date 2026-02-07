// MARK: - DegradedStateBanner.swift
// PURPOSE: Shared reusable component for inline degraded state indicators
// DEPENDENCIES: SwiftUI

import SwiftUI

struct DegradedStateBanner: View {
    let icon: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil
    var color: Color = .orange

    var body: some View {
        HStack(spacing: SafaSpacing.xs) {
            Image(systemName: icon)
                .font(.caption2)

            Text(message)
                .font(SafaTypography.labelSmall)

            Spacer()

            if let actionLabel {
                Button(actionLabel) {
                    action?()
                }
                .font(SafaTypography.labelSmall)
                .fontWeight(.medium)
            }
        }
        .foregroundColor(color)
        .padding(.horizontal, SafaSpacing.md)
        .padding(.vertical, SafaSpacing.xs)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.sm))
    }
}

// MARK: - Standard Variants

extension DegradedStateBanner {
    static func locationFallback(locationName: String, action: (() -> Void)? = nil) -> DegradedStateBanner {
        DegradedStateBanner(
            icon: "location.slash",
            message: "Using \(locationName)",
            actionLabel: action != nil ? "Update" : nil,
            action: action,
            color: .orange
        )
    }

    static func offline() -> DegradedStateBanner {
        DegradedStateBanner(
            icon: "wifi.slash",
            message: "Offline — changes saved locally",
            color: .orange
        )
    }

    static func compassLowAccuracy(action: (() -> Void)? = nil) -> DegradedStateBanner {
        DegradedStateBanner(
            icon: "exclamationmark.circle",
            message: "Low compass accuracy",
            actionLabel: action != nil ? "Calibrate" : nil,
            action: action,
            color: .yellow
        )
    }

    static func syncPaused() -> DegradedStateBanner {
        DegradedStateBanner(
            icon: "icloud.slash",
            message: "Sync paused",
            color: .orange
        )
    }

    static func storageLow(action: (() -> Void)? = nil) -> DegradedStateBanner {
        DegradedStateBanner(
            icon: "externaldrive.badge.exclamationmark",
            message: "Storage low",
            actionLabel: action != nil ? "Manage" : nil,
            action: action,
            color: .red
        )
    }
}

// MARK: - Preview

#Preview("Degraded State Banners") {
    VStack(spacing: 12) {
        DegradedStateBanner.locationFallback(locationName: "London, UK")
        DegradedStateBanner.offline()
        DegradedStateBanner.compassLowAccuracy()
        DegradedStateBanner.syncPaused()
        DegradedStateBanner.storageLow()
    }
    .padding()
}
