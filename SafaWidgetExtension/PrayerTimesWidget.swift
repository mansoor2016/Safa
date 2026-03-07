// MARK: - PrayerTimesWidget.swift
// PURPOSE: Contextual widget showing prayer state — countdown, prayer window, log prompt, spiritual content
// DEPENDENCIES: WidgetKit, SwiftUI, SafaShared

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
    let nextPrayerName: String
    let nextPrayerTime: Date
    let hasNextPrayer: Bool
    /// Whether the prayer time has just arrived (grace window: 0-15 min after prayer time).
    let isGrace: Bool

    // MARK: - Contextual State

    /// Resolved widget state for lock screen contextual display.
    let widgetState: WidgetPrayerState
    /// Post-prayer snippet content (may be nil if no snippet available).
    let snippetArabic: String?
    let snippetTranslation: String?
    let snippetReference: String?
    /// Dynamic deep link URL based on current state.
    let deepLinkURL: String
}

// MARK: - Widget Provider

struct Provider: AppIntentTimelineProvider {

    private let defaultPrayers = DefaultPrayerTimes()
    private let store = WidgetDataStore()
    private let calculator = NextPrayerCalculator()

    private func loadPrayers() -> [PrayerInfo] {
        store.loadPrayers() ?? defaultPrayers.forToday()
    }

    private func makeEntry(
        configuration: ConfigurationAppIntent,
        at date: Date = Date(),
        nextPrayer: PrayerInfo? = nil,
        prayers: [PrayerInfo]? = nil,
        isGrace: Bool = false
    ) -> PrayerTimeEntry {
        let prayerList = prayers ?? loadPrayers()
        let next = nextPrayer ?? calculator.nextPrayer(from: prayerList, at: date)

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayerList,
            loggedPrayerIds: store.readLoggedPrayerIds(at: date),
            streakCount: store.readStreakData().current,
            at: date
        )

        let (snippetArabic, snippetTranslation, snippetReference, deepLink) =
            WidgetSnippetResolver.resolve(state: state, snippet: store.readSnippet())

