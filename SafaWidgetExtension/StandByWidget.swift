// MARK: - StandByWidget.swift
// PURPOSE: StandBy mode widget optimized for bedside visibility (iOS 17+)
// DEPENDENCIES: WidgetKit, SwiftUI, SafaShared

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
    /// Stable prayer identifier (e.g. "fajr") for logic that must not depend on localized names.
    let prayerId: String?
    /// Resolved contextual state for matching lock screen behavior.
    let widgetState: WidgetPrayerState
    /// Post-prayer snippet fields (nil when not in postPrayer state or no snippet available).
    let snippetTranslation: String?
    let snippetReference: String?
}

// MARK: - Widget Provider

struct StandByPrayerProvider: AppIntentTimelineProvider {

    private let store = WidgetDataStore()
    private let defaultPrayers = DefaultPrayerTimes()
    private let calculator = NextPrayerCalculator()

    func placeholder(in context: Context) -> StandByPrayerEntry {
        makeEntry(configuration: StandByConfigIntent())
    }

    func snapshot(for configuration: StandByConfigIntent, in context: Context) async -> StandByPrayerEntry {
        makeEntry(configuration: configuration)
    }

    func timeline(for configuration: StandByConfigIntent, in context: Context) async -> Timeline<StandByPrayerEntry> {
        let now = Date()
        let prayers = store.loadPrayers() ?? defaultPrayers.forToday()

        // Use contextual boundaries that include post-prayer expiry
        let boundaryDates = calculator.contextualTimelineBoundaries(from: prayers, startingAt: now)

        let entries = boundaryDates.map { boundaryDate in
            makeEntry(configuration: configuration, at: boundaryDate, prayers: prayers)
        }

        let refreshDate = calculator.timelineRefreshDate(from: prayers, startingAt: now)
        return Timeline(entries: entries, policy: .after(refreshDate))
    }

    private func makeEntry(
        configuration: StandByConfigIntent,
        at date: Date = Date(),
        prayers: [PrayerInfo]? = nil
    ) -> StandByPrayerEntry {
        let prayerList = prayers ?? store.loadPrayers() ?? defaultPrayers.forToday()
        let next = calculator.nextPrayer(from: prayerList, at: date)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayerList,
            loggedPrayerIds: store.readLoggedPrayerIds(at: date),
            streakCount: store.readStreakData().current,
            at: date
        )

        // Read snippet for post-prayer, validating prayerId
        let snippet = store.readSnippet()
        let snippetTranslation: String?
        let snippetReference: String?
        if case .postPrayer(let id) = state, snippet?.prayerId == id {
            snippetTranslation = snippet?.translation
            snippetReference = snippet?.reference
        } else {
            snippetTranslation = nil
            snippetReference = nil
        }

        let isGrace = prayerList.contains { isPrayerTimeNow($0.time, at: date) }
        let prayerId: String?
        switch state {
        case .preAdhan(_, _, let id), .prayerWindow(_, _, let id),
             .gracePrompt(_, let id), .postPrayer(let id):
            prayerId = id
        case .allComplete, .dayEnded:
            prayerId = next?.id
        }

