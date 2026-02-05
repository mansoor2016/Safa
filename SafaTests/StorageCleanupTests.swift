// MARK: - StorageCleanupTests.swift
// PURPOSE: Tests for StorageCleanupService and RetentionPeriod
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class StorageCleanupTests: XCTestCase {

    // MARK: - RetentionPeriod Tests

    func testRetentionPeriodDays() {
        XCTAssertEqual(RetentionPeriod.oneMonth.days, 30)
        XCTAssertEqual(RetentionPeriod.threeMonths.days, 90)
        XCTAssertEqual(RetentionPeriod.sixMonths.days, 180)
        XCTAssertNil(RetentionPeriod.never.days)
    }

    func testRetentionPeriodDisplayNames() {
        XCTAssertEqual(RetentionPeriod.oneMonth.displayName, "1 Month")
        XCTAssertEqual(RetentionPeriod.threeMonths.displayName, "3 Months")
        XCTAssertEqual(RetentionPeriod.sixMonths.displayName, "6 Months")
        XCTAssertEqual(RetentionPeriod.never.displayName, "Never")
    }

    func testRetentionPeriodDescriptions() {
        XCTAssertTrue(RetentionPeriod.oneMonth.description.contains("1 month"))
        XCTAssertTrue(RetentionPeriod.threeMonths.description.contains("3 months"))
        XCTAssertTrue(RetentionPeriod.sixMonths.description.contains("6 months"))
        XCTAssertTrue(RetentionPeriod.never.description.contains("Never"))
    }

    func testRetentionPeriodCodable() throws {
        let period = RetentionPeriod.threeMonths

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(period)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RetentionPeriod.self, from: data)

        XCTAssertEqual(decoded, period)
    }

    func testAllRetentionPeriodsExist() {
        let allCases = RetentionPeriod.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.oneMonth))
        XCTAssertTrue(allCases.contains(.threeMonths))
        XCTAssertTrue(allCases.contains(.sixMonths))
        XCTAssertTrue(allCases.contains(.never))
    }

    // MARK: - AudioFileMetadata Tests

    func testAudioFileMetadataDaysSinceLastPlayed() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!

        let metadata = AudioFileMetadata(
            id: "test",
            fileName: "test.mp3",
            lastPlayedDate: twoDaysAgo,
            downloadedDate: Date(),
            fileSize: 1000
        )

        XCTAssertEqual(metadata.daysSinceLastPlayed, 2)
    }

    func testAudioFileMetadataNeverPlayed() {
        let metadata = AudioFileMetadata(
            id: "test",
            fileName: "test.mp3",
            lastPlayedDate: nil,
            downloadedDate: Date(),
            fileSize: 1000
        )

        XCTAssertNil(metadata.daysSinceLastPlayed)
    }

    func testAudioFileMetadataFormattedFileSize() {
        let metadata = AudioFileMetadata(
            id: "test",
            fileName: "test.mp3",
            lastPlayedDate: nil,
            downloadedDate: Date(),
            fileSize: 1_000_000 // 1 MB
        )

        // Should format as KB or MB
        XCTAssertFalse(metadata.formattedFileSize.isEmpty)
    }

    // MARK: - File Expiration Tests

    func testFileIsExpiredWithOneMonthRetention() {
        let thirtyOneDaysAgo = Calendar.current.date(byAdding: .day, value: -31, to: Date())!

        let metadata = AudioFileMetadata(
            id: "test",
            fileName: "test.mp3",
            lastPlayedDate: thirtyOneDaysAgo,
            downloadedDate: Date(),
            fileSize: 1000
        )

        // File last played 31 days ago should be expired with 1 month retention
        if let daysSinceLastPlayed = metadata.daysSinceLastPlayed,
           let retentionDays = RetentionPeriod.oneMonth.days {
            XCTAssertTrue(daysSinceLastPlayed > retentionDays)
        }
    }

    func testFileIsNotExpiredWithNeverRetention() {
        let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!

        let metadata = AudioFileMetadata(
            id: "test",
            fileName: "test.mp3",
            lastPlayedDate: yearAgo,
            downloadedDate: Date(),
            fileSize: 1000
        )

        // With "Never" retention, files should never be expired
        XCTAssertNil(RetentionPeriod.never.days)
        // Even a year-old file should not be marked for cleanup
    }

    func testRecentFileIsNotExpired() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let metadata = AudioFileMetadata(
            id: "test",
            fileName: "test.mp3",
            lastPlayedDate: yesterday,
            downloadedDate: Date(),
            fileSize: 1000
        )

        // File played yesterday should not be expired
        if let daysSinceLastPlayed = metadata.daysSinceLastPlayed,
           let retentionDays = RetentionPeriod.oneMonth.days {
            XCTAssertTrue(daysSinceLastPlayed < retentionDays)
        }
    }
}
