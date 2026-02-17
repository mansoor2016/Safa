// MARK: - DataExportService.swift
// PURPOSE: Export user data as JSON or CSV for data sovereignty
// DEPENDENCIES: Foundation

import Foundation

struct DataExportService {

    // MARK: - Export Models

    struct ExportPayload: Codable {
        let schemaVersion: String
        let exportedAt: Date
        let appVersion: String
        let preferences: UserPreferences
        let userStats: UserStats
        let streaks: [Streak]
        let quranBookmarks: [QuranBookmark]
        let quranProgress: QuranProgress?
    }

    // MARK: - JSON Export

    /// Exports all user data as a JSON file
    static func exportJSON(
        userRepository: UserRepositoryProtocol,
        quranRepository: QuranRepositoryProtocol
    ) async throws -> Data {
        let prefs = await userRepository.getPreferences()
        let stats = try await userRepository.getUserStats()
        let streaks = try await userRepository.getStreaks()
        let bookmarks = try await quranRepository.getBookmarks()
        let progress = try await quranRepository.getReadingProgress()

        let payload = ExportPayload(
            schemaVersion: "1.0",
            exportedAt: Date(),
            appVersion: "0.0.1",
            preferences: prefs,
            userStats: stats,
            streaks: streaks,
            quranBookmarks: bookmarks,
            quranProgress: progress
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    // MARK: - CSV Export (Prayer Logs)

    /// Exports prayer logs as CSV
    static func exportPrayerLogsCSV(
        prayerRepository: PrayerRepositoryProtocol,
        from startDate: Date,
        to endDate: Date
    ) async throws -> Data {
        let logs = try await prayerRepository.getPrayerLogs(from: startDate, to: endDate)

        var csv = "date,prayer,logged_at,on_time\n"
        let dateFormatter = ISO8601DateFormatter()

        for log in logs {
            let date = dateFormatter.string(from: log.date)
            let loggedAt = dateFormatter.string(from: log.loggedAt)
            csv += "\(date),\(log.prayerType.rawValue),\(loggedAt),\(log.isOnTime)\n"
        }

        return Data(csv.utf8)
    }
}
