// MARK: - DailyGoalsCard.swift
// PURPOSE: Shared daily goals checklist for Prayer and Ramadan pages
// DEPENDENCIES: SwiftUI

import SwiftUI

struct DailyGoalsCard: View {
    let isRamadan: Bool
    let loggedPrayers: Set<PrayerType>

    private var allPrayersLogged: Bool {
        PrayerType.obligatoryPrayers.allSatisfy { loggedPrayers.contains($0) }
    }

    var body: some View {
        TitledCard(title: "Daily Goals", subtitle: "Track your ibadah") {
            VStack(spacing: SafaSpacing.sm) {
                // Always shown
                DailyGoalRow(
                    icon: "checkmark.circle",
                    title: "5 Daily Prayers",
                    isCompleted: allPrayersLogged
                )

                DailyGoalRow(
                    icon: "book",
                    title: "Read Quran",
                    isCompleted: false // TODO: wire to actual reading progress
                )

                DailyGoalRow(
                    icon: "hands.sparkles",
                    title: "Morning Dhikr",
                    isCompleted: false // TODO: wire to dhikr completion
                )

                DailyGoalRow(
                    icon: "hands.sparkles",
                    title: "Evening Dhikr",
                    isCompleted: false // TODO: wire to dhikr completion
                )

                // Ramadan-only goals
                if isRamadan {
                    DailyGoalRow(
                        icon: "moon.stars",
                        title: "Taraweeh",
                        isCompleted: false
                    )

                    DailyGoalRow(
                        icon: "book.fill",
                        title: "Read 1 Juz",
                        isCompleted: false
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Non-Ramadan") {
    DailyGoalsCard(isRamadan: false, loggedPrayers: [.fajr, .dhuhr, .asr])
        .padding()
}

#Preview("Ramadan") {
    DailyGoalsCard(isRamadan: true, loggedPrayers: [.fajr, .dhuhr, .asr, .maghrib, .isha])
        .padding()
}
