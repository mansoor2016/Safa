// MARK: - HadithViewModelTests.swift
// PURPOSE: Unit tests for HadithViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

@MainActor
final class HadithViewModelTests: XCTestCase {

    var sut: HadithViewModel!
    var mockRepository: TestableHadithRepository!

    override func setUp() {
        super.setUp()
        mockRepository = TestableHadithRepository()
        sut = HadithViewModel(hadithRepository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasEmptyCollections() {
        XCTAssertTrue(sut.collections.isEmpty)
    }

    func test_initialState_hasNoDailyHadith() {
        XCTAssertNil(sut.dailyHadith)
    }

    func test_initialState_isNotLoading() {
        XCTAssertFalse(sut.isLoading)
    }

    func test_initialState_isNotSearching() {
        XCTAssertFalse(sut.isSearching)
    }

    func test_initialState_hasNoError() {
        XCTAssertNil(sut.error)
    }

    func test_initialState_hasEmptySearchQuery() {
        XCTAssertTrue(sut.searchQuery.isEmpty)
    }

    func test_initialState_hasEmptySearchResults() {
        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    // MARK: - Load Collections Tests

    func test_loadCollections_success_populatesCollections() async {
        // Given
        let expectedCollections = [
            HadithCollection(
                id: "bukhari",
                nameEnglish: "Sahih al-Bukhari",
                nameArabic: "صحيح البخاري",
                compilerName: "Imam Bukhari",
                totalHadiths: 7563,
                totalBooks: 97
            )
        ]
        mockRepository.collectionsToReturn = expectedCollections

        // When
        await sut.loadCollections()

        // Then
        XCTAssertEqual(sut.collections.count, 1)
        XCTAssertEqual(sut.collections.first?.id, "bukhari")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func test_loadCollections_failure_setsError() async {
        // Given
        mockRepository.errorToThrow = TestError.testFailure

        // When
        await sut.loadCollections()

        // Then
        XCTAssertTrue(sut.collections.isEmpty)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadCollections_clearsLoadingAfterCompletion() async {
        // Given
        mockRepository.collectionsToReturn = []

        // When
        await sut.loadCollections()

        // Then - should not be loading after completion
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Load Daily Hadith Tests

    func test_loadDailyHadith_success_populatesDailyHadith() async {
        // Given
        let expectedHadith = Hadith(
            id: "daily_1",
            collectionId: "bukhari",
            bookId: "1",
            hadithNumber: 1,
            textArabic: "إنما الأعمال بالنيات",
            textEnglish: "Actions are judged by intentions",
            narrator: "Umar ibn Al-Khattab",
            grading: .sahih,
            reference: "Bukhari 1"
        )
        mockRepository.dailyHadithToReturn = expectedHadith

        // When
        await sut.loadDailyHadith()

        // Then
        XCTAssertNotNil(sut.dailyHadith)
        XCTAssertEqual(sut.dailyHadith?.id, "daily_1")
        XCTAssertEqual(sut.dailyHadith?.textEnglish, "Actions are judged by intentions")
        XCTAssertNil(sut.error)
    }

    func test_loadDailyHadith_failure_setsError() async {
        // Given
        mockRepository.errorToThrow = TestError.networkFailure

        // When
        await sut.loadDailyHadith()

        // Then
        XCTAssertNil(sut.dailyHadith)
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Search Tests

    func test_search_withEmptyQuery_doesNothing() async {
        // Given
        sut.searchQuery = ""

        // When
        await sut.search()

        // Then
        XCTAssertFalse(sut.isSearching)
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    func test_search_withQuery_setsSearchingState() async {
        // Given
        sut.searchQuery = "intentions"
        mockRepository.searchResultsToReturn = []

        // When
        await sut.search()

        // Then - isSearching remains true after search completes
        XCTAssertTrue(sut.isSearching)
        XCTAssertFalse(sut.isLoading)
    }

    func test_search_success_populatesSearchResults() async {
        // Given
        sut.searchQuery = "intentions"
        let expectedResults = [
            Hadith(
                id: "search_1",
                collectionId: "bukhari",
                bookId: "1",
                hadithNumber: 1,
                textArabic: "إنما الأعمال بالنيات",
                textEnglish: "Actions are judged by intentions",
                narrator: "Umar ibn Al-Khattab",
                grading: .sahih,
                reference: "Bukhari 1"
            ),
            Hadith(
                id: "search_2",
                collectionId: "muslim",
                bookId: "2",
                hadithNumber: 42,
                textArabic: "نية المؤمن خير من عمله",
                textEnglish: "The intention of a believer is better than his deed",
                narrator: "Abu Hurairah",
                grading: .hasan,
                reference: "Muslim 42"
            )
        ]
        mockRepository.searchResultsToReturn = expectedResults

        // When
        await sut.search()

        // Then
        XCTAssertEqual(sut.searchResults.count, 2)
        XCTAssertEqual(sut.searchResults.first?.id, "search_1")
        XCTAssertNil(sut.error)
    }

    func test_search_failure_setsError() async {
        // Given
        sut.searchQuery = "test"
        mockRepository.errorToThrow = TestError.networkFailure

        // When
        await sut.search()

        // Then
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Clear Search Tests

    func test_clearSearch_resetsSearchState() {
        // Given
        sut.searchQuery = "test query"
        sut.searchResults = [
            Hadith(
                id: "1",
                collectionId: "bukhari",
                bookId: "1",
                hadithNumber: 1,
                textArabic: "Arabic",
                textEnglish: "English",
                narrator: "Narrator",
                grading: .sahih,
                reference: "Ref"
            )
        ]

        // When
        sut.clearSearch()

        // Then
        XCTAssertTrue(sut.searchQuery.isEmpty)
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertFalse(sut.isSearching)
    }

    // MARK: - Selection Tests

    func test_selectedCollection_canBeSet() {
        // Given
        let collection = HadithCollection(
            id: "bukhari",
            nameEnglish: "Sahih al-Bukhari",
            nameArabic: "صحيح البخاري",
            compilerName: "Imam Bukhari",
            totalHadiths: 7563,
            totalBooks: 97
        )

        // When
        sut.selectedCollection = collection

        // Then
        XCTAssertNotNil(sut.selectedCollection)
        XCTAssertEqual(sut.selectedCollection?.id, "bukhari")
    }

    func test_selectedHadith_canBeSet() {
        // Given
        let hadith = Hadith(
            id: "1",
            collectionId: "bukhari",
            bookId: "1",
            hadithNumber: 1,
            textArabic: "Arabic",
            textEnglish: "English",
            narrator: "Narrator",
            grading: .sahih,
            reference: "Ref"
        )

        // When
        sut.selectedHadith = hadith

        // Then
        XCTAssertNotNil(sut.selectedHadith)
        XCTAssertEqual(sut.selectedHadith?.id, "1")
    }
}

// MARK: - Test Error

private enum TestError: Error {
    case testFailure
    case networkFailure
}

// MARK: - Testable Mock Repository

/// Configurable mock repository for ViewModel testing
@MainActor
final class TestableHadithRepository: HadithRepositoryProtocol {
    var collectionsToReturn: [HadithCollection] = []
    var dailyHadithToReturn: Hadith?
    var searchResultsToReturn: [Hadith] = []
    var errorToThrow: Error?

    private var bookmarkedHadiths: [Hadith] = []

    nonisolated func getCollections() async throws -> [HadithCollection] {
        let error = await errorToThrow
        let collections = await collectionsToReturn
        if let error {
            throw error
        }
        return collections
    }

    nonisolated func getBooks(forCollection collectionId: String) async throws -> [HadithBook] {
        let error = await errorToThrow
        if let error {
            throw error
        }
        return []
    }

    nonisolated func getHadiths(collection collectionId: String, book bookId: String) async throws -> [Hadith] {
        let error = await errorToThrow
        if let error {
            throw error
        }
        return []
    }

    nonisolated func getHadith(collection collectionId: String, number hadithNumber: Int) async throws -> Hadith? {
        let error = await errorToThrow
        if let error {
            throw error
        }
        return nil
    }

    nonisolated func searchHadiths(query: String) async throws -> [Hadith] {
        let error = await errorToThrow
        let results = await searchResultsToReturn
        if let error {
            throw error
        }
        return results
    }

    nonisolated func getDailyHadith(for date: Date) async throws -> Hadith {
        let error = await errorToThrow
        let dailyHadith = await dailyHadithToReturn
        if let error {
            throw error
        }
        guard let hadith = dailyHadith else {
            return Hadith(
                id: "default",
                collectionId: "bukhari",
                bookId: "1",
                hadithNumber: 1,
                textArabic: "Arabic",
                textEnglish: "English",
                narrator: "Narrator",
                grading: .sahih,
                reference: "Ref"
            )
        }
        return hadith
    }

    nonisolated func getBookmarks() async throws -> [Hadith] {
        return await bookmarkedHadiths
    }

    nonisolated func addBookmark(_ hadith: Hadith) async throws {
        await MainActor.run {
            bookmarkedHadiths.append(hadith)
        }
    }

    nonisolated func removeBookmark(_ hadith: Hadith) async throws {
        let hadithId = hadith.id
        await MainActor.run {
            bookmarkedHadiths.removeAll { $0.id == hadithId }
        }
    }

    nonisolated func isBookmarked(_ hadith: Hadith) async throws -> Bool {
        let hadithId = hadith.id
        return await bookmarkedHadiths.contains { $0.id == hadithId }
    }
}
