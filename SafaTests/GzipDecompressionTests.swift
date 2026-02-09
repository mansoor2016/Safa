// MARK: - GzipDecompressionTests.swift
// PURPOSE: Test gzip decompression for bundled compressed databases
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class GzipDecompressionTests: XCTestCase {

    // MARK: - Data+Gzip Tests

    func test_gunzip_returnsNil_forEmptyData() {
        let data = Data()
        XCTAssertNil(data.gunzip())
    }

    func test_gunzip_returnsNil_forNonGzipData() {
        let data = Data("Hello world".utf8)
        XCTAssertNil(data.gunzip())
    }

    func test_gunzip_returnsNil_forTooSmallData() {
        let data = Data([0x1f, 0x8b, 0x08]) // Valid magic but too short
        XCTAssertNil(data.gunzip())
    }

    func test_gunzip_decompressesValidGzipData() {
        // Use the actual bundled hadith.sqlite.gz as the test fixture
        // This tests the real decompression path without creating temp files
        guard let gzPath = Bundle.main.url(forResource: "hadith", withExtension: "sqlite.gz", subdirectory: "Data/Database")
                ?? Bundle.main.url(forResource: "hadith", withExtension: "sqlite.gz") else {
            // No .gz in bundle (might be running with uncompressed DB) — skip
            return
        }

        guard let compressedData = try? Data(contentsOf: gzPath) else {
            XCTFail("Could not read hadith.sqlite.gz")
            return
        }

        XCTAssertTrue(compressedData.count > 0)
        // Verify gzip magic number
        XCTAssertEqual(compressedData[0], 0x1f)
        XCTAssertEqual(compressedData[1], 0x8b)

        guard let decompressed = compressedData.gunzip() else {
            XCTFail("gunzip() returned nil for hadith.sqlite.gz")
            return
        }

        // Decompressed should be larger than compressed
        XCTAssertGreaterThan(decompressed.count, compressedData.count)

        // Should start with SQLite magic header
        let header = String(data: decompressed.prefix(16), encoding: .utf8)
        XCTAssertTrue(header?.starts(with: "SQLite format 3") == true,
                      "Decompressed data should be valid SQLite")
    }

    // MARK: - SQLiteService Database Path Tests

    func test_databasePath_findsQuranSqlite() {
        let path = SQLiteService.shared.databasePath(for: "quran")
        XCTAssertNotNil(path, "Should find quran.sqlite in bundle")
    }

    func test_databasePath_findsHadithGzipped() {
        // hadith.sqlite.gz should be in bundle, decompresses to Application Support
        let path = SQLiteService.shared.databasePath(for: "hadith")
        XCTAssertNotNil(path, "Should find hadith database (decompressed from .gz)")

        if let path = path {
            XCTAssertTrue(path.lastPathComponent == "hadith.sqlite")
            XCTAssertTrue(FileManager.default.fileExists(atPath: path.path))
        }
    }

    func test_databasePath_returnsNil_forNonexistent() {
        let path = SQLiteService.shared.databasePath(for: "nonexistent_db")
        XCTAssertNil(path)
    }

    func test_hadithDecompressed_isValidSqlite() throws {
        guard let path = SQLiteService.shared.databasePath(for: "hadith") else {
            XCTFail("Hadith database not found")
            return
        }

        // Verify it's a valid SQLite file by checking magic bytes
        let data = try Data(contentsOf: path, options: .mappedIfSafe)
        let header = String(data: data.prefix(16), encoding: .utf8)
        XCTAssertTrue(header?.starts(with: "SQLite format 3") == true,
                      "Decompressed file should be valid SQLite")
    }
}
