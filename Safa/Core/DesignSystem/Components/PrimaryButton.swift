// MARK: - PrimaryButton.swift
// PURPOSE: Primary button component for main actions
// DEPENDENCIES: SwiftUI

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var fullWidth: Bool = true

    var body: some View {
        Button(action: {
            HapticFeedbackService.shared.play(.commit)
            action()
        }) {
            HStack(spacing: SafaSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(SafaTypography.titleMedium)
                }
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: SafaSpacing.ButtonHeight.md)
            .padding(.horizontal, SafaSpacing.lg)
            .background(isDisabled ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
        }
        .disabled(isLoading || isDisabled)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: SafaSpacing.md) {
        PrimaryButton(title: "Continue") {
            print("Tapped")
        }

        PrimaryButton(title: "Loading...", action: {}, isLoading: true)

        PrimaryButton(title: "Disabled", action: {}, isDisabled: true)

        PrimaryButton(title: "Compact", action: {}, fullWidth: false)
    }
    .padding()
}
