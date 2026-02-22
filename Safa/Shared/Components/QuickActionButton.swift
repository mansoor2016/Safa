// MARK: - QuickActionButton.swift
// PURPOSE: Reusable quick action button used on Prayer and Ramadan pages
// DEPENDENCIES: SwiftUI

import SwiftUI

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedbackService.shared.play(.tap)
            action()
        }) {
            VStack(spacing: SafaSpacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(height: 28)

                Text(title)
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SafaSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
        }
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to open \(title)")
    }
}
