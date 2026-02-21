// MARK: - LLMServiceProtocol.swift
// PURPOSE: Protocol defining the LLM generation interface for dependency injection
// DEPENDENCIES: Foundation

import Foundation

/// Protocol for LLM text generation used by ChatOrchestrator.
protocol LLMServiceProtocol {
    /// Generate a streaming response for the given prompt.
    /// - Parameters:
    ///   - prompt: The user's input text.
    ///   - systemPrompt: The system prompt guiding the model.
    ///   - context: Optional chat context for topic awareness.
    /// - Returns: An async stream of text chunks.
    func generateResponseStreaming(
        prompt: String,
        systemPrompt: String,
        context: ChatContext?
    ) -> AsyncThrowingStream<String, Error>
}
