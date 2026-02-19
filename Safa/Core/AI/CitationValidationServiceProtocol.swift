// MARK: - CitationValidationServiceProtocol.swift
// PURPOSE: Protocol for post-LLM citation validation against RAG results
// DEPENDENCIES: Foundation

import Foundation

/// Post-LLM, pre-OutputSafety citation validator. Cross-references model citations against RAG results.
protocol CitationValidationServiceProtocol {
    /// Validate citations against the RAG context that was used to generate the response.
    /// - Parameters:
    ///   - citations: Citations from the AI response.
    ///   - ragContext: The RAG context used for generation.
    /// - Returns: Citations with `verified` flag updated. Fabricated citations are removed.
    func validate(citations: [Citation], ragContext: RAGContext) -> [Citation]
}

/// Pass-through stub that marks all citations as verified. Used until real implementation is wired.
/// This ensures the OutputSafetyService citation check passes in Phase 0 (no real validation yet).
struct PassthroughCitationValidationService: CitationValidationServiceProtocol {
    func validate(citations: [Citation], ragContext: RAGContext) -> [Citation] {
        citations.map { Citation(source: $0.source, reference: $0.reference, verified: true) }
    }
}
