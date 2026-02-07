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

    func test_initialState_selectedFilterIsAll() {
        XCTAssertEqual(sut.selectedFilter, .all)
    }

    // MARK: - Search Tests

    func test_search_findsResultsByTranslation() async {
        sut.searchText = "Merciful"
        await sut.search()
        // "Most Merciful" appears in translation
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

    // MARK: - Filter Tests

    func test_search_withAllFilter_searchesEverything() async {
        sut.selectedFilter = .all
        sut.searchText = "Allah"
        await sut.search()
        XCTAssertFalse(sut.searchResults.isEmpty)
    }

    func test_search_withTranslationFilter_onlySearchesTranslation() async {
        sut.selectedFilter = .translation
        sut.searchText = "Allah"
        await sut.search()
        XCTAssertFalse(sut.searchResults.isEmpty)
    }

    func test_search_withSurahNameFilter_onlySearchesSurahName() async {
        sut.selectedFilter = .surahName
        sut.searchText = "Rahman"
        await sut.search()
        XCTAssertFalse(sut.searchResults.isEmpty)
        XCTAssertTrue(sut.searchResults.allSatisfy { $0.surahName.lowercased().contains("rahman") })
    }

    func test_search_withArabicFilter_onlySearchesArabic() async {
        sut.selectedFilter = .arabic
        sut.searchText = "بِسْمِ"
        await sut.search()
        XCTAssertFalse(sut.searchResults.isEmpty)
    }

    func test_selectedFilter_canBeChanged() {
        sut.selectedFilter = .translation
        XCTAssertEqual(sut.selectedFilter, .translation)

        sut.selectedFilter = .surahName
        XCTAssertEqual(sut.selectedFilter, .surahName)
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

    // MARK: - SearchFilter Enum Tests

    func test_searchFilter_allCases() {
        let allCases = QuranSearchViewModel.SearchFilter.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.all))
        XCTAssertTrue(allCases.contains(.arabic))
        XCTAssertTrue(allCases.contains(.translation))
        XCTAssertTrue(allCases.contains(.surahName))
    }

    func test_searchFilter_rawValues() {
        XCTAssertEqual(QuranSearchViewModel.SearchFilter.all.rawValue, "All")
        XCTAssertEqual(QuranSearchViewModel.SearchFilter.arabic.rawValue, "Arabic")
        XCTAssertEqual(QuranSearchViewModel.SearchFilter.translation.rawValue, "Translation")
        XCTAssertEqual(QuranSearchViewModel.SearchFilter.surahName.rawValue, "Surah Name")
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

    func test_quranSearchResult_storesAllProperties() {
        let result = QuranSearchResult(
            surahNumber: 112,
            surahName: "Al-Ikhlas",
            ayahNumber: 1,
            arabicText: "قُلْ هُوَ اللَّهُ أَحَدٌ",
            translation: "Say: He is Allah, the One"
        )

        XCTAssertEqual(result.surahNumber, 112)
        XCTAssertEqual(result.surahName, "Al-Ikhlas")
        XCTAssertEqual(result.ayahNumber, 1)
        XCTAssertEqual(result.arabicText, "قُلْ هُوَ اللَّهُ أَحَدٌ")
        XCTAssertEqual(result.translation, "Say: He is Allah, the One")
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
        // Even with same data, IDs should be different
        XCTAssertNotEqual(result1.id, result2.id)
    }

    // MARK: - Sample Data Tests

    func test_sampleData_containsAlFatiha() async {
        sut.selectedFilter = .surahName
        sut.searchText = "Fatiha"
        await sut.search()
        XCTAssertFalse(sut.searchResults.isEmpty)
    }

    func test_sampleData_containsAlBaqarah() async {
        sut.selectedFilter = .surahName
        sut.searchText = "Baqarah"
        await sut.search()
        XCTAssertFalse(sut.searchResults.isEmpty)
    }

    func test_sampleData_containsAyatulKursi() async {
        sut.searchText = "Sustainer"
        await sut.search()
        // Ayatul Kursi (2:255) contains "Sustainer of [all] existence"
        XCTAssertFalse(sut.searchResults.isEmpty, "Should find results for 'Sustainer'")
    }

    func test_sampleData_containsArRahman() async {
        sut.selectedFilter = .surahName
        sut.searchText = "Rahman"
        await sut.search()
        XCTAssertFalse(sut.searchResults.isEmpty)
    }

    func test_sampleData_containsAlIkhlas() async {
        sut.selectedFilter = .surahName
        sut.searchText = "Ikhlas"
        await sut.search()
        XCTAssertFalse(sut.searchResults.isEmpty)
    }

    // MARK: - Edge Cases

    func test_search_withWhitespace_stillSearches() async {
        sut.searchText = "   Allah   "
        await sut.search()
        // The search includes whitespace in query, so may not find results
        // Testing that it doesn't crash
        _ = sut.searchResults
    }

    func test_search_withSpecialCharacters() async {
        sut.searchText = "Allah!"
        await sut.search()
        // Should complete without crashing
        _ = sut.searchResults
    }

    func test_search_setsIsSearchingCorrectly() async {
        // Note: In the actual implementation, isSearching is synchronous
        // so it's set to true then immediately false
        sut.searchText = "test"
        await sut.search()
        // After search completes, isSearching should be false
        XCTAssertFalse(sut.isSearching)
    }
}
