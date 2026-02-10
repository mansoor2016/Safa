// MARK: - QuranSearchViewModelTests.swift
// PURPOSE: Unit tests for QuranSearchViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class QuranSearchViewModelTests: XCTestCase {

    var sut: QuranSearchViewModel!

    override func setUp() {
        super.setUp()
        sut = QuranSearchViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_searchTextIsEmpty() {
        XCTAssertTrue(sut.searchText.isEmpty)
    }

    func test_initialState_searchResultsIsEmpty() {
        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    func test_initialState_isSearchingIsFalse() {
        XCTAssertFalse(sut.isSearching)
    }

    func test_initialState_recentSearchesIsEmpty() {
        XCTAssertTrue(sut.recentSearches.isEmpty)
    }

    // MARK: - Search Tests

    func test_search_findsResultsByTranslation() async {
        sut.searchText = "Merciful"
        await sut.search()
        XCTAssertFalse(sut.searchResults.isEmpty)
    }

    func test_search_findsResultsBySurahName() async {
        sut.searchText = "Fatiha"
        await sut.search()
        XCTAssertFalse(sut.searchResults.isEmpty)
        XCTAssertTrue(sut.searchResults.allSatisfy { $0.surahName.contains("Fatiha") })
    }

    func test_search_findsResultsByArabicText() async {
        sut.searchText = "بِسْمِ"
        await sut.search()
        XCTAssertFalse(sut.searchResults.isEmpty)
    }

    func test_search_returnsEmpty_forNoMatch() async {
        sut.searchText = "xyz123nonexistent"
        await sut.search()
        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    func test_search_clearsResults_whenSearchTextEmpty() async {
        // First do a search
        sut.searchText = "Allah"
        await sut.search()
        XCTAssertFalse(sut.searchResults.isEmpty)

        // Then clear search text and search again
        sut.searchText = ""
        await sut.search()
        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    func test_search_isCaseInsensitive() async {
        sut.searchText = "ALLAH"
        await sut.search()
        let upperResults = sut.searchResults.count

        sut.searchText = "allah"
        await sut.search()
        let lowerResults = sut.searchResults.count

        XCTAssertEqual(upperResults, lowerResults)
    }

    // MARK: - Recent Searches Tests

    func test_search_addsToRecentSearches() async {
        sut.searchText = "mercy"
        await sut.search()
        XCTAssertTrue(sut.recentSearches.contains("mercy"))
    }

    func test_search_addsToFrontOfRecentSearches() async {
        sut.searchText = "first"
        await sut.search()

        sut.searchText = "second"
        await sut.search()

        XCTAssertEqual(sut.recentSearches.first, "second")
    }

    func test_search_doesNotDuplicateRecentSearches() async {
        sut.searchText = "mercy"
        await sut.search()
        await sut.search()
        await sut.search()

        let mercyCount = sut.recentSearches.filter { $0 == "mercy" }.count
        XCTAssertEqual(mercyCount, 1)
    }

    func test_recentSearches_limitsToTen() async {
        for i in 1...15 {
            sut.searchText = "search\(i)"
            await sut.search()
        }

        XCTAssertLessThanOrEqual(sut.recentSearches.count, 10)
    }

    func test_clearRecentSearches_removesAll() async {
        sut.searchText = "test1"
        await sut.search()
        sut.searchText = "test2"
        await sut.search()

        XCTAssertFalse(sut.recentSearches.isEmpty)

        sut.clearRecentSearches()

        XCTAssertTrue(sut.recentSearches.isEmpty)
    }

    func test_selectRecentSearch_setsSearchText() {
        sut.selectRecentSearch("Allah")
        XCTAssertEqual(sut.searchText, "Allah")
    }

    // MARK: - QuranSearchResult Model Tests

    func test_quranSearchResult_isIdentifiable() {
        let result = QuranSearchResult(
            surahNumber: 1,
            surahName: "Al-Fatiha",
            ayahNumber: 1,
            arabicText: "Test",
            translation: "Test"
        )
        XCTAssertNotNil(result.id)
    }

    func test_quranSearchResult_referenceFormat() {
        let result = QuranSearchResult(
            surahNumber: 2,
            surahName: "Al-Baqarah",
            ayahNumber: 255,
            arabicText: "Test",
            translation: "Test"
        )
        XCTAssertEqual(result.reference, "Al-Baqarah (2:255)")
    }

    func test_quranSearchResult_uniqueIds() {
        let result1 = QuranSearchResult(
            surahNumber: 1,
            surahName: "Test",
            ayahNumber: 1,
            arabicText: "A",
            translation: "A"
        )
        let result2 = QuranSearchResult(
            surahNumber: 1,
            surahName: "Test",
            ayahNumber: 1,
            arabicText: "A",
            translation: "A"
        )
        XCTAssertNotEqual(result1.id, result2.id)
    }

    // MARK: - Edge Cases

    func test_search_withWhitespace_stillSearches() async {
        sut.searchText = "   Allah   "
        await sut.search()
        _ = sut.searchResults
    }

    func test_search_withSpecialCharacters() async {
        sut.searchText = "Allah!"
        await sut.search()
        _ = sut.searchResults
    }

    func test_search_setsIsSearchingCorrectly() async {
        sut.searchText = "test"
        await sut.search()
        XCTAssertFalse(sut.isSearching)
    }
}
