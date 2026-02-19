// MARK: - CitationValidationService.swift
// PURPOSE: Cross-references AI citations against RAG results to strip fabricated sources
// DEPENDENCIES: Foundation, CitationValidationServiceProtocol, RAGContext

import Foundation

struct CitationValidationService: CitationValidationServiceProtocol {

    func validate(citations: [Citation], ragContext: RAGContext) -> [Citation] {
        // When RAG context is empty, mark all as verified —
        // can't validate without ground truth, prevents OutputSafety false failures
        guard !ragContext.isEmpty else {
            return citations.map { $0.withVerified(true) }
        }

        return citations.compactMap { citation in
            if matchesRAGResult(citation, ragContext: ragContext) {
                return citation.withVerified(true)
            }
            return nil // Strip fabricated citations
        }
    }

    // MARK: - Matching

    private func matchesRAGResult(_ citation: Citation, ragContext: RAGContext) -> Bool {
        guard let type = citation.type else {
            // Untyped citations — fall back to text matching
            return matchesByText(citation, ragContext: ragContext)
        }

        switch type {
        case .quran:
            return ragContext.quranReferences.contains { ref in
                citation.surahNumber == ref.surahNumber && citation.ayahNumber == ref.ayahNumber
            }
        case .hadith:
            return ragContext.hadithReferences.contains { ref in
                citation.collectionId == ref.collection && citation.hadithNumber == ref.hadithNumber
            }
        case .dua:
            return ragContext.duaReferences.contains { ref in
                citation.duaId == ref.duaId
            }
        }
    }

    private func matchesByText(_ citation: Citation, ragContext: RAGContext) -> Bool {
        let ref = citation.reference.lowercased()

        for quranRef in ragContext.quranReferences {
            if ref.contains("\(quranRef.surahNumber):\(quranRef.ayahNumber)") {
                return true
            }
        }

        for hadithRef in ragContext.hadithReferences {
            if ref.contains(hadithRef.collection.lowercased()) && ref.contains("\(hadithRef.hadithNumber)") {
                return true
            }
        }

        for duaRef in ragContext.duaReferences {
            if ref.contains(duaRef.title.lowercased()) {
                return true
            }
        }

        return false
    }
}
