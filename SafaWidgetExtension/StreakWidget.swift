// MARK: - StreakWidget.swift
// PURPOSE: Widget showing the user's current prayer/daily streak
// DEPENDENCIES: WidgetKit, SwiftUI

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry

struct StreakEntry: TimelineEntry {
    let date: Date
    let currentCount: Int
    let longestCount: Int
    let isActiveToday: Bool
    let configuration: StreakConfigIntent
}

// MARK: - Widget Provider

struct StreakProvider: AppIntentTimelineProvider {
    private let appGroupId = "group.com.safa.app"

    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(
            date: Date(),
            currentCount: 7,
            longestCount: 14,
            isActiveToday: true,
            configuration: StreakConfigIntent()
        )
    }

    func snapshot(for configuration: StreakConfigIntent, in context: Context) async -> StreakEntry {
        let data = loadStreakData()
        return StreakEntry(
            date: Date(),
            currentCount: data.current,
            longestCount: data.longest,
            isActiveToday: data.activeToday,
            configuration: configuration
        )
    }

    func timeline(for configuration: StreakConfigIntent, in context: Context) async -> Timeline<StreakEntry> {
        let data = loadStreakData()
        let entry = StreakEntry(
            date: Date(),
            currentCount: data.current,
            longestCount: data.longest,
            isActiveToday: data.activeToday,
            configuration: configuration
        )

        // Refresh at midnight (streak may change) or in 1 hour
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let refreshDate = min(midnight, Date().addingTimeInterval(3600))
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    private func loadStreakData() -> (current: Int, longest: Int, activeToday: Bool) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            return (0, 0, false)
        }
        return (
            defaults.integer(forKey: "streakCurrentCount"),
            defaults.integer(forKey: "streakLongestCount"),
            defaults.bool(forKey: "streakIsActiveToday")
        )
    }
}

// MARK: - Configuration Intent

struct StreakConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Prayer Streak"
    static var description = IntentDescription("Shows your current prayer streak")

    @Parameter(title: "Show Longest Streak", default: true)
    var showLongest: Bool
}

// MARK: - Widget Views

struct StreakWidgetView: View {
    var entry: StreakProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallStreakView(entry: entry)
        case .systemMedium:
            MediumStreakView(entry: entry)
        default:
            SmallStreakView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallStreakView: View {
    let entry: StreakEntry

    var body: some View {
        VStack(spacing: 8) {
            // Flame icon
            Image(systemName: entry.isActiveToday ? "flame.fill" : "flame")
                .font(.system(size: 32))
                .foregroundStyle(entry.isActiveToday ? .orange : .secondary)
                .symbolEffect(.pulse, isActive: entry.isActiveToday && entry.currentCount > 0)

            // Count
            Text("\(entry.currentCount)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(entry.currentCount > 0 ? .primary : .secondary)

            // Label
            Text("day streak")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Active indicator
            if entry.isActiveToday {
                Text("Active today")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget

struct MediumStreakView: View {
    let entry: StreakEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Current streak
            VStack(spacing: 8) {
                Image(systemName: entry.isActiveToday ? "flame.fill" : "flame")
                    .font(.system(size: 36))
                    .foregroundStyle(entry.isActiveToday ? .orange : .secondary)

                Text("\(entry.currentCount)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.currentCount > 0 ? .primary : .secondary)

                Text("day streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right: Stats
            VStack(alignment: .leading, spacing: 12) {
                // Active today
                HStack(spacing: 6) {
                    Image(systemName: entry.isActiveToday ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundStyle(entry.isActiveToday ? .green : .secondary)
                    Text(entry.isActiveToday ? "Active today" : "Not active yet")
                        .font(.caption)
                        .foregroundStyle(entry.isActiveToday ? .primary : .secondary)
                }

                // Longest streak
                if entry.configuration.showLongest {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text("Best: \(entry.longestCount) days")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Motivational message
                Text(motivationalMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var motivationalMessage: LocalizedStringResource {
        if !entry.isActiveToday && entry.currentCount > 0 {
            return "Pray today to keep your streak!"
        } else if entry.currentCount >= 30 {
            return "Mashallah! A whole month!"
        } else if entry.currentCount >= 7 {
            return "Keep going, you're on a roll!"
        } else if entry.currentCount > 0 {
            return "Every day counts."
        } else {
            return "Start your streak today."
        }
    }
}

// MARK: - Widget Definition

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: StreakConfigIntent.self,
            provider: StreakProvider()
        ) { entry in
            StreakWidgetView(entry: entry)
                .widgetURL(URL(string: "safa://prayer"))
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Prayer Streak")
        .description("Track your daily prayer streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakEntry(date: .now, currentCount: 7, longestCount: 14, isActiveToday: true, configuration: StreakConfigIntent())
    StreakEntry(date: .now, currentCount: 0, longestCount: 14, isActiveToday: false, configuration: StreakConfigIntent())
}

#Preview(as: .systemMedium) {
    StreakWidget()
} timeline: {
    StreakEntry(date: .now, currentCount: 21, longestCount: 30, isActiveToday: true, configuration: StreakConfigIntent())
    StreakEntry(date: .now, currentCount: 3, longestCount: 30, isActiveToday: false, configuration: StreakConfigIntent())
}
