// MARK: - TodayPrayerStatusCard.swift
// PURPOSE: Hero card showing today's 5 prayer statuses with distinct icons per state
// DEPENDENCIES: SwiftUI, PrayerDayStatus, PrayerType

import SwiftUI

struct TodayPrayerStatusCard: View {
    let statuses: [PrayerDayStatus]
    let scheduleAvailable: Bool

    private var loggedCount: Int {
        statuses.filter(\.isLogged).count
    }

    var body: some View {
        ContentCard {
            VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                header
                prayerColumns
                if !scheduleAvailable {
                    locationHint
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack {
            Text("Today")
                .font(SafaTypography.titleMedium)
                .foregroundStyle(SafaColors.Fallback.text)

            Spacer()

            Text("\(loggedCount)/5")
                .font(SafaTypography.labelMedium)
                .foregroundStyle(SafaColors.Fallback.secondaryText)
        }
    }

    // MARK: - Prayer Columns

    @ViewBuilder
    private var prayerColumns: some View {
        HStack(spacing: 0) {
            ForEach(statuses) { status in
                prayerColumn(status)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func prayerColumn(_ status: PrayerDayStatus) -> some View {
        VStack(spacing: SafaSpacing.xs) {
            Image(systemName: status.prayerType.iconName)
                .font(.system(size: SafaSpacing.IconSize.sm))
                .foregroundStyle(status.prayerType.color)

            Text(status.prayerType.shortName)
                .font(SafaTypography.labelSmall)
                .foregroundStyle(SafaColors.Fallback.secondaryText)

            statusIcon(for: status)
        }
    }

    @ViewBuilder
    private func statusIcon(for status: PrayerDayStatus) -> some View {
        let (icon, color) = statusIconInfo(for: status)
        Image(systemName: icon)
            .font(.system(size: SafaSpacing.IconSize.md))
            .foregroundStyle(color)
    }

    // MARK: - Location Hint

    @ViewBuilder
    private var locationHint: some View {
        HStack(spacing: SafaSpacing.xxs) {
            Image(systemName: "location.slash")
                .font(.caption2)
            Text("Enable location for full status")
                .font(SafaTypography.bodySmall)
        }
        .foregroundStyle(SafaColors.Fallback.tertiaryText)
    }

    // MARK: - Helpers

    private func statusIconInfo(for status: PrayerDayStatus) -> (icon: String, color: Color) {
        if status.isLogged {
            if status.isMakeup {
                return ("arrow.uturn.backward.circle", .blue)
            } else if status.isOnTime {
                return ("checkmark.circle.fill", SafaColors.success)
            } else {
                return ("checkmark.circle", SafaColors.warning)
            }
        } else if !scheduleAvailable {
            return ("questionmark.circle", Color(.systemGray3))
        } else if status.isMissed {
            return ("minus.circle", .orange)
        } else {
            return ("circle", Color(.systemGray3))
        }
    }

    private var accessibilityDescription: String {
        var parts = ["Today's prayers, \(loggedCount) of 5 completed."]
        for status in statuses {
            let name = status.prayerType.displayName
            if status.isLogged {
                if status.isOnTime {
                    parts.append("\(name): logged on time.")
                } else if status.isMakeup {
                    parts.append("\(name): makeup prayer.")
                } else {
                    parts.append("\(name): logged late.")
                }
            } else if status.isMissed {
                parts.append("\(name): missed.")
            } else {
                parts.append("\(name): upcoming.")
            }
        }
        return parts.joined(separator: " ")
    }
}
