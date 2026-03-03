// MARK: - NotificationDeniedBanner.swift
// PURPOSE: Prominent banner shown when iOS notification permission is denied
// DEPENDENCIES: SwiftUI

import SwiftUI

struct NotificationDeniedBanner: View {
    var body: some View {
        HStack(spacing: SafaSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Notifications Disabled")
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(SafaColors.Fallback.text)

                Text("Enable in iOS Settings to receive prayer reminders")
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            Spacer()

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(SafaTypography.labelSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, SafaSpacing.sm)
                    .padding(.vertical, SafaSpacing.xs)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
    }
}
