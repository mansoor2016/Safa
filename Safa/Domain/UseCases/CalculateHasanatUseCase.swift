// MARK: - CalculateHasanatUseCase.swift
// PURPOSE: Use case for calculating and awarding Hasanat (good deed points)
// DEPENDENCIES: Foundation

import Foundation

// MARK: - Hasanat Action

/// Represents actions that can earn Hasanat
enum HasanatAction: Equatable {
    // Prayer Actions
    case prayerLogged(PrayerType)
    case allFivePrayersLogged
    case prayerOnTime
    case tahajjudPrayer
    case fridayPrayer

    // Quran Actions
    case quranPageRead
    case quranSurahCompleted(surahNumber: Int)
    case quranJuzCompleted
    case quranKhatm // Complete Quran

    // Learning Actions
    case lessonCompleted
    case trackCompleted
    case perfectPronunciation

    // Dhikr Actions
    case morningDhikrCompleted
    case eveningDhikrCompleted
    case tasbeeh(count: Int)
    case duaRecited

    // Social Actions
    case invitedFriend
    case friendJoined
    case sharedVerse

    // Streak Actions
    case streakMilestone(days: Int)
    case perfectWeek
    case perfectMonth

    // Special Actions
    case firstTimeAction(action: String)
    case ramadanBonus
    case jumahBonus
}

// MARK: - Calculate Hasanat Use Case Protocol

protocol CalculateHasanatUseCaseProtocol {
    func calculatePoints(for action: HasanatAction) -> Int
    func calculateWithMultipliers(for action: HasanatAction, isRamadan: Bool, isFriday: Bool) -> Int
}

// MARK: - Calculate Hasanat Use Case Implementation

final class CalculateHasanatUseCase: CalculateHasanatUseCaseProtocol {

    // MARK: - Base Point Values

    private let basePoints: [String: Int] = [
        // Prayer
        "prayerLogged": 10,
        "allFivePrayers": 25,
        "prayerOnTime": 5,
        "tahajjud": 30,
        "fridayPrayer": 20,

        // Quran
        "quranPage": 5,
        "quranSurah": 15,
        "quranJuz": 50,
        "quranKhatm": 500,

        // Learning
        "lessonComplete": 10,
        "trackComplete": 100,
        "perfectPronunciation": 5,

        // Dhikr
        "morningDhikr": 15,
        "eveningDhikr": 15,
        "tasbeeh33": 10,
        "tasbeeh100": 20,
        "duaRecited": 5,

        // Social
        "inviteFriend": 10,
        "friendJoined": 25,
        "shareVerse": 5,

        // Streaks
        "streak7": 50,
        "streak30": 150,
        "streak100": 500,
        "perfectWeek": 100,
        "perfectMonth": 300,

        // First time
        "firstTime": 20
    ]

    // MARK: - Multipliers

    private let ramadanMultiplier: Double = 2.0
    private let fridayMultiplier: Double = 1.5

    // MARK: - Public Methods

    /// Calculate base points for an action
    func calculatePoints(for action: HasanatAction) -> Int {
        switch action {
        case .prayerLogged:
            return basePoints["prayerLogged"] ?? 10

        case .allFivePrayersLogged:
            return basePoints["allFivePrayers"] ?? 25

        case .prayerOnTime:
            return basePoints["prayerOnTime"] ?? 5

        case .tahajjudPrayer:
            return basePoints["tahajjud"] ?? 30

        case .fridayPrayer:
            return basePoints["fridayPrayer"] ?? 20

        case .quranPageRead:
            return basePoints["quranPage"] ?? 5

        case .quranSurahCompleted(let surahNumber):
            // Bonus for longer surahs
            return calculateSurahPoints(surahNumber: surahNumber)

        case .quranJuzCompleted:
            return basePoints["quranJuz"] ?? 50

        case .quranKhatm:
            return basePoints["quranKhatm"] ?? 500

        case .lessonCompleted:
            return basePoints["lessonComplete"] ?? 10

        case .trackCompleted:
            return basePoints["trackComplete"] ?? 100

        case .perfectPronunciation:
            return basePoints["perfectPronunciation"] ?? 5

        case .morningDhikrCompleted:
            return basePoints["morningDhikr"] ?? 15

        case .eveningDhikrCompleted:
            return basePoints["eveningDhikr"] ?? 15

        case .tasbeeh(let count):
            return calculateTasbeehPoints(count: count)

        case .duaRecited:
            return basePoints["duaRecited"] ?? 5

        case .invitedFriend:
            return basePoints["inviteFriend"] ?? 10

        case .friendJoined:
            return basePoints["friendJoined"] ?? 25

        case .sharedVerse:
            return basePoints["shareVerse"] ?? 5

        case .streakMilestone(let days):
            return calculateStreakPoints(days: days)

        case .perfectWeek:
            return basePoints["perfectWeek"] ?? 100

        case .perfectMonth:
            return basePoints["perfectMonth"] ?? 300

        case .firstTimeAction:
            return basePoints["firstTime"] ?? 20

        case .ramadanBonus:
            return 0 // This is handled via multiplier

        case .jumahBonus:
            return 0 // This is handled via multiplier
        }
    }

