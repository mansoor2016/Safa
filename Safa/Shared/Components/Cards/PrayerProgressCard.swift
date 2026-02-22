// MARK: - PrayerProgressCard.swift
// PURPOSE: Shared prayer progress dots in a ContentCard, used on Prayer and Ramadan pages
// DEPENDENCIES: ContentCard, PrayerProgressIndicator

import SwiftUI

struct PrayerProgressCard: View {
    let prayers: [PrayerTime]
    let loggedPrayers: Set<PrayerType>
    let nextPrayer: PrayerTime?
    let onLogPrayer: (PrayerType) -> Void

    var body: some View {
        ContentCard {
            PrayerProgressIndicator(
                prayers: prayers,
                loggedPrayers: loggedPrayers,
                nextPrayer: nextPrayer,
                style: .expanded,
                onLogPrayer: onLogPrayer
            )
        }
    }
}
