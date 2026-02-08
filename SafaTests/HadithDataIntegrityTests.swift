// MARK: - HadithDataIntegrityTests.swift
// PURPOSE: Verify hadith database integrity and completeness
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class HadithDataIntegrityTests: XCTestCase {

    private var sut: HadithRepository!

    override func setUp() {
        super.setUp()
        sut = HadithRepository(coreData: CoreDataStack.shared)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Collection Tests

    func test_allCollections_returns6() async throws {
        let collections = try await sut.getCollections()
        XCTAssertEqual(collections.count, 6, "Should have 6 Kutub al-Sittah collections")
    }

    func test_collectionIds_areCorrect() async throws {
        let collections = try await sut.getCollections()
        let ids = Set(collections.map { $0.id })
        XCTAssertTrue(ids.contains("bukhari"))
        XCTAssertTrue(ids.contains("muslim"))
        XCTAssertTrue(ids.contains("abudawud"))
        XCTAssertTrue(ids.contains("tirmidhi"))
        XCTAssertTrue(ids.contains("nasai"))
        XCTAssertTrue(ids.contains("ibnmajah"))
    }

    func test_allCollections_haveNames() async throws {
        let collections = try await sut.getCollections()
        for collection in collections {
            XCTAssertFalse(collection.nameEnglish.isEmpty, "\(collection.id) should have English name")
            XCTAssertFalse(collection.nameArabic.isEmpty, "\(collection.id) should have Arabic name")
            XCTAssertFalse(collection.compilerName.isEmpty, "\(collection.id) should have compiler name")
        }
    }

    func test_allCollections_havePositiveCounts() async throws {
        let collections = try await sut.getCollections()
        for collection in collections {
            XCTAssertGreaterThan(collection.totalHadiths, 0, "\(collection.id) should have hadiths")
            XCTAssertGreaterThan(collection.totalBooks, 0, "\(collection.id) should have books")
        }
    }

    // MARK: - Hadith Count Tests

    func test_bukhari_hasExpectedHadithCount() async throws {
        let books = try await sut.getBooks(forCollection: "bukhari")
        var total = 0
        for book in books {
            let hadiths = try await sut.getHadiths(collection: "bukhari", book: book.id)
            total += hadiths.count
        }
        XCTAssertGreaterThanOrEqual(total, 7000, "Bukhari should have 7000+ hadiths, got \(total)")
    }

    func test_muslim_hasExpectedHadithCount() async throws {
        let books = try await sut.getBooks(forCollection: "muslim")
        var total = 0
        for book in books {
            let hadiths = try await sut.getHadiths(collection: "muslim", book: book.id)
            total += hadiths.count
        }
        XCTAssertGreaterThanOrEqual(total, 7000, "Muslim should have 7000+ hadiths, got \(total)")
    }

    // MARK: - Book Tests

    func test_bukhari_has97Books() async throws {
        let books = try await sut.getBooks(forCollection: "bukhari")
        XCTAssertEqual(books.count, 97, "Bukhari should have 97 books")
    }

    func test_allCollections_haveBooks() async throws {
        let collections = try await sut.getCollections()
        for collection in collections {
            let books = try await sut.getBooks(forCollection: collection.id)
            XCTAssertGreaterThan(books.count, 0, "\(collection.id) should have books, got 0")
        }
    }

    func test_books_haveNames() async throws {
        let books = try await sut.getBooks(forCollection: "bukhari")
        for book in books.prefix(10) {
            XCTAssertFalse(book.nameEnglish.isEmpty, "Book \(book.id) should have English name")
        }
    }

    // MARK: - Hadith Content Tests

    func test_hadiths_haveArabicText() async throws {
        let books = try await sut.getBooks(forCollection: "bukhari")
        guard let firstBook = books.first else { XCTFail("No books"); return }
        let hadiths = try await sut.getHadiths(collection: "bukhari", book: firstBook.id)
        for hadith in hadiths.prefix(5) {
            XCTAssertFalse(hadith.textArabic.isEmpty, "Hadith \(hadith.id) should have Arabic text")
        }
    }

    func test_hadiths_haveEnglishText() async throws {
        let books = try await sut.getBooks(forCollection: "bukhari")
        guard let firstBook = books.first else { XCTFail("No books"); return }
        let hadiths = try await sut.getHadiths(collection: "bukhari", book: firstBook.id)
        for hadith in hadiths.prefix(5) {
            XCTAssertFalse(hadith.textEnglish.isEmpty, "Hadith \(hadith.id) should have English text")
        }
    }

    func test_hadiths_haveNarrators() async throws {
        let books = try await sut.getBooks(forCollection: "bukhari")
        guard let firstBook = books.first else { XCTFail("No books"); return }
        let hadiths = try await sut.getHadiths(collection: "bukhari", book: firstBook.id)
        for hadith in hadiths.prefix(5) {
            XCTAssertFalse(hadith.narrator.isEmpty, "Hadith \(hadith.id) should have narrator")
        }
    }

    // MARK: - Search Tests

    func test_ftsSearch_forPrayer_returnsResults() async throws {
        let results = try await sut.searchHadiths(query: "prayer")
        XCTAssertGreaterThan(results.count, 0, "Should find results for 'prayer'")
    }

    func test_ftsSearch_forFasting_returnsResults() async throws {
        let results = try await sut.searchHadiths(query: "fasting")
        XCTAssertGreaterThan(results.count, 0, "Should find results for 'fasting'")
    }

    func test_ftsSearch_emptyQuery_returnsEmpty() async throws {
        let results = try await sut.searchHadiths(query: "")
        XCTAssertEqual(results.count, 0, "Empty query should return no results")
    }

    // MARK: - Daily Hadith Tests

    func test_dailyHadith_returnsNonEmpty() async throws {
        let hadith = try await sut.getDailyHadith(for: Date())
        XCTAssertFalse(hadith.textEnglish.isEmpty)
        XCTAssertFalse(hadith.textArabic.isEmpty)
    }

    func test_dailyHadith_isDeterministic() async throws {
        let date = Date()
        let hadith1 = try await sut.getDailyHadith(for: date)
        let hadith2 = try await sut.getDailyHadith(for: date)
        XCTAssertEqual(hadith1.id, hadith2.id, "Same date should return same hadith")
    }

    // MARK: - Bukhari Hadith 1 (Most Famous Hadith)

    func test_bukhari_hadith1_actionsByIntentions() async throws {
        let books = try await sut.getBooks(forCollection: "bukhari")
        guard let firstBook = books.first else { XCTFail("No books"); return }
        let hadiths = try await sut.getHadiths(collection: "bukhari", book: firstBook.id)
        guard let first = hadiths.first else { XCTFail("No hadiths"); return }
        XCTAssertTrue(
            first.textEnglish.lowercased().contains("intention") || first.textEnglish.lowercased().contains("deeds"),
            "First hadith should mention intentions/deeds. Got: \(first.textEnglish.prefix(100))"
        )
    }
}
