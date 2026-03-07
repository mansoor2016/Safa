// MARK: - PrayerViewModelTestHelpers.swift
// PURPOSE: Shared mock types for PrayerViewModel test suites
// DEPENDENCIES: XCTest, CoreLocation, Safa

import XCTest
import CoreLocation
@testable import Safa

// MARK: - Test Error

enum PrayerTestError: Error {
    case locationFailed
    case logFailed
    case notificationFailed
}

// MARK: - Testable Prayer Repository

@MainActor
class TestablePrayerRepository: PrayerRepositoryProtocol {
    var prayersToReturn: [PrayerTime] = []
    var prayerLogsToReturn: [PrayerLog] = []
    var errorToThrow: Error?

    var getPrayersCallCount = 0
    var logPrayerCallCount = 0
    var logPrayerCalled = false
    /// The `for` date parameter from the most recent `logPrayer` call.
    var lastLoggedForDate: Date?
    /// Error that only affects logPrayer (not getPrayers/getPrayerLogs).
    var logPrayerErrorToThrow: Error?
    /// When non-empty, logPrayer throws `logPrayerErrorToThrow` only for these types (others succeed).
    var logPrayerFailForTypes: Set<PrayerType> = []
    var lastRequestedDate: Date?
    /// When true, getPrayers will suspend at a gate for test synchronization.
    var shouldSuspendGetPrayers = false
    /// Continuation that getPrayers is waiting on. Resume from test to unblock.
    var getPrayersGate: CheckedContinuation<Void, Never>?

    nonisolated func getPrayers(for date: Date, location: Coordinates, method: CalculationMethod, madhab: Madhab? = nil) async throws -> [PrayerTime] {
        let error = await errorToThrow
        if let error { throw error }
        await MainActor.run {
            getPrayersCallCount += 1
            lastRequestedDate = date
        }
        // If gate is enabled, suspend until the test resumes the continuation
        let shouldSuspend = await MainActor.run { shouldSuspendGetPrayers }
        if shouldSuspend {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                Task { @MainActor in
                    self.getPrayersGate = continuation
                }
            }
        }
        return await prayersToReturn
    }

    nonisolated func logPrayer(_ prayer: PrayerType, for date: Date, at time: Date, isOnTime: Bool) async throws {
        let generalError = await errorToThrow
        let logSpecificError = await logPrayerErrorToThrow
        let failTypes = await logPrayerFailForTypes
        if let error = generalError { throw error }
        if let error = logSpecificError, failTypes.isEmpty || failTypes.contains(prayer) { throw error }
        await MainActor.run {
            logPrayerCallCount += 1
            logPrayerCalled = true
            lastLoggedForDate = date
        }
    }

    nonisolated func getPrayerLogs(from: Date, to: Date) async throws -> [PrayerLog] {
        return await prayerLogsToReturn
    }

    nonisolated func getPrayerLogs(for date: Date) async throws -> [PrayerLog] {
        return await prayerLogsToReturn
    }

    nonisolated func deletePrayerLog(_ log: PrayerLog) async throws {}

    nonisolated func isPrayerLogged(_ prayer: PrayerType, for date: Date) async throws -> Bool {
        let logs = await prayerLogsToReturn
        return await MainActor.run {
            logs.contains { $0.prayerType == prayer }
        }
    }

    nonisolated func getSunnahTimes(for date: Date, location: Coordinates, method: CalculationMethod, madhab: Madhab?) -> [SunnahTime] {
        []
    }
}

// MARK: - Persisting Testable Prayer Repository

/// Variant of TestablePrayerRepository where logPrayer actually adds to prayerLogsToReturn,
/// allowing tests to verify persistence survives across reloads.
@MainActor
final class PersistingTestablePrayerRepository: TestablePrayerRepository {
    override nonisolated func logPrayer(_ prayer: PrayerType, for date: Date, at time: Date, isOnTime: Bool) async throws {
        try await super.logPrayer(prayer, for: date, at: time, isOnTime: isOnTime)
        await MainActor.run {
            let log = PrayerLog(prayerType: prayer, date: date, loggedAt: time, isOnTime: isOnTime)
            prayerLogsToReturn.append(log)
        }
    }
}

