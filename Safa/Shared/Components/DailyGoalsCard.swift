// MARK: - DailyGoalsCard.swift
// PURPOSE: Shared daily goals checklist for Prayer and Ramadan pages
// DEPENDENCIES: SwiftUI

import SwiftUI

struct DailyGoalsCard: View {
    let isRamadan: Bool
    let loggedPrayers: Set<PrayerType>

    // Manually toggleable goals (persisted per day via UserDefaults)
    @State private var completedGoals: Set<String> = []

    private var allPrayersLogged: Bool {
        PrayerType.obligatoryPrayers.allSatisfy { loggedPrayers.contains($0) }
    }

    private var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "dailyGoals_\(formatter.string(from: Date()))"
    }

    var body: some View {
        TitledCard(title: "Daily Goals", subtitle: "Track your ibadah") {
            VStack(spacing: SafaSpacing.sm) {
                // Prayer goal — auto-tracked from logged prayers
                DailyGoalRow(
                    icon: "checkmark.circle",
                    title: "5 Daily Prayers",
                    isCompleted: allPrayersLogged
                )

                // Manually toggleable goals
                goalRow("quran", icon: "book", title: "Read Quran")
                goalRow("morning_dhikr", icon: "hands.sparkles", title: "Morning Dhikr")
                goalRow("evening_dhikr", icon: "hands.sparkles", title: "Evening Dhikr")

                // Ramadan-only goals
                if isRamadan {
                    goalRow("taraweeh", icon: "moon.stars", title: "Taraweeh")
                    goalRow("juz", icon: "book.fill", title: "Read 1 Juz")
                }
            }
        }
        .onAppear { loadGoals() }
    }

    // MARK: - Goal Row Helper

    private func goalRow(_ id: String, icon: String, title: String) -> some View {
        DailyGoalRow(
            icon: icon,
            title: title,
            isCompleted: completedGoals.contains(id),
            onToggle: { toggleGoal(id) }
        )
    }

    // MARK: - Toggle + Persist

    private func toggleGoal(_ id: String) {
        withAnimation {
            if completedGoals.contains(id) {
                completedGoals.remove(id)
            } else {
                completedGoals.insert(id)
            }
        }
        saveGoals()
    }

    private func loadGoals() {
        let saved = UserDefaults.standard.stringArray(forKey: dateKey) ?? []
        completedGoals = Set(saved)
    }

    private func saveGoals() {
        UserDefaults.standard.set(Array(completedGoals), forKey: dateKey)
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
