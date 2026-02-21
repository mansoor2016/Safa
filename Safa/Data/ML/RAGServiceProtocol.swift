// MARK: - RAGServiceProtocol.swift
// PURPOSE: Protocol for RAG (Retrieval-Augmented Generation) context retrieval
// DEPENDENCIES: Foundation

import Foundation

protocol RAGServiceProtocol {
    /// Retrieve relevant Quran and Hadith context for a given query,
    /// optionally biased by a ChatContext (e.g. specific surah/ayah or hadith).
    func retrieveContext(for query: String, context: ChatContext?) async -> RAGContext
}
