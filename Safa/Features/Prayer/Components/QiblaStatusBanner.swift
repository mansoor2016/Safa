// MARK: - QiblaStatusBanner.swift
// PURPOSE: Priority-resolved single status banner for the Qibla compass
// DEPENDENCIES: SwiftUI, DegradedStateBanner, QiblaCompassHelpers

import SwiftUI

// MARK: - Status Enum

enum QiblaCompassStatus: Equatable {
    case permissionDenied
    case headingTimedOut
    case unreliable
    case lowAccuracy
    case simulated
    case normal

    /// Resolves the highest-priority status from current compass state.
    static func resolve(
        isPermissionDenied: Bool,
        headingTimedOut: Bool,
        accuracy: QiblaCompassHelpers.CompassAccuracy,
        isSimulated: Bool
    ) -> QiblaCompassStatus {
        if isPermissionDenied { return .permissionDenied }
        if headingTimedOut { return .headingTimedOut }
        if accuracy == .unreliable { return .unreliable }
        if accuracy == .low { return .lowAccuracy }
        if isSimulated { return .simulated }
        return .normal
    }
}

// MARK: - Banner View

struct QiblaStatusBanner: View {
    let status: QiblaCompassStatus
    var onOpenSettings: (() -> Void)?

    var body: some View {
        switch status {
        case .permissionDenied:
            VStack(spacing: SafaSpacing.xs) {
                DegradedStateBanner(
                    icon: "location.slash.fill",
                    message: "Compass needs location permission to determine heading.",
                    color: .red
                )
                if let onOpenSettings {
                    Button("Open Settings", action: onOpenSettings)
                        .font(SafaTypography.labelSmall)
                }
            }

        case .headingTimedOut:
            DegradedStateBanner(
                icon: "exclamationmark.triangle.fill",
                message: "No compass updates detected. Move your phone in a figure-8.",
                color: .red
            )

        case .unreliable:
            DegradedStateBanner(
                icon: "arrow.triangle.2.circlepath",
                message: "Move your device in a figure-8 to calibrate the compass",
                color: .orange
            )

        case .lowAccuracy:
            DegradedStateBanner.compassLowAccuracy()

        case .simulated:
            DegradedStateBanner(
                icon: "ant.fill",
                message: "Debug mode: magnetometer reading not available",
                color: .orange
            )

        case .normal:
            EmptyView()
        }
    }
}
