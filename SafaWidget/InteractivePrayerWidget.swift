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
        return [
            PrayerStatus(id: "fajr", name: "Fajr", time: now.addingTimeInterval(-36000), isLogged: true, isPast: true, isNext: false),
            PrayerStatus(id: "dhuhr", name: "Dhuhr", time: now.addingTimeInterval(-14400), isLogged: true, isPast: true, isNext: false),
            PrayerStatus(id: "asr", name: "Asr", time: now.addingTimeInterval(-3600), isLogged: false, isPast: true, isNext: false),
            PrayerStatus(id: "maghrib", name: "Maghrib", time: now.addingTimeInterval(1800), isLogged: false, isPast: false, isNext: true),
            PrayerStatus(id: "isha", name: "Isha", time: now.addingTimeInterval(7200), isLogged: false, isPast: false, isNext: false)
        ]
    }

    private static func loadPrayers() -> [PrayerStatus] {
        // Load from App Group UserDefaults
        guard let defaults = UserDefaults(suiteName: "group.com.safa.app") else {
            return samplePrayers()
        }

        let now = Date()
        let loggedPrayers = defaults.stringArray(forKey: "loggedPrayers_\(dateKey())") ?? []

        // In production, these times would come from the prayer calculation
        return [
            PrayerStatus(id: "fajr", name: "Fajr", time: now.addingTimeInterval(-36000), isLogged: loggedPrayers.contains("fajr"), isPast: true, isNext: false),
            PrayerStatus(id: "dhuhr", name: "Dhuhr", time: now.addingTimeInterval(-14400), isLogged: loggedPrayers.contains("dhuhr"), isPast: true, isNext: false),
            PrayerStatus(id: "asr", name: "Asr", time: now.addingTimeInterval(-3600), isLogged: loggedPrayers.contains("asr"), isPast: true, isNext: false),
            PrayerStatus(id: "maghrib", name: "Maghrib", time: now.addingTimeInterval(1800), isLogged: loggedPrayers.contains("maghrib"), isPast: false, isNext: true),
            PrayerStatus(id: "isha", name: "Isha", time: now.addingTimeInterval(7200), isLogged: loggedPrayers.contains("isha"), isPast: false, isNext: false)
        ]
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

                // Notify main app to sync and award Hasanat
                NotificationCenter.default.post(
                    name: Notification.Name("com.safa.prayerLoggedFromWidget"),
                    object: nil,
                    userInfo: ["prayerId": prayerId]
                )
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
            PrayerStatus(id: "fajr", name: "Fajr", time: Date().addingTimeInterval(-36000), isLogged: true, isPast: true, isNext: false),
            PrayerStatus(id: "dhuhr", name: "Dhuhr", time: Date().addingTimeInterval(-14400), isLogged: true, isPast: true, isNext: false),
            PrayerStatus(id: "asr", name: "Asr", time: Date().addingTimeInterval(-3600), isLogged: false, isPast: true, isNext: false),
            PrayerStatus(id: "maghrib", name: "Maghrib", time: Date().addingTimeInterval(1800), isLogged: false, isPast: false, isNext: true),
            PrayerStatus(id: "isha", name: "Isha", time: Date().addingTimeInterval(7200), isLogged: false, isPast: false, isNext: false)
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
            PrayerStatus(id: "fajr", name: "Fajr", time: Date().addingTimeInterval(-36000), isLogged: true, isPast: true, isNext: false),
            PrayerStatus(id: "dhuhr", name: "Dhuhr", time: Date().addingTimeInterval(-14400), isLogged: true, isPast: true, isNext: false),
            PrayerStatus(id: "asr", name: "Asr", time: Date().addingTimeInterval(-3600), isLogged: false, isPast: true, isNext: false),
            PrayerStatus(id: "maghrib", name: "Maghrib", time: Date().addingTimeInterval(1800), isLogged: false, isPast: false, isNext: true),
            PrayerStatus(id: "isha", name: "Isha", time: Date().addingTimeInterval(7200), isLogged: false, isPast: false, isNext: false)
        ],
        configuration: InteractivePrayerConfigIntent()
    )
}
