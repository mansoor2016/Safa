// MARK: - SafaWidget.swift
// PURPOSE: Widget extension for Safa app
// DEPENDENCIES: WidgetKit, SwiftUI

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry

struct PrayerTimeEntry: TimelineEntry {
    let date: Date
    let prayers: [(name: String, time: Date)]
    let hijriDate: String
    let configuration: ConfigurationAppIntent

    var nextPrayer: (name: String, time: Date)? {
        let now = Date()
        return prayers.first { $0.time > now }
    }

    var nextPrayerName: String {
        nextPrayer?.name ?? "Isha"
    }

    var nextPrayerTime: Date {
        nextPrayer?.time ?? Date()
    }
}

// MARK: - Widget Provider

struct Provider: AppIntentTimelineProvider {

    // London, UK default prayer times (approximate, updated per timeline refresh)
    private func todayPrayers() -> [(name: String, time: Date)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Read from shared UserDefaults if available, else use reasonable London defaults
        // These approximate times will be replaced when App Group sharing is implemented
        let month = cal.component(.month, from: Date())

        // Seasonal adjustment for London (rough approximation)
        let fajrHour: Int
        let dhuhrHour = 12
        let dhuhrMin = 30
        let asrHour: Int
        let maghribHour: Int
        let maghribMin: Int
        let ishaHour: Int

        switch month {
        case 11, 12, 1, 2: // Winter
            fajrHour = 6; asrHour = 14; maghribHour = 16; maghribMin = 15; ishaHour = 18
        case 3, 4: // Spring
            fajrHour = 5; asrHour = 15; maghribHour = 18; maghribMin = 30; ishaHour = 20
        case 5, 6, 7: // Summer
            fajrHour = 3; asrHour = 17; maghribHour = 21; maghribMin = 0; ishaHour = 22
        case 8, 9, 10: // Autumn
            fajrHour = 5; asrHour = 16; maghribHour = 19; maghribMin = 0; ishaHour = 20
        default:
            fajrHour = 5; asrHour = 15; maghribHour = 18; maghribMin = 0; ishaHour = 20
        }

        return [
            ("Fajr", cal.date(bySettingHour: fajrHour, minute: 30, second: 0, of: today)!),
            ("Dhuhr", cal.date(bySettingHour: dhuhrHour, minute: dhuhrMin, second: 0, of: today)!),
            ("Asr", cal.date(bySettingHour: asrHour, minute: 45, second: 0, of: today)!),
            ("Maghrib", cal.date(bySettingHour: maghribHour, minute: maghribMin, second: 0, of: today)!),
            ("Isha", cal.date(bySettingHour: ishaHour, minute: 0, second: 0, of: today)!)
        ]
    }

    private func makeEntry(configuration: ConfigurationAppIntent) -> PrayerTimeEntry {
        PrayerTimeEntry(
            date: Date(),
            prayers: todayPrayers(),
            hijriDate: "Sha'ban 1447",
            configuration: configuration
        )
    }

    func placeholder(in context: Context) -> PrayerTimeEntry {
        makeEntry(configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> PrayerTimeEntry {
        makeEntry(configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<PrayerTimeEntry> {
        let entry = makeEntry(configuration: configuration)

        // Refresh at the next prayer time, or in 30 minutes if all prayers passed
        let refreshDate = entry.nextPrayer?.time ?? Date().addingTimeInterval(1800)
        return Timeline(entries: [entry], policy: .after(refreshDate))
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

            Text(entry.nextPrayerName)
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

                Text(entry.nextPrayerName)
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
                ForEach(entry.prayers, id: \.name) { prayer in
                    PrayerRow(
                        name: prayer.name,
                        time: prayer.time.formatted(date: .omitted, time: .shortened),
                        isNext: prayer.name == entry.nextPrayerName
                    )
                }
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

                    Text(entry.nextPrayerName)
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
                ForEach(entry.prayers, id: \.name) { prayer in
                    LargePrayerRow(
                        name: prayer.name,
                        time: prayer.time.formatted(date: .omitted, time: .shortened),
                        isPast: prayer.time < Date(),
                        isNext: prayer.name == entry.nextPrayerName
                    )
                }
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
                Text(entry.nextPrayerName.prefix(3))
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
                Text("Next: \(entry.nextPrayerName)")
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
        Text("\(entry.nextPrayerName) at \(entry.nextPrayerTime, style: .time)")
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
