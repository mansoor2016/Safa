// MARK: - OrchestratorEvent.swift
// PURPOSE: Streaming events emitted by the ChatOrchestrator pipeline
// DEPENDENCIES: Foundation

import Foundation

/// Events emitted by the ChatOrchestrator as a request moves through the pipeline.
enum OrchestratorEvent {
    /// Input safety declined the request. No LLM call was made.
    case safetyDeclined(refusalText: String)

    /// Input safety allowed with caution — a warning banner should be shown above the response.
    case cautionBanner(warning: String)

    /// A chunk of streaming text from the LLM.
    case streamingChunk(String)

    /// RAG context was retrieved (informational, for logging/debugging).
    case ragContextRetrieved(topic: RAGTopic, sourceCount: Int)

    /// The pipeline completed with a final response.
    case completed(AIResponse)

    /// The pipeline encountered an error and returned a canned fallback.
    case fallback(reason: String, response: AIResponse)
}

/// The structured response from the AI pipeline.
struct AIResponse {
    let answer: String
    let citations: [Citation]
    let confidence: ConfidenceBand

    static func canned(_ text: String) -> AIResponse {
        AIResponse(answer: text, citations: [], confidence: .low)
    }
}

/// A source citation attached to an AI response.
struct Citation: Codable, Hashable {
    let source: String
    let reference: String
    let verified: Bool

    init(source: String, reference: String, verified: Bool = false) {
        self.source = source
        self.reference = reference
        self.verified = verified
    }
}

/// Confidence level of the AI response.
enum ConfidenceBand: String, Codable {
    case high
    case medium
    case low
}
