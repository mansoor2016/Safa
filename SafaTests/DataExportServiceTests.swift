// MARK: - DataExportServiceTests.swift
// PURPOSE: Unit tests for data export functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

@MainActor
final class DataExportServiceTests: XCTestCase {

    // MARK: - JSON Export Tests

    func test_exportJSON_producesValidJSON() async throws {
        // Given
        let mockUserRepo = ExportTestMockUserRepository()
        let mockQuranRepo = ExportTestMockQuranRepository()

        // When
        let data = try await DataExportService.exportJSON(
            userRepository: mockUserRepo,
            quranRepository: mockQuranRepo
        )

        // Then
        XCTAssertFalse(data.isEmpty)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
    }

    func test_exportJSON_containsSchemaVersion() async throws {
        let data = try await DataExportService.exportJSON(
            userRepository: ExportTestMockUserRepository(),
            quranRepository: ExportTestMockQuranRepository()
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(DataExportService.ExportPayload.self, from: data)
        XCTAssertEqual(payload.schemaVersion, "1.0")
    }

    func test_exportJSON_containsAppVersion() async throws {
        let data = try await DataExportService.exportJSON(
            userRepository: ExportTestMockUserRepository(),
            quranRepository: ExportTestMockQuranRepository()
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(DataExportService.ExportPayload.self, from: data)
        XCTAssertEqual(payload.appVersion, "0.0.1")
    }

    func test_exportJSON_containsExportDate() async throws {
        let before = Date().addingTimeInterval(-1)
        let data = try await DataExportService.exportJSON(
            userRepository: ExportTestMockUserRepository(),
            quranRepository: ExportTestMockQuranRepository()
        )
        let after = Date().addingTimeInterval(1)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(DataExportService.ExportPayload.self, from: data)
        XCTAssertGreaterThanOrEqual(payload.exportedAt, before)
        XCTAssertLessThanOrEqual(payload.exportedAt, after)
    }

    func test_exportJSON_containsPreferences() async throws {
        let data = try await DataExportService.exportJSON(
            userRepository: ExportTestMockUserRepository(),
            quranRepository: ExportTestMockQuranRepository()
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(DataExportService.ExportPayload.self, from: data)
        XCTAssertNotNil(payload.preferences)
    }

    // MARK: - CSV Export Tests

    func test_exportCSV_producesValidCSV() async throws {
        let mockPrayerRepo = ExportTestMockPrayerRepository()

        let data = try await DataExportService.exportPrayerLogsCSV(
            prayerRepository: mockPrayerRepo,
            from: Date().addingTimeInterval(-86400),
            to: Date()
        )

        let csv = String(data: data, encoding: .utf8)
        XCTAssertNotNil(csv)
        XCTAssertTrue(csv!.hasPrefix("date,prayer,logged_at,on_time"))
    }

    func test_exportCSV_containsHeader() async throws {
        let data = try await DataExportService.exportPrayerLogsCSV(
            prayerRepository: ExportTestMockPrayerRepository(),
            from: Date().addingTimeInterval(-86400),
            to: Date()
        )

        let csv = String(data: data, encoding: .utf8)!
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.first, "date,prayer,logged_at,on_time")
    }

    func test_exportCSV_emptyLogs_hasOnlyHeader() async throws {
        let data = try await DataExportService.exportPrayerLogsCSV(
            prayerRepository: ExportTestMockPrayerRepository(),
            from: Date().addingTimeInterval(-86400),
            to: Date()
        )

        let csv = String(data: data, encoding: .utf8)!
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 1) // Just header
    }
}

// MARK: - Mock Repositories

@MainActor
private final class ExportTestMockUserRepository: UserRepositoryProtocol {
    nonisolated func getUserStats() async throws -> UserStats { UserStats() }
    nonisolated func updateUserStats(_ stats: UserStats) async throws {}
    nonisolated func addHasanat(_ amount: Int) async throws -> Int { amount }
    nonisolated func getStreaks() async throws -> [Streak] {
        StreakType.allCases.map { Streak(type: $0) }
    }
    nonisolated func getStreak(type: StreakType) async throws -> Streak? { Streak(type: type) }
    nonisolated func updateStreak(_ streak: Streak) async throws {}
    nonisolated func recordStreakActivity(type: StreakType) async throws {}
    nonisolated func getAchievements() async throws -> [Achievement] { [] }
    nonisolated func unlockAchievement(_ achievementId: String) async throws {}
    nonisolated func isAchievementUnlocked(_ achievementId: String) async throws -> Bool { false }
    nonisolated func getPreference<T: Codable>(key: String) async throws -> T? { nil }
    nonisolated func setPreference<T: Codable>(key: String, value: T) async throws {}
    nonisolated func getPreferences() async -> UserPreferences { UserPreferences() }
    nonisolated func updatePreferences(_ preferences: UserPreferences) async throws {}
    nonisolated func getStreakFreezes() async throws -> Int { 0 }
    nonisolated func useStreakFreeze() async throws {}
    nonisolated func awardStreakFreeze() async throws {}
}

@MainActor
private final class ExportTestMockQuranRepository: QuranRepositoryProtocol {
    nonisolated func getAllSurahs() async throws -> [Surah] { [] }
    nonisolated func getSurah(number: Int) async throws -> Surah? { nil }
    nonisolated func getAyahs(forSurah number: Int) async throws -> [Ayah] { [] }
    nonisolated func getAyah(surah: Int, ayah: Int) async throws -> Ayah? { nil }
    nonisolated func searchAyahs(query: String) async throws -> [Ayah] { [] }
    nonisolated func getBookmarks() async throws -> [QuranBookmark] { [] }
    nonisolated func addBookmark(surah: Int, ayah: Int) async throws {}
    nonisolated func removeBookmark(surah: Int, ayah: Int) async throws {}
    nonisolated func isBookmarked(surah: Int, ayah: Int) async throws -> Bool { false }
    nonisolated func getReadingProgress() async throws -> QuranProgress? { nil }
    nonisolated func updateProgress(surah: Int, ayah: Int) async throws {}
    nonisolated func getJuz(number: Int) async throws -> Juz? { nil }
    nonisolated func getAllJuz() async throws -> [Juz] { [] }
}

@MainActor
private final class ExportTestMockPrayerRepository: PrayerRepositoryProtocol {
    nonisolated func getPrayers(for date: Date, location: Coordinates, method: CalculationMethod) async throws -> [PrayerTime] { [] }
    nonisolated func logPrayer(_ prayer: PrayerType, for date: Date, at time: Date, isOnTime: Bool) async throws {}
    nonisolated func getPrayerLogs(from: Date, to: Date) async throws -> [PrayerLog] { [] }
    nonisolated func getPrayerLogs(for date: Date) async throws -> [PrayerLog] { [] }
    nonisolated func deletePrayerLog(_ log: PrayerLog) async throws {}
    nonisolated func isPrayerLogged(_ prayer: PrayerType, for date: Date) async throws -> Bool { false }
}
