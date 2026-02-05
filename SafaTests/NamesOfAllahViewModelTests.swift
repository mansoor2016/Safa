// MARK: - NamesOfAllahViewModelTests.swift
// PURPOSE: Unit tests for NamesOfAllahViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class NamesOfAllahViewModelTests: XCTestCase {

    var sut: NamesOfAllahViewModel!

    override func setUp() {
        super.setUp()
        sut = NamesOfAllahViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_loadsAllNames() {
        XCTAssertEqual(sut.names.count, 99)
    }

    func test_initialState_searchTextIsEmpty() {
        XCTAssertTrue(sut.searchText.isEmpty)
    }

    func test_initialState_selectedNameIsNil() {
        XCTAssertNil(sut.selectedName)
    }

    func test_initialState_filteredNamesEqualsAllNames() {
        XCTAssertEqual(sut.filteredNames.count, sut.names.count)
    }

    // MARK: - Names Data Tests

    func test_names_containsArRahman() {
        let arRahman = sut.names.first { $0.id == 1 }
        XCTAssertNotNil(arRahman)
        XCTAssertEqual(arRahman?.transliteration, "Ar-Rahman")
        XCTAssertEqual(arRahman?.meaning, "The Most Gracious")
    }

    func test_names_containsArRaheem() {
        let arRaheem = sut.names.first { $0.id == 2 }
        XCTAssertNotNil(arRaheem)
        XCTAssertEqual(arRaheem?.transliteration, "Ar-Raheem")
        XCTAssertEqual(arRaheem?.meaning, "The Most Merciful")
    }

    func test_names_containsAlMalik() {
        let alMalik = sut.names.first { $0.id == 3 }
        XCTAssertNotNil(alMalik)
        XCTAssertEqual(alMalik?.transliteration, "Al-Malik")
    }

    func test_names_allHaveArabicText() {
        for name in sut.names {
            XCTAssertFalse(name.arabic.isEmpty, "Name \(name.id) should have Arabic text")
        }
    }

    func test_names_allHaveTransliteration() {
        for name in sut.names {
            XCTAssertFalse(name.transliteration.isEmpty, "Name \(name.id) should have transliteration")
        }
    }

    func test_names_allHaveMeaning() {
        for name in sut.names {
            XCTAssertFalse(name.meaning.isEmpty, "Name \(name.id) should have meaning")
        }
    }

    func test_names_allHaveExplanation() {
        for name in sut.names {
            XCTAssertFalse(name.explanation.isEmpty, "Name \(name.id) should have explanation")
        }
    }

    func test_names_idsAreSequential() {
        let ids = sut.names.map { $0.id }.sorted()
        for i in 0..<ids.count {
            XCTAssertEqual(ids[i], i + 1, "ID at index \(i) should be \(i + 1)")
        }
    }

    // MARK: - Search Filter Tests

    func test_filteredNames_returnsAllWhenSearchEmpty() {
        sut.searchText = ""
        XCTAssertEqual(sut.filteredNames.count, 99)
    }

    func test_filteredNames_filtersByTransliteration() {
        sut.searchText = "Rahman"
        let results = sut.filteredNames
        XCTAssertTrue(results.contains { $0.transliteration == "Ar-Rahman" })
    }

    func test_filteredNames_filtersByMeaning() {
        sut.searchText = "Merciful"
        let results = sut.filteredNames
        XCTAssertTrue(results.contains { $0.meaning.contains("Merciful") })
    }

    func test_filteredNames_filtersByArabic() {
        sut.searchText = "الرَّحْمَنُ"
        let results = sut.filteredNames
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.arabic == "الرَّحْمَنُ" })
    }

    func test_filteredNames_isCaseInsensitive() {
        sut.searchText = "RAHMAN"
        let upperResults = sut.filteredNames

        sut.searchText = "rahman"
        let lowerResults = sut.filteredNames

        XCTAssertEqual(upperResults.count, lowerResults.count)
    }

    func test_filteredNames_returnsEmptyForNoMatch() {
        sut.searchText = "xyz123nonexistent"
        XCTAssertTrue(sut.filteredNames.isEmpty)
    }

    func test_filteredNames_returnsMultipleMatches() {
        sut.searchText = "Al-"
        let results = sut.filteredNames
        XCTAssertGreaterThan(results.count, 1)
    }

    func test_filteredNames_searchesPartialMatch() {
        sut.searchText = "King"
        let results = sut.filteredNames
        XCTAssertTrue(results.contains { $0.meaning.contains("King") })
    }

    // MARK: - Selected Name Tests

    func test_selectedName_canBeSet() {
        let name = sut.names.first!
        sut.selectedName = name
        XCTAssertEqual(sut.selectedName?.id, name.id)
    }

    func test_selectedName_canBeCleared() {
        sut.selectedName = sut.names.first
        XCTAssertNotNil(sut.selectedName)

        sut.selectedName = nil
        XCTAssertNil(sut.selectedName)
    }

    // MARK: - NameOfAllah Model Tests

    func test_nameOfAllah_identifiable() {
        let name = NameOfAllah(id: 1, arabic: "Test", transliteration: "Test", meaning: "Test", explanation: "Test")
        XCTAssertEqual(name.id, 1)
    }

    func test_nameOfAllah_hashable() {
        let name1 = NameOfAllah(id: 1, arabic: "A", transliteration: "A", meaning: "A", explanation: "A")
        let name2 = NameOfAllah(id: 1, arabic: "A", transliteration: "A", meaning: "A", explanation: "A")
        XCTAssertEqual(name1.hashValue, name2.hashValue)
    }

    func test_nameOfAllah_codable() throws {
        let name = NameOfAllah(id: 1, arabic: "الرَّحْمَنُ", transliteration: "Ar-Rahman", meaning: "The Most Gracious", explanation: "Test explanation")

        let encoder = JSONEncoder()
        let data = try encoder.encode(name)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(NameOfAllah.self, from: data)

        XCTAssertEqual(decoded.id, name.id)
        XCTAssertEqual(decoded.arabic, name.arabic)
        XCTAssertEqual(decoded.transliteration, name.transliteration)
        XCTAssertEqual(decoded.meaning, name.meaning)
        XCTAssertEqual(decoded.explanation, name.explanation)
    }
}
