// MARK: - ChatRequest.swift
// PURPOSE: Request envelope for AI chat pipeline
// DEPENDENCIES: Foundation

import Foundation

/// Encapsulates a user's chat request with all context needed by the pipeline.
struct ChatRequest {
    let text: String
    let conversationId: UUID
    let context: ChatContext?
    let conversationHistory: [ChatMessage]

    init(
        text: String,
        conversationId: UUID,
        context: ChatContext? = nil,
        conversationHistory: [ChatMessage] = []
    ) {
        self.text = text
        self.conversationId = conversationId
        self.context = context
        self.conversationHistory = conversationHistory
    }
}
