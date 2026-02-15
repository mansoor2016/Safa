// MARK: - PrayerTimePreviewCard.swift
// PURPOSE: Compact read-only preview of today's prayer times for a given method/madhab
// DEPENDENCIES: SwiftUI, PrayerTimeCalculator

import SwiftUI

struct PrayerTimePreviewCard: View {
    let method: CalculationMethod
    let madhab: Madhab
    let location: Coordinates
    let date: Date

    private let calculator = PrayerTimeCalculator()

    private var prayers: [PrayerTime] {
        calculator.calculatePrayerTimes(
            for: date,
            location: location,
            method: method,
            madhab: madhab
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.sm) {
            Text("Today's Prayer Times")
                .font(SafaTypography.labelMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            let leftColumn = prayers.filter { [.fajr, .sunrise, .dhuhr].contains($0.type) }
            let rightColumn = prayers.filter { [.asr, .maghrib, .isha].contains($0.type) }

            HStack(alignment: .top, spacing: SafaSpacing.lg) {
                VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                    ForEach(leftColumn) { prayer in
                        prayerRow(prayer)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                    ForEach(rightColumn) { prayer in
                        prayerRow(prayer)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(SafaSpacing.md)
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
    }

    private func prayerRow(_ prayer: PrayerTime) -> some View {
        HStack(spacing: SafaSpacing.xs) {
            Text(prayer.type.displayName)
                .font(SafaTypography.bodySmall)
                .foregroundColor(SafaColors.Fallback.secondaryText)
                .frame(width: 56, alignment: .leading)

            Text(prayer.time.formatted(date: .omitted, time: .shortened))
                .font(SafaTypography.bodySmall)
                .foregroundColor(SafaColors.Fallback.text)
                .monospacedDigit()
        }
    }
}
