// MARK: - ProgressStatsFooter.swift
// PURPOSE: Compact stats footer showing level, hasanat, and activity counts
// DEPENDENCIES: SwiftUI, UserStats, CircularProgressRing

import SwiftUI

struct ProgressStatsFooter: View {
    let userStats: UserStats
    let levelProgress: Double
    let hasanatToNextLevel: Int

    var body: some View {
        ContentCard {
            VStack(spacing: SafaSpacing.md) {
                levelRow
                statsGrid
            }
        }
    }

    // MARK: - Level Row

    @ViewBuilder
    private var levelRow: some View {
        HStack(spacing: SafaSpacing.sm) {
            CircularProgressRing(
                progress: levelProgress,
                size: 44,
                lineWidth: 4
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Level \(userStats.currentLevel) — \(UserStats.levelTitle(for: userStats.currentLevel))")
                    .font(SafaTypography.labelMedium)
                    .foregroundStyle(SafaColors.Fallback.text)

                Text("\(userStats.totalHasanat) Hasanat")
                    .font(SafaTypography.bodySmall)
                    .foregroundStyle(SafaColors.Fallback.secondaryText)
            }

            Spacer()

            if userStats.currentLevel < UserStats.maxLevel {
                Text("\(hasanatToNextLevel) to next")
                    .font(SafaTypography.labelSmall)
                    .foregroundStyle(SafaColors.Fallback.tertiaryText)
            } else {
                Text("Max Level")
                    .font(SafaTypography.labelSmall)
                    .foregroundStyle(SafaColors.Fallback.tertiaryText)
            }
        }
    }

    // MARK: - Stats Grid

    @ViewBuilder
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SafaSpacing.xs) {
            statItem(icon: "moon.stars", value: "\(userStats.totalPrayersLogged)", label: "Prayers", color: .blue)
            statItem(icon: "book", value: "\(userStats.totalAyahsRead)", label: "Ayahs", color: .green)
            statItem(icon: "graduationcap", value: "\(userStats.lessonsCompleted)", label: "Lessons", color: .purple)
            statItem(icon: "circle.circle", value: formatNumber(userStats.totalTasbeehCount), label: "Tasbeeh", color: .orange)
        }
    }

    @ViewBuilder
    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: SafaSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: SafaSpacing.IconSize.sm))
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(SafaTypography.labelMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(SafaColors.Fallback.text)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(SafaColors.Fallback.secondaryText)
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }
}
