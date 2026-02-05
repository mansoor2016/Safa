// MARK: - HealthKitService.swift
// PURPOSE: Apple Health integration for logging Ramadan fasting hours
// DEPENDENCIES: HealthKit

import Foundation
import HealthKit

// MARK: - Fasting Log Entry

struct FastingLogEntry: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let type: FastingType
    let syncedToHealth: Bool

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var durationHours: Double {
        duration / 3600
    }

    enum FastingType: String, Codable {
        case ramadan = "ramadan"
        case voluntary = "voluntary"
        case qadha = "qadha" // Making up missed fasts
    }

    init(startDate: Date, endDate: Date, type: FastingType = .ramadan, syncedToHealth: Bool = false) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.type = type
        self.syncedToHealth = syncedToHealth
    }
}

// MARK: - HealthKit Service

@Observable
final class HealthKitService {
    static let shared = HealthKitService()

    // MARK: - Properties

    private let healthStore = HKHealthStore()
    private let userDefaults = UserDefaults.standard

    private(set) var isHealthKitAvailable: Bool = false
    private(set) var authorizationStatus: HKAuthorizationStatus = .notDetermined
    private(set) var isAuthorized: Bool = false

    // Storage Keys
    private let syncEnabledKey = "com.safa.healthkit.syncEnabled"
    private let hasPromptedKey = "com.safa.healthkit.hasPrompted"
    private let fastingLogsKey = "com.safa.healthkit.fastingLogs"

    // Configuration
    var syncEnabled: Bool {
        get { userDefaults.bool(forKey: syncEnabledKey) }
        set { userDefaults.set(newValue, forKey: syncEnabledKey) }
    }

    var hasPromptedUser: Bool {
        get { userDefaults.bool(forKey: hasPromptedKey) }
        set { userDefaults.set(newValue, forKey: hasPromptedKey) }
    }

    // MARK: - Init

    private init() {
        checkAvailability()
    }

    // MARK: - Availability

    func checkAvailability() {
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()

        if isHealthKitAvailable {
            // Check current authorization status for dietary energy
            let status = healthStore.authorizationStatus(for: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
            authorizationStatus = status
            isAuthorized = status == .sharingAuthorized
        }
    }

    // MARK: - Authorization

    /// Request HealthKit authorization for writing fasting data
    func requestAuthorization() async -> Bool {
        guard isHealthKitAvailable else {
            return false
        }

        // Define the data types we want to write
        // Note: There's no dedicated "fasting" type in HealthKit
        // We use Sleep Analysis as a proxy since fasting is time-based
        // In a production app, you might use a custom workout type or dietary data
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        let typesToRead: Set<HKObjectType> = []

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)

            await MainActor.run {
                checkAvailability()
            }

            return isAuthorized
        } catch {
            print("HealthKitService: Authorization error: \(error)")
            return false
        }
    }

    // MARK: - Fasting Logging

    /// Log a completed fast to Apple Health
    func logFast(start: Date, end: Date, type: FastingLogEntry.FastingType = .ramadan) async throws {
        guard syncEnabled else {
            // Just save locally if sync is disabled
            saveFastingLogLocally(start: start, end: end, type: type, synced: false)
            return
        }

        if !isAuthorized {
            let authorized = await requestAuthorization()
            if !authorized {
                throw HealthKitError.authorizationDenied
            }
        }

        // Create a sleep analysis sample (using as proxy for fasting period)
        // In production, consider using HKWorkout with a custom activity type
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.typeNotAvailable
        }

        // Use "in bed" category as it represents a time period
        let sample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.inBed.rawValue,
            start: start,
            end: end,
            metadata: [
                HKMetadataKeyWasUserEntered: true,
                "com.safa.fasting.type": type.rawValue,
                "com.safa.fasting.source": "Safa App"
            ]
        )

        try await healthStore.save(sample)
        saveFastingLogLocally(start: start, end: end, type: type, synced: true)
    }

    /// Log today's fast (convenience method for Ramadan)
    func logTodaysFast(suhoorTime: Date, iftarTime: Date) async throws {
        try await logFast(start: suhoorTime, end: iftarTime, type: .ramadan)
    }

    // MARK: - Local Fasting Logs

    private func saveFastingLogLocally(start: Date, end: Date, type: FastingLogEntry.FastingType, synced: Bool) {
        var logs = getFastingLogs()
        let entry = FastingLogEntry(startDate: start, endDate: end, type: type, syncedToHealth: synced)
        logs.append(entry)

        if let data = try? JSONEncoder().encode(logs) {
            userDefaults.set(data, forKey: fastingLogsKey)
        }
    }

    func getFastingLogs() -> [FastingLogEntry] {
        guard let data = userDefaults.data(forKey: fastingLogsKey),
              let logs = try? JSONDecoder().decode([FastingLogEntry].self, from: data) else {
            return []
        }
        return logs.sorted { $0.startDate > $1.startDate }
    }

    func getTotalFastingHours() -> Double {
        getFastingLogs().reduce(0) { $0 + $1.durationHours }
    }

    func getRamadanFastCount() -> Int {
        getFastingLogs().filter { $0.type == .ramadan }.count
    }

    // MARK: - Sync Pending Logs

    /// Sync any unsynced fasting logs to HealthKit
    func syncPendingLogs() async {
        guard syncEnabled && isAuthorized else { return }

        let logs = getFastingLogs().filter { !$0.syncedToHealth }

        for log in logs {
            do {
                try await logFast(start: log.startDate, end: log.endDate, type: log.type)
            } catch {
                print("HealthKitService: Failed to sync log: \(error)")
            }
        }
    }

    // MARK: - Reset

    func clearLocalLogs() {
        userDefaults.removeObject(forKey: fastingLogsKey)
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied
    case typeNotAvailable
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Apple Health is not available on this device."
        case .authorizationDenied:
            return "Apple Health access was denied. Please enable access in Settings."
        case .typeNotAvailable:
            return "The required health data type is not available."
        case .saveFailed(let error):
            return "Failed to save to Apple Health: \(error.localizedDescription)"
        }
    }
}

// MARK: - Feature Flag Integration

extension HealthKitService {
    var isAvailable: Bool {
        isHealthKitAvailable && FeatureFlags.shared.isEnabled(.healthKitSync)
    }
}

// MARK: - Ramadan Integration

extension HealthKitService {
    /// Prompt user to enable Health sync on first fast logged during Ramadan
    func promptForHealthSyncIfNeeded() async -> Bool {
        guard !hasPromptedUser && isHealthKitAvailable else {
            return false
        }

        hasPromptedUser = true
        return true // Return true to indicate prompt should be shown
    }

    /// Calculate fasting hours for a given day during Ramadan
    func calculateFastingHours(suhoorTime: Date, iftarTime: Date) -> Double {
        let duration = iftarTime.timeIntervalSince(suhoorTime)
        return max(0, duration / 3600)
    }
}
