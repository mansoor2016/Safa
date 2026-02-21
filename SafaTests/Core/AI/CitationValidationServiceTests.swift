// MARK: - CitationValidationServiceTests.swift
// PURPOSE: Unit tests for CitationValidationService cross-reference logic
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class CitationValidationServiceTests: XCTestCase {

    private let sut = CitationValidationService()

    // MARK: - Quran

    func test_validQuranCitation_markedVerified() {
        let citation = Citation(
            source: "Quran",
            reference: "Al-Baqarah 2:255",
            type: .quran,
            surahNumber: 2,
            ayahNumber: 255
        )
        let ragContext = RAGContext(
            quranReferences: [QuranReference(
                surahNumber: 2, surahName: "Al-Baqarah", ayahNumber: 255,
                arabic: "...", translation: "...", relevanceScore: 0.9
            )],
            hadithReferences: [],
            duaReferences: [],
            topic: .quran
        )

        let result = sut.validate(citations: [citation], ragContext: ragContext)

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first?.verified ?? false)
    }

    // MARK: - Fabricated

    func test_fabricatedCitation_stripped() {
        let citation = Citation(
            source: "Quran",
            reference: "Al-Imran 3:100",
            type: .quran,
            surahNumber: 3,
            ayahNumber: 100
        )
        let ragContext = RAGContext(
            quranReferences: [QuranReference(
                surahNumber: 2, surahName: "Al-Baqarah", ayahNumber: 255,
                arabic: "...", translation: "...", relevanceScore: 0.9
            )],
            hadithReferences: [],
            duaReferences: [],
            topic: .quran
        )

        let result = sut.validate(citations: [citation], ragContext: ragContext)

        XCTAssertTrue(result.isEmpty, "Fabricated citation should be stripped")
    }

    // MARK: - Hadith

    func test_validHadithCitation_markedVerified() {
        let citation = Citation(
            source: "Sahih al-Bukhari",
            reference: "Sahih al-Bukhari 1",
            type: .hadith,
            collectionId: "Sahih al-Bukhari",
            hadithNumber: 1
        )
        let ragContext = RAGContext(
            quranReferences: [],
            hadithReferences: [HadithReference(
                collection: "Sahih al-Bukhari", hadithNumber: 1,
                narrator: "Umar", text: "Actions are by intentions.",
                grading: "Sahih", relevanceScore: 0.95
            )],
            duaReferences: [],
            topic: .hadith
        )

        let result = sut.validate(citations: [citation], ragContext: ragContext)

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first?.verified ?? false)
    }

    // MARK: - Dua

    func test_validDuaCitation_markedVerified() {
        let citation = Citation(
            source: "Dua",
            reference: "Dua before sleeping",
            type: .dua,
            duaId: "dua_sleep_001"
        )
        let ragContext = RAGContext(
            quranReferences: [],
            hadithReferences: [],
            duaReferences: [DuaReference(
                duaId: "dua_sleep_001", title: "Dua before sleeping",
                arabic: "...", translation: "...", source: nil,
                relevanceScore: 0.8
            )],
            topic: .dua
        )

        let result = sut.validate(citations: [citation], ragContext: ragContext)

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first?.verified ?? false)
    }

    // MARK: - Empty RAG Context

    func test_emptyRagContext_marksCitationsVerified() {
        let citation = Citation(
            source: "Quran",
            reference: "Al-Baqarah 2:255",
            type: .quran,
            surahNumber: 2,
            ayahNumber: 255
        )
        let ragContext = RAGContext(
            quranReferences: [],
            hadithReferences: [],
            duaReferences: [],
            topic: .general
        )

        let result = sut.validate(citations: [citation], ragContext: ragContext)

        XCTAssertEqual(result.count, 1, "Empty RAG context should pass all citations through")
        XCTAssertTrue(result.first?.verified ?? false)
    }

    // MARK: - Untyped Citation Fallback (matchesByText)

    func test_untypedQuranCitation_matchesByReferenceText() {
        // Given — citation has no structured type, but reference text contains "2:255"
        let citation = Citation(
            source: "Quran",
            reference: "Al-Baqarah 2:255"
            // No type, surahNumber, or ayahNumber — forces matchesByText path
        )
        let ragContext = RAGContext(
            quranReferences: [QuranReference(
                surahNumber: 2, surahName: "Al-Baqarah", ayahNumber: 255,
                arabic: "...", translation: "...", relevanceScore: 0.9
            )],
            hadithReferences: [],
            duaReferences: [],
            topic: .quran
        )

        let result = sut.validate(citations: [citation], ragContext: ragContext)

        XCTAssertEqual(result.count, 1, "Untyped citation matching RAG by text should be verified")
        XCTAssertTrue(result.first?.verified ?? false)
    }

    func test_untypedHadithCitation_matchesByReferenceText() {
        // Given — citation has no structured type, but reference text contains collection + number
        let citation = Citation(
            source: "Hadith",
            reference: "Sahih al-Bukhari 1"
        )
        let ragContext = RAGContext(
            quranReferences: [],
            hadithReferences: [HadithReference(
                collection: "Sahih al-Bukhari", hadithNumber: 1,
                narrator: "Umar", text: "Actions are by intentions.",
                grading: "Sahih", relevanceScore: 0.95
            )],
            duaReferences: [],
            topic: .hadith
        )

        let result = sut.validate(citations: [citation], ragContext: ragContext)

        XCTAssertEqual(result.count, 1, "Untyped hadith citation matching RAG by text should be verified")
        XCTAssertTrue(result.first?.verified ?? false)
    }

    func test_untypedCitation_noMatch_stripped() {
        // Given — untyped citation that doesn't match any RAG result
        let citation = Citation(
            source: "Unknown",
            reference: "Some fabricated source"
        )
        let ragContext = RAGContext(
            quranReferences: [QuranReference(
                surahNumber: 2, surahName: "Al-Baqarah", ayahNumber: 255,
                arabic: "...", translation: "...", relevanceScore: 0.9
            )],
            hadithReferences: [],
            duaReferences: [],
            topic: .quran
        )

        let result = sut.validate(citations: [citation], ragContext: ragContext)

        XCTAssertTrue(result.isEmpty, "Untyped citation with no text match should be stripped")
    }

    // MARK: - withVerified Field Preservation

    func test_withVerified_preservesAllStructuredFields() {
        // Given — a citation with all structured fields populated
        let original = Citation(
            source: "Quran",
            reference: "Al-Baqarah 2:255",
            verified: false,
            type: .quran,
            surahNumber: 2,
            ayahNumber: 255,
            collectionId: "test-collection",
            hadithNumber: 42,
            duaId: "test-dua"
        )

        // When
        let verified = original.withVerified(true)

        // Then — every field except verified should be preserved
        XCTAssertTrue(verified.verified)
        XCTAssertEqual(verified.source, "Quran")
        XCTAssertEqual(verified.reference, "Al-Baqarah 2:255")
        XCTAssertEqual(verified.type, .quran)
        XCTAssertEqual(verified.surahNumber, 2)
        XCTAssertEqual(verified.ayahNumber, 255)
        XCTAssertEqual(verified.collectionId, "test-collection")
        XCTAssertEqual(verified.hadithNumber, 42)
        XCTAssertEqual(verified.duaId, "test-dua")
    }

    // MARK: - Mixed Citations

    func test_mixedCitations_onlyValidKept() {
        let validCitation = Citation(
            source: "Quran",
            reference: "Al-Baqarah 2:255",
            type: .quran,
            surahNumber: 2,
            ayahNumber: 255
        )
        let fabricatedCitation = Citation(
            source: "Quran",
            reference: "Al-Imran 3:999",
            type: .quran,
            surahNumber: 3,
            ayahNumber: 999
        )
        let ragContext = RAGContext(
            quranReferences: [QuranReference(
                surahNumber: 2, surahName: "Al-Baqarah", ayahNumber: 255,
                arabic: "...", translation: "...", relevanceScore: 0.9
            )],
            hadithReferences: [],
            duaReferences: [],
            topic: .quran
        )

        let result = sut.validate(citations: [validCitation, fabricatedCitation], ragContext: ragContext)

        XCTAssertEqual(result.count, 1, "Only the valid citation should remain")
        XCTAssertEqual(result.first?.surahNumber, 2)
        XCTAssertEqual(result.first?.ayahNumber, 255)
    }
}
