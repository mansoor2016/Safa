// MARK: - TasbeehCounterView.swift
// PURPOSE: Tasbeeh counter with unified dial and card-based layout
// DEPENDENCIES: SwiftUI, TasbeehDial, TasbeehHelpers

import SwiftUI

struct TasbeehCounterView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    let dhikr: CommonDhikr

    @State private var count = 0
    @State private var targetCount: Int
    @State private var isComplete = false
    @State private var showSettings = false

    init(dhikr: CommonDhikr) {
        self.dhikr = dhikr
        _targetCount = State(initialValue: dhikr.defaultCount)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.1), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SafaSpacing.lg) {
                        // Hero card: Arabic text + dial
                        ContentCard {
                            VStack(spacing: SafaSpacing.md) {
                                // Dhikr text
                                VStack(spacing: SafaSpacing.sm) {
                                    Text(dhikr.arabic)
                                        .font(SafaTypography.arabicLarge)
                                        .foregroundColor(SafaColors.Fallback.text)
                                        .environment(\.layoutDirection, .rightToLeft)

                                    Text(dhikr.translation)
                                        .font(SafaTypography.bodyMedium)
                                        .foregroundColor(SafaColors.Fallback.secondaryText)
                                }

                                // Unified counter dial
                                TasbeehDial(
                                    count: count,
                                    target: targetCount,
                                    dhikrName: dhikr.rawValue,
                                    onTap: incrementCount
                                )
                            }
                        }

                        // Secondary card: controls
                        ContentCard {
                            VStack(spacing: SafaSpacing.md) {
                                // Target display
                                HStack {
                                    Text("Target")
                                        .font(SafaTypography.labelMedium)
                                        .foregroundColor(SafaColors.Fallback.secondaryText)

                                    Spacer()

                                    Button {
                                        showSettings = true
                                    } label: {
                                        HStack(spacing: SafaSpacing.xxs) {
                                            Text("\(targetCount)")
                                                .font(SafaTypography.titleSmall)
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.accentColor)
                                    }
                                }

                                Divider()

                                // Undo + Reset controls
                                HStack(spacing: SafaSpacing.xl) {
                                    Button {
                                        if count > 0 {
                                            withAnimation { count -= 1 }
                                            HapticFeedbackService.shared.play(.tap)
                                        }
                                    } label: {
                                        Label("Undo", systemImage: "minus.circle")
                                            .font(SafaTypography.bodyMedium)
                                            .foregroundColor(SafaColors.Fallback.secondaryText)
                                    }
                                    .disabled(count == 0)
                                    .accessibilityLabel("Undo last count")
                                    .accessibilityHint("Double tap to subtract one from the counter")

                                    Spacer()

                                    Button {
                                        withAnimation { count = 0 }
                                        HapticFeedbackService.shared.play(.commit)
                                    } label: {
                                        Label("Reset", systemImage: "arrow.counterclockwise")
                                            .font(SafaTypography.bodyMedium)
                                            .foregroundColor(SafaColors.Fallback.secondaryText)
                                    }
                                    .disabled(count == 0)
                                    .accessibilityLabel("Reset counter")
                                    .accessibilityHint("Double tap to reset the counter to zero")
                                }
                            }
                        }
                    }
                    .padding(SafaSpacing.md)
                }
            }
            .navigationTitle(dhikr.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { saveAndDismiss() }
                }
            }
            .sheet(isPresented: $showSettings) {
                targetSettingsSheet
            }
            .alert("Complete!", isPresented: $isComplete) {
                Button("Continue") { count = 0 }
                Button("Done") { saveAndDismiss() }
            } message: {
                Text("You've completed \(targetCount) \(dhikr.rawValue)!")
            }
        }
    }

    // MARK: - Target Settings Sheet

    private var targetSettingsSheet: some View {
        NavigationStack {
            List {
                Section("Target Count") {
                    ForEach([33, 34, 100, 1000], id: \.self) { target in
                        Button {
                            targetCount = target
                            showSettings = false
                        } label: {
                            HStack {
                                Text("\(target)")
                                Spacer()
                                if targetCount == target {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .foregroundColor(SafaColors.Fallback.text)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showSettings = false }
                }
            }
        }
        .compactSheet()
    }

    // MARK: - Methods

    private func incrementCount() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            count += 1
        }

        HapticFeedbackService.shared.play(.tasbeehTap)

        if TasbeehHelpers.isComplete(count: count, target: targetCount) {
            HapticFeedbackService.shared.play(.tasbeehMilestone)
            isComplete = true
        }
    }

    private func saveAndDismiss() {
        if TasbeehHelpers.isComplete(count: count, target: targetCount) {
            Task {
                await dependencies.userState.awardHasanat(.tasbeehSession)
            }
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    TasbeehCounterView(dhikr: .subhanAllah)
        .environment(Dependencies())
}
