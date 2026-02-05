// MARK: - Gamification.swift
// PURPOSE: Domain entities for streaks, achievements, user stats, and Hasanat

import Foundation
import SwiftUI

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
        case .dhikr: return "Complete morning or evening adhkar"
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

// MARK: - Achievement
struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let category: AchievementCategory
    let title: String
    let description: String
    let iconName: String
    var isUnlocked: Bool
    var unlockedAt: Date?

    enum AchievementCategory: String, Codable, CaseIterable {
        case quran
        case prayer
        case learning
        case dhikr
        case ramadan
        case social
        case streak
        case milestone
        case special

        var displayName: String {
            rawValue.capitalized
        }
    }

    /// Standard memberwise initializer
    init(id: String, category: AchievementCategory, title: String, description: String, iconName: String, isUnlocked: Bool, unlockedAt: Date? = nil) {
        self.id = id
        self.category = category
        self.title = title
        self.description = description
        self.iconName = iconName
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
    }

    /// Convenience initializer with requirement string (for CheckAchievementsUseCase)
    init(id: String, title: String, description: String, iconName: String, category: AchievementCategory, requirement: String) {
        self.id = id
        self.category = category
        self.title = title
        self.description = description
        self.iconName = iconName
        self.isUnlocked = false
        self.unlockedAt = nil
    }

    /// Alias for iconName for convenience
    var icon: String { iconName }

    /// Color based on achievement category
    var color: Color {
        switch category {
        case .quran: return .green
        case .prayer: return .blue
        case .learning: return .purple
        case .dhikr: return .orange
        case .ramadan: return .indigo
        case .social: return .pink
        case .streak: return .red
        case .milestone: return .yellow
        case .special: return .cyan
        }
    }

    // MARK: - Predefined Achievements

    static let allAchievements: [Achievement] = [
        // Quran
        Achievement(id: "quran_first_page", category: .quran, title: "First Page", description: "Read your first page of Quran", iconName: "book", isUnlocked: false),
        Achievement(id: "quran_surah_complete", category: .quran, title: "Surah Complete", description: "Finish any surah", iconName: "book.fill", isUnlocked: false),
        Achievement(id: "quran_juz_complete", category: .quran, title: "Juz Champion", description: "Complete a full juz", iconName: "trophy", isUnlocked: false),
        Achievement(id: "quran_khatm", category: .quran, title: "Khatm", description: "Complete the entire Quran", iconName: "star.fill", isUnlocked: false),
        Achievement(id: "quran_listener", category: .quran, title: "Listener", description: "Listen to 10 hours of recitation", iconName: "headphones", isUnlocked: false),

        // Prayer
        Achievement(id: "prayer_first", category: .prayer, title: "First Prayer", description: "Log your first prayer", iconName: "moon", isUnlocked: false),
        Achievement(id: "prayer_perfect_day", category: .prayer, title: "Perfect Day", description: "Log all 5 prayers in a day", iconName: "star", isUnlocked: false),
        Achievement(id: "prayer_week_warrior", category: .prayer, title: "Week Warrior", description: "7-day prayer streak", iconName: "flame", isUnlocked: false),
        Achievement(id: "prayer_month_strong", category: .prayer, title: "Month Strong", description: "30-day prayer streak", iconName: "flame.fill", isUnlocked: false),
        Achievement(id: "prayer_fajr_fighter", category: .prayer, title: "Fajr Fighter", description: "30 Fajr prayers logged", iconName: "sunrise", isUnlocked: false),

        // Learning
        Achievement(id: "learn_alphabet", category: .learning, title: "Alphabet Master", description: "Learn all Arabic letters", iconName: "textformat.abc", isUnlocked: false),
        Achievement(id: "learn_pronunciation", category: .learning, title: "Clear Voice", description: "Pass 50 pronunciation checks", iconName: "waveform", isUnlocked: false),
        Achievement(id: "learn_tajweed", category: .learning, title: "Tajweed Student", description: "Complete Tajweed basics", iconName: "text.book.closed", isUnlocked: false),
        Achievement(id: "learn_scholar", category: .learning, title: "Scholar's Path", description: "Complete all learning tracks", iconName: "graduationcap.fill", isUnlocked: false),

        // Dhikr
        Achievement(id: "dhikr_first", category: .dhikr, title: "First Tasbeeh", description: "Complete your first session", iconName: "circle", isUnlocked: false),
        Achievement(id: "dhikr_morning", category: .dhikr, title: "Morning Person", description: "7-day morning adhkar streak", iconName: "sunrise.fill", isUnlocked: false),
        Achievement(id: "dhikr_evening", category: .dhikr, title: "Evening Devotee", description: "7-day evening adhkar streak", iconName: "sunset.fill", isUnlocked: false),
        Achievement(id: "dhikr_10k", category: .dhikr, title: "10,000 Count", description: "Lifetime tasbeeh count", iconName: "infinity", isUnlocked: false),

        // Ramadan
        Achievement(id: "ramadan_first", category: .ramadan, title: "Ramadan Ready", description: "Complete first fast", iconName: "moon.fill", isUnlocked: false),
        Achievement(id: "ramadan_full", category: .ramadan, title: "Full Month", description: "Fast all 30 days", iconName: "trophy.fill", isUnlocked: false),
        Achievement(id: "ramadan_khatm", category: .ramadan, title: "Ramadan Khatm", description: "Complete Quran during Ramadan", iconName: "book.circle.fill", isUnlocked: false),
        Achievement(id: "ramadan_taraweeh", category: .ramadan, title: "Night Worshipper", description: "Complete Taraweeh for 10 nights", iconName: "moon.stars.fill", isUnlocked: false),
    ]
}

