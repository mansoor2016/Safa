// MARK: - DatabasePerformanceTests.swift
// PURPOSE: Verify database query performance stays within budgets
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class DatabasePerformanceTests: XCTestCase {

    // MARK: - Quran Query Performance

    func test_quranGetAllSurahs_under50ms() async throws {
        let repo = QuranRepository(coreData: CoreDataStack.shared)
        let start = CFAbsoluteTimeGetCurrent()
        let surahs = try await repo.getAllSurahs()
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertFalse(surahs.isEmpty)
        XCTAssertLessThan(elapsed, 0.01, "getAllSurahs should complete in < 10ms, took \(elapsed * 1000)ms")
    }

    func test_quranGetAyahs_under50ms() async throws {
        let repo = QuranRepository(coreData: CoreDataStack.shared)
        let start = CFAbsoluteTimeGetCurrent()
        let ayahs = try await repo.getAyahs(forSurah: 2) // Al-Baqarah (286 ayahs — largest)
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertEqual(ayahs.count, 286)
        XCTAssertLessThan(elapsed, 0.02, "getAyahs(surah 2) should complete in < 20ms, took \(elapsed * 1000)ms")
    }

    func test_quranFTSSearch_under500ms() async throws {
        let repo = QuranRepository(coreData: CoreDataStack.shared)
        let start = CFAbsoluteTimeGetCurrent()
        let results = try await repo.searchAyahs(query: "mercy")
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertGreaterThan(results.count, 0)
        XCTAssertLessThan(elapsed, 0.1, "FTS search should complete in < 100ms, took \(elapsed * 1000)ms")
    }

    func test_quranGetSingleAyah_under50ms() async throws {
        let repo = QuranRepository(coreData: CoreDataStack.shared)
        let start = CFAbsoluteTimeGetCurrent()
        let ayah = try await repo.getAyah(surah: 2, ayah: 255) // Ayat al-Kursi
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertNotNil(ayah)
        XCTAssertLessThan(elapsed, 0.01, "getSingleAyah should complete in < 10ms, took \(elapsed * 1000)ms")
    }

    // MARK: - Hadith Query Performance

    func test_hadithGetAllCollections_under50ms() async throws {
        let repo = HadithRepository(coreData: CoreDataStack.shared)
        let start = CFAbsoluteTimeGetCurrent()
        let collections = try await repo.getCollections()
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertEqual(collections.count, 6)
        XCTAssertLessThan(elapsed, 0.01, "getCollections should complete in < 10ms, took \(elapsed * 1000)ms")
    }

    func test_hadithGetBooks_under50ms() async throws {
        let repo = HadithRepository(coreData: CoreDataStack.shared)
        let start = CFAbsoluteTimeGetCurrent()
        let books = try await repo.getBooks(forCollection: "bukhari")
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertEqual(books.count, 97)
        XCTAssertLessThan(elapsed, 0.02, "getBooks should complete in < 20ms, took \(elapsed * 1000)ms")
    }

    func test_hadithFTSSearch_under500ms() async throws {
        let repo = HadithRepository(coreData: CoreDataStack.shared)
        let start = CFAbsoluteTimeGetCurrent()
        let results = try await repo.searchHadiths(query: "prayer")
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertGreaterThan(results.count, 0)
        XCTAssertLessThan(elapsed, 0.1, "Hadith FTS search should complete in < 100ms, took \(elapsed * 1000)ms")
    }

    func test_hadithDailyHadith_under50ms() async throws {
        let repo = HadithRepository(coreData: CoreDataStack.shared)
        let start = CFAbsoluteTimeGetCurrent()
        let hadith = try await repo.getDailyHadith(for: Date())
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertFalse(hadith.textEnglish.isEmpty)
        XCTAssertLessThan(elapsed, 0.01, "getDailyHadith should complete in < 10ms, took \(elapsed * 1000)ms")
    }

    // MARK: - Prayer Time Calculation Performance

    func test_prayerTimeCalculation_under50ms() {
        let calculator = PrayerTimeCalculator()
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)

        let start = CFAbsoluteTimeGetCurrent()
        let prayers = calculator.calculatePrayerTimes(for: Date(), location: london, method: .muslimWorldLeague)
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertEqual(prayers.count, 6)
        XCTAssertLessThan(elapsed, 0.05, "Prayer calculation should complete in < 50ms, took \(elapsed * 1000)ms")
    }

    func test_prayerTimeCalculation_allMethods_under100ms() {
        let calculator = PrayerTimeCalculator()
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)

        let start = CFAbsoluteTimeGetCurrent()
        for method in CalculationMethod.allCases {
            _ = calculator.calculatePrayerTimes(for: Date(), location: london, method: method)
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertLessThan(elapsed, 0.1, "All 12 methods should calculate in < 100ms total, took \(elapsed * 1000)ms")
    }

    // MARK: - Repeated Query Performance (tests connection pooling)

    func test_repeatedQuranQueries_stayFast() async throws {
        let repo = QuranRepository(coreData: CoreDataStack.shared)

        // Warm up
        _ = try await repo.getAllSurahs()

        // Time 10 repeated queries
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<10 {
            _ = try await repo.getAllSurahs()
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let avgMs = (elapsed / 10) * 1000

        XCTAssertLessThan(avgMs, 10, "Repeated queries should average < 10ms each, got \(avgMs)ms")
    }
}
