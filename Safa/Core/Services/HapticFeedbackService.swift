// MARK: - HapticFeedbackService.swift
// PURPOSE: Centralized haptic feedback management
// DEPENDENCIES: UIKit, CoreHaptics

import UIKit
import CoreHaptics

// MARK: - Haptic Feedback Service

@Observable
final class HapticFeedbackService {

    // MARK: - Properties

    var isEnabled: Bool = true
    private var hapticEngine: CHHapticEngine?
    private let impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator]
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    // MARK: - Storage Keys

    private let enabledKey = "com.safa.haptics.enabled"

    // MARK: - Initialization

    init() {
        // Initialize impact generators for each style
        impactGenerators = [
            .light: UIImpactFeedbackGenerator(style: .light),
            .medium: UIImpactFeedbackGenerator(style: .medium),
            .heavy: UIImpactFeedbackGenerator(style: .heavy),
            .soft: UIImpactFeedbackGenerator(style: .soft),
            .rigid: UIImpactFeedbackGenerator(style: .rigid)
        ]

        loadSettings()
        prepareGenerators()
        initializeHapticEngine()
    }

    // MARK: - Settings

    func loadSettings() {
        isEnabled = UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: enabledKey)
    }

    // MARK: - Preparation

    private func prepareGenerators() {
        impactGenerators.values.forEach { $0.prepare() }
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    private func initializeHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            hapticEngine = try CHHapticEngine()
            hapticEngine?.isAutoShutdownEnabled = true
            try hapticEngine?.start()
        } catch {
            print("Haptic engine initialization failed: \(error)")
        }
    }

    // MARK: - Simple Haptics

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, intensity: CGFloat = 1.0) {
        guard isEnabled else { return }
        impactGenerators[style]?.impactOccurred(intensity: intensity)
    }

    func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(type)
    }

    // MARK: - App-Specific Haptics

    /// Haptic for prayer logging
    func prayerLogged() {
        guard isEnabled else { return }
        notification(.success)
    }

    /// Haptic for streak milestone
    func streakMilestone() {
        guard isEnabled else { return }
        playCustomPattern(.celebration)
    }

    /// Haptic for achievement unlocked
    func achievementUnlocked() {
        guard isEnabled else { return }
        playCustomPattern(.celebration)
    }

    /// Haptic for tasbeeh count
    func tasbeehTap() {
        guard isEnabled else { return }
        impact(.soft, intensity: 0.6)
    }

    /// Haptic for tasbeeh milestone (33, 99, etc.)
    func tasbeehMilestone() {
        guard isEnabled else { return }
        impact(.rigid, intensity: 1.0)
    }

    /// Haptic for button tap
    func buttonTap() {
        guard isEnabled else { return }
        impact(.light, intensity: 0.7)
    }

    /// Haptic for navigation
    func navigate() {
        guard isEnabled else { return }
        selection()
    }

    /// Haptic for error
    func error() {
        guard isEnabled else { return }
        notification(.error)
    }

    /// Haptic for warning
    func warning() {
        guard isEnabled else { return }
        notification(.warning)
    }

    /// Haptic for Qibla found
    func qiblaFound() {
        guard isEnabled else { return }
        playCustomPattern(.qiblaLock)
    }

    /// Haptic for level up
    func levelUp() {
        guard isEnabled else { return }
        playCustomPattern(.levelUp)
    }

    // MARK: - Custom Patterns

    enum HapticPattern {
        case celebration
        case qiblaLock
        case levelUp
        case completion
    }

    func playCustomPattern(_ pattern: HapticPattern) {
        guard isEnabled, let engine = hapticEngine else {
            // Fallback to basic haptics
            notification(.success)
            return
        }

        do {
            let hapticPattern = try createPattern(for: pattern)
            let player = try engine.makePlayer(with: hapticPattern)
            try engine.start()
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Fallback
            notification(.success)
        }
    }

    private func createPattern(for pattern: HapticPattern) throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []

        switch pattern {
        case .celebration:
            // Triple burst
            events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ], relativeTime: 0.1),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ], relativeTime: 0.2)
            ]

        case .qiblaLock:
            // Strong pulse followed by sustained vibration
            events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ], relativeTime: 0.1, duration: 0.3)
            ]

        case .levelUp:
            // Rising intensity pattern
            events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0.08),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ], relativeTime: 0.16)
            ]

        case .completion:
            // Satisfying completion tap
            events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ], relativeTime: 0)
            ]
        }

        return try CHHapticPattern(events: events, parameters: [])
    }
}

// MARK: - Singleton

extension HapticFeedbackService {
    static let shared = HapticFeedbackService()
}

// MARK: - SwiftUI View Modifier

import SwiftUI

struct HapticModifier: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    HapticFeedbackService.shared.impact(style)
                }
            }
    }
}

extension View {
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, trigger: Bool) -> some View {
        modifier(HapticModifier(style: style, trigger: trigger))
    }

    func hapticOnTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(TapGesture().onEnded { _ in
            HapticFeedbackService.shared.impact(style)
        })
    }
}
