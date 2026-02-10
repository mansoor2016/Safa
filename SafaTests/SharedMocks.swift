// MARK: - SharedMocks.swift
// PURPOSE: Shared mock repositories and services for tests
// DEPENDENCIES: XCTest, @testable import Safa

import Foundation
import CoreLocation
@testable import Safa

// MARK: - Mock User Repository

/// Shared mock that covers all test needs: stub returns, call tracking, and state storage.
/// Use for any test requiring UserRepositoryProtocol.
@MainActor
final class MockUserRepository: UserRepositoryProtocol {
    // MARK: - Configurable State
    var statsToReturn = UserStats()
    var storedPreferences = UserPreferences()
    var streaksToReturn: [Streak] = StreakType.allCases.map { Streak(type: $0) }
    var achievementsToReturn: [Achievement] = []
    var unlockedAchievements: Set<String> = []
    var streakFreezesCount = 0
    var errorToThrow: Error?

    // MARK: - Call Tracking
    var addHasanatCalls: [Int] = []
    var recordStreakCalls: [StreakType] = []
    var updateStatsCalls: [UserStats] = []
    var updatePreferencesCalls: [UserPreferences] = []

    // MARK: - User Stats

    nonisolated func getUserStats() async throws -> UserStats {
        if let error = await errorToThrow { throw error }
        return await statsToReturn
    }

    nonisolated func updateUserStats(_ stats: UserStats) async throws {
        if let error = await errorToThrow { throw error }
        await MainActor.run {
            statsToReturn = stats
            updateStatsCalls.append(stats)
        }
    }

    @discardableResult
    nonisolated func addHasanat(_ amount: Int) async throws -> Int {
        if let error = await errorToThrow { throw error }
        return await MainActor.run {
            addHasanatCalls.append(amount)
            statsToReturn.totalHasanat += amount
            return statsToReturn.totalHasanat
        }
    }

    // MARK: - Streaks

    nonisolated func getStreaks() async throws -> [Streak] {
        if let error = await errorToThrow { throw error }
        return await streaksToReturn
    }

    nonisolated func getStreak(type: StreakType) async throws -> Streak? {
        if let error = await errorToThrow { throw error }
        return await streaksToReturn.first { $0.type == type } ?? Streak(type: type)
    }

    nonisolated func updateStreak(_ streak: Streak) async throws {
        if let error = await errorToThrow { throw error }
    }

    nonisolated func recordStreakActivity(type: StreakType) async throws {
        if let error = await errorToThrow { throw error }
        await MainActor.run { recordStreakCalls.append(type) }
    }

    // MARK: - Achievements

    nonisolated func getAchievements() async throws -> [Achievement] {
        if let error = await errorToThrow { throw error }
        return await achievementsToReturn
    }

    nonisolated func unlockAchievement(_ achievementId: String) async throws {
        if let error = await errorToThrow { throw error }
        await MainActor.run { unlockedAchievements.insert(achievementId) }
    }

    nonisolated func isAchievementUnlocked(_ achievementId: String) async throws -> Bool {
        if let error = await errorToThrow { throw error }
        return await unlockedAchievements.contains(achievementId)
    }

    // MARK: - Preferences

    nonisolated func getPreference<T: Codable>(key: String) async throws -> T? { nil }
    nonisolated func setPreference<T: Codable>(key: String, value: T) async throws {}

    nonisolated func getPreferences() async -> UserPreferences {
        await storedPreferences
    }

    nonisolated func updatePreferences(_ preferences: UserPreferences) async throws {
        if let error = await errorToThrow { throw error }
        await MainActor.run {
            storedPreferences = preferences
            updatePreferencesCalls.append(preferences)
        }
    }

    // MARK: - Streak Freezes

    nonisolated func getStreakFreezes() async throws -> Int {
        if let error = await errorToThrow { throw error }
        return await streakFreezesCount
    }

    nonisolated func useStreakFreeze() async throws {
        if let error = await errorToThrow { throw error }
    }

    nonisolated func awardStreakFreeze() async throws {
        if let error = await errorToThrow { throw error }
    }
}

// MARK: - Mock Prayer Repository

/// Shared mock for PrayerRepositoryProtocol with call tracking and configurable returns.
@MainActor
final class MockPrayerRepository: PrayerRepositoryProtocol {
    // MARK: - Configurable State
    var prayersToReturn: [PrayerTime] = []
    var prayerLogsToReturn: [PrayerLog] = []
    var errorToThrow: Error?

    // MARK: - Call Tracking
    var getPrayersCallCount = 0
    var logPrayerCallCount = 0

    // MARK: - Protocol

    nonisolated func getPrayers(for date: Date, location: Coordinates, method: CalculationMethod, madhab: Madhab? = nil) async throws -> [PrayerTime] {
        if let error = await errorToThrow { throw error }
        await MainActor.run { getPrayersCallCount += 1 }
        return await prayersToReturn
    }

    nonisolated func logPrayer(_ type: PrayerType, for date: Date, at time: Date, isOnTime: Bool) async throws {
        if let error = await errorToThrow { throw error }
        await MainActor.run { logPrayerCallCount += 1 }
    }

    nonisolated func deletePrayerLog(_ log: PrayerLog) async throws {
        if let error = await errorToThrow { throw error }
    }

    nonisolated func getPrayerLogs(for date: Date) async throws -> [PrayerLog] {
        if let error = await errorToThrow { throw error }
        return await prayerLogsToReturn
    }

    nonisolated func getPrayerLogs(from: Date, to: Date) async throws -> [PrayerLog] {
        if let error = await errorToThrow { throw error }
        return await prayerLogsToReturn
    }

    nonisolated func isPrayerLogged(_ type: PrayerType, for date: Date) async throws -> Bool {
        let logs = await prayerLogsToReturn
        return logs.contains { $0.prayerType == type }
    }
}

// MARK: - Mock Location Service

/// Shared mock for LocationServiceProtocol.
final class MockLocationService: LocationServiceProtocol {
    var locationToReturn: CLLocation?
    var coordinatesToReturn: Coordinates?
    var errorToThrow: Error?

    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse

    var coordinates: Coordinates? {
        if let coords = coordinatesToReturn { return coords }
        if let loc = locationToReturn {
            return Coordinates(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        }
        return nil
    }

    func requestPermission() {}

    func getCurrentLocation() async throws -> CLLocation {
        if let error = errorToThrow { throw error }
        return locationToReturn ?? CLLocation(latitude: 51.5074, longitude: -0.1278)
    }
}

// NotificationService mock removed — notifications consolidated into NotificationScheduler singleton
