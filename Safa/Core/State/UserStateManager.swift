// MARK: - UserStateManager.swift
// PURPOSE: Global state manager for user gamification data
// DEPENDENCIES: Foundation, UserRepositoryProtocol

import Foundation

@Observable
final class UserStateManager {
    // MARK: - Published State
    var userStats: UserStats
    var streaks: [Streak]
    var achievements: [Achievement]
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Dependencies
    private let userRepository: UserRepositoryProtocol

    // MARK: - Init
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
        self.userStats = UserStats()
        self.streaks = StreakType.allCases.map { Streak(type: $0) }
        self.achievements = Achievement.allAchievements

        // Load initial data
        Task {
            await loadUserData()
        }
    }

    // MARK: - Load Data

    func loadUserData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            userStats = try await userRepository.getUserStats()
            streaks = try await userRepository.getStreaks()
            achievements = try await userRepository.getAchievements()
            syncStreakToWidget()
        } catch {
            self.error = error
        }
    }

    // MARK: - Hasanat

    func awardHasanat(_ award: HasanatAward) async {
        do {
            // Check for Ramadan multiplier
            let points = HijriDateConverter.shared.isRamadan() ? award.points * 2 : award.points
            let newTotal = try await userRepository.addHasanat(points)

            // Update local state
            userStats.totalHasanat = newTotal
            userStats.currentLevel = UserStats.calculateLevel(from: newTotal)

            // Check for level-up achievements
            await checkLevelAchievements()
        } catch {
            self.error = error
        }
    }

    // MARK: - Streaks

    func recordActivity(type: StreakType) async {
        do {
            try await userRepository.recordStreakActivity(type: type)
            streaks = try await userRepository.getStreaks()

            // Award daily open hasanat if this is the first activity today
            if type == .daily {
                await awardHasanat(.dailyOpen)
            }

            // Check for streak achievements
            await checkStreakAchievements()

            // Sync streak to widget
            syncStreakToWidget()
        } catch {
            self.error = error
        }
    }

    // MARK: - Achievements

    func checkAndUnlockAchievement(_ achievementId: String) async {
        do {
            guard !(try await userRepository.isAchievementUnlocked(achievementId)) else {
                return
            }

            try await userRepository.unlockAchievement(achievementId)
            achievements = try await userRepository.getAchievements()

            // Update user stats
            if !userStats.unlockedAchievements.contains(achievementId) {
                userStats.unlockedAchievements.append(achievementId)
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Private Achievement Checks

    private func checkLevelAchievements() async {
        // Could add level-based achievements here
    }

    private func checkStreakAchievements() async {
        for streak in streaks {
            switch streak.type {
            case .prayer:
                if streak.currentCount >= 7 {
                    await checkAndUnlockAchievement("prayer_week_warrior")
                }
                if streak.currentCount >= 30 {
                    await checkAndUnlockAchievement("prayer_month_strong")
                }
            case .dhikr:
                if streak.currentCount >= 7 {
                    await checkAndUnlockAchievement("dhikr_morning")
                    await checkAndUnlockAchievement("dhikr_evening")
                }
            default:
                break
            }
        }
    }

    // MARK: - Computed Properties

    var currentLevel: Int {
        userStats.currentLevel
    }

    var levelTitle: String {
        UserStats.levelTitle(for: currentLevel)
    }

    var totalHasanat: Int {
        userStats.totalHasanat
    }

    var hasanatToNextLevel: Int {
        let nextLevelHasanat = UserStats.hasanatForLevel(currentLevel + 1)
        let currentLevelHasanat = UserStats.hasanatForLevel(currentLevel)
        return nextLevelHasanat - currentLevelHasanat
    }

    var hasanatProgressInLevel: Int {
        let currentLevelHasanat = UserStats.hasanatForLevel(currentLevel)
        return totalHasanat - currentLevelHasanat
    }

    var levelProgress: Double {
        guard hasanatToNextLevel > 0 else { return 1.0 }
        return Double(hasanatProgressInLevel) / Double(hasanatToNextLevel)
    }

    var dailyStreak: Streak? {
        streaks.first { $0.type == .daily }
    }

    var prayerStreak: Streak? {
        streaks.first { $0.type == .prayer }
    }

    var unlockedAchievementCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var totalAchievementCount: Int {
        achievements.count
    }

    // MARK: - Widget Sync

    private func syncStreakToWidget() {
        let streak = dailyStreak ?? prayerStreak
        WidgetDataService.shared.writeStreakData(
            currentCount: streak?.currentCount ?? 0,
            longestCount: streak?.longestCount ?? 0,
            isActiveToday: streak?.isActiveToday ?? false
        )
    }
}
