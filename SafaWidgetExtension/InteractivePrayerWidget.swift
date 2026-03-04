// MARK: - InteractivePrayerWidget.swift
// PURPOSE: Interactive widget allowing users to log prayers directly from home screen
// DEPENDENCIES: WidgetKit, SwiftUI, AppIntents

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry

struct InteractivePrayerEntry: TimelineEntry {
    let date: Date
    let prayers: [PrayerStatus]
    let configuration: InteractivePrayerConfigIntent
}

struct PrayerStatus: Identifiable {
    let id: String
    let name: String
    let time: Date
    let isLogged: Bool
    let isPast: Bool
    let isNext: Bool
}

// MARK: - Widget Provider

struct InteractivePrayerProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> InteractivePrayerEntry {
        InteractivePrayerEntry(
            date: Date(),
            prayers: Self.samplePrayers(),
            configuration: InteractivePrayerConfigIntent()
        )
    }

    func snapshot(for configuration: InteractivePrayerConfigIntent, in context: Context) async -> InteractivePrayerEntry {
        InteractivePrayerEntry(
            date: Date(),
            prayers: Self.loadPrayers(),
            configuration: configuration
        )
    }

    func timeline(for configuration: InteractivePrayerConfigIntent, in context: Context) async -> Timeline<InteractivePrayerEntry> {
        let entry = InteractivePrayerEntry(
            date: Date(),
            prayers: Self.loadPrayers(),
            configuration: configuration
        )

        // Refresh every 15 minutes to update prayer status
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private static func samplePrayers() -> [PrayerStatus] {
        let now = Date()
        let names = localizedPrayerNames()
        return [
            PrayerStatus(id: "fajr", name: names[0], time: now.addingTimeInterval(-36000), isLogged: true, isPast: true, isNext: false),
            PrayerStatus(id: "dhuhr", name: names[1], time: now.addingTimeInterval(-14400), isLogged: true, isPast: true, isNext: false),
            PrayerStatus(id: "asr", name: names[2], time: now.addingTimeInterval(-3600), isLogged: false, isPast: true, isNext: false),
            PrayerStatus(id: "maghrib", name: names[3], time: now.addingTimeInterval(1800), isLogged: false, isPast: false, isNext: true),
            PrayerStatus(id: "isha", name: names[4], time: now.addingTimeInterval(7200), isLogged: false, isPast: false, isNext: false)
        ]
    }

    private static func localizedPrayerNames() -> [String] {
        [
            String(localized: "Fajr"), String(localized: "Dhuhr"),
            String(localized: "Asr"), String(localized: "Maghrib"),
            String(localized: "Isha")
        ]
    }

    private static func loadPrayers() -> [PrayerStatus] {
        guard let defaults = UserDefaults(suiteName: "group.com.safa.app") else {
            return samplePrayers()
        }

        let now = Date()
        let loggedPrayers = defaults.stringArray(forKey: "loggedPrayers_\(dateKey())") ?? []

        // Read localized prayer names from App Group (written by main app on language change)
        let namesFallback = localizedPrayerNames()
        let names = defaults.stringArray(forKey: "prayerNames") ?? namesFallback
        let prayerKeys: [(id: String, timeKey: String)] = [
            ("fajr", "fajrTime"),
            ("dhuhr", "dhuhrTime"),
            ("asr", "asrTime"),
            ("maghrib", "maghribTime"),
            ("isha", "ishaTime")
        ]

        var prayers: [PrayerStatus] = []
        var foundNextPrayer = false

        for (index, prayer) in prayerKeys.enumerated() {
            guard let time = defaults.object(forKey: prayer.timeKey) as? Date else {
                // If any prayer time is missing, fall back to sample data
                return samplePrayers()
            }

            let name = index < names.count ? names[index] : namesFallback[index]
            let isPast = time <= now
            let isNext = !isPast && !foundNextPrayer
            if isNext { foundNextPrayer = true }

            prayers.append(PrayerStatus(
                id: prayer.id,
                name: name,
                time: time,
                isLogged: loggedPrayers.contains(prayer.id),
                isPast: isPast,
                isNext: isNext
            ))
        }

        return prayers
    }

    private static func dateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Configuration Intent

struct InteractivePrayerConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Interactive Prayer Tracker"
    static var description = IntentDescription("Log prayers directly from your home screen")

    @Parameter(title: "Show Time", default: true)
    var showTime: Bool

    @Parameter(title: "Compact Mode", default: false)
    var compactMode: Bool
}

// MARK: - Log Prayer Widget Intent

struct WidgetLogPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Prayer from Widget"
    static var description = IntentDescription("Mark a prayer as completed")

    @Parameter(title: "Prayer ID")
    var prayerId: String

    init() {
        self.prayerId = "fajr"
    }

    init(prayerId: String) {
        self.prayerId = prayerId
    }

    func perform() async throws -> some IntentResult {
        // Save to App Group UserDefaults
        if let defaults = UserDefaults(suiteName: "group.com.safa.app") {
            let dateKey = Self.dateKey()
            var loggedPrayers = defaults.stringArray(forKey: "loggedPrayers_\(dateKey)") ?? []

            if !loggedPrayers.contains(prayerId) {
                loggedPrayers.append(prayerId)
                defaults.set(loggedPrayers, forKey: "loggedPrayers_\(dateKey)")
            }
        }

        // Reload widget timeline
        WidgetCenter.shared.reloadTimelines(ofKind: "InteractivePrayerWidget")

        return .result()
    }

    private static func dateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Widget Views

