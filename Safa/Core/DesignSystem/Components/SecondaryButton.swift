// MARK: - SecondaryButton.swift
// PURPOSE: Secondary button component for alternative actions
// DEPENDENCIES: SwiftUI

import SwiftUI

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var fullWidth: Bool = true

    var body: some View {
        Button(action: {
            HapticFeedbackService.shared.play(.tap)
            action()
        }) {
            HStack(spacing: SafaSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(SafaTypography.titleMedium)
                }
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: SafaSpacing.ButtonHeight.md)
            .padding(.horizontal, SafaSpacing.lg)
            .background(Color.clear)
            .foregroundColor(isDisabled ? .gray : .accentColor)
            .overlay(
                RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg)
                    .stroke(isDisabled ? Color.gray : Color.accentColor, lineWidth: 2)
            )
        }
        .disabled(isLoading || isDisabled)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: SafaSpacing.md) {
        SecondaryButton(title: "Skip") {
            print("Tapped")
        }

        SecondaryButton(title: "Loading...", action: {}, isLoading: true)

        SecondaryButton(title: "Disabled", action: {}, isDisabled: true)

        SecondaryButton(title: "Compact", action: {}, fullWidth: false)
    }
    .padding()
}
