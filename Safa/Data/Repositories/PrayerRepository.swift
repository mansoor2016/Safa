// MARK: - PrayerRepository.swift
// PURPOSE: Implementation of prayer data access and persistence
// DEPENDENCIES: CoreData, PrayerRepositoryProtocol

import Foundation
import CoreData

final class PrayerRepository: PrayerRepositoryProtocol {
    // MARK: - Dependencies
    private let coreData: CoreDataStack
    private let calculator = PrayerTimeCalculator()

    // MARK: - Init
    init(coreData: CoreDataStack) {
        self.coreData = coreData
    }

    // MARK: - Prayer Times

    func getPrayers(for date: Date, location: Coordinates, method: CalculationMethod, madhab: Madhab? = nil) async throws -> [PrayerTime] {
        let prefs = PreferencesManager.loadPreferencesSync()
        var prayers = calculator.calculatePrayerTimes(for: date, location: location, method: method, madhab: madhab)
        let adjustments = prefs.prayerAdjustments
        if !adjustments.isEmpty {
            prayers = prayers.map { prayer in
                guard let offset = adjustments[prayer.type.rawValue], offset != 0 else { return prayer }
                return PrayerTime(
                    id: prayer.id,
                    type: prayer.type,
                    time: prayer.time.addingTimeInterval(TimeInterval(offset * 60)),
                    isNext: prayer.isNext
                )
            }
        }
        return prayers
    }

    // MARK: - Prayer Logging

    func logPrayer(_ prayer: PrayerType, for date: Date, at time: Date, isOnTime: Bool) async throws {
        // Check if already logged
        let existingLog = try await fetchPrayerLog(prayer: prayer, date: date)
        if existingLog != nil {
            return // Already logged
        }

        // Create new log
        // TODO: Implement with Core Data managed object
        // For now, store in UserDefaults as placeholder
        var logs = getPrayerLogsFromDefaults()
        let log = PrayerLog(
            prayerType: prayer,
            date: date,
            loggedAt: time,
            isOnTime: isOnTime
        )
        logs.append(log)
        savePrayerLogsToDefaults(logs)
    }

    func getPrayerLogs(from startDate: Date, to endDate: Date) async throws -> [PrayerLog] {
        let allLogs = getPrayerLogsFromDefaults()
        return allLogs.filter { log in
            log.date >= startDate && log.date <= endDate
        }
    }

    func getPrayerLogs(for date: Date) async throws -> [PrayerLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return try await getPrayerLogs(from: startOfDay, to: endOfDay)
    }

    func deletePrayerLog(_ log: PrayerLog) async throws {
        var logs = getPrayerLogsFromDefaults()
        logs.removeAll { $0.id == log.id }
        savePrayerLogsToDefaults(logs)
    }

    func isPrayerLogged(_ prayer: PrayerType, for date: Date) async throws -> Bool {
        let logs = try await getPrayerLogs(for: date)
        return logs.contains { $0.prayerType == prayer }
    }

    // MARK: - Private Helpers

    private func fetchPrayerLog(prayer: PrayerType, date: Date) async throws -> PrayerLog? {
        let logs = try await getPrayerLogs(for: date)
        return logs.first { $0.prayerType == prayer }
    }

    // MARK: - Temporary UserDefaults Storage (until Core Data entities are created)
    // Uses App Group UserDefaults so widgets can also access prayer logs

    private let prayerLogsKey = AppConstants.StorageKeys.prayerLogs
    private let migrationKey = AppConstants.StorageKeys.prayerLogsMigrated
    private lazy var appGroupDefaults: UserDefaults = {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupId) ?? .standard
        migrateToAppGroupIfNeeded(defaults)
        return defaults
    }()

    /// One-time migration from UserDefaults.standard to App Group
    private func migrateToAppGroupIfNeeded(_ appGroup: UserDefaults) {
        guard !appGroup.bool(forKey: migrationKey) else { return }

        // Copy existing data from standard to App Group
        if let data = UserDefaults.standard.data(forKey: prayerLogsKey) {
            appGroup.set(data, forKey: prayerLogsKey)
        }
        appGroup.set(true, forKey: migrationKey)
    }

    private func getPrayerLogsFromDefaults() -> [PrayerLog] {
        guard let data = appGroupDefaults.data(forKey: prayerLogsKey),
              let logs = try? JSONDecoder().decode([PrayerLog].self, from: data) else {
            return []
        }
        return logs
    }

    private func savePrayerLogsToDefaults(_ logs: [PrayerLog]) {
        guard let data = try? JSONEncoder().encode(logs) else { return }
        appGroupDefaults.set(data, forKey: prayerLogsKey)
    }
}
