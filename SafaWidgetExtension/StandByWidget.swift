// MARK: - StandByWidget.swift
// PURPOSE: StandBy mode widget optimized for bedside visibility (iOS 17+)
// DEPENDENCIES: WidgetKit, SwiftUI

import WidgetKit
import SwiftUI
import AppIntents
import SafaShared

// MARK: - Widget Entry

struct StandByPrayerEntry: TimelineEntry {
    let date: Date
    let nextPrayer: String
    let nextPrayerTime: Date
    let fajrTime: Date?
    let hijriDate: String
    let configuration: StandByConfigIntent
    /// Whether the prayer time has just arrived (grace window: 0-15 min after prayer time).
    let isGrace: Bool
}

// MARK: - Widget Provider

struct StandByPrayerProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> StandByPrayerEntry {
        StandByPrayerEntry(
            date: Date(),
            nextPrayer: "Fajr",
            nextPrayerTime: Date().addingTimeInterval(3600),
            fajrTime: Date().addingTimeInterval(3600),
            hijriDate: HijriDateHelper().hijriDateString(),
            configuration: StandByConfigIntent(),
            isGrace: false
        )
    }

    func snapshot(for configuration: StandByConfigIntent, in context: Context) async -> StandByPrayerEntry {
        StandByPrayerEntry(
            date: Date(),
            nextPrayer: "Fajr",
            nextPrayerTime: Date().addingTimeInterval(18000),
            fajrTime: Date().addingTimeInterval(18000),
            hijriDate: HijriDateHelper().hijriDateString(),
            configuration: configuration,
            isGrace: false
        )
    }

    func timeline(for configuration: StandByConfigIntent, in context: Context) async -> Timeline<StandByPrayerEntry> {
        let prayerData = loadPrayerData()
        let isGrace = isPrayerTimeNow(prayerData.nextPrayerTime)
        let entry = StandByPrayerEntry(
            date: Date(),
            nextPrayer: prayerData.nextPrayer,
            nextPrayerTime: prayerData.nextPrayerTime,
            fajrTime: prayerData.fajrTime,
            hijriDate: prayerData.hijriDate,
            configuration: configuration,
            isGrace: isGrace
        )

        // Refresh at grace end, next prayer time, or every 30 minutes
        let fallback = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let nextUpdate: Date
        if isGrace {
            // Refresh when grace ends
            let graceEnd = prayerData.nextPrayerTime.addingTimeInterval(PrayerTimeConstants.graceInterval)
            nextUpdate = min(graceEnd, fallback)
        } else if prayerData.nextPrayerTime > Date() {
            // Refresh at next prayer time
            nextUpdate = min(prayerData.nextPrayerTime, fallback)
        } else {
            // Prayer time is in the past (stale data) — use 30 min fallback
            nextUpdate = fallback
        }
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func loadPrayerData() -> (nextPrayer: String, nextPrayerTime: Date, fajrTime: Date?, hijriDate: String) {
        // Load from App Group UserDefaults
        guard let defaults = UserDefaults(suiteName: "group.com.safa.app") else {
            let defaultTime = Date().addingTimeInterval(18000)
            return ("Fajr", defaultTime, defaultTime, HijriDateHelper().hijriDateString())
        }

        let nextPrayer = defaults.string(forKey: "nextPrayerName") ?? "Fajr"
        let nextPrayerTime = defaults.object(forKey: "nextPrayerTime") as? Date ?? Date().addingTimeInterval(18000)
        let fajrTime = defaults.object(forKey: "fajrTime") as? Date
        let hijriDate = defaults.string(forKey: "hijriDate") ?? HijriDateHelper().hijriDateString()

        return (nextPrayer, nextPrayerTime, fajrTime, hijriDate)
    }
}

// MARK: - Configuration Intent

struct StandByConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "StandBy Prayer Times"
    static var description = IntentDescription("Large, readable prayer times for bedside StandBy mode")

    @Parameter(title: "Show Fajr Countdown", default: true)
    var showFajrCountdown: Bool

    @Parameter(title: "High Contrast", default: true)
    var highContrast: Bool
}

// MARK: - Widget Views

struct StandByPrayerWidgetView: View {
    var entry: StandByPrayerProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        switch family {
        case .systemSmall:
            SmallStandByView(entry: entry)
        case .systemMedium:
            MediumStandByView(entry: entry)
        default:
            SmallStandByView(entry: entry)
        }
    }
}

// MARK: - Small StandBy View

struct SmallStandByView: View {
    let entry: StandByPrayerEntry

    private var textColor: Color {
        entry.configuration.highContrast ? .white : .primary
    }

    private var secondaryColor: Color {
        entry.configuration.highContrast ? .white.opacity(0.7) : .secondary
    }

