// MARK: - RamadanSubviews.swift
// PURPOSE: Supporting views for Ramadan feature
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Fasting Day Cell

struct FastingDayCell: View {
    let day: Int
    let isFasted: Bool
    let isToday: Bool
    let isPast: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)

                if isFasted {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text("\(day)")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(textColor)
                }
            }
        }
        .disabled(!isPast && !isToday)
    }

    private var backgroundColor: Color {
        if isFasted {
            return .green
        } else if isToday {
            return Color.accentColor.opacity(0.2)
        } else if isPast {
            return Color.red.opacity(0.2)
        } else {
            return Color.gray.opacity(0.1)
        }
    }

    private var textColor: Color {
        if isToday {
            return .accentColor
        } else if isPast && !isFasted {
            return .red
        } else {
            return SafaColors.Fallback.secondaryText
        }
    }
}

// MARK: - Ramadan Quick Action

struct RamadanQuickAction: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text(title)
                        .font(SafaTypography.bodyMedium)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text(subtitle)
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SafaSpacing.md)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
        }
    }
}

// MARK: - Daily Goal Row

struct DailyGoalRow: View {
    let icon: String
    let title: String
    let isCompleted: Bool
    var isEnabled: Bool = true
    var onToggle: (() -> Void)? = nil

    var body: some View {
        Button {
            HapticFeedbackService.shared.play(isCompleted ? .tap : .commit)
            onToggle?()
        } label: {
            HStack {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : SafaColors.Fallback.tertiaryText)
                    .frame(width: 24)

                Text(title)
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(isCompleted ? .green : SafaColors.Fallback.text)

                Spacer()

                if isCompleted {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .font(.caption)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }
            }
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.2), value: isCompleted)
        }
        .buttonStyle(.plain)
        .disabled(onToggle == nil || !isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(formatGoalAccessibilityLabel(title: title, isCompleted: isCompleted))
        .accessibilityHint(
            !isEnabled ? "Available after Asr prayer" :
            onToggle != nil ? (isCompleted ? "Double tap to undo" : "Double tap to complete") : ""
        )
    }
}

// MARK: - Taraweeh Tracker Sheet

struct TaraweehTrackerSheet: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var rakahsPrayed = 8

    var body: some View {
        NavigationStack {
            VStack(spacing: SafaSpacing.xl) {
                Spacer()

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)

                Text("Taraweeh Tonight")
                    .font(SafaTypography.headlineMedium)

                rakahsCounter

                Spacer()

                saveButton
            }
            .padding()
            .navigationTitle("Taraweeh")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .compactSheet()
    }

    // MARK: - Subviews

    private var rakahsCounter: some View {
        VStack(spacing: SafaSpacing.sm) {
            Text("Rak'ahs Prayed")
                .font(SafaTypography.labelMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            HStack(spacing: SafaSpacing.lg) {
                Button {
                    if rakahsPrayed > 0 { rakahsPrayed -= 2 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.accentColor)
                }

                Text("\(rakahsPrayed)")
                    .font(SafaTypography.counterLarge)
                    .frame(width: 80)
                    .contentTransition(.numericText())

                Button {
                    if rakahsPrayed < 20 { rakahsPrayed += 2 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.accentColor)
                }
            }

            Text("Common: 8 or 20 rak'ahs")
                .font(SafaTypography.labelSmall)
                .foregroundColor(SafaColors.Fallback.tertiaryText)
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                await HasanatTracker.awardOnce(.taraweeh, key: "taraweeh", via: dependencies.userState)
            }
            dismiss()
        } label: {
            Text("Save")
                .font(SafaTypography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
        }
    }
}

// MARK: - Ramadan Settings Sheet

struct RamadanSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var healthSyncEnabled: Bool
    let healthKitService: HealthKitService

    @State private var isRequestingAuthorization = false

    var body: some View {
        NavigationStack {
            List {
                healthSection
                notificationsSection
            }
            .navigationTitle("Ramadan Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .fullSheet()
    }

    // MARK: - Sections

    private var healthSection: some View {
        Section {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sync to Apple Health")
                    Text("Coming soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .opacity(0.5)
        } header: {
            Text("Apple Health")
        } footer: {
            Text("Fasting hours will be logged to Apple Health in a future update.")
        }
    }

    private var healthToggle: some View {
        Toggle(isOn: $healthSyncEnabled) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sync to Apple Health")
                    Text("Log fasting hours automatically")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onChange(of: healthSyncEnabled) { _, newValue in
            handleHealthSyncToggle(newValue)
        }
        .disabled(isRequestingAuthorization)
    }

    @ViewBuilder
    private var healthStats: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.orange)
            Text("Total fasting hours")
            Spacer()
            Text(String(format: "%.1f hrs", healthKitService.getTotalFastingHours()))
                .foregroundColor(.secondary)
        }

        HStack {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.green)
            Text("Ramadan fasts logged")
            Spacer()
            Text("\(healthKitService.getRamadanFastCount())")
                .foregroundColor(.secondary)
        }
    }

    private var healthUnavailable: some View {
        HStack {
            Image(systemName: "heart.slash")
                .foregroundColor(.gray)
            Text("Apple Health not available on this device")
                .foregroundColor(.secondary)
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Suhoor Reminder", isOn: .constant(true))
            Toggle("Iftar Reminder", isOn: .constant(true))
        }
    }

    private func handleHealthSyncToggle(_ newValue: Bool) {
        Task {
            if newValue {
                isRequestingAuthorization = true
                let authorized = await healthKitService.requestAuthorization()
                isRequestingAuthorization = false
                if !authorized {
                    healthSyncEnabled = false
                } else {
                    healthKitService.syncEnabled = true
                }
            } else {
                healthKitService.syncEnabled = false
            }
        }
    }
}
