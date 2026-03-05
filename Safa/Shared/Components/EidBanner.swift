// MARK: - EidBanner.swift
// PURPOSE: Rich Eid banner with type-aware visuals, reminders, and share action
// DEPENDENCIES: SwiftUI, EidType

import SwiftUI

struct EidBanner: View {
    let eidType: EidType
    let dayNumber: Int
    let eidPrayerTime: Date?
    let onShare: () -> Void
    let onDismiss: () -> Void

    @State private var completedReminders: Set<String> = []

    var body: some View {
        VStack(spacing: SafaSpacing.sm) {
            header
            acceptanceDua
            Divider().background(Color.white.opacity(0.2))
            reminders
            shareButton
        }
        .padding(SafaSpacing.md)
        .background(
            LinearGradient(
                colors: eidType.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
        .shadow(color: eidType.gradientColors.first?.opacity(0.3) ?? .clear, radius: 10, x: 0, y: 5)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: SafaSpacing.xs) {
                Image(systemName: eidType.icon)
                    .foregroundColor(.yellow)

                Text("Eid Mubarak!")
                    .font(SafaTypography.titleSmall)
                    .foregroundColor(.white)
            }

            Spacer()

            Text("Day \(dayNumber) of \(eidType.daysRange.count)")
                .font(SafaTypography.labelSmall)
                .foregroundColor(.white.opacity(0.8))

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(SafaSpacing.xxs)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Acceptance Dua

    private var acceptanceDua: some View {
        VStack(spacing: SafaSpacing.xxs) {
            Text(eidType.acceptanceDuaArabic)
                .font(SafaTypography.arabicMedium)
                .foregroundColor(.white.opacity(0.95))
                .environment(\.layoutDirection, .rightToLeft)
                .accessibilityArabic()

            Text(eidType.localizedAcceptanceDua)
                .font(SafaTypography.bodySmall)
                .foregroundColor(.white.opacity(0.8))
        }
    }

    // MARK: - Reminders

    private var reminders: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.xs) {
            Text("Reminders")
                .font(SafaTypography.labelSmall)
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)

            if let time = eidPrayerTime {
                HStack(spacing: SafaSpacing.xs) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))

                    Text("Eid Prayer: \(time.formatted(date: .omitted, time: .shortened))")
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(.white.opacity(0.9))

                    Spacer()
                }
            }

            ForEach(eidType.reminders) { reminder in
                let isCompleted = completedReminders.contains(reminder.title)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isCompleted {
                            completedReminders.remove(reminder.title)
                        } else {
                            completedReminders.insert(reminder.title)
                        }
                    }
                } label: {
                    HStack(spacing: SafaSpacing.xs) {
                        Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                            .font(.caption)
                            .foregroundColor(isCompleted ? .white : .white.opacity(0.8))

                        Text(reminder.localizedSubtitle)
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(.white.opacity(isCompleted ? 0.5 : 0.9))
                            .strikethrough(isCompleted, color: .white.opacity(0.5))
                            .lineLimit(2)

                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(reminder.localizedTitle), \(isCompleted ? String(localized: "completed") : String(localized: "not completed"))")
                .accessibilityHint(isCompleted ? String(localized: "Double tap to unmark") : String(localized: "Double tap to mark as done"))
            }
        }
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button(action: onShare) {
            HStack(spacing: SafaSpacing.xs) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                Text("Share Eid Greeting")
                    .font(SafaTypography.labelMedium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, SafaSpacing.md)
            .padding(.vertical, SafaSpacing.xs)
            .background(Color.white.opacity(0.2))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Eid Message Picker Sheet

struct EidMessagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let eidType: EidType
    let onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(eidType.shareMessages.enumerated()), id: \.offset) { _, message in
                    Button {
                        dismiss()
                        onSelect(message)
                    } label: {
                        Text(message)
                            .font(SafaTypography.bodySmall)
                            .foregroundColor(SafaColors.Fallback.text)
                            .padding(.vertical, SafaSpacing.xs)
                    }
                }
            }
            .navigationTitle("Choose a Greeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .compactSheet()
    }
}

// MARK: - Preview

#Preview("Eid al-Fitr Banner") {
    VStack(spacing: SafaSpacing.md) {
        EidBanner(
            eidType: .fitr,
            dayNumber: 1,
            eidPrayerTime: Date().addingTimeInterval(3600),
            onShare: {},
            onDismiss: {}
        )

        EidBanner(
            eidType: .adha,
            dayNumber: 2,
            eidPrayerTime: nil,
            onShare: {},
            onDismiss: {}
        )
    }
    .padding()
}
