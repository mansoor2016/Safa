// MARK: - MonthlyConsistencyCard.swift
// PURPOSE: Monthly prayer heatmap with average and streak badge
// DEPENDENCIES: SwiftUI, ProgressDashboardViewModel.DayPrayerCount

import SwiftUI

struct MonthlyConsistencyCard: View {
    let monthlyData: [ProgressDashboardViewModel.DayPrayerCount]
    let prayerStreak: Streak?
    let streakFreezes: Int
    let calendar: Calendar
    let now: Date

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: now)
    }

    private var startOfMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
    }

    private var weekdayOffset: Int {
        let firstDayWeekday = calendar.component(.weekday, from: startOfMonth)
        return firstDayWeekday - 1
    }

    var body: some View {
        TitledCard(title: "Prayer Consistency") {
            VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                headerBadges
                heatmapGrid
                legend
            }
        }
    }

    // MARK: - Header Badges

    @ViewBuilder
    private var headerBadges: some View {
        HStack(spacing: SafaSpacing.xs) {
            Text(monthTitle)
                .font(SafaTypography.bodySmall)
                .foregroundStyle(SafaColors.Fallback.secondaryText)

            Spacer()

            if let streak = prayerStreak, streak.currentCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame")
                        .font(.caption2)
                    Text("\(streak.currentCount)")
                        .font(SafaTypography.labelSmall)
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, SafaSpacing.xs)
                .padding(.vertical, SafaSpacing.xxs)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
            }

            if streakFreezes > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "snowflake")
                        .font(.caption2)
                    Text("\(streakFreezes)")
                        .font(SafaTypography.labelSmall)
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, SafaSpacing.xs)
                .padding(.vertical, SafaSpacing.xxs)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Heatmap Grid

    @ViewBuilder
    private var heatmapGrid: some View {
        let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
            ForEach(weekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .foregroundStyle(SafaColors.Fallback.secondaryText)
                    .frame(height: 20)
            }

            ForEach(0..<weekdayOffset, id: \.self) { _ in
                Color.clear.frame(height: 32)
            }

            ForEach(monthlyData) { day in
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorForCount(day.count))
                    .frame(height: 32)
            }
        }
    }

    // MARK: - Legend

    @ViewBuilder
    private var legend: some View {
        HStack(spacing: SafaSpacing.md) {
            ForEach(0...5, id: \.self) { count in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForCount(count))
                        .frame(width: 12, height: 12)
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundStyle(SafaColors.Fallback.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Helpers

    private func colorForCount(_ count: Int) -> Color {
        switch count {
        case 0: return Color(.systemGray5)
        case 1: return Color.green.opacity(0.2)
        case 2: return Color.green.opacity(0.4)
        case 3: return Color.green.opacity(0.6)
        case 4: return Color.green.opacity(0.8)
        case 5: return Color.green
        default: return Color.green
        }
    }
}
