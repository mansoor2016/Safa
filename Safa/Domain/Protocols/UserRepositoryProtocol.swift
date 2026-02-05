// MARK: - UserRepositoryProtocol.swift
// PURPOSE: Defines contract for user data, progress, and gamification persistence

import Foundation

protocol UserRepositoryProtocol {
    // MARK: - User Stats

    /// Gets the current user stats
    /// - Returns: User stats including Hasanat, level, achievements
    func getUserStats() async throws -> UserStats

    /// Updates user stats
    /// - Parameter stats: The updated stats
    func updateUserStats(_ stats: UserStats) async throws

    /// Adds Hasanat to the user's total
    /// - Parameter amount: Amount of Hasanat to add
    /// - Returns: Updated total Hasanat
    @discardableResult
    func addHasanat(_ amount: Int) async throws -> Int

    // MARK: - Streaks

    /// Gets all streaks
    /// - Returns: Array of streak data
    func getStreaks() async throws -> [Streak]

    /// Gets a specific streak
    /// - Parameter type: The streak type
    /// - Returns: The streak if found
    func getStreak(type: StreakType) async throws -> Streak?

    /// Updates a streak
    /// - Parameter streak: The updated streak
    func updateStreak(_ streak: Streak) async throws

    /// Records activity for streak tracking
    /// - Parameter type: The activity type
    func recordStreakActivity(type: StreakType) async throws

    // MARK: - Achievements

    /// Gets all achievements with unlock status
    /// - Returns: Array of achievements
    func getAchievements() async throws -> [Achievement]

    /// Unlocks an achievement
    /// - Parameter achievementId: The achievement identifier
    func unlockAchievement(_ achievementId: String) async throws

    /// Checks if an achievement is unlocked
    /// - Parameter achievementId: The achievement identifier
    /// - Returns: True if unlocked
    func isAchievementUnlocked(_ achievementId: String) async throws -> Bool

    // MARK: - Preferences

    /// Gets a user preference
    /// - Parameter key: The preference key
    /// - Returns: The preference value
    func getPreference<T: Codable>(key: String) async throws -> T?

    /// Sets a user preference
    /// - Parameters:
    ///   - key: The preference key
    ///   - value: The preference value
    func setPreference<T: Codable>(key: String, value: T) async throws

    /// Gets all user preferences
    /// - Returns: User preferences struct
    func getPreferences() async -> UserPreferences

    /// Updates user preferences
    /// - Parameter preferences: The updated preferences
    func updatePreferences(_ preferences: UserPreferences) async throws

    // MARK: - Streak Freezes

    /// Gets remaining streak freezes
    /// - Returns: Number of available freezes
    func getStreakFreezes() async throws -> Int

    /// Uses a streak freeze
    func useStreakFreeze() async throws

    /// Awards a streak freeze
    func awardStreakFreeze() async throws
}
