// MARK: - UserRepository.swift
// PURPOSE: Implementation of user data, progress, and gamification persistence
// DEPENDENCIES: CoreData, UserRepositoryProtocol

import Foundation
import CoreData

final class UserRepository: UserRepositoryProtocol {
    // MARK: - Dependencies
    private let coreData: CoreDataStack

    // MARK: - Storage Keys
    private let userStatsKey = "com.safa.user.stats"
    private let streaksKey = "com.safa.user.streaks"
    private let achievementsKey = "com.safa.user.achievements"
    private let preferencesKey = "com.safa.user.preferences"

    // MARK: - Init
    init(coreData: CoreDataStack) {
        self.coreData = coreData
    }

    // MARK: - User Stats

    func getUserStats() async throws -> UserStats {
        guard let data = UserDefaults.standard.data(forKey: userStatsKey),
              let stats = try? JSONDecoder().decode(UserStats.self, from: data) else {
            return UserStats()
        }
        return stats
    }

    func updateUserStats(_ stats: UserStats) async throws {
        let data = try JSONEncoder().encode(stats)
        UserDefaults.standard.set(data, forKey: userStatsKey)
    }

    @discardableResult
    func addHasanat(_ amount: Int) async throws -> Int {
        var stats = try await getUserStats()
        stats.totalHasanat += amount
        stats.currentLevel = UserStats.calculateLevel(from: stats.totalHasanat)
        try await updateUserStats(stats)
        return stats.totalHasanat
    }

    // MARK: - Streaks

    func getStreaks() async throws -> [Streak] {
        guard let data = UserDefaults.standard.data(forKey: streaksKey),
              let streaks = try? JSONDecoder().decode([Streak].self, from: data) else {
            // Return default streaks for all types
            return StreakType.allCases.map { Streak(type: $0) }
        }
        return streaks
    }

    func getStreak(type: StreakType) async throws -> Streak? {
        let streaks = try await getStreaks()
        return streaks.first { $0.type == type }
    }

    func updateStreak(_ streak: Streak) async throws {
        var streaks = try await getStreaks()
        if let index = streaks.firstIndex(where: { $0.type == streak.type }) {
            streaks[index] = streak
        } else {
            streaks.append(streak)
        }
        let data = try JSONEncoder().encode(streaks)
        UserDefaults.standard.set(data, forKey: streaksKey)
    }

    func recordStreakActivity(type: StreakType) async throws {
        var streak = try await getStreak(type: type) ?? Streak(type: type)

        // Check if already recorded today
        if let lastActivity = streak.lastActivityDate,
           Calendar.current.isDateInToday(lastActivity) {
            return
        }

        // Check if this extends the streak or resets it
        if let lastActivity = streak.lastActivityDate {
            let calendar = Calendar.current
            let daysSinceLastActivity = calendar.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0

            if daysSinceLastActivity == 1 {
                // Consecutive day - extend streak
                streak.currentCount += 1
            } else if daysSinceLastActivity > 1 {
                // Streak broken - check for freeze
                let freezes = try await getStreakFreezes()
                if freezes > 0 && daysSinceLastActivity == 2 {
                    // Use freeze to maintain streak
                    try await useStreakFreeze()
                    streak.currentCount += 1
                } else {
                    // Reset streak
                    streak.currentCount = 1
                }
            }
        } else {
            // First activity
            streak.currentCount = 1
        }

        // Update longest count if needed
        if streak.currentCount > streak.longestCount {
            streak.longestCount = streak.currentCount
        }

        streak.lastActivityDate = Date()
        try await updateStreak(streak)

        // Award streak freeze at milestones
        if streak.currentCount == 7 || streak.currentCount % 30 == 0 {
            try await awardStreakFreeze()
        }
    }

    // MARK: - Achievements

    func getAchievements() async throws -> [Achievement] {
        let unlockedIds = getUnlockedAchievementIds()
        return Achievement.allAchievements.map { achievement in
            var updated = achievement
            if unlockedIds.contains(achievement.id) {
                updated.isUnlocked = true
            }
            return updated
        }
    }

    func unlockAchievement(_ achievementId: String) async throws {
        var ids = getUnlockedAchievementIds()
        guard !ids.contains(achievementId) else { return }
        ids.append(achievementId)
        UserDefaults.standard.set(ids, forKey: achievementsKey)

        // Update user stats
        var stats = try await getUserStats()
        if !stats.unlockedAchievements.contains(achievementId) {
            stats.unlockedAchievements.append(achievementId)
            try await updateUserStats(stats)
        }
    }

    func isAchievementUnlocked(_ achievementId: String) async throws -> Bool {
        let ids = getUnlockedAchievementIds()
        return ids.contains(achievementId)
    }

    // MARK: - Preferences

    func getPreference<T: Codable>(key: String) async throws -> T? {
        let fullKey = "\(preferencesKey).\(key)"
        guard let data = UserDefaults.standard.data(forKey: fullKey),
              let value = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        return value
    }

    func setPreference<T: Codable>(key: String, value: T) async throws {
        let fullKey = "\(preferencesKey).\(key)"
        let data = try JSONEncoder().encode(value)
        UserDefaults.standard.set(data, forKey: fullKey)
    }

    // MARK: - User Preferences

    func getPreferences() async -> UserPreferences {
        let fullKey = "\(preferencesKey).all"
        guard let data = UserDefaults.standard.data(forKey: fullKey),
              let prefs = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return UserPreferences()
        }
        return prefs
    }

    func updatePreferences(_ preferences: UserPreferences) async throws {
        let fullKey = "\(preferencesKey).all"
        let data = try JSONEncoder().encode(preferences)
        UserDefaults.standard.set(data, forKey: fullKey)
    }

    // MARK: - Streak Freezes

    func getStreakFreezes() async throws -> Int {
        let stats = try await getUserStats()
        return stats.streakFreezes
    }

    func useStreakFreeze() async throws {
        var stats = try await getUserStats()
        guard stats.streakFreezes > 0 else { return }
        stats.streakFreezes -= 1
        try await updateUserStats(stats)
    }

    func awardStreakFreeze() async throws {
        var stats = try await getUserStats()
        stats.streakFreezes += 1
        try await updateUserStats(stats)
    }

    // MARK: - Private Helpers

    private func getUnlockedAchievementIds() -> [String] {
        UserDefaults.standard.stringArray(forKey: achievementsKey) ?? []
    }
}
