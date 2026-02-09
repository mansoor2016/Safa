// MARK: - CheckAchievementsUseCase.swift
// PURPOSE: Use case for checking and unlocking achievements
// DEPENDENCIES: Foundation, AchievementDefinitions

import Foundation

// MARK: - Type Aliases
typealias AchievementCategory = Achievement.AchievementCategory

// MARK: - Achievement Criteria

/// Defines the requirements for unlocking an achievement
struct AchievementCriteria {
    let achievementId: String
    let requirement: AchievementRequirement
    let category: AchievementCategory
    let tier: AchievementTier

    enum AchievementTier: Int {
        case bronze = 1
        case silver = 2
        case gold = 3
        case platinum = 4
    }
}

/// Types of achievement requirements
enum AchievementRequirement {
    case singleAction(action: String)
    case cumulativeCount(action: String, count: Int)
    case streakDays(type: StreakType, days: Int)
    case levelReached(level: Int)
    case hasanatEarned(amount: Int)
    case prayerStreak(days: Int)
    case quranProgress(pages: Int)
    case quranComplete
    case lessonsCompleted(count: Int)
    case trackCompleted(trackId: String)
    case allTracksCompleted
    case familySize(members: Int)
    case shareCount(count: Int)
    case dhikrCompleted(type: DhikrType, count: Int)
    case tasbeehCount(total: Int)
    case ramadanComplete
    case perfectWeek
    case perfectMonth
}

// MARK: - Achievement Check Result

struct AchievementCheckResult {
    let achievement: Achievement
    let wasUnlocked: Bool
    let progress: Double // 0.0 to 1.0
    let currentValue: Int
    let targetValue: Int
}

// MARK: - Check Achievements Use Case Protocol

protocol CheckAchievementsUseCaseProtocol {
    func checkAllAchievements(with stats: UserStats) -> [AchievementCheckResult]
    func checkSpecificAchievement(_ achievementId: String, with stats: UserStats) -> AchievementCheckResult?
    func getUnlockedAchievements() -> [Achievement]
    func getLockedAchievements() -> [Achievement]
    func getProgress(for achievementId: String, with stats: UserStats) -> Double
}

// MARK: - Check Achievements Use Case Implementation

final class CheckAchievementsUseCase: CheckAchievementsUseCaseProtocol {

    // MARK: - Properties

    private var unlockedAchievementIds: Set<String> = []
    private let allAchievements: [Achievement]
    private let criteria: [String: AchievementCriteria]

    // MARK: - Initialization

    init() {
        self.allAchievements = AchievementDefinitions.createAllAchievements()
        self.criteria = AchievementDefinitions.createAllCriteria()
    }

    // MARK: - Public Methods

    func checkAllAchievements(with stats: UserStats) -> [AchievementCheckResult] {
        var results: [AchievementCheckResult] = []

        for achievement in allAchievements {
            let wasAlreadyUnlocked = unlockedAchievementIds.contains(achievement.id)
            let isNowUnlocked = checkUnlockCondition(for: achievement.id, with: stats)

            let progress = getProgress(for: achievement.id, with: stats)
            let (current, target) = getProgressValues(for: achievement.id, with: stats)

            if isNowUnlocked && !wasAlreadyUnlocked {
                unlockedAchievementIds.insert(achievement.id)
            }

            results.append(AchievementCheckResult(
                achievement: achievement,
                wasUnlocked: isNowUnlocked && !wasAlreadyUnlocked,
                progress: progress,
                currentValue: current,
                targetValue: target
            ))
        }

        return results
    }

    func checkSpecificAchievement(_ achievementId: String, with stats: UserStats) -> AchievementCheckResult? {
        guard let achievement = allAchievements.first(where: { $0.id == achievementId }) else {
            return nil
        }

        let wasAlreadyUnlocked = unlockedAchievementIds.contains(achievementId)
        let isNowUnlocked = checkUnlockCondition(for: achievementId, with: stats)

        if isNowUnlocked && !wasAlreadyUnlocked {
            unlockedAchievementIds.insert(achievementId)
        }

        let progress = getProgress(for: achievementId, with: stats)
        let (current, target) = getProgressValues(for: achievementId, with: stats)

        return AchievementCheckResult(
            achievement: achievement,
            wasUnlocked: isNowUnlocked && !wasAlreadyUnlocked,
            progress: progress,
            currentValue: current,
            targetValue: target
        )
    }

    func getUnlockedAchievements() -> [Achievement] {
        return allAchievements.filter { unlockedAchievementIds.contains($0.id) }
    }

    func getLockedAchievements() -> [Achievement] {
        return allAchievements.filter { !unlockedAchievementIds.contains($0.id) }
    }

    func getProgress(for achievementId: String, with stats: UserStats) -> Double {
        let (current, target) = getProgressValues(for: achievementId, with: stats)
        guard target > 0 else { return 0 }
        return min(1.0, Double(current) / Double(target))
    }

    // MARK: - Private Methods

