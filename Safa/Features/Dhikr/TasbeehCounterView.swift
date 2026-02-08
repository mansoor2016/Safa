// MARK: - TasbeehCounterView.swift
// PURPOSE: Tasbeeh counter with haptic feedback
// DEPENDENCIES: SwiftUI

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

                VStack(spacing: SafaSpacing.xl) {
                    Spacer()

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

                    Spacer()

                    // Counter display
                    counterDisplay

                    Spacer()

                    // Counter button
                    counterButton

                    Spacer()

                    // Controls
                    controlsRow
                }
                .padding()
            }
            .navigationTitle(dhikr.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                targetSettingsSheet
            }
            .alert("Complete!", isPresented: $isComplete) {
                Button("Continue") {
                    // Reset for another round
                    count = 0
                }
                Button("Done") {
                    saveAndDismiss()
                }
            } message: {
                Text("You've completed \(targetCount) \(dhikr.rawValue)!")
            }
        }
    }

    // MARK: - Counter Display

    private var counterDisplay: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                .frame(width: 250, height: 250)
                .accessibilityHidden(true)

            Circle()
                .trim(from: 0, to: min(Double(count) / Double(targetCount), 1.0))
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 250, height: 250)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: count)
                .accessibilityHidden(true)

            // Count display
            VStack(spacing: SafaSpacing.xs) {
                Text("\(count)")
                    .font(SafaTypography.counterLarge)
                    .foregroundColor(SafaColors.Fallback.text)
                    .contentTransition(.numericText())

                Text("of \(targetCount)")
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(counterAccessibilityLabel)
        .accessibilityValue("\(count) of \(targetCount)")
    }

    private var counterAccessibilityLabel: String {
        let percentage = Int((Double(count) / Double(targetCount)) * 100)
        if count == 0 {
            return "\(dhikr.rawValue) counter, \(targetCount) remaining"
        } else if count >= targetCount {
            return "\(dhikr.rawValue) counter complete, \(count) repetitions"
        } else {
            return "\(dhikr.rawValue) counter, \(count) of \(targetCount), \(percentage) percent complete"
        }
    }

    // MARK: - Counter Button

    private var counterButton: some View {
        Button {
            incrementCount()
        } label: {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                )
                .shadow(color: Color.accentColor.opacity(0.3), radius: 10, y: 5)
        }
        .buttonStyle(CounterButtonStyle())
        .accessibilityLabel("Increment counter")
        .accessibilityHint("Double tap to count one \(dhikr.rawValue)")
        .accessibilityValue("\(count)")
    }

    // MARK: - Controls Row

    private var controlsRow: some View {
        HStack(spacing: SafaSpacing.xl) {
            // Reset button
            Button {
                withAnimation {
                    count = 0
                }
                HapticFeedbackService.shared.play(.commit)
            } label: {
                VStack(spacing: SafaSpacing.xxs) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                    Text("Reset")
                        .font(SafaTypography.labelSmall)
                }
                .foregroundColor(SafaColors.Fallback.secondaryText)
            }
            .accessibilityLabel("Reset counter")
            .accessibilityHint("Double tap to reset the counter to zero")

            // Minus button
            Button {
                if count > 0 {
                    withAnimation {
                        count -= 1
                    }
                    HapticFeedbackService.shared.play(.tap)
                }
            } label: {
                VStack(spacing: SafaSpacing.xxs) {
                    Image(systemName: "minus.circle")
                        .font(.title2)
                    Text("Undo")
                        .font(SafaTypography.labelSmall)
                }
                .foregroundColor(SafaColors.Fallback.secondaryText)
            }
            .disabled(count == 0)
            .accessibilityLabel("Undo last count")
            .accessibilityHint("Double tap to subtract one from the counter")
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
                    Button("Done") {
                        showSettings = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Methods

    private func incrementCount() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            count += 1
        }

        // Haptic feedback
        HapticFeedbackService.shared.play(.tasbeehTap)

        // Check for completion
        if count >= targetCount {
            HapticFeedbackService.shared.play(.tasbeehMilestone)
            isComplete = true
        }
    }

    private func saveAndDismiss() {
        // Award Hasanat if target reached
        if count >= targetCount {
            Task {
                await dependencies.userState.awardHasanat(.tasbeehSession)
            }
        }
        dismiss()
    }
}

// MARK: - Counter Button Style

private struct CounterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    TasbeehCounterView(dhikr: .subhanAllah)
        .environment(Dependencies())
}
