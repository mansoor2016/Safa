// MARK: - QuranUITests.swift
// PURPOSE: UI tests for Quran reading flow
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class QuranViewModelTests: XCTestCase {

    var sut: QuranViewModel!

    override func setUp() {
        super.setUp()
        sut = QuranViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func testSelectedSurahInitiallyNil() {
        XCTAssertNil(sut.selectedSurah)
    }

    // MARK: - Search Tests

    func testSearchQueryInitiallyEmpty() {
        XCTAssertTrue(sut.searchQuery.isEmpty)
    }

    func testSearchResults() {
        // Verify search functionality exists
        XCTAssertNotNil(sut.searchResults)
    }
}

// MARK: - Surah List Tests

final class SurahListTests: XCTestCase {

    func testSurahHasRequiredFields() {
        let surah = Surah(
            number: 1,
            nameArabic: "الفاتحة",
            nameEnglish: "Al-Fatiha",
            nameTransliteration: "Al-Fatihah",
            ayahCount: 7,
            revelationType: .meccan
        )

        XCTAssertEqual(surah.number, 1)
        XCTAssertEqual(surah.nameEnglish, "Al-Fatiha")
        XCTAssertEqual(surah.ayahCount, 7)
    }

    func testRevelationTypes() {
        XCTAssertEqual(RevelationType.meccan.rawValue, "meccan")
        XCTAssertEqual(RevelationType.medinan.rawValue, "medinan")
    }

    func testSurahEquality() {
        let surah1 = Surah(number: 1, nameArabic: "الفاتحة", nameEnglish: "Al-Fatiha", nameTransliteration: "Al-Fatihah", ayahCount: 7, revelationType: .meccan)
        let surah2 = Surah(number: 1, nameArabic: "الفاتحة", nameEnglish: "Al-Fatiha", nameTransliteration: "Al-Fatihah", ayahCount: 7, revelationType: .meccan)

        XCTAssertEqual(surah1, surah2)
    }
}

// MARK: - Ayah Tests

final class AyahTests: XCTestCase {

    func testAyahHasRequiredFields() {
        let ayah = Ayah(
            number: 1,
            surahNumber: 1,
            numberInSurah: 1,
            text: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            translation: "In the name of Allah, the Most Gracious, the Most Merciful"
        )

        XCTAssertEqual(ayah.numberInSurah, 1)
        XCTAssertFalse(ayah.text.isEmpty)
        XCTAssertFalse(ayah.translation.isEmpty)
    }

    func testAyahIdentifiable() {
        let ayah = Ayah(
            number: 1,
            surahNumber: 1,
            numberInSurah: 1,
            text: "Test",
            translation: "Test"
        )

        XCTAssertNotNil(ayah.id)
    }
}

// MARK: - Bookmark Tests

final class QuranBookmarkTests: XCTestCase {

    func testBookmarkCreation() {
        let bookmark = QuranBookmark(
            id: UUID(),
            surahNumber: 2,
            ayahNumber: 255,
            note: "Ayatul Kursi",
            createdAt: Date()
        )

        XCTAssertEqual(bookmark.surahNumber, 2)
        XCTAssertEqual(bookmark.ayahNumber, 255)
        XCTAssertEqual(bookmark.note, "Ayatul Kursi")
    }

    func testBookmarkEquality() {
        let id = UUID()
        let bookmark1 = QuranBookmark(id: id, surahNumber: 1, ayahNumber: 1, note: nil, createdAt: Date())
        let bookmark2 = QuranBookmark(id: id, surahNumber: 1, ayahNumber: 1, note: nil, createdAt: Date())

        XCTAssertEqual(bookmark1, bookmark2)
    }
}

// MARK: - Reading Progress Tests

final class ReadingProgressTests: XCTestCase {

    func testReadingProgressCreation() {
        let progress = ReadingProgress(
            lastSurah: 2,
            lastAyah: 100,
            lastReadDate: Date()
        )

        XCTAssertEqual(progress.lastSurah, 2)
        XCTAssertEqual(progress.lastAyah, 100)
    }

    func testReadingProgressCodable() throws {
        let progress = ReadingProgress(lastSurah: 5, lastAyah: 50, lastReadDate: Date())

        let data = try JSONEncoder().encode(progress)
        let decoded = try JSONDecoder().decode(ReadingProgress.self, from: data)

        XCTAssertEqual(decoded.lastSurah, progress.lastSurah)
        XCTAssertEqual(decoded.lastAyah, progress.lastAyah)
    }
}

// MARK: - Quran Search Tests

final class QuranSearchViewModelTests: XCTestCase {

    func testSearchFilters() {
        XCTAssertEqual(QuranSearchViewModel.SearchFilter.all.rawValue, "all")
        XCTAssertEqual(QuranSearchViewModel.SearchFilter.arabic.rawValue, "arabic")
        XCTAssertEqual(QuranSearchViewModel.SearchFilter.translation.rawValue, "translation")
        XCTAssertEqual(QuranSearchViewModel.SearchFilter.surahName.rawValue, "surahName")
    }

    func testAllFiltersCaseIterable() {
        let filters = QuranSearchViewModel.SearchFilter.allCases

        XCTAssertEqual(filters.count, 4)
    }
}
