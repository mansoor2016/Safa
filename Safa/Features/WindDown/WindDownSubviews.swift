// MARK: - WindDownSubviews.swift
// PURPOSE: Supporting views for wind down feature
// DEPENDENCIES: SwiftUI, WindDownViewModel

import SwiftUI

// MARK: - Sleep Dhikr Row

struct SleepDhikrRow: View {
    let dhikr: SleepDhikr
    let isCompleted: Bool
    let onTap: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : .secondary)
            }

            Button {
                onTap()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(dhikr.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(isCompleted ? .secondary : .primary)
                            .strikethrough(isCompleted)

                        if dhikr.count > 1 {
                            Text("×\(dhikr.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.indigo)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.indigo.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    Text(dhikr.benefit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.forward")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Dhikr Detail Sheet

struct DhikrDetailSheet: View {
    let dhikr: SleepDhikr
    let viewModel: WindDownViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentCount: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    arabicSection
                    transliterationSection
                    translationSection
                    benefitSection
                    counterSection
                }
                .padding()
            }
            .navigationTitle(dhikr.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Subviews

    private var arabicSection: some View {
        Text(dhikr.arabic)
            .font(.system(size: 32, weight: .medium, design: .serif))
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var transliterationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transliteration")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(dhikr.transliteration)
                .font(.body)
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Translation")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(dhikr.translation)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var benefitSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(.indigo)

            Text(dhikr.benefit)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.indigo.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var counterSection: some View {
        if dhikr.count > 1 {
            VStack(spacing: 16) {
                Text("\(currentCount) / \(dhikr.count)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(currentCount >= dhikr.count ? .green : .primary)

                Button {
                    handleCountTap()
                } label: {
                    Text(currentCount >= dhikr.count ? "Completed" : "Tap to Count")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(currentCount >= dhikr.count ? Color.green : Color.indigo)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(currentCount >= dhikr.count)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            Button {
                viewModel.toggleDhikr(dhikr.id)
                dismiss()
            } label: {
                Text(viewModel.completedDhikr.contains(dhikr.id) ? "Mark Incomplete" : "Mark Complete")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.completedDhikr.contains(dhikr.id) ? Color.gray : Color.indigo)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func handleCountTap() {
        if currentCount < dhikr.count {
            currentCount += 1
            HapticFeedbackService.shared.play(.commit)
        }

        if currentCount >= dhikr.count {
            viewModel.toggleDhikr(dhikr.id)
        }
    }
}

// MARK: - Fajr Alarm Sheet

struct FajrAlarmSheet: View {
    let viewModel: WindDownViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTime: Date
    @State private var isEnabled: Bool

    init(viewModel: WindDownViewModel) {
        self.viewModel = viewModel
        _selectedTime = State(initialValue: viewModel.fajrAlarmTime)
        _isEnabled = State(initialValue: viewModel.fajrAlarmEnabled)
    }

    var body: some View {
        NavigationStack {
            Form {
                alarmToggleSection
                infoSection
                optionsSection
            }
            .navigationTitle("Fajr Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndDismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var alarmToggleSection: some View {
        Section {
            Toggle("Enable Fajr Alarm", isOn: $isEnabled)

            if isEnabled {
                DatePicker(
                    "Alarm Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }

    private var infoSection: some View {
        Section {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)

                Text("The alarm will be set based on Fajr prayer time for your location. You can adjust the offset if needed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var optionsSection: some View {
        Section("Alarm Options") {
            HStack {
                Text("Sound")
                Spacer()
                Text("Adhan")
                    .foregroundStyle(.secondary)
            }
            .disabledFeature(isDisabled: true, name: "Sound Selection")

            HStack {
                Text("Snooze")
                Spacer()
                Text("9 minutes")
                    .foregroundStyle(.secondary)
            }
            .disabledFeature(isDisabled: true, name: "Snooze Settings")
        }
    }

    private func saveAndDismiss() {
        viewModel.fajrAlarmEnabled = isEnabled
        viewModel.fajrAlarmTime = selectedTime
        dismiss()
    }
}
