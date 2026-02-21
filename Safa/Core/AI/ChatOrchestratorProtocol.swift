// MARK: - ChatOrchestratorProtocol.swift
// PURPOSE: Protocol for the AI chat pipeline coordinator
// DEPENDENCIES: Foundation

import Foundation

/// Coordinates the full AI chat pipeline: safety → RAG → prompt → LLM → validation → output.
protocol ChatOrchestratorProtocol {
    /// Process a chat request through the full pipeline, yielding events as they occur.
    /// - Parameter request: The user's chat request.
    /// - Returns: An async stream of orchestrator events.
    func process(_ request: ChatRequest) -> AsyncThrowingStream<OrchestratorEvent, Error>
}
