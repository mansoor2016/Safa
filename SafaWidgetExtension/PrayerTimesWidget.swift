// MARK: - SafaWidget.swift
// PURPOSE: Widget extension for Safa app
// DEPENDENCIES: WidgetKit, SwiftUI

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry

struct PrayerTimeEntry: TimelineEntry {
    let date: Date
    let nextPrayer: String
    let nextPrayerTime: Date
    let hijriDate: String
    let configuration: ConfigurationAppIntent
}

// MARK: - Widget Provider

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PrayerTimeEntry {
        PrayerTimeEntry(
            date: Date(),
            nextPrayer: "Fajr",
            nextPrayerTime: Date().addingTimeInterval(3600),
            hijriDate: "1 Ramadan 1446",
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> PrayerTimeEntry {
        // Load actual data from App Group
        PrayerTimeEntry(
            date: Date(),
            nextPrayer: "Dhuhr",
            nextPrayerTime: Date().addingTimeInterval(7200),
            hijriDate: "15 Sha'ban 1446",
            configuration: configuration
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<PrayerTimeEntry> {
        var entries: [PrayerTimeEntry] = []

        // Generate a timeline of prayer times
        let currentDate = Date()
        let entry = PrayerTimeEntry(
            date: currentDate,
            nextPrayer: "Asr",
            nextPrayerTime: currentDate.addingTimeInterval(10800),
            hijriDate: "15 Sha'ban 1446",
            configuration: configuration
        )
        entries.append(entry)

        // Refresh after the next prayer time
        return Timeline(entries: entries, policy: .after(entry.nextPrayerTime))
    }
}

// MARK: - Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Prayer Times"
    static var description = IntentDescription("Shows next prayer time")

    @Parameter(title: "Show Hijri Date", default: true)
    var showHijriDate: Bool
}

// MARK: - Widget Views

struct SafaWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: PrayerTimeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                Spacer()
            }

            Spacer()

            Text("Next Prayer")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(entry.nextPrayer)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(entry.nextPrayerTime, style: .time)
                .font(.caption)
                .foregroundColor(.accentColor)

            if entry.configuration.showHijriDate {
                Text(entry.hijriDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: PrayerTimeEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)

                    Text("Safa")
                        .font(.headline)
                }

                Spacer()

                Text("Next Prayer")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(entry.nextPrayer)
                    .font(.title)
                    .fontWeight(.bold)

                HStack {
                    Text(entry.nextPrayerTime, style: .time)
                    Text("•")
                    Text(entry.nextPrayerTime, style: .relative)
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }

            Spacer()

            // Prayer times column
            VStack(alignment: .trailing, spacing: 4) {
                PrayerRow(name: "Fajr", time: "5:23 AM", isNext: false)
                PrayerRow(name: "Dhuhr", time: "12:30 PM", isNext: false)
                PrayerRow(name: "Asr", time: "3:45 PM", isNext: true)
                PrayerRow(name: "Maghrib", time: "6:15 PM", isNext: false)
                PrayerRow(name: "Isha", time: "7:45 PM", isNext: false)
            }
        }
        .padding()
    }
}

struct PrayerRow: View {
    let name: String
    let time: String
    let isNext: Bool

    var body: some View {
        HStack {
            Text(name)
                .font(.caption2)
                .foregroundColor(isNext ? .primary : .secondary)

            Text(time)
                .font(.caption2)
                .fontWeight(isNext ? .bold : .regular)
                .foregroundColor(isNext ? .accentColor : .secondary)
        }
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: PrayerTimeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading) {
                    Text("Safa")
                        .font(.headline)

                    if entry.configuration.showHijriDate {
                        Text(entry.hijriDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Next prayer highlight
            HStack {
                VStack(alignment: .leading) {
                    Text("Next Prayer")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(entry.nextPrayer)
                        .font(.title)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(entry.nextPrayerTime, style: .time)
                        .font(.title2)
                        .foregroundColor(.accentColor)

                    Text(entry.nextPrayerTime, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(12)

            // All prayers
            VStack(spacing: 8) {
                LargePrayerRow(name: "Fajr", time: "5:23 AM", isPast: true)
                LargePrayerRow(name: "Sunrise", time: "6:45 AM", isPast: true)
                LargePrayerRow(name: "Dhuhr", time: "12:30 PM", isPast: true)
                LargePrayerRow(name: "Asr", time: "3:45 PM", isPast: false, isNext: true)
                LargePrayerRow(name: "Maghrib", time: "6:15 PM", isPast: false)
                LargePrayerRow(name: "Isha", time: "7:45 PM", isPast: false)
            }

            Spacer()
        }
        .padding()
    }
}

struct LargePrayerRow: View {
    let name: String
    let time: String
    var isPast: Bool = false
    var isNext: Bool = false

    var body: some View {
        HStack {
            Circle()
                .fill(isNext ? Color.accentColor : (isPast ? Color.green : Color.gray.opacity(0.3)))
                .frame(width: 8, height: 8)

            Text(name)
                .font(.subheadline)
                .foregroundColor(isPast ? .secondary : .primary)

            Spacer()

            Text(time)
                .font(.subheadline)
                .fontWeight(isNext ? .bold : .regular)
                .foregroundColor(isNext ? .accentColor : (isPast ? .secondary : .primary))
        }
    }
}

// MARK: - Lock Screen Widgets

struct AccessoryCircularView: View {
    let entry: PrayerTimeEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Text(entry.nextPrayer.prefix(3))
                    .font(.caption2)
                    .fontWeight(.bold)

                Text(entry.nextPrayerTime, style: .time)
                    .font(.caption2)
            }
        }
    }
}

struct AccessoryRectangularView: View {
    let entry: PrayerTimeEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Next: \(entry.nextPrayer)")
                    .font(.headline)

                Text(entry.nextPrayerTime, style: .time)
                    .font(.caption)
            }

            Spacer()

            Image(systemName: "moon.stars")
        }
    }
}

struct AccessoryInlineView: View {
    let entry: PrayerTimeEntry

    var body: some View {
        Text("\(entry.nextPrayer) at \(entry.nextPrayerTime, style: .time)")
    }
}

// MARK: - Widget Definition

struct PrayerTimesWidget: Widget {
    let kind: String = "SafaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            SafaWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Prayer Times")
        .description("Shows the next prayer time and daily schedule.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// Bundle and previews are in SafaWidgetExtensionBundle.swift