// MARK: - Testable Location Service

final class TestableLocationService: LocationServiceProtocol {
    var locationToReturn: CLLocation?
    var errorToThrow: Error?
    var coordinatesToReturn: Coordinates?
    var getCurrentLocationCallCount = 0

    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    var coordinates: Coordinates? {
        if let coords = coordinatesToReturn { return coords }
        if let loc = locationToReturn {
            return Coordinates(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        }
        return nil
    }

    func requestPermission() {
        // No-op for testing
    }

    func getCurrentLocation() async throws -> CLLocation {
        getCurrentLocationCallCount += 1
        if let error = errorToThrow {
            throw error
        }
        return locationToReturn ?? CLLocation(latitude: 0, longitude: 0)
    }
}

// MARK: - Mock User Repository for Prayer Tests

@MainActor
final class PrayerTestMockUserRepository: UserRepositoryProtocol {
    var storedPreferences = UserPreferences()

    nonisolated func getUserStats() async throws -> UserStats {
        return UserStats()
    }

    nonisolated func updateUserStats(_ stats: UserStats) async throws {}

    nonisolated func addHasanat(_ amount: Int) async throws -> Int {
        return amount
    }

    nonisolated func getStreaks() async throws -> [Streak] {
        return StreakType.allCases.map { Streak(type: $0) }
    }

    nonisolated func getStreak(type: StreakType) async throws -> Streak? {
        return Streak(type: type)
    }

    nonisolated func updateStreak(_ streak: Streak) async throws {}

    var recordStreakCalls: [StreakType] = []

    nonisolated func recordStreakActivity(type: StreakType) async throws {
        await MainActor.run { recordStreakCalls.append(type) }
    }

    nonisolated func getPreference<T: Codable>(key: String) async throws -> T? {
        return nil
    }

    nonisolated func setPreference<T: Codable>(key: String, value: T) async throws {}

    nonisolated func getPreferences() async -> UserPreferences {
        return await storedPreferences
    }

    nonisolated func updatePreferences(_ preferences: UserPreferences) async throws {
        await MainActor.run { storedPreferences = preferences }
    }

    nonisolated func getStreakFreezes() async throws -> Int {
        return 0
    }

    nonisolated func useStreakFreeze() async throws {}

    nonisolated func awardStreakFreeze() async throws {}
}

// MARK: - Mock Prayer Helpers

/// Creates a set of future mock prayers for testing.
func createMockPrayers() -> [PrayerTime] {
    let now = Date()
    return [
        PrayerTime(type: .fajr, time: now.addingTimeInterval(3600)),
        PrayerTime(type: .sunrise, time: now.addingTimeInterval(7200)),
        PrayerTime(type: .dhuhr, time: now.addingTimeInterval(14400)),
        PrayerTime(type: .asr, time: now.addingTimeInterval(21600)),
        PrayerTime(type: .maghrib, time: now.addingTimeInterval(28800)),
        PrayerTime(type: .isha, time: now.addingTimeInterval(36000))
    ]
}

/// Creates mock prayers with some in the past for testing.
func createMockPrayersWithPast() -> [PrayerTime] {
    let now = Date()
    return [
        PrayerTime(type: .fajr, time: now.addingTimeInterval(-7200)),    // 2 hours ago
        PrayerTime(type: .sunrise, time: now.addingTimeInterval(-5400)), // 1.5 hours ago
        PrayerTime(type: .dhuhr, time: now.addingTimeInterval(-3600)),   // 1 hour ago
        PrayerTime(type: .asr, time: now.addingTimeInterval(3600)),      // 1 hour from now
        PrayerTime(type: .maghrib, time: now.addingTimeInterval(7200)),  // 2 hours from now
        PrayerTime(type: .isha, time: now.addingTimeInterval(10800))     // 3 hours from now
    ]
}