    var body: some View {
        VStack(spacing: 8) {
            // Prayer name - extra large
            Text(entry.nextPrayer)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
                .minimumScaleFactor(0.7)

            // Time - very large for visibility
            Text(entry.nextPrayerTime, style: .time)
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundColor(.accentColor)
                .minimumScaleFactor(0.6)

            // Countdown or grace message
            if entry.isGrace {
                Text("Prayer time")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(secondaryColor)
            } else {
                Text(entry.nextPrayerTime, style: .relative)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(secondaryColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium StandBy View

struct MediumStandByView: View {
    let entry: StandByPrayerEntry

    private var textColor: Color {
        entry.configuration.highContrast ? .white : .primary
    }

    private var secondaryColor: Color {
        entry.configuration.highContrast ? .white.opacity(0.7) : .secondary
    }

    private var isFajrNext: Bool {
        entry.nextPrayer.lowercased() == "fajr"
    }

    var body: some View {
        HStack(spacing: 20) {
            // Left side - Next Prayer
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: prayerIcon)
                        .font(.title2)
                        .foregroundColor(.accentColor)

                    Text(entry.isGrace ? "Time to pray" : "Next Prayer")
                        .font(.caption)
                        .foregroundColor(secondaryColor)
                }

                Text(entry.nextPrayer)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)

                Text(entry.nextPrayerTime, style: .time)
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundColor(.accentColor)
                    .minimumScaleFactor(0.7)

                if entry.isGrace {
                    Text("Prayer time")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(secondaryColor)
                } else {
                    Text(entry.nextPrayerTime, style: .relative)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(secondaryColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(secondaryColor)

            // Right side - Fajr info (for bedside use)
            if entry.configuration.showFajrCountdown, let fajrTime = entry.fajrTime, !isFajrNext {
                VStack(spacing: 8) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)

                    Text("Fajr")
                        .font(.headline)
                        .foregroundColor(textColor)

                    Text(fajrTime, style: .time)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)

                    if isPrayerTimeNow(fajrTime) {
                        Text("Prayer time")
                            .font(.caption)
                            .foregroundColor(secondaryColor)
                            .multilineTextAlignment(.center)
                    } else if fajrTime > Date() {
                        Text(fajrTime, style: .relative)
                            .font(.caption)
                            .foregroundColor(secondaryColor)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                // Show Hijri date when Fajr is next
                VStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.purple)

                    Text(entry.hijriDate)
                        .font(.headline)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)

                    Text(Date(), style: .date)
                        .font(.caption)
                        .foregroundColor(secondaryColor)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var prayerIcon: String {
        switch entry.nextPrayer.lowercased() {
        case "fajr": return "sunrise.fill"
        case "dhuhr": return "sun.max.fill"
        case "asr": return "sun.haze.fill"
        case "maghrib": return "sunset.fill"
        case "isha": return "moon.stars.fill"
        default: return "clock.fill"
        }
    }
}

// MARK: - Widget Definition

struct StandByPrayerWidget: Widget {
    let kind: String = "StandByPrayerWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: StandByConfigIntent.self,
            provider: StandByPrayerProvider()
        ) { entry in
            StandByPrayerWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Prayer StandBy")
        .description("Large, readable prayer times for bedside StandBy mode. Perfect for Fajr alarms.")
        .supportedFamilies([.systemSmall, .systemMedium])
        // Note: For proper StandBy support, add to Info.plist:
        // NSSupportsStandByMode = YES
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    StandByPrayerWidget()
} timeline: {
    StandByPrayerEntry(
        date: .now,
        nextPrayer: "Fajr",
        nextPrayerTime: Date().addingTimeInterval(18000),
        fajrTime: Date().addingTimeInterval(18000),
        hijriDate: HijriDateHelper().hijriDateString(),
        configuration: StandByConfigIntent(),
        isGrace: false
    )
}

#Preview(as: .systemMedium) {
    StandByPrayerWidget()
} timeline: {
    StandByPrayerEntry(
        date: .now,
        nextPrayer: "Isha",
        nextPrayerTime: Date().addingTimeInterval(3600),
        fajrTime: Date().addingTimeInterval(28800),
        hijriDate: HijriDateHelper().hijriDateString(),
        configuration: StandByConfigIntent(),
        isGrace: false
    )
}

#Preview("Fajr Next", as: .systemMedium) {
    StandByPrayerWidget()
} timeline: {
    StandByPrayerEntry(
        date: .now,
        nextPrayer: "Fajr",
        nextPrayerTime: Date().addingTimeInterval(14400),
        fajrTime: Date().addingTimeInterval(14400),
        hijriDate: HijriDateHelper().hijriDateString(),
        configuration: StandByConfigIntent(),
        isGrace: false
    )
}
