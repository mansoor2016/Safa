// MARK: - PreEidBanner.swift
// PURPOSE: Countdown banner shown 7 days before each Eid with prep reminders
// DEPENDENCIES: SwiftUI, EidType

import SwiftUI

struct PreEidBanner: View {
    let eidType: EidType
    let daysUntil: Int
    let onDismiss: () -> Void

    private var isUrgent: Bool { daysUntil <= 3 }

    var body: some View {
        HStack(spacing: SafaSpacing.md) {
            Image(systemName: eidType.icon)
                .font(.title2)
                .foregroundColor(isUrgent ? .orange : .accentColor)

            VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                Text("\(eidType.localizedDisplayName) is coming!")
                    .font(SafaTypography.titleSmall)
                    .foregroundColor(SafaColors.Fallback.text)

                Text("\(daysUntil) day(s) until \(eidType.localizedDisplayName)")
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)

                if let firstReminder = eidType.reminders.first {
                    Text("Remember to \(firstReminder.localizedTitle.lowercased())")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(isUrgent ? .orange : SafaColors.Fallback.tertiaryText)
                }
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
        .padding(SafaSpacing.md)
        .background(isUrgent ? Color.orange.opacity(0.1) : Color.accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
    }
}

// MARK: - Preview

#Preview("Pre-Eid Banner") {
    VStack(spacing: SafaSpacing.md) {
        PreEidBanner(eidType: .fitr, daysUntil: 5, onDismiss: {})
        PreEidBanner(eidType: .adha, daysUntil: 2, onDismiss: {})
    }
    .padding()
}
