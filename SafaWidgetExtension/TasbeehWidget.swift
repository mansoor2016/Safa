// MARK: - TasbeehWidget.swift
// PURPOSE: Interactive tasbeeh counter widget with tap-to-increment
// DEPENDENCIES: WidgetKit, SwiftUI, AppIntents

import WidgetKit
import SwiftUI
import AppIntents
import AppIntents

// MARK: - Widget Entry

struct TasbeehEntry: TimelineEntry {
    let date: Date
    let count: Int
    let dhikrType: String
    let dhikrArabic: String
    let targetCount: Int
    let configuration: TasbeehConfigIntent
}

// MARK: - Widget Provider

struct TasbeehProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TasbeehEntry {
        TasbeehEntry(
            date: Date(),
            count: 0,
            dhikrType: "SubhanAllah",
            dhikrArabic: "سُبْحَانَ اللهِ",
            targetCount: 33,
            configuration: TasbeehConfigIntent()
        )
    }

    func snapshot(for configuration: TasbeehConfigIntent, in context: Context) async -> TasbeehEntry {
        let storage = TasbeehWidgetData.load()
        return TasbeehEntry(
            date: Date(),
            count: storage.count,
            dhikrType: storage.dhikrType,
            dhikrArabic: storage.dhikrArabic,
            targetCount: storage.targetCount,
            configuration: configuration
        )
    }

    func timeline(for configuration: TasbeehConfigIntent, in context: Context) async -> Timeline<TasbeehEntry> {
        let storage = TasbeehWidgetData.load()
        let entry = TasbeehEntry(
            date: Date(),
            count: storage.count,
            dhikrType: storage.dhikrType,
            dhikrArabic: storage.dhikrArabic,
            targetCount: storage.targetCount,
            configuration: configuration
        )

        // Widget will be refreshed by intent, but also refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

// MARK: - Tasbeeh Widget Data

struct TasbeehWidgetData {
    var count: Int
    var dhikrType: String
    var dhikrArabic: String
    var targetCount: Int

    static func load() -> TasbeehWidgetData {
        guard let defaults = UserDefaults(suiteName: "group.com.safa.app") else {
            return TasbeehWidgetData(count: 0, dhikrType: "SubhanAllah", dhikrArabic: "سُبْحَانَ اللهِ", targetCount: 33)
        }

        return TasbeehWidgetData(
            count: defaults.integer(forKey: "tasbeeh_widget_count"),
            dhikrType: defaults.string(forKey: "tasbeeh_widget_dhikr") ?? "SubhanAllah",
            dhikrArabic: defaults.string(forKey: "tasbeeh_widget_arabic") ?? "سُبْحَانَ اللهِ",
            targetCount: defaults.integer(forKey: "tasbeeh_widget_target") == 0 ? 33 : defaults.integer(forKey: "tasbeeh_widget_target")
        )
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: "group.com.safa.app") else { return }
        defaults.set(count, forKey: "tasbeeh_widget_count")
        defaults.set(dhikrType, forKey: "tasbeeh_widget_dhikr")
        defaults.set(dhikrArabic, forKey: "tasbeeh_widget_arabic")
        defaults.set(targetCount, forKey: "tasbeeh_widget_target")
    }
}

// MARK: - Configuration Intent

struct TasbeehConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Tasbeeh Counter"
    static var description = IntentDescription("Count your dhikr with a tap")

    @Parameter(title: "Show Arabic", default: true)
    var showArabic: Bool

    @Parameter(title: "Target Count", default: 33)
    var targetCount: Int
}

// MARK: - Increment Intent

struct WidgetIncrementTasbeehIntent: AppIntent {
    static var title: LocalizedStringResource = "Increment Tasbeeh"
    static var description = IntentDescription("Add one to the counter")

    func perform() async throws -> some IntentResult {
        var data = TasbeehWidgetData.load()
        data.count += 1
        data.save()

        // Reload widget
        WidgetCenter.shared.reloadTimelines(ofKind: "TasbeehWidget")

        return .result()
    }
}

// MARK: - Reset Intent

struct WidgetResetTasbeehIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Tasbeeh"
    static var description = IntentDescription("Reset the counter to zero")

    func perform() async throws -> some IntentResult {
        var data = TasbeehWidgetData.load()
        data.count = 0
        data.save()

        // Reload widget
        WidgetCenter.shared.reloadTimelines(ofKind: "TasbeehWidget")

        return .result()
    }
}

// MARK: - Cycle Dhikr Intent

struct WidgetCycleDhikrIntent: AppIntent {
    static var title: LocalizedStringResource = "Change Dhikr"
    static var description = IntentDescription("Cycle to the next dhikr type")

