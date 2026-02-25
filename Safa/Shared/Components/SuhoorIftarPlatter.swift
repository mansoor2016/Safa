// MARK: - SuhoorIftarPlatter.swift
// PURPOSE: Shared Suhoor/Iftar countdown platter used by both Home and Ramadan tabs
// DEPENDENCIES: SwiftUI, RamadanCountdownHelpers, ContentCard

import SwiftUI

struct SuhoorIftarPlatter: View {
    let suhoorTime: Date?
    let iftarTime: Date?

    var body: some View {
        ContentCard {
            VStack(spacing: SafaSpacing.sm) {
                // Suhoor + Iftar times on one line
                HStack {
                    HStack(spacing: SafaSpacing.xs) {
                        Image(systemName: "sunrise.fill")
                            .foregroundStyle(.orange)
                        Text("Suhoor")
                            .font(SafaTypography.labelSmall)
                            .foregroundStyle(.secondary)
                        if let suhoor = suhoorTime {
                            Text(suhoor.formatted(date: .omitted, time: .shortened))
                                .font(SafaTypography.titleSmall)
                        }
                    }

                    Spacer()

                    HStack(spacing: SafaSpacing.xs) {
                        Image(systemName: "moon.fill")
                            .foregroundStyle(.purple)
                        Text("Iftar")
                            .font(SafaTypography.labelSmall)
                            .foregroundStyle(.secondary)
                        if let iftar = iftarTime {
                            Text(iftar.formatted(date: .omitted, time: .shortened))
                                .font(SafaTypography.titleSmall)
                        }
                    }
                }

                Divider()

                // Live countdown (uses shared helper for Suhoor-first priority)
                switch RamadanCountdownHelpers.resolveTarget(now: Date(), suhoorTime: suhoorTime, iftarTime: iftarTime) {
                case .suhoor(let time):
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.orange)
                        Text(time, style: .timer)
                            .font(SafaTypography.headlineLarge)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("until Suhoor ends")
                            .font(SafaTypography.labelMedium)
                            .foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                case .iftar(let time):
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(Color.accentColor)
                        Text(time, style: .timer)
                            .font(SafaTypography.headlineLarge)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("until Iftar")
                            .font(SafaTypography.labelMedium)
                            .foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                case .nextSuhoor(let time):
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.secondary)
                        Text(time, style: .timer)
                            .font(SafaTypography.headlineLarge)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .foregroundStyle(.secondary)
                        Text("until Suhoor tomorrow")
                            .font(SafaTypography.labelMedium)
                            .foregroundStyle(.tertiary)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                case .complete:
                    Label("Fasting complete for today", systemImage: "checkmark.circle.fill")
                        .font(SafaTypography.titleSmall)
                        .foregroundStyle(.green)
                }
            }
        }
    }
}
