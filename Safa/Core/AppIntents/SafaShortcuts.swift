// MARK: - SafaShortcuts.swift
// PURPOSE: App Intents for Siri Shortcuts integration
// DEPENDENCIES: AppIntents, Dependencies

import AppIntents
import SwiftUI

// MARK: - Intent Helpers

private enum IntentHelpers {
    /// Get the user's saved coordinates, falling back to London
    static func getCoordinates() -> Coordinates {
        Dependencies.shared.locationService.coordinates ?? AppDefaults.defaultCoordinates
    }

    /// Get the user's saved calculation method
    static func getCalculationMethod() async -> CalculationMethod {
        let prefs = await PreferencesManager.shared.getPreferences()
        return prefs.calculationMethod
    }

    /// Calculate today's prayer times using real data
    static func getTodayPrayers() async -> [PrayerTime] {
        let coords = getCoordinates()
        let prefs = await PreferencesManager.shared.getPreferences()
        let calculator = PrayerTimeCalculator()
        return calculator.calculatePrayerTimes(for: Date(), location: coords, method: prefs.calculationMethod, madhab: prefs.madhab)
    }

    /// Format a time for display
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Map PrayerTypeEntity ID to PrayerType
    static func prayerType(from entityId: String) -> PrayerType? {
        PrayerType(rawValue: entityId)
    }
}

// MARK: - Prayer Times Intent

struct GetPrayerTimesIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Prayer Times"
    static var description = IntentDescription("Get today's prayer times for your location")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let prayers = await IntentHelpers.getTodayPrayers()

        guard !prayers.isEmpty else {
            return .result(value: "Unable to calculate prayer times. Please open Safa to set your location.")
        }

        let lines = prayers.map { prayer in
            "\(prayer.type.displayName): \(IntentHelpers.formatTime(prayer.time))"
        }
        let prayerTimes = "Today's Prayer Times:\n" + lines.joined(separator: "\n")

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
        let prayers = await IntentHelpers.getTodayPrayers()
        let now = Date()

        // Find the next obligatory prayer
        guard let nextPrayer = prayers.first(where: { $0.type.isObligatory && $0.time > now }) else {
            return .result(value: "All prayers for today have passed. May Allah accept your worship.")
        }

        let interval = nextPrayer.time.timeIntervalSince(now)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        let timeString = IntentHelpers.formatTime(nextPrayer.time)
        let remainingString: String
        if hours > 0 {
            remainingString = "in \(hours)h \(minutes)m"
        } else {
            remainingString = "in \(minutes)m"
        }

        return .result(value: "Next prayer: \(nextPrayer.type.displayName) at \(timeString) (\(remainingString))")
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
        guard let prayerType = IntentHelpers.prayerType(from: prayer.id) else {
            return .result(dialog: "Unknown prayer type.")
        }

        let deps = Dependencies.shared
        let now = Date()

        // Check if already logged
        let alreadyLogged = try? await deps.prayerRepository.isPrayerLogged(prayerType, for: now)
        if alreadyLogged == true {
            return .result(dialog: "\(prayer.name) prayer is already logged for today.")
        }

        // Determine if on time by comparing to calculated prayer time
        let prayers = await IntentHelpers.getTodayPrayers()
        let matchingPrayer = prayers.first(where: { $0.type == prayerType })
        let isOnTime = matchingPrayer.map { abs(now.timeIntervalSince($0.time)) < 30 * 60 } ?? false

        do {
            try await deps.prayerRepository.logPrayer(prayerType, for: now, at: now, isOnTime: isOnTime)
            await HasanatTracker.awardOnce(.prayerLogged, key: "prayer_\(prayerType.rawValue)", via: deps.userState)
            await deps.userState.incrementPrayersLogged()
            await deps.userState.recordActivity(type: .prayer)

            // Check if all five obligatory prayers are now logged
            let logs = try await deps.prayerRepository.getPrayerLogs(for: now)
            let loggedTypes = Set(logs.map { $0.prayerType })
            if PrayerType.obligatoryPrayers.allSatisfy({ loggedTypes.contains($0) }) {
                await HasanatTracker.awardOnce(.prayerAllFive, key: "prayerAllFive", via: deps.userState)
            }

            return .result(dialog: "Logged \(prayer.name) prayer. +10 Hasanat earned!")
        } catch {
            return .result(dialog: "Could not log prayer. Please try again in the app.")
        }
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

// MARK: - Increment Tasbeeh Intent (Interactive Widget)

struct IncrementTasbeehIntent: AppIntent {
    static var title: LocalizedStringResource = "Increment Tasbeeh"
    static var description = IntentDescription("Add one to the tasbeeh counter")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Dhikr Type")
    var dhikrType: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get current count from shared storage
        let currentCount = TasbeehWidgetStorage.shared.currentCount
        let newCount = currentCount + 1
        TasbeehWidgetStorage.shared.currentCount = newCount