    private static let dhikrTypes: [(name: String, arabic: String)] = [
        ("SubhanAllah", "سُبْحَانَ اللهِ"),
        ("Alhamdulillah", "الْحَمْدُ للهِ"),
        ("Allahu Akbar", "اللهُ أَكْبَرُ"),
        ("La ilaha illallah", "لَا إِلٰهَ إِلَّا اللهُ")
    ]

    func perform() async throws -> some IntentResult {
        var data = TasbeehWidgetData.load()

        // Find current index and cycle to next
        let currentIndex = Self.dhikrTypes.firstIndex(where: { $0.name == data.dhikrType }) ?? 0
        let nextIndex = (currentIndex + 1) % Self.dhikrTypes.count
        let nextDhikr = Self.dhikrTypes[nextIndex]

        data.dhikrType = nextDhikr.name
        data.dhikrArabic = nextDhikr.arabic
        data.count = 0 // Reset count when changing dhikr
        data.save()

        // Reload widget
        WidgetCenter.shared.reloadTimelines(ofKind: "TasbeehWidget")

        return .result()
    }
}

// MARK: - Widget Views

struct TasbeehWidgetView: View {
    var entry: TasbeehProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallTasbeehView(entry: entry)
        case .systemMedium:
            MediumTasbeehView(entry: entry)
        default:
            SmallTasbeehView(entry: entry)
        }
    }
}

// MARK: - Small Widget View

struct SmallTasbeehView: View {
    let entry: TasbeehEntry

    private var progress: Double {
        guard entry.targetCount > 0 else { return 0 }
        return min(Double(entry.count) / Double(entry.targetCount), 1.0)
    }

    private var isComplete: Bool {
        entry.count >= entry.targetCount
    }

    var body: some View {
        Button(intent: WidgetIncrementTasbeehIntent()) {
            VStack(spacing: 8) {
                // Dhikr name
                if entry.configuration.showArabic {
                    Text(entry.dhikrArabic)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Count with circular progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            isComplete ? Color.green : Color.accentColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(entry.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(isComplete ? .green : .primary)
                }
                .frame(width: 60, height: 60)

                // Target
                Text("/ \(entry.targetCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Tap hint
                Text("Tap to count")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Medium Widget View

struct MediumTasbeehView: View {
    let entry: TasbeehEntry

    private var progress: Double {
        guard entry.targetCount > 0 else { return 0 }
        return min(Double(entry.count) / Double(entry.targetCount), 1.0)
    }

    private var isComplete: Bool {
        entry.count >= entry.targetCount
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Counter button
            Button(intent: WidgetIncrementTasbeehIntent()) {
                VStack(spacing: 8) {
                    if entry.configuration.showArabic {
                        Text(entry.dhikrArabic)
                            .font(.title3)
                            .foregroundColor(.primary)
                    }

                    Text(entry.dhikrType)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 6)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                isComplete ? Color.green : Color.accentColor,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("\(entry.count)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(isComplete ? .green : .primary)

                            Text("/ \(entry.targetCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 80, height: 80)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)

            Divider()

            // Right side - Actions
            VStack(spacing: 12) {
                // Reset button
                Button(intent: WidgetResetTasbeehIntent()) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                // Cycle dhikr button
                Button(intent: WidgetCycleDhikrIntent()) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Change")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Spacer()

                // Completion indicator
                if isComplete {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Complete!")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("\(entry.targetCount - entry.count) to go")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}

// MARK: - Widget Definition

struct TasbeehWidget: Widget {
    let kind: String = "TasbeehWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TasbeehConfigIntent.self,
            provider: TasbeehProvider()
        ) { entry in
            TasbeehWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Tasbeeh Counter")
        .description("Count your dhikr with a tap. Tracks SubhanAllah, Alhamdulillah, Allahu Akbar.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TasbeehWidget()
} timeline: {
    TasbeehEntry(
        date: .now,
        count: 15,
        dhikrType: "SubhanAllah",
        dhikrArabic: "سُبْحَانَ اللهِ",
        targetCount: 33,
        configuration: TasbeehConfigIntent()
    )
}

#Preview(as: .systemMedium) {
    TasbeehWidget()
} timeline: {
    TasbeehEntry(
        date: .now,
        count: 28,
        dhikrType: "Alhamdulillah",
        dhikrArabic: "الْحَمْدُ للهِ",
        targetCount: 33,
        configuration: TasbeehConfigIntent()
    )
}

#Preview("Complete", as: .systemSmall) {
    TasbeehWidget()
} timeline: {
    TasbeehEntry(
        date: .now,
        count: 33,
        dhikrType: "SubhanAllah",
        dhikrArabic: "سُبْحَانَ اللهِ",
        targetCount: 33,
        configuration: TasbeehConfigIntent()
    )
}