struct InteractivePrayerWidgetView: View {
    var entry: InteractivePrayerProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallInteractivePrayerView(entry: entry)
        case .systemMedium:
            MediumInteractivePrayerView(entry: entry)
        default:
            SmallInteractivePrayerView(entry: entry)
        }
    }
}

// MARK: - Small Widget View

struct SmallInteractivePrayerView: View {
    let entry: InteractivePrayerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("Prayer Log")
                    .font(.caption2)
                    .fontWeight(.semibold)
                Spacer()
            }

            Spacer()

            // Show logged count
            let loggedCount = entry.prayers.filter { $0.isLogged }.count
            Text("\(loggedCount)/5")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(loggedCount == 5 ? .green : .primary)

            Text("prayers today")
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            // Next prayer to log
            if let nextToLog = entry.prayers.first(where: { $0.isPast && !$0.isLogged }) {
                Button(intent: WidgetLogPrayerIntent(prayerId: nextToLog.id)) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Log \(nextToLog.name)")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

// MARK: - Medium Widget View

struct MediumInteractivePrayerView: View {
    let entry: InteractivePrayerEntry

    var body: some View {
        HStack(spacing: 12) {
            // Left side - Summary
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.accentColor)
                    Text("Prayer Log")
                        .font(.headline)
                }

                Spacer()

                let loggedCount = entry.prayers.filter { $0.isLogged }.count
                HStack(alignment: .firstTextBaseline) {
                    Text("\(loggedCount)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(loggedCount == 5 ? .green : .primary)
                    Text("/ 5")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Text(loggedCount == 5 ? "All prayers logged!" : "prayers completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Right side - Prayer buttons
            VStack(spacing: 4) {
                ForEach(entry.prayers) { prayer in
                    PrayerLogButton(prayer: prayer, showTime: entry.configuration.showTime)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}

// MARK: - Prayer Log Button

struct PrayerLogButton: View {
    let prayer: PrayerStatus
    let showTime: Bool

    var body: some View {
        if prayer.isLogged {
            // Already logged - show checkmark
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)

                Text(prayer.name)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .strikethrough()

                Spacer()

                if showTime {
                    Text(prayer.time, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        } else if prayer.isPast {
            // Not logged but past - can log
            Button(intent: WidgetLogPrayerIntent(prayerId: prayer.id)) {
                HStack {
                    Image(systemName: "circle")
                        .foregroundColor(.orange)
                        .font(.caption)

                    Text(prayer.name)
                        .font(.caption2)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("Log")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                }
            }
            .buttonStyle(.plain)
        } else {
            // Future prayer - disabled
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                    .font(.caption)

                Text(prayer.name)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                if showTime {
                    Text(prayer.time, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Widget Definition

struct InteractivePrayerWidget: Widget {
    let kind: String = "InteractivePrayerWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: InteractivePrayerConfigIntent.self,
            provider: InteractivePrayerProvider()
        ) { entry in
            InteractivePrayerWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Prayer Tracker")
        .description("Log your daily prayers with a tap.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    InteractivePrayerWidget()
} timeline: {
    InteractivePrayerEntry(
        date: .now,
        prayers: [
            PrayerStatus(id: "fajr", name: String(localized: "Fajr"), time: Date().addingTimeInterval(-36000), isLogged: true, isPast: true, isNext: false),
            PrayerStatus(id: "dhuhr", name: String(localized: "Dhuhr"), time: Date().addingTimeInterval(-14400), isLogged: true, isPast: true, isNext: false),
            PrayerStatus(id: "asr", name: String(localized: "Asr"), time: Date().addingTimeInterval(-3600), isLogged: false, isPast: true, isNext: false),
            PrayerStatus(id: "maghrib", name: String(localized: "Maghrib"), time: Date().addingTimeInterval(1800), isLogged: false, isPast: false, isNext: true),
            PrayerStatus(id: "isha", name: String(localized: "Isha"), time: Date().addingTimeInterval(7200), isLogged: false, isPast: false, isNext: false)
        ],
        configuration: InteractivePrayerConfigIntent()
    )
}

#Preview(as: .systemMedium) {
    InteractivePrayerWidget()
} timeline: {
    InteractivePrayerEntry(
        date: .now,
        prayers: [
            PrayerStatus(id: "fajr", name: String(localized: "Fajr"), time: Date().addingTimeInterval(-36000), isLogged: true, isPast: true, isNext: false),
            PrayerStatus(id: "dhuhr", name: String(localized: "Dhuhr"), time: Date().addingTimeInterval(-14400), isLogged: true, isPast: true, isNext: false),
            PrayerStatus(id: "asr", name: String(localized: "Asr"), time: Date().addingTimeInterval(-3600), isLogged: false, isPast: true, isNext: false),
            PrayerStatus(id: "maghrib", name: String(localized: "Maghrib"), time: Date().addingTimeInterval(1800), isLogged: false, isPast: false, isNext: true),
            PrayerStatus(id: "isha", name: String(localized: "Isha"), time: Date().addingTimeInterval(7200), isLogged: false, isPast: false, isNext: false)
        ],
        configuration: InteractivePrayerConfigIntent()
    )
}
