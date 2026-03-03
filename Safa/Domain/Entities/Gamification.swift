// MARK: - Gamification.swift
// PURPOSE: Domain entities for streaks, user stats, and Hasanat

import Foundation

// MARK: - Streak Type
enum StreakType: String, Codable, CaseIterable, Identifiable {
    case daily
    case prayer
    case quran
    case dhikr
    case learning

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .prayer: return "Prayer"
        case .quran: return "Quran"
        case .dhikr: return "Dhikr"
        case .learning: return "Learning"
        }
    }

    var description: String {
        switch self {
        case .daily: return "Open app and complete any activity"
        case .prayer: return "Log all 5 prayers"
        case .quran: return "Read any amount of Quran"
        case .dhikr: return "Complete morning or evening dhikr"
        case .learning: return "Complete at least one lesson"
        }
    }

    var iconName: String {
        switch self {
        case .daily: return "flame"
        case .prayer: return "moon.stars"
        case .quran: return "book"
        case .dhikr: return "heart"
        case .learning: return "graduationcap"
        }
    }
}

// MARK: - Streak
struct Streak: Identifiable, Codable, Hashable {
    let id: UUID
    let type: StreakType
    var currentCount: Int
    var longestCount: Int
    var lastActivityDate: Date?

    init(
        id: UUID = UUID(),
        type: StreakType,
        currentCount: Int = 0,
        longestCount: Int = 0,
        lastActivityDate: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.currentCount = currentCount
        self.longestCount = longestCount
        self.lastActivityDate = lastActivityDate
    }

    var isActiveToday: Bool {
        guard let lastActivity = lastActivityDate else { return false }
        return Calendar.current.isDateInToday(lastActivity)
    }
}

// MARK: - User Stats
struct UserStats: Codable, Hashable {
    var totalHasanat: Int
    var currentLevel: Int
    var lessonsCompleted: Int
    var totalPrayersLogged: Int
    var totalAyahsRead: Int
    var totalTasbeehCount: Int
    var streakFreezes: Int

    init(
        totalHasanat: Int = 0,
        currentLevel: Int = 1,
        lessonsCompleted: Int = 0,
        totalPrayersLogged: Int = 0,
        totalAyahsRead: Int = 0,
        totalTasbeehCount: Int = 0,
        streakFreezes: Int = 0
    ) {
        self.totalHasanat = totalHasanat
        self.currentLevel = currentLevel
        self.lessonsCompleted = lessonsCompleted
        self.totalPrayersLogged = totalPrayersLogged
        self.totalAyahsRead = totalAyahsRead
        self.totalTasbeehCount = totalTasbeehCount
        self.streakFreezes = streakFreezes
    }

    // Backwards-compatible decoding: ignore legacy unlockedAchievements field
    private enum CodingKeys: String, CodingKey {
        case totalHasanat, currentLevel, lessonsCompleted
        case totalPrayersLogged, totalAyahsRead, totalTasbeehCount, streakFreezes
    }

    static let maxLevel = 20

    /// Calculate level based on total Hasanat.
    /// Progression: ~6 months to level 10, ~2 years to level 15, ~5 years to level 20.
    /// Based on ~100 hasanat/day for a consistent user.
    static func calculateLevel(from hasanat: Int) -> Int {
        switch hasanat {
        case 0..<100: return 1          // Beginner
        case 100..<300: return 2        // Seeker
        case 300..<600: return 3        // Learner
        case 600..<1_000: return 4     // Dedicated
        case 1_000..<2_000: return 5   // Consistent
        case 2_000..<4_000: return 6   // Devoted
        case 4_000..<7_000: return 7   // Steadfast
        case 7_000..<12_000: return 8  // Committed
        case 12_000..<18_000: return 9 // Excellent
        case 18_000..<25_000: return 10 // Muhsin
        case 25_000..<35_000: return 11 // Sabir (Patient)
        case 35_000..<50_000: return 12 // Shakir (Grateful)
        case 50_000..<70_000: return 13 // Mukhlis (Sincere)
        case 70_000..<95_000: return 14 // Muttaqi (Mindful)
        case 95_000..<120_000: return 15 // Sadiq (Truthful)
        case 120_000..<145_000: return 16 // Zahid (Detached)
        case 145_000..<170_000: return 17 // Arif (Knowing)
        case 170_000..<195_000: return 18 // Qani (Content)
        case 195_000..<220_000: return 19 // Siddiq (Righteous)
        default: return 20               // Muhsin al-Kamil
        }
    }

    static func levelTitle(for level: Int) -> String {
        switch level {
        case 1: return "Beginner"
        case 2: return "Seeker"
        case 3: return "Learner"
        case 4: return "Dedicated"
        case 5: return "Consistent"
        case 6: return "Devoted"
        case 7: return "Steadfast"
        case 8: return "Committed"
        case 9: return "Excellent"
        case 10: return "Muhsin"
        case 11: return "Sabir"
        case 12: return "Shakir"
        case 13: return "Mukhlis"
        case 14: return "Muttaqi"
        case 15: return "Sadiq"
        case 16: return "Zahid"
        case 17: return "Arif"
        case 18: return "Qani"
        case 19: return "Siddiq"
        case 20: return "Muhsin al-Kamil"
        default: return "Beginner"
        }
    }

    static func hasanatForLevel(_ level: Int) -> Int {
        switch level {
        case 1: return 0
        case 2: return 100
        case 3: return 300
        case 4: return 600
        case 5: return 1_000
        case 6: return 2_000
        case 7: return 4_000
        case 8: return 7_000
        case 9: return 12_000
        case 10: return 18_000
        case 11: return 25_000
        case 12: return 35_000
        case 13: return 50_000
        case 14: return 70_000
        case 15: return 95_000
        case 16: return 120_000
        case 17: return 145_000
        case 18: return 170_000
        case 19: return 195_000
        case 20: return 220_000
        default: return 0
        }
    }
}

// UserPreferences extracted to Domain/Entities/UserPreferences.swift

// MARK: - Hasanat Awards
enum HasanatAward {
    case prayerLogged
    case prayerAllFive
    case quranPage
    case quranSurah
    case quranJuz
    case lessonComplete
    case lessonPerfect
    case tajweedModule
    case morningDhikr
    case eveningDhikr
    case tasbeehSession
    case dailyOpen
    case dailyVerse
    case dailyHadith
    case share
    case inviteAccepted
    case fastingDay
    case taraweeh

    var points: Int {
        switch self {
        case .prayerLogged: return 10
        case .prayerAllFive: return 25
        case .quranPage: return 5
        case .quranSurah: return 15
        case .quranJuz: return 50
        case .lessonComplete: return 10
        case .lessonPerfect: return 5
        case .tajweedModule: return 20
        case .morningDhikr: return 15
        case .eveningDhikr: return 15
        case .tasbeehSession: return 10
        case .dailyOpen: return 5
        case .dailyVerse: return 3
        case .dailyHadith: return 3
        case .share: return 5
        case .inviteAccepted: return 25
        case .fastingDay: return 20
        case .taraweeh: return 25
        }
    }
}
