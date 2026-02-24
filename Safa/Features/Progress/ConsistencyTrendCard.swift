// MARK: - ConsistencyTrendCard.swift
// PURPOSE: Shows this week vs last week prayer consistency trend with delta
// DEPENDENCIES: SwiftUI, ConsistencyTrend

import SwiftUI

struct ConsistencyTrendCard: View {
    let trend: ConsistencyTrend

    var body: some View {
        ContentCard {
            VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                HStack(alignment: .top) {
                    rateSection
                    Spacer()
                    onTimeSection
                }

                footer
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Rate Section

    @ViewBuilder
    private var rateSection: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: SafaSpacing.xs) {
                Text("\(Int(trend.thisWeekRate * 100))%")
                    .font(SafaTypography.displaySmall)
                    .fontWeight(.bold)
                    .foregroundStyle(SafaColors.Fallback.text)

                if trend.hasBaseline {
                    deltaIndicator
                }
            }

            if trend.hasBaseline {
                Text("vs last week")
                    .font(SafaTypography.bodySmall)
                    .foregroundStyle(SafaColors.Fallback.secondaryText)
            } else {
                Text("First week — keep going!")
                    .font(SafaTypography.bodySmall)
                    .foregroundStyle(SafaColors.Fallback.secondaryText)
            }
        }
    }

    @ViewBuilder
    private var deltaIndicator: some View {
        let delta = trend.delta
        let deltaPercent = Int(abs(delta) * 100)

        HStack(spacing: 2) {
            if abs(delta) <= 0.05 {
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(SafaColors.Fallback.secondaryText)
            } else if delta > 0 {
                Image(systemName: "arrow.up")
                    .font(.caption)
                Text("\(deltaPercent)%")
                    .font(SafaTypography.labelSmall)
            } else {
                Image(systemName: "arrow.down")
                    .font(.caption)
                Text("\(deltaPercent)%")
                    .font(SafaTypography.labelSmall)
            }
        }
        .foregroundStyle(deltaColor)
    }

    // MARK: - On-Time Section

    @ViewBuilder
    private var onTimeSection: some View {
        VStack(alignment: .trailing, spacing: SafaSpacing.xxs) {
            Text("\(Int(trend.onTimeRate * 100))%")
                .font(SafaTypography.titleMedium)
                .fontWeight(.semibold)
                .foregroundStyle(SafaColors.Fallback.text)

            Text("on time")
                .font(SafaTypography.bodySmall)
                .foregroundStyle(SafaColors.Fallback.secondaryText)
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        Text("\(trend.thisWeekLogged)/\(trend.thisWeekOpportunities) prayers this week")
            .font(SafaTypography.bodySmall)
            .foregroundStyle(SafaColors.Fallback.tertiaryText)
    }

    // MARK: - Helpers

    private var deltaColor: Color {
        let delta = trend.delta
        if abs(delta) <= 0.05 { return SafaColors.Fallback.secondaryText }
        return delta > 0 ? SafaColors.success : .orange
    }

    private var accessibilityDescription: String {
        var parts = ["This week: \(Int(trend.thisWeekRate * 100)) percent."]
        if trend.hasBaseline {
            let delta = trend.delta
            let deltaPercent = Int(abs(delta) * 100)
            if abs(delta) <= 0.05 {
                parts.append("Same as last week.")
            } else if delta > 0 {
                parts.append("Up \(deltaPercent) percent from last week.")
            } else {
                parts.append("Down \(deltaPercent) percent from last week.")
            }
        } else {
            parts.append("First week, no comparison yet.")
        }
        parts.append("\(Int(trend.onTimeRate * 100)) percent on time.")
        parts.append("\(trend.thisWeekLogged) of \(trend.thisWeekOpportunities) prayer opportunities.")
        return parts.joined(separator: " ")
    }
}
