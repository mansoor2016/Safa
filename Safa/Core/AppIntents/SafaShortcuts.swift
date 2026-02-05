// MARK: - SafaShortcuts.swift
// PURPOSE: App Intents for Siri Shortcuts integration
// DEPENDENCIES: AppIntents

import AppIntents
import SwiftUI

// MARK: - Prayer Times Intent

struct GetPrayerTimesIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Prayer Times"
    static var description = IntentDescription("Get today's prayer times for your location")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // In a real implementation, this would fetch from the repository
        let prayerTimes = """
        Today's Prayer Times:
        Fajr: 5:23 AM
        Sunrise: 6:45 AM
        Dhuhr: 12:30 PM
        Asr: 3:45 PM
        Maghrib: 6:15 PM
        Isha: 7:45 PM
        """

        return .result(value: prayerTimes)
    }
}

// MARK: - Next Prayer Intent

struct GetNextPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Next Prayer"
    static var description = IntentDescription("Get the next prayer time")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // In a real implementation, this would calculate based on current time
        return .result(value: "Next prayer: Asr at 3:45 PM (in 2 hours)")
    }
}

// MARK: - Log Prayer Intent

struct LogPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Prayer"
    static var description = IntentDescription("Log that you've completed a prayer")

    @Parameter(title: "Prayer")
    var prayer: PrayerTypeEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$prayer) prayer")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // In a real implementation, this would save to the repository
        return .result(dialog: "Logged \(prayer.name) prayer. +10 Hasanat earned!")
    }
}

// MARK: - Prayer Type Entity

struct PrayerTypeEntity: AppEntity {
    var id: String
    var name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Prayer"
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = PrayerTypeEntityQuery()

    static let fajr = PrayerTypeEntity(id: "fajr", name: "Fajr")
    static let dhuhr = PrayerTypeEntity(id: "dhuhr", name: "Dhuhr")
    static let asr = PrayerTypeEntity(id: "asr", name: "Asr")
    static let maghrib = PrayerTypeEntity(id: "maghrib", name: "Maghrib")
    static let isha = PrayerTypeEntity(id: "isha", name: "Isha")
}

struct PrayerTypeEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [PrayerTypeEntity] {
        let all: [PrayerTypeEntity] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
        return all.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [PrayerTypeEntity] {
        [.fajr, .dhuhr, .asr, .maghrib, .isha]
    }
}

// MARK: - Start Tasbeeh Intent

struct StartTasbeehIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Tasbeeh"
    static var description = IntentDescription("Open the tasbeeh counter")

    static var openAppWhenRun: Bool = true

    @Parameter(title: "Dhikr")
    var dhikr: DhikrEntity?

    @MainActor
    func perform() async throws -> some IntentResult {
        // App will open to tasbeeh view
        return .result()
    }
}

// MARK: - Dhikr Entity

struct DhikrEntity: AppEntity {
    var id: String
    var name: String
    var arabic: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Dhikr"
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(arabic)")
    }

    static var defaultQuery = DhikrEntityQuery()

    static let subhanAllah = DhikrEntity(id: "subhanallah", name: "SubhanAllah", arabic: "سُبْحَانَ اللهِ")
    static let alhamdulillah = DhikrEntity(id: "alhamdulillah", name: "Alhamdulillah", arabic: "الْحَمْدُ للهِ")
    static let allahuAkbar = DhikrEntity(id: "allahuakbar", name: "Allahu Akbar", arabic: "اللهُ أَكْبَرُ")
}

struct DhikrEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [DhikrEntity] {
        let all: [DhikrEntity] = [.subhanAllah, .alhamdulillah, .allahuAkbar]
        return all.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [DhikrEntity] {
        [.subhanAllah, .alhamdulillah, .allahuAkbar]
    }
}

// MARK: - Open Quran Intent

struct OpenQuranIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Quran"
    static var description = IntentDescription("Open the Quran reader")

    static var openAppWhenRun: Bool = true

    @Parameter(title: "Surah Number")
    var surahNumber: Int?

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Get Qibla Direction Intent

struct GetQiblaDirectionIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Qibla Direction"
    static var description = IntentDescription("Get the Qibla direction from your location")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // In a real implementation, this would calculate based on user's location
        return .result(value: "Qibla direction: 58° (Northeast)")
    }
}

// MARK: - Daily Verse Intent

struct GetDailyVerseIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Daily Verse"
    static var description = IntentDescription("Get today's verse of the day")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // In a real implementation, this would fetch from the repository
        let verse = """
        بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ

        "In the name of Allah, the Most Gracious, the Most Merciful"

        — Surah Al-Fatiha (1:1)
        """
        return .result(value: verse)
    }
}

// MARK: - Ask Safa Intent

struct AskSafaIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask Safa"
    static var description = IntentDescription("Ask Safa an Islamic question")

    static var openAppWhenRun: Bool = true

    @Parameter(title: "Question")
    var question: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        // App will open to chat view with the question
        return .result()
    }
}

// MARK: - App Shortcuts Provider

struct SafaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetNextPrayerIntent(),
            phrases: [
                "What's the next prayer in \(.applicationName)",
                "When is the next prayer in \(.applicationName)",
                "Next prayer time in \(.applicationName)"
            ],
            shortTitle: "Next Prayer",
            systemImageName: "clock"
        )

        AppShortcut(
            intent: GetPrayerTimesIntent(),
            phrases: [
                "Get prayer times from \(.applicationName)",
                "Today's prayer times in \(.applicationName)",
                "Show me prayer times in \(.applicationName)"
            ],
            shortTitle: "Prayer Times",
            systemImageName: "list.bullet"
        )

        AppShortcut(
            intent: StartTasbeehIntent(),
            phrases: [
                "Start tasbeeh in \(.applicationName)",
                "Open dhikr counter in \(.applicationName)",
                "Count tasbeeh in \(.applicationName)"
            ],
            shortTitle: "Tasbeeh",
            systemImageName: "circle.circle"
        )

        AppShortcut(
            intent: GetQiblaDirectionIntent(),
            phrases: [
                "Which way is Qibla in \(.applicationName)",
                "Qibla direction in \(.applicationName)",
                "Find Qibla with \(.applicationName)"
            ],
            shortTitle: "Qibla",
            systemImageName: "location.north"
        )

        AppShortcut(
            intent: GetDailyVerseIntent(),
            phrases: [
                "Daily verse from \(.applicationName)",
                "Get verse of the day from \(.applicationName)",
                "Read today's verse in \(.applicationName)"
            ],
            shortTitle: "Daily Verse",
            systemImageName: "book"
        )

        AppShortcut(
            intent: AskSafaIntent(),
            phrases: [
                "Ask \(.applicationName) a question",
                "Ask \(.applicationName)",
                "Islamic question for \(.applicationName)"
            ],
            shortTitle: "Ask Safa",
            systemImageName: "sparkles"
        )
    }
}