        return PrayerTimeEntry(
            date: date,
            prayers: prayerList,
            hijriDate: store.readHijriDate(for: date),
            configuration: configuration,
            nextPrayerName: next?.name ?? String(localized: "Isha"),
            nextPrayerTime: next?.time ?? date,
            hasNextPrayer: next != nil,
            isGrace: isGrace,
            widgetState: state,
            snippetArabic: snippetArabic,
            snippetTranslation: snippetTranslation,
            snippetReference: snippetReference,
            deepLinkURL: deepLink
        )
    }

    func placeholder(in context: Context) -> PrayerTimeEntry {
        let prayers = defaultPrayers.forToday()
        let next = calculator.nextPrayer(from: prayers)
        return PrayerTimeEntry(
            date: Date(),
            prayers: prayers,
            hijriDate: store.readHijriDate(),
            configuration: ConfigurationAppIntent(),
            nextPrayerName: next?.name ?? String(localized: "Isha"),
            nextPrayerTime: next?.time ?? Date(),
            hasNextPrayer: next != nil,
            isGrace: false,
            widgetState: .preAdhan(prayerName: next?.name ?? "Isha", prayerTime: next?.time ?? Date(), prayerId: next?.id ?? "isha"),
            snippetArabic: nil,
            snippetTranslation: nil,
            snippetReference: nil,
            deepLinkURL: "safa://prayer"
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> PrayerTimeEntry {
        makeEntry(configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<PrayerTimeEntry> {
        let now = Date()
        let prayers = loadPrayers()

        // Use contextual boundaries that include post-prayer expiry times
        let boundaryDates = calculator.contextualTimelineBoundaries(from: prayers, startingAt: now)

        let entries = boundaryDates.map { boundaryDate in
            // For each boundary, compute the state at that moment
            let isGrace = prayers.contains { isPrayerTimeNow($0.time, at: boundaryDate) }
            let next = calculator.nextPrayer(from: prayers, at: boundaryDate)
                ?? prayers.last(where: { isPrayerTimeNow($0.time, at: boundaryDate) })

            return makeEntry(
                configuration: configuration,
                at: boundaryDate,
                nextPrayer: next,
                prayers: prayers,
                isGrace: isGrace
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
                Image(systemName: smallIcon)
                    .font(.caption)
                    .foregroundColor(.accentColor)
                Spacer()
            }

            Spacer()

            switch entry.widgetState {
            case .preAdhan(let name, let time, _):
                Text("Next Prayer")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(time, style: .time)
                    .font(.caption)
                    .foregroundColor(.accentColor)

            case .prayerWindow(let name, _, _):
                Text("Time to pray")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Prayer time")
                    .font(.caption)
                    .foregroundColor(.accentColor)

            case .gracePrompt(let name, _):
                Text(name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Pray when ready")
                    .font(.caption)
                    .foregroundColor(.accentColor)

            case .postPrayer:
                if let translation = entry.snippetTranslation,
                   let reference = entry.snippetReference {
                    Text("\"\(translation)\"")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text("— \(reference)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)

                    Text("Alhamdulillah")
                        .font(.caption)
                        .foregroundColor(.primary)
                }

            case .allComplete(let streak):
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundColor(.purple)

                Text("All prayers complete")
                    .font(.caption2)
                    .foregroundColor(.primary)

                if streak > 0 {
                    Text("\(streak)-day streak")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

            case .dayEnded:
                Text("Rest well")
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

    private var smallIcon: String {
        switch entry.widgetState {
        case .prayerWindow:
            return prayerIcon(for: entry.widgetState, filled: true)
        case .preAdhan, .gracePrompt:
            return prayerIcon(for: entry.widgetState)
        case .postPrayer:
            return "book.fill"
        case .allComplete:
            return "checkmark.circle.fill"
        case .dayEnded:
            return "moon.zzz.fill"
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: PrayerTimeEntry

    var body: some View {
        HStack {
            // Left side — contextual state
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: mediumIcon)
                        .font(.title3)
                        .foregroundColor(.accentColor)

                    Text("Safa")
                        .font(.headline)
                }

                Spacer()

                switch entry.widgetState {
                case .preAdhan(let name, let time, _):
                    Text("Next Prayer")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(name)
                        .font(.title)
                        .fontWeight(.bold)

                    HStack {
                        Text(time, style: .time)
                        Text("·")
                        Text(time, style: .relative)
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)

                case .prayerWindow(let name, let time, _):
                    Text("Time to pray")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(name)
                        .font(.title)
                        .fontWeight(.bold)

                    HStack {
                        Text(time, style: .time)
                        Text("·")
                        Text("Prayer time")
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)

                case .gracePrompt(let name, _):
                    Text(name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Pray when ready")
                        .font(.caption)
                        .foregroundColor(.accentColor)

                case .postPrayer:
                    if let translation = entry.snippetTranslation,
                       let reference = entry.snippetReference {
                        Text("\"\(translation)\"")
                            .font(.callout)
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        Text("— \(reference)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)

                        Text("Alhamdulillah")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }

                case .allComplete(let streak):
                    Text("All prayers complete")
                        .font(.callout)
                        .fontWeight(.bold)

                    if streak > 0 {
                        Text("\(streak)-day streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                case .dayEnded:
                    Spacer()

                    Text("Rest well")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: "moon.zzz.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Right side — prayer list
            VStack(alignment: .trailing, spacing: 4) {
                ForEach(entry.prayers, id: \.id) { prayer in
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

    private var mediumIcon: String {
        switch entry.widgetState {
        case .prayerWindow:
            return prayerIcon(for: entry.widgetState, filled: true)
        case .preAdhan, .gracePrompt:
            return prayerIcon(for: entry.widgetState)
        case .postPrayer:
            return "book.fill"
        case .allComplete:
            return "moon.stars.fill"
        case .dayEnded:
            return "moon.zzz.fill"
        }
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

// MARK: - Lock Screen Widgets

struct AccessoryCircularView: View {
    let entry: PrayerTimeEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            switch entry.widgetState {
            case .preAdhan(let name, let time, _):
                VStack(spacing: 2) {
                    Text(name.prefix(3))
                        .font(.caption2)
                        .fontWeight(.bold)
                    Text(time, style: .time)
                        .font(.caption2)
                }

            case .prayerWindow(let name, _, _):
                VStack(spacing: 2) {
                    Image(systemName: prayerIcon(for: entry.widgetState, filled: true))
                        .font(.caption)
                    Text(name.prefix(3))
                        .font(.caption2)
                        .fontWeight(.bold)
                }

            case .gracePrompt:
                Image(systemName: "circle")
                    .font(.title3)

            case .postPrayer:
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)

            case .allComplete:
                VStack(spacing: 2) {
                    Image(systemName: "moon.stars.fill")
                        .font(.caption)
                    Image(systemName: "checkmark")
                        .font(.caption2)
                }

            case .dayEnded:
                Image(systemName: "moon.zzz.fill")
                    .font(.title3)
            }
        }
    }
}

struct AccessoryRectangularView: View {
    let entry: PrayerTimeEntry

    var body: some View {
        switch entry.widgetState {
        case .preAdhan(let name, let time, _):
            HStack {
                Image(systemName: prayerIcon(for: entry.widgetState))
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text(time, style: .time)
                        Text("·")
                        Text(time, style: .relative)
                    }
                    .font(.caption)
                }
                Spacer()
            }

        case .prayerWindow(let name, let time, _):
            HStack {
                Image(systemName: prayerIcon(for: entry.widgetState, filled: true))
                VStack(alignment: .leading) {
                    Text("Time to pray")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text(name)
                        Text("·")
                        Text(time, style: .time)
                    }
                    .font(.caption)
                }
                Spacer()
            }

        case .gracePrompt(let name, _):
            HStack {
                Image(systemName: "checkmark.circle")
                VStack(alignment: .leading) {
                    Text("\(name)")
                        .font(.headline)
                    Text("Pray when ready")
                        .font(.caption)
                }
                Spacer()
            }

        case .postPrayer:
            if let translation = entry.snippetTranslation,
               let reference = entry.snippetReference {
                HStack {
                    Image(systemName: "book.fill")
                    VStack(alignment: .leading) {
                        Text("\"\(translation)\"")
                            .font(.caption)
                            .lineLimit(2)
                        Text("— \(reference)")
                            .font(.caption2)
                    }
                    Spacer()
                }
            } else {
                // Fallback if no snippet available
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    VStack(alignment: .leading) {
                        Text("Prayer logged")
                            .font(.headline)
                        Text("Alhamdulillah")
                            .font(.caption)
                    }
                    Spacer()
                }
            }

        case .allComplete(let streak):
            HStack {
                Image(systemName: "moon.stars.fill")
                VStack(alignment: .leading) {
                    Text("All prayers complete")
                        .font(.headline)
                    if streak > 0 {
                        Text("\(streak) day streak")
                            .font(.caption)
                    }
                }
                Spacer()
            }

        case .dayEnded:
            HStack {
                Image(systemName: "moon.zzz")
                VStack(alignment: .leading) {
                    Text("Rest well")
                        .font(.headline)
                    Text(entry.hijriDate)
                        .font(.caption)
                }
                Spacer()
            }
        }
    }
}

struct AccessoryInlineView: View {
    let entry: PrayerTimeEntry

    var body: some View {
        switch entry.widgetState {
        case .preAdhan(let name, let time, _):
            Text("\(name) at \(time, style: .time)")

        case .prayerWindow(let name, _, _):
            Text("Time to pray \(name)")

        case .gracePrompt(let name, _):
            Text("\(name) · pray when ready")

        case .postPrayer:
            if let reference = entry.snippetReference {
                Text(reference)
            } else {
                Text("Alhamdulillah ✓")
            }

        case .allComplete:
            Text("All prayers complete")

        case .dayEnded:
            Text("Rest well")
        }
    }
}

// MARK: - Helpers

/// Returns an SF Symbol name for the prayer associated with a widget state.
private func prayerIcon(for state: WidgetPrayerState, filled: Bool = false) -> String {
    let prayerId: String
    switch state {
    case .preAdhan(_, _, let id), .prayerWindow(_, _, let id), .gracePrompt(_, let id), .postPrayer(let id):
        prayerId = id
    case .allComplete, .dayEnded:
        prayerId = ""
    }

    let base: String
    switch prayerId {
    case "fajr": base = "sunrise"
    case "dhuhr": base = "sun.max"
    case "asr": base = "sun.haze"
    case "maghrib": base = "sunset"
    case "isha": base = "moon.stars"
    default: base = "clock"
    }

    return filled ? "\(base).fill" : base
}

// MARK: - Widget Definition

struct PrayerTimesWidget: Widget {
    let kind: String = "SafaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            SafaWidgetEntryView(entry: entry)
                .widgetURL(URL(string: entry.deepLinkURL))
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
