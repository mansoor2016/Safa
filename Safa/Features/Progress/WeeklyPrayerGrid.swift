// MARK: - WeeklyPrayerGrid.swift
// PURPOSE: 7 days × 5 prayers matrix showing prayer status for the week
// DEPENDENCIES: SwiftUI, DayPrayerSummary, PrayerType

import SwiftUI

struct WeeklyPrayerGrid: View {
    let grid: [DayPrayerSummary]
    let calendar: Calendar

    var body: some View {
        TitledCard(title: "This Week") {
            VStack(spacing: SafaSpacing.xs) {
                headerRow
                prayerRows
            }
        }
    }

    // MARK: - Header Row (Day abbreviations)

    @ViewBuilder
    private var headerRow: some View {
        HStack(spacing: SafaSpacing.xxs) {
            // Row label spacer
            Text("")
                .frame(width: 28)

            ForEach(Array(grid.enumerated()), id: \.offset) { _, day in
                let isToday = calendar.isDateInToday(day.date)
                Text(dayAbbreviation(day.date))
                    .font(SafaTypography.labelSmall)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isToday ? SafaColors.Fallback.text : SafaColors.Fallback.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Prayer Rows

    @ViewBuilder
    private var prayerRows: some View {
        ForEach(PrayerType.obligatoryPrayers) { prayerType in
            HStack(spacing: SafaSpacing.xxs) {
                Text(prayerType.shortName)
                    .font(SafaTypography.labelSmall)
                    .foregroundStyle(SafaColors.Fallback.secondaryText)
                    .frame(width: 28, alignment: .leading)

                ForEach(grid) { day in
                    let status = day.prayers.first { $0.prayerType == prayerType }
                    gridCell(for: status, prayerType: prayerType)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    @ViewBuilder
    private func gridCell(for status: PrayerDayStatus?, prayerType: PrayerType) -> some View {
        let size: CGFloat = 28

        Group {
            if let status, status.isLogged {
                RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.sm)
                    .fill(status.isOnTime ? prayerType.color : prayerType.color.opacity(0.6))
                    .overlay {
                        Image(systemName: status.isOnTime ? "checkmark" : "clock")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
            } else if let status, status.isMissed {
                RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.sm)
                    .fill(prayerType.color.opacity(0.15))
                    .overlay {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(prayerType.color.opacity(0.5))
                    }
            } else {
                RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.sm)
                    .fill(Color(.systemGray5))
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Helpers

    private func dayAbbreviation(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.calendar = calendar
        return String(formatter.string(from: date).prefix(3))
    }
}
