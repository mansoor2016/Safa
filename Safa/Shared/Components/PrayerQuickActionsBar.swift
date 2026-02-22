// MARK: - PrayerQuickActionsBar.swift
// PURPOSE: Shared Qibla + Adhan quick action buttons used on Prayer and Ramadan pages
// DEPENDENCIES: QuickActionButton, AdhanPlayButton

import SwiftUI

struct PrayerQuickActionsBar: View {
    var isFajr: Bool = false
    var onQibla: () -> Void

    var body: some View {
        HStack(spacing: SafaSpacing.md) {
            QuickActionButton(
                icon: "location.north.fill",
                title: "Qibla",
                action: onQibla
            )

            AdhanPlayButton(style: .quickAction, isFajr: isFajr)
        }
    }
}
