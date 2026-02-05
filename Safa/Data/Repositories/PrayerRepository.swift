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

    func getPrayers(for date: Date, location: Coordinates, method: CalculationMethod) async throws -> [PrayerTime] {
        calculator.calculatePrayerTimes(for: date, location: location, method: method)
    }

    // MARK: - Prayer Logging

    func logPrayer(_ prayer: PrayerType, for date: Date, at time: Date, isOnTime: Bool) async throws {
        let context = coreData.viewContext

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

    private let prayerLogsKey = "com.safa.prayerLogs"

    private func getPrayerLogsFromDefaults() -> [PrayerLog] {
        guard let data = UserDefaults.standard.data(forKey: prayerLogsKey),
              let logs = try? JSONDecoder().decode([PrayerLog].self, from: data) else {
            return []
        }
        return logs
    }

    private func savePrayerLogsToDefaults(_ logs: [PrayerLog]) {
        guard let data = try? JSONEncoder().encode(logs) else { return }
        UserDefaults.standard.set(data, forKey: prayerLogsKey)
    }
}