        // Award Hasanat at milestones (33, 66, 99)
        var message = "Count: \(newCount)"
        if newCount == 33 || newCount == 66 || newCount == 99 {
            message = "Count: \(newCount) - Milestone! +5 Hasanat"
            NotificationCenter.default.post(
                name: .tasbeehMilestoneReached,
                object: nil,
                userInfo: ["count": newCount]
            )
        }

        return .result(dialog: "\(message)")
    }
}

// MARK: - Reset Tasbeeh Intent (Interactive Widget)

struct ResetTasbeehIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Tasbeeh"
    static var description = IntentDescription("Reset the tasbeeh counter to zero")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        TasbeehWidgetStorage.shared.currentCount = 0
        return .result(dialog: "Tasbeeh counter reset")
    }
}

// MARK: - Tasbeeh Widget Storage

@Observable
final class TasbeehWidgetStorage {
    static let shared = TasbeehWidgetStorage()

    private let userDefaults: UserDefaults
    private let countKey = AppConstants.StorageKeys.tasbeehWidgetCount
    private let dhikrKey = AppConstants.StorageKeys.tasbeehDhikrType

    var currentCount: Int {
        get { userDefaults.integer(forKey: countKey) }
        set { userDefaults.set(newValue, forKey: countKey) }
    }

    var currentDhikr: String {
        get { userDefaults.string(forKey: dhikrKey) ?? "SubhanAllah" }
        set { userDefaults.set(newValue, forKey: dhikrKey) }
    }

    private init() {
        // Use App Group for widget access
        if let appGroupDefaults = UserDefaults(suiteName: AppConstants.appGroupId) {
            self.userDefaults = appGroupDefaults
        } else {
            self.userDefaults = .standard
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let tasbeehMilestoneReached = Notification.Name("com.safa.tasbeehMilestoneReached")
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
        let coords = IntentHelpers.getCoordinates()
        let calculator = PrayerTimeCalculator()
        let bearing = calculator.calculateQiblaDirection(from: coords)
        let rounded = Int(bearing.rounded())

        let cardinal = Self.cardinalDirection(for: bearing)

        return .result(value: "Qibla direction: \(rounded)\u{00B0} (\(cardinal)) from your location")
    }

    private static func cardinalDirection(for degrees: Double) -> String {
        let directions = ["North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest"]
        let index = Int((degrees + 22.5).truncatingRemainder(dividingBy: 360) / 45)
        return directions[index]
    }
}

// MARK: - Daily Verse Intent

struct GetDailyVerseIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Daily Verse"
    static var description = IntentDescription("Get today's verse of the day")

    static var openAppWhenRun: Bool = false

    /// Well-known ayahs that make good daily verses (surah, ayah)
    private static let curatedVerses: [(surah: Int, ayah: Int)] = [
        (1, 1), (2, 255), (2, 286), (3, 139), (3, 173),
        (5, 3), (6, 162), (13, 28), (14, 7), (16, 97),
        (17, 80), (20, 114), (23, 115), (24, 35), (25, 63),
        (28, 88), (29, 69), (33, 56), (39, 53), (40, 60),
        (41, 30), (42, 11), (49, 13), (55, 13), (57, 4),
        (59, 22), (65, 3), (67, 2), (93, 5), (94, 6),
        (112, 1),
    ]

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Use day-of-year as a stable daily seed
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % Self.curatedVerses.count
        let ref = Self.curatedVerses[index]

        let repo = Dependencies.shared.quranRepository

        do {
            if let ayah = try await repo.getAyah(surah: ref.surah, ayah: ref.ayah) {
                let surahName = try await repo.getSurah(number: ref.surah)?.nameEnglish ?? "Surah \(ref.surah)"
                let verse = """
                \(ayah.textArabic)

                "\(ayah.textTranslation)"

                \u{2014} \(surahName) (\(ref.surah):\(ref.ayah))
                """
                return .result(value: verse)
            }
        } catch {
            // Fall through to fallback
        }

        // Fallback if repository fails
        let verse = """
        \u{0628}\u{0650}\u{0633}\u{0652}\u{0645}\u{0650} \u{0627}\u{0644}\u{0644}\u{0651}\u{0647}\u{0650} \u{0627}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{0652}\u{0645}\u{064E}\u{0670}\u{0646}\u{0650} \u{0627}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{0650}\u{064A}\u{0645}\u{0650}

        "In the name of Allah, the Most Gracious, the Most Merciful"

        \u{2014} Al-Fatiha (1:1)
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
        guard !FeatureFlags.shared.isDisabled(.aiCompanion) else {
            return .result()
        }
        if let question {
            AppRouter.shared.pendingChatLaunchMode = .autoSend
            AppRouter.shared.pendingChatInput = question
        }
        AppRouter.shared.navigate(to: .chat)
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
