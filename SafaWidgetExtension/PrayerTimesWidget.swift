// MARK: - SafaWidget.swift
// PURPOSE: Widget extension for Safa app
// DEPENDENCIES: WidgetKit, SwiftUI

import WidgetKit
import SwiftUI
import AppIntents
import SafaShared

// MARK: - Widget Entry

struct PrayerTimeEntry: TimelineEntry {
    let date: Date
    let prayers: [PrayerInfo]
    let hijriDate: String
    let configuration: ConfigurationAppIntent

    /// Stored next prayer info — set at entry creation, not computed from Date().
    /// This ensures WidgetKit pre-rendered entries show the correct prayer for their time window.
    let nextPrayerName: String
    let nextPrayerTime: Date
    let hasNextPrayer: Bool
    /// Whether the prayer time has just arrived (grace window: 0-15 min after prayer time).
    let isGrace: Bool
}

// MARK: - Widget Provider

struct Provider: AppIntentTimelineProvider {

    // Shared logic from SafaShared (single source of truth)
    private let defaultPrayers = DefaultPrayerTimes()
    private let hijriHelper = HijriDateHelper()
    private let appGroupId = "group.com.safa.app"

    /// Load prayer times from App Group (written by main app), fall back to London defaults
    private func loadPrayers() -> [PrayerInfo] {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            return defaultPrayers.forToday()
        }

        // Read localized prayer names from App Group (written by main app on language change)
        let namesFallback = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
        let names = defaults.stringArray(forKey: "prayerNames") ?? namesFallback
        let timeKeys = ["fajrTime", "dhuhrTime", "asrTime", "maghribTime", "ishaTime"]

        var prayers: [PrayerInfo] = []
        for (index, key) in timeKeys.enumerated() {
            if let time = defaults.object(forKey: key) as? Date {
                let name = index < names.count ? names[index] : namesFallback[index]
                prayers.append(PrayerInfo(name: name, time: time))
            }
        }

        // If we got all 5 prayer times from App Group, use them; otherwise fall back
        guard prayers.count == 5 else {
            return defaultPrayers.forToday()
        }

        return prayers
    }

    /// Load hijri date from App Group, fall back to local calculation
    private func loadHijriDate() -> String {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let hijri = defaults.string(forKey: "hijriDate"), !hijri.isEmpty else {
            return hijriHelper.hijriDateString()
        }
        return hijri
    }

    private let calculator = NextPrayerCalculator()

    private func makeEntry(configuration: ConfigurationAppIntent, at date: Date = Date(), nextPrayer: PrayerInfo? = nil, prayers: [PrayerInfo]? = nil, isGrace: Bool = false) -> PrayerTimeEntry {
        let prayerList = prayers ?? loadPrayers()
        let next = nextPrayer ?? calculator.nextPrayer(from: prayerList, at: date)
        return PrayerTimeEntry(
            date: date,
            prayers: prayerList,
            hijriDate: loadHijriDate(),
            configuration: configuration,
            nextPrayerName: next?.name ?? "Isha",
            nextPrayerTime: next?.time ?? date,
            hasNextPrayer: next != nil,
            isGrace: isGrace
        )
    }

    func placeholder(in context: Context) -> PrayerTimeEntry {
        let prayers = defaultPrayers.forToday()
        let next = calculator.nextPrayer(from: prayers)
        return PrayerTimeEntry(
            date: Date(),
            prayers: prayers,
            hijriDate: hijriHelper.hijriDateString(),
            configuration: ConfigurationAppIntent(),
            nextPrayerName: next?.name ?? "Isha",
            nextPrayerTime: next?.time ?? Date(),
            hasNextPrayer: next != nil,
            isGrace: false
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> PrayerTimeEntry {
        makeEntry(configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<PrayerTimeEntry> {
        let now = Date()
        let prayers = loadPrayers()
        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        let entries = boundaries.map { boundary in
            makeEntry(
                configuration: configuration,
                at: boundary.date,
                nextPrayer: boundary.nextPrayer,
                prayers: prayers,
                isGrace: boundary.isGrace
            )
        }

        let refreshDate = calculator.timelineRefreshDate(from: prayers, startingAt: now)
        return Timeline(entries: entries, policy: .after(refreshDate))
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

            if entry.hasNextPrayer {
                Text(entry.isGrace ? "Time to pray" : "Next Prayer")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(entry.nextPrayerName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if entry.isGrace {
                    Text("Prayer time")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                } else {
                    Text(entry.nextPrayerTime, style: .time)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            } else {
                Text("No More Prayers Today")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Image(systemName: "moon.zzz.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }

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

                if entry.hasNextPrayer {
                    Text(entry.isGrace ? "Time to pray" : "Next Prayer")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(entry.nextPrayerName)
                        .font(.title)
                        .fontWeight(.bold)

                    if entry.isGrace {
                        Text("Prayer time")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    } else {
                        HStack {
                            Text(entry.nextPrayerTime, style: .time)
                            Text("·")
                            Text(entry.nextPrayerTime, style: .relative)
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                } else {
                    Spacer()

                    Text("No More Prayers Today")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: "moon.zzz.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }
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
                .widgetURL(URL(string: "safa://prayer"))
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Prayer Times")
        .description("Shows the next prayer time and daily schedule.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// Bundle and previews are in SafaWidgetExtensionBundle.swift
