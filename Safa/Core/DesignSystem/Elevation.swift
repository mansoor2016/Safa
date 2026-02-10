// MARK: - Elevation.swift
// PURPOSE: Semantic elevation and surface tokens for cards and containers
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Elevation Levels

enum SafaElevation {
    /// Flat surface — no shadow, no lift (e.g., list row, inline content)
    case none
    /// Low elevation — subtle lift for cards resting on a surface
    case low
    /// Medium elevation — standard card elevation (default for ContentCard)
    case medium
    /// High elevation — floating overlays, popovers, auto-scroll control
    case high

    var shadowColor: Color {
        switch self {
        case .none: return .clear
        case .low: return .black.opacity(0.05)
        case .medium: return .black.opacity(0.08)
        case .high: return .black.opacity(0.12)
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .none: return 0
        case .low: return 4
        case .medium: return 8
        case .high: return 16
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .none: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 4
        }
    }
}

// MARK: - Surface Tokens

enum SafaSurface {
    /// Primary background (root-level screen)
    case primary
    /// Secondary background (cards, grouped content)
    case secondary
    /// Tertiary background (nested cards, badges, summary blocks)
    case tertiary

    var color: Color {
        switch self {
        case .primary: return Color(UIColor.systemBackground)
        case .secondary: return Color(UIColor.secondarySystemBackground)
        case .tertiary: return Color(UIColor.tertiarySystemBackground)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply semantic elevation shadow
    func elevation(_ level: SafaElevation) -> some View {
        shadow(
            color: level.shadowColor,
            radius: level.shadowRadius,
            x: 0,
            y: level.shadowY
        )
    }

    /// Apply surface background with corner radius and elevation
    func surfaceCard(
        surface: SafaSurface = .secondary,
        cornerRadius: CGFloat = SafaSpacing.CornerRadius.lg,
        elevation: SafaElevation = .medium
    ) -> some View {
        self
            .background(surface.color)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .elevation(elevation)
    }
}