// MARK: - User Stats
struct UserStats: Codable, Hashable {
    var totalHasanat: Int
    var currentLevel: Int
    var unlockedAchievements: [String]
    var lessonsCompleted: Int
    var totalPrayersLogged: Int
    var totalAyahsRead: Int
    var totalTasbeehCount: Int
    var streakFreezes: Int

    init(
        totalHasanat: Int = 0,
        currentLevel: Int = 1,
        unlockedAchievements: [String] = [],
        lessonsCompleted: Int = 0,
        totalPrayersLogged: Int = 0,
        totalAyahsRead: Int = 0,
        totalTasbeehCount: Int = 0,
        streakFreezes: Int = 0
    ) {
        self.totalHasanat = totalHasanat
        self.currentLevel = currentLevel
        self.unlockedAchievements = unlockedAchievements
        self.lessonsCompleted = lessonsCompleted
        self.totalPrayersLogged = totalPrayersLogged
        self.totalAyahsRead = totalAyahsRead
        self.totalTasbeehCount = totalTasbeehCount
        self.streakFreezes = streakFreezes
    }

    /// Calculate level based on total Hasanat
    static func calculateLevel(from hasanat: Int) -> Int {
        switch hasanat {
        case 0..<100: return 1      // Beginner
        case 100..<300: return 2    // Seeker
        case 300..<600: return 3    // Learner
        case 600..<1000: return 4   // Dedicated
        case 1000..<2000: return 5  // Consistent
        case 2000..<4000: return 6  // Devoted
        case 4000..<7000: return 7  // Steadfast
        case 7000..<12000: return 8 // Committed
        case 12000..<20000: return 9 // Excellent
        default: return 10          // Muhsin
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
        default: return "Beginner"
        }
    }

    static func hasanatForLevel(_ level: Int) -> Int {
        switch level {
        case 1: return 0
        case 2: return 100
        case 3: return 300
        case 4: return 600
        case 5: return 1000
        case 6: return 2000
        case 7: return 4000
        case 8: return 7000
        case 9: return 12000
        case 10: return 20000
        default: return 0
        }
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable, Hashable {
    var calculationMethod: CalculationMethod
    var madhab: Madhab
    var notificationsEnabled: Bool
    var hapticFeedbackEnabled: Bool
    var hasCompletedOnboarding: Bool
    var selectedTranslation: String
    var showArabicText: Bool
    var showTransliteration: Bool
    var accentColorName: String

    // Location-based preferences
    var savedLocationName: String?
    var savedLatitude: Double?
    var savedLongitude: Double?
    var savedCountryCode: String?
    var useLocationBasedDefaults: Bool

    init(
        calculationMethod: CalculationMethod = AppDefaults.calculationMethod,
        madhab: Madhab = AppDefaults.madhab,
        notificationsEnabled: Bool = AppDefaults.notificationsEnabled,
        hapticFeedbackEnabled: Bool = AppDefaults.hapticFeedbackEnabled,
        hasCompletedOnboarding: Bool = false,
        selectedTranslation: String = AppDefaults.translationLanguage,
        showArabicText: Bool = AppDefaults.showArabicText,
        showTransliteration: Bool = AppDefaults.showTransliteration,
        accentColorName: String = AppDefaults.accentColorName,
        savedLocationName: String? = nil,
        savedLatitude: Double? = nil,
        savedLongitude: Double? = nil,
        savedCountryCode: String? = nil,
        useLocationBasedDefaults: Bool = AppDefaults.useLocationBasedDefaults
    ) {
        self.calculationMethod = calculationMethod
        self.madhab = madhab
        self.notificationsEnabled = notificationsEnabled
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.selectedTranslation = selectedTranslation
        self.showArabicText = showArabicText
        self.showTransliteration = showTransliteration
        self.accentColorName = accentColorName
        self.savedLocationName = savedLocationName
        self.savedLatitude = savedLatitude
        self.savedLongitude = savedLongitude
        self.savedCountryCode = savedCountryCode
        self.useLocationBasedDefaults = useLocationBasedDefaults
    }

    /// Apply location context to preferences
    mutating func applyLocationDefaults(from context: LocationContext) {
        calculationMethod = context.recommendedMethod
        madhab = context.recommendedMadhab
        selectedTranslation = context.recommendedLanguage
        savedLocationName = context.regionName
        savedLatitude = context.coordinates.latitude
        savedLongitude = context.coordinates.longitude
        savedCountryCode = context.countryCode
    }

    /// Check if saved location exists
    var hasSavedLocation: Bool {
        savedLatitude != nil && savedLongitude != nil
    }

    /// Get saved coordinates if available
    var savedCoordinates: Coordinates? {
        guard let lat = savedLatitude, let lng = savedLongitude else { return nil }
        return Coordinates(latitude: lat, longitude: lng)
    }
}

// MARK: - Hasanat Awards
enum HasanatAward {
    case prayerLogged
    case prayerAllFive
    case quranPage
    case quranSurah
    case quranJuz
    case lessonComplete
    case lessonPerfect
    case pronunciationPass
    case tajweedModule
    case morningAdhkar
    case eveningAdhkar
    case tasbeehSession
    case dailyOpen
    case dailyVerse
    case dailyHadith
    case share
    case inviteAccepted
    case familyJoined
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
        case .pronunciationPass: return 5
        case .tajweedModule: return 20
        case .morningAdhkar: return 15
        case .eveningAdhkar: return 15
        case .tasbeehSession: return 10
        case .dailyOpen: return 5
        case .dailyVerse: return 3
        case .dailyHadith: return 3
        case .share: return 5
        case .inviteAccepted: return 25
        case .familyJoined: return 15
        case .fastingDay: return 20
        case .taraweeh: return 25
        }
    }
}
