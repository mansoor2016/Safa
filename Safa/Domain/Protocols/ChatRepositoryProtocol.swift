// MARK: - ChatRepositoryProtocol.swift
// PURPOSE: Defines contract for AI chat conversations and history

import Foundation

protocol ChatRepositoryProtocol {
    /// Sends a message and gets a response
    /// - Parameter message: The user's message
    /// - Returns: The AI response
    func sendMessage(_ message: String) async throws -> ChatMessage

    /// Sends a message with streaming response
    /// - Parameter message: The user's message
    /// - Returns: AsyncStream of response chunks
    func sendMessageStreaming(_ message: String) -> AsyncThrowingStream<String, Error>

    /// Gets all conversations
    /// - Returns: Array of conversations
    func getConversations() async throws -> [Conversation]

    /// Gets a specific conversation
    /// - Parameter conversationId: The conversation identifier
    /// - Returns: The conversation if found
    func getConversation(id conversationId: String) async throws -> Conversation?

    /// Gets messages for a conversation
    /// - Parameter conversationId: The conversation identifier
    /// - Returns: Array of messages
    func getMessages(forConversation conversationId: String) async throws -> [ChatMessage]

    /// Creates a new conversation
    /// - Returns: The new conversation
    func createConversation() async throws -> Conversation

    /// Deletes a conversation
    /// - Parameter conversationId: The conversation identifier
    func deleteConversation(id conversationId: String) async throws

    /// Sets the active conversation
    /// - Parameter conversationId: The conversation identifier
    func setActiveConversation(id conversationId: String) async throws

    /// Gets the active conversation
    /// - Returns: The currently active conversation
    func getActiveConversation() async throws -> Conversation?

    /// Clears chat history
    func clearHistory() async throws
}