        return StandByPrayerEntry(
            date: date,
            nextPrayer: next?.name ?? String(localized: "Isha"),
            nextPrayerTime: next?.time ?? date,
            fajrTime: store.readFajrTime(),
            hijriDate: store.readHijriDate(for: date),
            configuration: configuration,
            isGrace: isGrace,
            prayerId: prayerId,
            widgetState: state,
            snippetTranslation: snippetTranslation,
            snippetReference: snippetReference
        )
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

// MARK: - Prayer-Specific Background Gradient

/// Near-black gradients with barely perceptible prayer-specific tinting.
/// These should be felt subconsciously rather than noticed visually.
private func prayerGradient(for prayerId: String?) -> LinearGradient {
    let colors: [Color]
    switch prayerId ?? "" {
    case "fajr":
        // Cool pre-dawn blue
        colors = [Color(red: 0.05, green: 0.11, blue: 0.16), Color(red: 0.11, green: 0.16, blue: 0.22)]
    case "dhuhr":
        // Warm midday
        colors = [Color(red: 0.10, green: 0.10, blue: 0.06), Color(red: 0.16, green: 0.16, blue: 0.10)]
    case "asr":
        // Amber afternoon
        colors = [Color(red: 0.10, green: 0.08, blue: 0.06), Color(red: 0.16, green: 0.15, blue: 0.09)]
    case "maghrib":
        // Sunset ember
        colors = [Color(red: 0.10, green: 0.05, blue: 0.04), Color(red: 0.16, green: 0.08, blue: 0.06)]
    case "isha":
        // Night sky indigo
        colors = [Color(red: 0.04, green: 0.04, blue: 0.10), Color(red: 0.08, green: 0.08, blue: 0.16)]
    default:
        colors = [.black, .black]
    }
    return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
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
            switch entry.widgetState {
            case .preAdhan(let name, let time, _):
                Text(name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .minimumScaleFactor(0.7)

                Text(time, style: .time)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundColor(.accentColor)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())

                Text(time, style: .relative)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(secondaryColor)
                    .contentTransition(.numericText())

            case .prayerWindow(let name, _, _):
                Text(name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .minimumScaleFactor(0.7)

                Image(systemName: standByPrayerIcon(filled: true))
                    .font(.system(size: 42))
                    .foregroundColor(.accentColor)

                Text("Time to pray")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(secondaryColor)

            case .gracePrompt(let name, _):
                Text(name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .minimumScaleFactor(0.7)

                Image(systemName: "checkmark.circle")
                    .font(.system(size: 42))
                    .foregroundColor(.accentColor.opacity(0.7))

                Text("Pray when ready")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(secondaryColor)

            case .postPrayer:
                if let translation = entry.snippetTranslation,
                   let reference = entry.snippetReference {
                    Image(systemName: "book.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor.opacity(0.8))

                    Text("\"\(translation)\"")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                        .lineLimit(3)

                    Text("— \(reference)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(secondaryColor)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.green.opacity(0.8))

                    Text("Alhamdulillah")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(textColor)
                }

            case .allComplete(let streak):
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.purple.opacity(0.8))

                Text("All prayers complete")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)

                if streak > 0 {
                    Text("\(streak)-day streak")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(secondaryColor)
                }

            case .dayEnded:
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.purple.opacity(0.6))

                Text("Rest well")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(textColor)

                Text(entry.hijriDate)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(secondaryColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func standByPrayerIcon(filled: Bool = false) -> String {
        let base: String
        switch entry.prayerId ?? "" {
        case "fajr": base = "sunrise"
        case "dhuhr": base = "sun.max"
        case "asr": base = "sun.haze"
        case "maghrib": base = "sunset"
        case "isha": base = "moon.stars"
        default: base = "clock"
        }
        return filled ? "\(base).fill" : base
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
        if let id = entry.prayerId { return id == "fajr" }
        guard let fajrTime = entry.fajrTime else { return false }
        return abs(entry.nextPrayerTime.timeIntervalSince(fajrTime)) < 60
    }

    var body: some View {
        HStack(spacing: 20) {
            // Left side — contextual primary content
            leftColumn
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(secondaryColor)

            // Right side — secondary content
            rightColumn
                .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var leftColumn: some View {
        switch entry.widgetState {
        case .preAdhan(let name, let time, _):
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: prayerIcon)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    Text("Next Prayer")
                        .font(.caption)
                        .foregroundColor(secondaryColor)
                }

                Text(name)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)

                Text(time, style: .time)
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundColor(.accentColor)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())

                Text(time, style: .relative)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(secondaryColor)
                    .contentTransition(.numericText())
            }

        case .prayerWindow(let name, let time, _):
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: prayerIcon)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    Text("Time to pray")
                        .font(.caption)
                        .foregroundColor(secondaryColor)
                }

                Text(name)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)

