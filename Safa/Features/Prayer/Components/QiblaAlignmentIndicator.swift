// MARK: - QiblaAlignmentIndicator.swift
// PURPOSE: Pill badge showing alignment zone (perfect, close, near, far)
// DEPENDENCIES: SwiftUI, QiblaCompassHelpers

import SwiftUI

struct QiblaAlignmentIndicator: View {
    let qiblaDirection: Double
    let deviceHeading: Double

    private var zone: QiblaCompassHelpers.AlignmentZone {
        let relativeAngle = QiblaCompassHelpers.relativeAngle(
            qiblaDirection: qiblaDirection,
            deviceHeading: deviceHeading
        )
        return QiblaCompassHelpers.AlignmentZone.from(angle: relativeAngle)
    }

    var body: some View {
        HStack(spacing: SafaSpacing.xs) {
            if zone == .perfect {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }

            Text(statusText)
                .font(SafaTypography.bodyMedium)
                .foregroundColor(zone == .perfect ? .green : SafaColors.Fallback.secondaryText)
        }
        .padding(.horizontal, SafaSpacing.md)
        .padding(.vertical, SafaSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.sm)
                .fill(zone == .perfect ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
        )
        .accessibilityLabel(statusText)
    }

    private var statusText: String {
        switch zone {
        case .perfect: return "Facing Qibla"
        case .close: return "Almost there"
        case .near: return "Getting closer"
        case .far: return "Keep turning"
        }
    }
}
