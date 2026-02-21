// MARK: - ChatRepositoryProtocol.swift
// PURPOSE: Defines contract for AI chat persistence (conversations and messages)
// NOTE: Generation/inference moved to ChatOrchestrator. Repository is persist-only.

import Foundation

protocol ChatRepositoryProtocol {
    /// Gets all conversations
    func getConversations() async throws -> [Conversation]

    /// Gets a specific conversation
    func getConversation(id conversationId: String) async throws -> Conversation?

    /// Gets messages for a conversation
    func getMessages(forConversation conversationId: String) async throws -> [ChatMessage]

    /// Creates a new conversation
    func createConversation() async throws -> Conversation

    /// Deletes a conversation
    func deleteConversation(id conversationId: String) async throws

    /// Sets the active conversation
    func setActiveConversation(id conversationId: String) async throws

    /// Gets the active conversation
    func getActiveConversation() async throws -> Conversation?

    /// Saves a message to a conversation
    func saveMessage(_ message: ChatMessage) async throws

    /// Updates a conversation (title, messageCount, etc.)
    func updateConversation(_ conversation: Conversation) async throws

    /// Updates the feedback rating on a message
    func updateFeedback(messageId: UUID, rating: Int16) async throws

    /// Clears all chat history
    func clearHistory() async throws
}
