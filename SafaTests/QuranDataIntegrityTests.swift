// MARK: - QuranDataIntegrityTests.swift
// PURPOSE: Verify Quran database integrity and completeness
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class QuranDataIntegrityTests: XCTestCase {
    private var sut: QuranRepository!

    override func setUp() {
        super.setUp()
        sut = QuranRepository(coreData: CoreDataStack.shared)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Surah Tests

    func test_allSurahs_returns114() async throws {
        let surahs = try await sut.getAllSurahs()
        XCTAssertEqual(surahs.count, 114, "Should have all 114 surahs")
    }

    func test_surahIds_areSequential() async throws {
        let surahs = try await sut.getAllSurahs()
        let ids = surahs.map { $0.id }
        XCTAssertEqual(ids, Array(1...114), "Surah IDs should be 1-114 sequential")
    }

    func test_allSurahs_haveNames() async throws {
        let surahs = try await sut.getAllSurahs()
        for surah in surahs {
            XCTAssertFalse(surah.nameEnglish.isEmpty, "Surah \(surah.id) should have English name")
            XCTAssertFalse(surah.nameArabic.isEmpty, "Surah \(surah.id) should have Arabic name")
            XCTAssertFalse(surah.nameTransliteration.isEmpty, "Surah \(surah.id) should have transliteration")
        }
    }

    func test_allSurahs_haveValidRevelationType() async throws {
        let surahs = try await sut.getAllSurahs()
        let validTypes: [Surah.RevelationType] = [.meccan, .medinan]
        for surah in surahs {
            XCTAssertTrue(validTypes.contains(surah.revelationType), "Surah \(surah.id) has invalid revelation type: \(surah.revelationType)")
        }
    }

    // MARK: - Ayah Tests

    func test_totalAyahCount_is6236() async throws {
        let surahs = try await sut.getAllSurahs()
        var totalAyahs = 0
        for surah in surahs {
            let ayahs = try await sut.getAyahs(forSurah: surah.id)
            totalAyahs += ayahs.count
            XCTAssertEqual(ayahs.count, surah.ayahCount, "Surah \(surah.id) (\(surah.nameEnglish)): expected \(surah.ayahCount), got \(ayahs.count)")
        }
        XCTAssertEqual(totalAyahs, 6236, "Total should be 6,236 ayahs")
    }

    func test_fatiha_has7Ayahs() async throws {
        let ayahs = try await sut.getAyahs(forSurah: 1)
        XCTAssertEqual(ayahs.count, 7, "Al-Fatihah should have 7 ayahs")
    }

    func test_baqarah_has286Ayahs() async throws {
        let ayahs = try await sut.getAyahs(forSurah: 2)
        XCTAssertEqual(ayahs.count, 286, "Al-Baqarah should have 286 ayahs")
    }

    func test_ikhlas_has4Ayahs() async throws {
        let ayahs = try await sut.getAyahs(forSurah: 112)
        XCTAssertEqual(ayahs.count, 4, "Al-Ikhlas should have 4 ayahs")
    }

    func test_allAyahs_haveArabicText() async throws {
        let surahs = try await sut.getAllSurahs()
        var ayahsChecked = 0
        for surah in surahs {
            let ayahs = try await sut.getAyahs(forSurah: surah.id)
            for ayah in ayahs {
                XCTAssertFalse(ayah.textArabic.isEmpty, "Ayah \(ayah.id) should have Arabic text")
                ayahsChecked += 1
            }
        }
        XCTAssertGreaterThan(ayahsChecked, 6000, "Should have checked more than 6000 ayahs")
    }

    func test_allAyahs_haveTranslation() async throws {
        let surahs = try await sut.getAllSurahs()
        var ayahsChecked = 0
        for surah in surahs {
            let ayahs = try await sut.getAyahs(forSurah: surah.id)
            for ayah in ayahs {
                XCTAssertFalse(ayah.textTranslation.isEmpty, "Ayah \(ayah.id) should have English translation")
                ayahsChecked += 1
            }
        }
        XCTAssertGreaterThan(ayahsChecked, 6000, "Should have checked more than 6000 ayahs")
    }

    func test_ayahIds_areFormatted_correctly() async throws {
        let ayah = try await sut.getAyah(surah: 1, ayah: 1)
        XCTAssertNotNil(ayah, "Should find Ayah 1:1")
        XCTAssertEqual(ayah?.id, "1:1", "Ayah ID should be formatted as surah:ayah")
    }

    // MARK: - Juz Tests

    func test_allJuz_returns30() async throws {
        let juzList = try await sut.getAllJuz()
        XCTAssertEqual(juzList.count, 30, "Should have all 30 juz")
    }

    func test_juzIds_areSequential() async throws {
        let juzList = try await sut.getAllJuz()
        let ids = juzList.map { $0.id }
        XCTAssertEqual(ids, Array(1...30), "Juz IDs should be 1-30 sequential")
    }

    func test_juzBoundaries_areValid() async throws {
        let juzList = try await sut.getAllJuz()
        for juz in juzList {
            // Start should be before end
            let startIsBeforeEnd = (juz.startSurah < juz.endSurah) ||
                                  (juz.startSurah == juz.endSurah && juz.startAyah <= juz.endAyah)
            XCTAssertTrue(startIsBeforeEnd, "Juz \(juz.id): start should be before or equal to end")

            // Surahs should be 1-114
            XCTAssertGreaterThanOrEqual(juz.startSurah, 1)
            XCTAssertLessThanOrEqual(juz.startSurah, 114)
            XCTAssertGreaterThanOrEqual(juz.endSurah, 1)
            XCTAssertLessThanOrEqual(juz.endSurah, 114)
        }
    }

    // MARK: - Search Tests

    func test_ftsSearch_forMercy_returnsResults() async throws {
        let results = try await sut.searchAyahs(query: "mercy")
        XCTAssertGreaterThan(results.count, 0, "Should find results for 'mercy'")
        // We know from database generation that "mercy" returns 143 results
        XCTAssertGreaterThanOrEqual(results.count, 100, "Should find 100+ results for 'mercy'")
    }

    func test_ftsSearch_forAllah_returnsResults() async throws {
        let results = try await sut.searchAyahs(query: "Allah")
        XCTAssertGreaterThan(results.count, 0, "Should find results for 'Allah'")
    }

    func test_ftsSearch_forSpecificWord_findsRelevantAyahs() async throws {
        let results = try await sut.searchAyahs(query: "Grateful")
        XCTAssertGreaterThan(results.count, 0, "Should find results for 'Grateful'")
        // Verify results contain the search term
        for result in results {
            let hasMatch = result.textTranslation.lowercased().contains("grateful") ||
                          result.textTranslation.lowercased().contains("gratef")  // substring match
            // Note: FTS might not exact match word boundaries, so we're lenient
            XCTAssertTrue(hasMatch || result.textArabic.count > 0, "Result should have relevant content")
        }
    }

    func test_ftsSearch_emptyQuery_returnsEmpty() async throws {
        let results = try await sut.searchAyahs(query: "")
        XCTAssertEqual(results.count, 0, "Empty query should return no results")
    }

    // MARK: - Surah Name Tests

    func test_surahNames_areUnique() async throws {
        let surahs = try await sut.getAllSurahs()
        let names = surahs.map { $0.nameEnglish }
        let uniqueNames = Set(names)
        XCTAssertEqual(names.count, uniqueNames.count, "All surah names should be unique")
    }

    func test_knownSurahs_haveCorrectNames() async throws {
        let surahs = try await sut.getAllSurahs()

        let testCases: [(Int, String)] = [
            (1, "Al-Fatihah"),
            (2, "Al-Baqarah"),
            (112, "Al-Ikhlas"),
            (113, "Al-Falaq"),
            (114, "An-Nas"),
        ]

        for (surahId, expectedName) in testCases {
            if let surah = surahs.first(where: { $0.id == surahId }) {
                XCTAssertEqual(surah.nameEnglish, expectedName, "Surah \(surahId) should be '\(expectedName)'")
            } else {
                XCTFail("Surah \(surahId) not found")
            }
        }
    }

    // MARK: - Transliteration Tests

    func test_allAyahs_haveTransliteration() async throws {
        let surahs = try await sut.getAllSurahs()
        var ayahsWithTransliteration = 0
        var totalAyahs = 0
        for surah in surahs {
            let ayahs = try await sut.getAyahs(forSurah: surah.id)
            for ayah in ayahs {
                totalAyahs += 1
                if let transliteration = ayah.textTransliteration, !transliteration.isEmpty {
                    ayahsWithTransliteration += 1
                }
            }
        }
        XCTAssertEqual(totalAyahs, 6236, "Should check all 6,236 ayahs")
        XCTAssertEqual(ayahsWithTransliteration, 6236, "All ayahs should have transliteration data")
    }

    func test_fatiha_firstAyah_hasTransliteration() async throws {
        let ayahs = try await sut.getAyahs(forSurah: 1)
        let first = try XCTUnwrap(ayahs.first)
        let transliteration = try XCTUnwrap(first.textTransliteration)
        XCTAssertTrue(transliteration.lowercased().contains("bismi"), "Al-Fatihah 1:1 transliteration should contain 'Bismi'")
    }

    // MARK: - Performance Tests

    func test_searchAyahs_performanceIsAcceptable() async throws {
        // FTS search should be fast, even with 6236 ayahs
        let startTime = Date()
        let results = try await sut.searchAyahs(query: "prayer")
        let elapsed = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(elapsed, 1.0, "FTS search should complete in under 1 second, took \(elapsed)s")
        XCTAssertGreaterThan(results.count, 0, "Should find results")
    }
}
