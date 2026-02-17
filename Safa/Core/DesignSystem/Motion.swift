// MARK: - Motion.swift
// PURPOSE: Centralized animation duration, curve, and spring tokens
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Duration Tokens

enum SafaMotion {

    // MARK: - Durations

    /// Micro interactions: button press, toggle, badge flip (100ms)
    static let durationFast: TimeInterval = 0.1

    /// Standard state changes: tab switch, card expand, content fade (250ms)
    static let durationNormal: TimeInterval = 0.25

    /// Deliberate transitions: sheet present, scroll reveal, hero morph (400ms)
    static let durationSlow: TimeInterval = 0.4

    /// Emphasis animations: onboarding, celebration (600ms)
    static let durationEmphasis: TimeInterval = 0.6

    // MARK: - Curves (SwiftUI Animation)

    /// Micro interactions — snappy, no overshoot
    static let curveFast: Animation = .easeInOut(duration: durationFast)

    /// Standard state changes — balanced ease
    static let curveNormal: Animation = .easeInOut(duration: durationNormal)

    /// Deliberate transitions — smooth deceleration
    static let curveSlow: Animation = .easeOut(duration: durationSlow)

    /// Emphasis — spring with slight bounce
    static let curveEmphasis: Animation = .spring(duration: durationEmphasis, bounce: 0.15)

    // MARK: - Spring Presets

    /// Tight spring for press feedback (stiff, no bounce)
    static let springPress: Animation = .spring(duration: 0.15, bounce: 0)

    /// Standard spring for interactive elements
    static let springInteractive: Animation = .spring(duration: 0.3, bounce: 0.1)

    /// Bouncy spring for celebrations and milestones
    static let springBouncy: Animation = .spring(duration: 0.5, bounce: 0.3)

    // MARK: - Convenience

    /// Default animation for most transitions (standard curve)
    static let `default`: Animation = curveNormal

    /// Respects Reduce Motion — returns nil animation when enabled
    static func respectingMotion(_ animation: Animation) -> Animation? {
        UIAccessibility.isReduceMotionEnabled ? nil : animation
    }
}