    private func checkUnlockCondition(for achievementId: String, with stats: UserStats) -> Bool {
        guard let criteria = criteria[achievementId] else { return false }

        switch criteria.requirement {
        case .singleAction:
            return unlockedAchievementIds.contains(achievementId)

        case .cumulativeCount(let action, let count):
            return getCumulativeCount(for: action, stats: stats) >= count

        case .streakDays:
            return false // Would need streak data

        case .levelReached(let level):
            return stats.currentLevel >= level

        case .hasanatEarned(let amount):
            return stats.totalHasanat >= amount

        case .prayerStreak:
            return false // Would need streak data

        case .quranProgress(let pages):
            return stats.totalAyahsRead / 15 >= pages

        case .quranComplete:
            return stats.totalAyahsRead >= 6236

        case .lessonsCompleted(let count):
            return stats.lessonsCompleted >= count

        case .trackCompleted, .allTracksCompleted:
            return false // Would need learning progress data

        case .familySize, .shareCount:
            return false // Would need tracking data

        case .dhikrCompleted:
            return false // Would need dhikr tracking

        case .tasbeehCount(let total):
            return stats.totalTasbeehCount >= total

        case .ramadanComplete, .perfectWeek, .perfectMonth:
            return false // Would need calendar tracking
        }
    }

    private func getCumulativeCount(for action: String, stats: UserStats) -> Int {
        switch action {
        case "prayer": return stats.totalPrayersLogged
        case "quran": return stats.totalAyahsRead
        case "lesson": return stats.lessonsCompleted
        case "tasbeeh": return stats.totalTasbeehCount
        default: return 0
        }
    }

    private func getProgressValues(for achievementId: String, with stats: UserStats) -> (current: Int, target: Int) {
        guard let criteria = criteria[achievementId] else { return (0, 1) }

        switch criteria.requirement {
        case .singleAction:
            return (unlockedAchievementIds.contains(achievementId) ? 1 : 0, 1)

        case .cumulativeCount(let action, let count):
            return (getCumulativeCount(for: action, stats: stats), count)

        case .streakDays(_, let days):
            return (0, days)

        case .levelReached(let level):
            return (stats.currentLevel, level)

        case .hasanatEarned(let amount):
            return (stats.totalHasanat, amount)

        case .prayerStreak(let days):
            return (0, days)

        case .quranProgress(let pages):
            return (stats.totalAyahsRead / 15, pages)

        case .quranComplete:
            return (stats.totalAyahsRead, 6236)

        case .lessonsCompleted(let count):
            return (stats.lessonsCompleted, count)

        case .trackCompleted:
            return (0, 1)

        case .allTracksCompleted:
            return (0, 4)

        case .familySize(let members):
            return (0, members)

        case .shareCount(let count):
            return (0, count)

        case .dhikrCompleted(_, let count):
            return (0, count)

        case .tasbeehCount(let total):
            return (stats.totalTasbeehCount, total)

        case .ramadanComplete, .perfectMonth:
            return (0, 30)

        case .perfectWeek:
            return (0, 7)
        }
    }
}

// MARK: - Achievement Manager

/// Manager class that coordinates achievement checking across the app
@Observable
final class AchievementManager {
    private let checkUseCase: CheckAchievementsUseCaseProtocol
    private let hapticService: HapticFeedbackService?

    private(set) var recentlyUnlocked: [Achievement] = []
    private(set) var showingAchievementBanner = false
    private(set) var currentAchievementToShow: Achievement?

    var unlockedCount: Int { checkUseCase.getUnlockedAchievements().count }
    var totalCount: Int { checkUseCase.getUnlockedAchievements().count + checkUseCase.getLockedAchievements().count }

    init(
        checkUseCase: CheckAchievementsUseCaseProtocol = CheckAchievementsUseCase(),
        hapticService: HapticFeedbackService? = nil
    ) {
        self.checkUseCase = checkUseCase
        self.hapticService = hapticService
    }

    func checkAchievements(with stats: UserStats) {
        let results = checkUseCase.checkAllAchievements(with: stats)
        let newlyUnlocked = results.filter { $0.wasUnlocked }.map { $0.achievement }
        recentlyUnlocked.append(contentsOf: newlyUnlocked)

        for achievement in newlyUnlocked {
            notifyAchievementUnlocked(achievement)
        }
    }

    private func notifyAchievementUnlocked(_ achievement: Achievement) {
        hapticService?.achievementUnlocked()
        showAchievementBanner(achievement)

        Task {
            try? await NotificationScheduler.shared.showAchievementUnlocked(achievement: achievement)
        }
    }

    private func showAchievementBanner(_ achievement: Achievement) {
        currentAchievementToShow = achievement
        showingAchievementBanner = true

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            self.dismissAchievementBanner()
        }
    }

    func dismissAchievementBanner() {
        showingAchievementBanner = false
        currentAchievementToShow = nil
    }

    func clearRecentlyUnlocked() {
        recentlyUnlocked.removeAll()
    }

    func getUnlockedAchievements() -> [Achievement] {
        return checkUseCase.getUnlockedAchievements()
    }

    func getLockedAchievementsWithProgress(stats: UserStats) -> [(achievement: Achievement, progress: Double)] {
        return checkUseCase.getLockedAchievements().map { achievement in
            let progress = checkUseCase.getProgress(for: achievement.id, with: stats)
            return (achievement, progress)
        }
    }
}