                Text(time, style: .time)
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundColor(.accentColor)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())

                Text("Prayer time")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(secondaryColor)
            }

        case .gracePrompt(let name, _):
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundColor(.accentColor.opacity(0.7))
                    Text("Pray when ready")
                        .font(.caption)
                        .foregroundColor(secondaryColor)
                }

                Text(name)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)

                Text("Pray when ready")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(secondaryColor)
            }

        case .postPrayer:
            VStack(alignment: .leading, spacing: 8) {
                if let translation = entry.snippetTranslation,
                   let reference = entry.snippetReference {
                    Image(systemName: "book.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor.opacity(0.8))

                    Text("\"\(translation)\"")
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundColor(textColor)
                        .lineLimit(3)
                        .minimumScaleFactor(0.6)

                    Text("— \(reference)")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(secondaryColor)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.green.opacity(0.8))

                    Text("Alhamdulillah")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(textColor)
                }
            }

        case .allComplete(let streak):
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.purple.opacity(0.8))

                Text("All prayers complete")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)

                if streak > 0 {
                    Text("\(streak)-day streak")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(secondaryColor)
                }
            }

        case .dayEnded:
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.purple.opacity(0.6))

                Text("Rest well")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)

                Text(entry.hijriDate)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(secondaryColor)
            }
        }
    }

    @ViewBuilder
    private var rightColumn: some View {
        switch entry.widgetState {
        case .preAdhan, .prayerWindow, .gracePrompt:
            // Show Fajr countdown or hijri date (preserves original bedside behavior)
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
                        .contentTransition(.numericText())

                    if isPrayerTimeNow(fajrTime, at: entry.date) {
                        Text("Prayer time")
                            .font(.caption)
                            .foregroundColor(secondaryColor)
                            .multilineTextAlignment(.center)
                    } else if fajrTime > entry.date {
                        Text(fajrTime, style: .relative)
                            .font(.caption)
                            .foregroundColor(secondaryColor)
                            .multilineTextAlignment(.center)
                    }
                }
            } else {
                hijriPanel
            }

        case .postPrayer, .allComplete, .dayEnded:
            hijriPanel
        }
    }

    private var hijriPanel: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 32))
                .foregroundColor(.purple)

            Text(entry.hijriDate)
                .font(.headline)
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)

            Text(entry.date, style: .date)
                .font(.caption)
                .foregroundColor(secondaryColor)
        }
    }

    private var prayerIcon: String {
        let base: String
        switch entry.prayerId ?? "" {
        case "fajr": base = "sunrise"
        case "dhuhr": base = "sun.max"
        case "asr": base = "sun.haze"
        case "maghrib": base = "sunset"
        case "isha": base = "moon.stars"
        default: return "clock"
        }
        switch entry.widgetState {
        case .prayerWindow: return "\(base).fill"
        default: return base
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
                .containerBackground(for: .widget) {
                    if entry.configuration.highContrast {
                        Color.black
                    } else {
                        prayerGradient(for: entry.prayerId)
                    }
                }
        }
        .configurationDisplayName("Prayer StandBy")
        .description("Large, readable prayer times for bedside StandBy mode. Perfect for Fajr alarms.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    StandByPrayerWidget()
} timeline: {
    StandByPrayerEntry(
        date: .now,
        nextPrayer: String(localized: "Fajr"),
        nextPrayerTime: Date().addingTimeInterval(18000),
        fajrTime: Date().addingTimeInterval(18000),
        hijriDate: HijriDateHelper().hijriDateString(),
        configuration: StandByConfigIntent(),
        isGrace: false,
        prayerId: "fajr",
        widgetState: .preAdhan(prayerName: "Fajr", prayerTime: Date().addingTimeInterval(18000), prayerId: "fajr"),
        snippetTranslation: nil,
        snippetReference: nil
    )
}

#Preview(as: .systemMedium) {
    StandByPrayerWidget()
} timeline: {
    StandByPrayerEntry(
        date: .now,
        nextPrayer: String(localized: "Isha"),
        nextPrayerTime: Date().addingTimeInterval(3600),
        fajrTime: Date().addingTimeInterval(28800),
        hijriDate: HijriDateHelper().hijriDateString(),
        configuration: StandByConfigIntent(),
        isGrace: false,
        prayerId: "isha",
        widgetState: .preAdhan(prayerName: "Isha", prayerTime: Date().addingTimeInterval(3600), prayerId: "isha"),
        snippetTranslation: nil,
        snippetReference: nil
    )
}

#Preview("Post-Prayer", as: .systemSmall) {
    StandByPrayerWidget()
} timeline: {
    StandByPrayerEntry(
        date: .now,
        nextPrayer: String(localized: "Dhuhr"),
        nextPrayerTime: Date().addingTimeInterval(7200),
        fajrTime: nil,
        hijriDate: HijriDateHelper().hijriDateString(),
        configuration: StandByConfigIntent(),
        isGrace: false,
        prayerId: "fajr",
        widgetState: .postPrayer(prayerId: "fajr"),
        snippetTranslation: "Indeed, with hardship comes ease.",
        snippetReference: "Quran 94:6"
    )
}

#Preview("All Complete", as: .systemMedium) {
    StandByPrayerWidget()
} timeline: {
    StandByPrayerEntry(
        date: .now,
        nextPrayer: String(localized: "Isha"),
        nextPrayerTime: Date(),
        fajrTime: nil,
        hijriDate: HijriDateHelper().hijriDateString(),
        configuration: StandByConfigIntent(),
        isGrace: false,
        prayerId: nil,
        widgetState: .allComplete(streakCount: 7),
        snippetTranslation: nil,
        snippetReference: nil
    )
}