    /// Calculate points with time-based multipliers
    func calculateWithMultipliers(for action: HasanatAction, isRamadan: Bool, isFriday: Bool) -> Int {
        let basePoints = calculatePoints(for: action)
        var multiplier: Double = 1.0

        if isRamadan {
            multiplier = ramadanMultiplier
        }

        // Friday bonus only applies to certain actions
        if isFriday && isEligibleForFridayBonus(action) {
            multiplier = max(multiplier, fridayMultiplier)
        }

        return Int(Double(basePoints) * multiplier)
    }

    // MARK: - Private Helpers

    private func calculateSurahPoints(surahNumber: Int) -> Int {
        // Longer surahs get more points
        // Al-Baqarah (2) has 286 ayahs, short surahs have ~6 ayahs
        let basePoints = self.basePoints["quranSurah"] ?? 15

        // Simple tier system
        switch surahNumber {
        case 1: // Al-Fatiha (special)
            return basePoints + 5
        case 2: // Al-Baqarah (longest)
            return basePoints * 5
        case 3, 4: // Long surahs
            return basePoints * 4
        case 5...10:
            return basePoints * 3
        case 11...30:
            return basePoints * 2
        default:
            return basePoints
        }
    }

    private func calculateTasbeehPoints(count: Int) -> Int {
        switch count {
        case 0..<33:
            return count / 10 // 1 point per 10
        case 33..<100:
            return basePoints["tasbeeh33"] ?? 10
        case 100...:
            return basePoints["tasbeeh100"] ?? 20
        default:
            return 0
        }
    }

    private func calculateStreakPoints(days: Int) -> Int {
        switch days {
        case 7:
            return basePoints["streak7"] ?? 50
        case 30:
            return basePoints["streak30"] ?? 150
        case 100:
            return basePoints["streak100"] ?? 500
        default:
            // Bonus for other milestones
            if days % 10 == 0 {
                return days / 2
            }
            return 0
        }
    }

    private func isEligibleForFridayBonus(_ action: HasanatAction) -> Bool {
        switch action {
        case .prayerLogged, .quranPageRead, .quranSurahCompleted,
             .duaRecited, .morningDhikrCompleted, .eveningDhikrCompleted:
            return true
        default:
            return false
        }
    }
}

// MARK: - Hasanat Service

/// Service for tracking and awarding Hasanat points
@Observable
final class HasanatService {
    private let calculateUseCase: CalculateHasanatUseCaseProtocol
    private let calendar = Calendar.current

    var totalHasanat: Int = 0
    var todayHasanat: Int = 0
    var hasanatHistory: [Date: Int] = [:]

    init(calculateUseCase: CalculateHasanatUseCaseProtocol = CalculateHasanatUseCase()) {
        self.calculateUseCase = calculateUseCase
    }

    /// Award points for an action
    func award(for action: HasanatAction) {
        let isRamadan = isCurrentlyRamadan()
        let isFriday = calendar.component(.weekday, from: Date()) == 6

        let points = calculateUseCase.calculateWithMultipliers(
            for: action,
            isRamadan: isRamadan,
            isFriday: isFriday
        )

        totalHasanat += points
        todayHasanat += points

        // Update history
        let today = calendar.startOfDay(for: Date())
        hasanatHistory[today, default: 0] += points
    }

    /// Check if currently Ramadan (simplified check)
    private func isCurrentlyRamadan() -> Bool {
        let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)
        let month = islamicCalendar.component(.month, from: Date())
        return month == 9 // Ramadan is the 9th month
    }

    /// Get points for last N days
    func pointsForLastDays(_ days: Int) -> Int {
        let calendar = Calendar.current
        var total = 0

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            total += hasanatHistory[startOfDay] ?? 0
        }

        return total
    }

    /// Reset daily count (call at midnight)
    func resetDailyCount() {
        todayHasanat = 0
    }
}

// MARK: - Extensions for Point Values

extension HasanatAward {
    /// Get the action type for this award
    var action: HasanatAction {
        switch self {
        case .prayerLogged:
            return .prayerLogged(.fajr)
        case .prayerAllFive:
            return .allFivePrayersLogged
        case .quranPage:
            return .quranPageRead
        case .quranSurah:
            return .quranSurahCompleted(surahNumber: 1)
        case .quranJuz:
            return .quranJuzCompleted
        case .lessonComplete:
            return .lessonCompleted
        case .lessonPerfect:
            return .lessonCompleted
        case .pronunciationPass:
            return .lessonCompleted
        case .tajweedModule:
            return .lessonCompleted
        case .morningDhikr:
            return .morningDhikrCompleted
        case .eveningDhikr:
            return .eveningDhikrCompleted
        case .tasbeehSession:
            return .tasbeeh(count: 33)
        case .dailyOpen:
            return .morningDhikrCompleted
        case .dailyVerse:
            return .quranPageRead
        case .dailyHadith:
            return .quranPageRead
        case .share:
            return .sharedVerse
        case .inviteAccepted:
            return .invitedFriend
        case .fastingDay:
            return .morningDhikrCompleted
        case .taraweeh:
            return .prayerLogged(.isha)
        }
    }
}
