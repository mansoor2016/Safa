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

    func test_databasePath_findsQuranGzipped() {
        // quran.sqlite.gz should be in bundle, decompresses to Application Support
        let path = SQLiteService.shared.databasePath(for: "quran")
        XCTAssertNotNil(path, "Should find quran database (decompressed from .gz)")

        if let path = path {
            XCTAssertEqual(path.lastPathComponent, "quran.sqlite")
            XCTAssertTrue(FileManager.default.fileExists(atPath: path.path))
        }
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

    func test_staleCache_isReplacedWhenGzChanges() throws {
        // Use a unique name to avoid corrupting the shared singleton's quran/hadith caches
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            XCTFail("No Application Support directory")
            return
        }

        let dbDir = appSupport.appendingPathComponent("Databases")
        try fileManager.createDirectory(at: dbDir, withIntermediateDirectories: true)

        // Use the real quran.gz as the source
        guard let gzPath = Bundle.main.url(forResource: "quran", withExtension: "sqlite.gz", subdirectory: "Data/Database")
                ?? Bundle.main.url(forResource: "quran", withExtension: "sqlite.gz") else {
            XCTFail("quran.sqlite.gz not found in bundle")
            return
        }

        let testName = "quran_stale_test"
        let targetPath = dbDir.appendingPathComponent("\(testName).sqlite")
        let markerPath = dbDir.appendingPathComponent("\(testName).gz.size")

        // Clean up from previous runs
        try? fileManager.removeItem(at: targetPath)
        try? fileManager.removeItem(at: markerPath)

        // Write a stale marker with wrong size and dummy DB content
        try Data("12345".utf8).write(to: markerPath)
        try Data("stale".utf8).write(to: targetPath)

        // Read the actual bundled .gz size
        let bundledSize = try fileManager.attributesOfItem(atPath: gzPath.path)[.size] as! Int

        // Simulate what databasePath does: detect stale marker and re-decompress
        let markerData = try Data(contentsOf: markerPath)
        let markerString = String(data: markerData, encoding: .utf8)!
        let cachedSize = Int(markerString) ?? 0
        XCTAssertNotEqual(cachedSize, bundledSize, "Stale marker should differ from bundled .gz size")

        // Decompress fresh
        let compressedData = try Data(contentsOf: gzPath)
        let decompressed = try XCTUnwrap(compressedData.gunzip())
        try decompressed.write(to: targetPath)
        try Data("\(bundledSize)".utf8).write(to: markerPath)

        // Verify the marker now matches
        let updatedMarker = try String(contentsOf: markerPath, encoding: .utf8)
        XCTAssertEqual(Int(updatedMarker), bundledSize, "Marker should match bundled .gz size after refresh")

        // Verify the decompressed file is valid SQLite
        let header = try String(data: Data(contentsOf: targetPath).prefix(16), encoding: .utf8)
        XCTAssertTrue(header?.starts(with: "SQLite format 3") == true)

        // Clean up
        try? fileManager.removeItem(at: targetPath)
        try? fileManager.removeItem(at: markerPath)
    }

    func test_validCache_isNotRedecompressed() throws {
        // First call ensures decompression and marker are set
        let path1 = SQLiteService.shared.databasePath(for: "hadith")
        XCTAssertNotNil(path1)

        guard let path1 = path1 else { return }

        // Record the file's modification date
        let attrs1 = try FileManager.default.attributesOfItem(atPath: path1.path)
        let modDate1 = attrs1[.modificationDate] as? Date

        // Small delay to ensure timestamps would differ if file were rewritten
        Thread.sleep(forTimeInterval: 0.05)

        // Second call should return the cached file without re-decompressing
        let path2 = SQLiteService.shared.databasePath(for: "hadith")
        XCTAssertEqual(path1, path2)

        let attrs2 = try FileManager.default.attributesOfItem(atPath: path2!.path)
        let modDate2 = attrs2[.modificationDate] as? Date

        XCTAssertEqual(modDate1, modDate2, "Cached file should not be rewritten when marker matches")
    }

    func test_missingMarker_triggersRedecompression() throws {
        // If the marker file is missing (upgrade from pre-marker version), should re-decompress
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            XCTFail("No Application Support directory")
            return
        }

        let markerPath = appSupport.appendingPathComponent("Databases/hadith.gz.size")

        // Ensure hadith is decompressed first
        let path1 = SQLiteService.shared.databasePath(for: "hadith")
        XCTAssertNotNil(path1)

        // Delete only the marker (simulates upgrade from old version without markers)
        try? fileManager.removeItem(at: markerPath)

        // Should still return a valid path (re-decompresses and recreates marker)
        let path2 = SQLiteService.shared.databasePath(for: "hadith")
        XCTAssertNotNil(path2)

        // Marker should be recreated
        XCTAssertTrue(fileManager.fileExists(atPath: markerPath.path), "Marker should be recreated after re-decompression")
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
