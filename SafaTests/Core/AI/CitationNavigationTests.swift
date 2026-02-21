// MARK: - CitationNavigationTests.swift
// PURPOSE: Tests for Citation.navigationDestination() routing logic
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class CitationNavigationTests: XCTestCase {

    // MARK: - Quran Citations

    func test_quranCitation_withSurahAndAyah_navigatesToAyah() {
        let citation = Citation(
            source: "Quran",
            reference: "Al-Baqarah 2:255",
            type: .quran,
            surahNumber: 2,
            ayahNumber: 255
        )

        let destination = citation.navigationDestination()
        XCTAssertEqual(destination, .ayah(surah: 2, ayah: 255))
    }

    func test_quranCitation_withSurahOnly_navigatesToSurah() {
        let citation = Citation(
            source: "Quran",
            reference: "Al-Fatiha",
            type: .quran,
            surahNumber: 1
        )

        let destination = citation.navigationDestination()
        XCTAssertEqual(destination, .surah(number: 1))
    }

    func test_quranCitation_withoutSurahNumber_returnsNil() {
        let citation = Citation(
            source: "Quran",
            reference: "Unknown ref",
            type: .quran
        )

        XCTAssertNil(citation.navigationDestination())
    }

    // MARK: - Hadith Citations

    func test_hadithCitation_withCollectionAndNumber_navigatesToHadith() {
        let citation = Citation(
            source: "Sahih Bukhari",
            reference: "Bukhari 1",
            type: .hadith,
            collectionId: "bukhari",
            hadithNumber: 1
        )

        let destination = citation.navigationDestination()
        XCTAssertEqual(destination, .hadith(collection: "bukhari", hadithId: "1"))
    }

    func test_hadithCitation_withCollectionOnly_navigatesToCollection() {
        let citation = Citation(
            source: "Sahih Muslim",
            reference: "Muslim",
            type: .hadith,
            collectionId: "muslim"
        )

        let destination = citation.navigationDestination()
        XCTAssertEqual(destination, .hadith(collection: "muslim", hadithId: nil))
    }

    func test_hadithCitation_withoutCollection_returnsNil() {
        let citation = Citation(
            source: "Hadith",
            reference: "Unknown",
            type: .hadith
        )

        XCTAssertNil(citation.navigationDestination())
    }

    // MARK: - Dua Citations

    func test_duaCitation_alwaysNavigatesToDhikr() {
        let citation = Citation(
            source: "Dua",
            reference: "Morning dua",
            type: .dua,
            duaId: "dua_morning_001"
        )

        let destination = citation.navigationDestination()
        XCTAssertEqual(destination, .dhikr)
    }

    func test_duaCitation_withoutDuaId_stillNavigatesToDhikr() {
        let citation = Citation(
            source: "Dua",
            reference: "A dua",
            type: .dua
        )

        XCTAssertEqual(citation.navigationDestination(), .dhikr)
    }

    // MARK: - Untyped Citations

    func test_untypedCitation_returnsNil() {
        let citation = Citation(
            source: "General",
            reference: "Some reference"
        )

        XCTAssertNil(citation.navigationDestination())
    }
}
