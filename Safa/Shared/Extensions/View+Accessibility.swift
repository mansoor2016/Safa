// MARK: - View+Accessibility.swift
// PURPOSE: Reusable accessibility modifiers for VoiceOver, Dynamic Type, and Arabic text
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Accessibility Modifiers

extension View {
    /// Groups child elements and provides a combined label for VoiceOver.
    @ViewBuilder
    func accessibilityGrouped(label: String, hint: String? = nil) -> some View {
        if let hint {
            self
                .accessibilityElement(children: .combine)
                .accessibilityLabel(label)
                .accessibilityHint(hint)
        } else {
            self
                .accessibilityElement(children: .combine)
                .accessibilityLabel(label)
        }
    }

    /// Announces a progress value to VoiceOver (e.g., "3 of 5 prayers completed").
    func accessibilityProgress(label: String, current: Int, total: Int) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue("\(current) of \(total)")
    }

    /// Labels an icon-only button for VoiceOver.
    @ViewBuilder
    func accessibilityIconButton(label: String, hint: String? = nil) -> some View {
        if let hint {
            self
                .accessibilityLabel(label)
                .accessibilityHint(hint)
        } else {
            self
                .accessibilityLabel(label)
        }
    }

    /// Marks content as Arabic for correct VoiceOver pronunciation.
    func accessibilityArabic(label: String? = nil) -> some View {
        var view = AnyView(self)
        if let label {
            view = AnyView(view.accessibilityLabel(label))
        }
        return view
    }
}

// MARK: - Testable Label Builders

/// Builds an accessibility label for an ayah row.
func formatAyahAccessibilityLabel(surahName: String, ayahNumber: Int, translation: String?) -> String {
    var label = "Surah \(surahName), Ayah \(ayahNumber)"
    if let translation = translation, !translation.isEmpty {
        label += ". \(translation)"
    }
    return label
}

/// Builds an accessibility label for a prayer progress dot.
func formatPrayerDotAccessibilityLabel(prayerName: String, isLogged: Bool, isNext: Bool, isPast: Bool) -> String {
    let state: String
    if isLogged {
        state = "completed"
    } else if isNext {
        state = "next"
    } else if isPast {
        state = "missed"
    } else {
        state = "upcoming"
    }
    return "\(prayerName), \(state)"
}

/// Builds an accessibility label for a dhikr item.
func formatDhikrAccessibilityLabel(name: String, count: Int, isCompleted: Bool) -> String {
    let status = isCompleted ? ", completed" : ""
    return "\(name), \(count) times\(status)"
}

/// Builds an accessibility label for a daily goal row.
func formatGoalAccessibilityLabel(title: String, isCompleted: Bool) -> String {
    "\(title), \(isCompleted ? "completed" : "not completed")"
}
