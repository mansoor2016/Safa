// MARK: - ChatRepository.swift
// PURPOSE: Implementation of AI chat conversations and history
// DEPENDENCIES: LLMService, ChatRepositoryProtocol

import Foundation

final class ChatRepository: ChatRepositoryProtocol {
    // MARK: - Dependencies
    private let llmService: LLMService

    // MARK: - Storage Keys
    private let conversationsKey = AppConstants.StorageKeys.chatConversations
    private let messagesKeyPrefix = AppConstants.StorageKeys.chatMessagesPrefix
    private let activeConversationKey = AppConstants.StorageKeys.chatActiveConversation

    // MARK: - System Prompt
    private let systemPrompt = """
    You are the Safa AI Assistant, a knowledgeable and respectful companion for Muslims.

    Your role is to:
    - Answer questions about Islamic practices, duas, and daily worship
    - Provide accurate information with sources (Quran verses, Hadith references)
    - Be neutral on matters where scholars differ (mention different opinions)
    - Recommend consulting a qualified scholar for complex fiqh matters
    - Politely decline to discuss political topics

    Always:
    - Be respectful and kind
    - Include Arabic text with transliteration and translation when relevant
    - Cite sources (e.g., "Sahih Bukhari 1234", "Quran 2:255")
    - Acknowledge when you're uncertain
    """

    // MARK: - Init
    init(llmService: LLMService) {
        self.llmService = llmService
    }

    // MARK: - Send Message

    func sendMessage(_ message: String) async throws -> ChatMessage {
        // Get or create active conversation
        var conversation: Conversation
        if let existingConversation = try await getActiveConversation() {
            conversation = existingConversation
        } else {
            conversation = try await createConversation()
        }

        // Save user message
        let userMessage = ChatMessage(
            conversationId: conversation.id,
            role: .user,
            content: message
        )
        try await saveMessage(userMessage)

        // Generate response
        let response = try await llmService.generateResponse(prompt: message, systemPrompt: systemPrompt)

        // Save assistant message
        let assistantMessage = ChatMessage(
            conversationId: conversation.id,
            role: .assistant,
            content: response
        )
        try await saveMessage(assistantMessage)

        // Update conversation
        conversation.messageCount += 2
        conversation.updatedAt = Date()
        if conversation.title == nil && conversation.messageCount >= 2 {
            conversation.title = generateTitle(from: message)
        }
        try await updateConversation(conversation)

        return assistantMessage
    }

    func sendMessageStreaming(_ message: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Get or create active conversation
                    var conversation: Conversation
                    if let existingConversation = try await self.getActiveConversation() {
                        conversation = existingConversation
                    } else {
                        conversation = try await self.createConversation()
                    }

                    // Save user message
                    let userMessage = ChatMessage(
                        conversationId: conversation.id,
                        role: .user,
                        content: message
                    )
                    try await saveMessage(userMessage)

                    // Stream response
                    var fullResponse = ""
                    for try await chunk in llmService.generateResponseStreaming(prompt: message, systemPrompt: systemPrompt) {
                        fullResponse += chunk
                        continuation.yield(chunk)
                    }

                    // Save assistant message
                    let assistantMessage = ChatMessage(
                        conversationId: conversation.id,
                        role: .assistant,
                        content: fullResponse
                    )
                    try await saveMessage(assistantMessage)

                    // Update conversation
                    conversation.messageCount += 2
                    conversation.updatedAt = Date()
                    if conversation.title == nil && conversation.messageCount >= 2 {
                        conversation.title = generateTitle(from: message)
                    }
                    try await updateConversation(conversation)

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Conversations

    func getConversations() async throws -> [Conversation] {
        guard let data = UserDefaults.standard.data(forKey: conversationsKey),
              let conversations = try? JSONDecoder().decode([Conversation].self, from: data) else {
            return []
        }
        return conversations.sorted { $0.updatedAt > $1.updatedAt }
    }

    func getConversation(id conversationId: String) async throws -> Conversation? {
        let conversations = try await getConversations()
        return conversations.first { $0.id.uuidString == conversationId }
    }

    func getMessages(forConversation conversationId: String) async throws -> [ChatMessage] {
        let key = messagesKeyPrefix + conversationId
        guard let data = UserDefaults.standard.data(forKey: key),
              let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
            return []
        }
        return messages.sorted { $0.timestamp < $1.timestamp }
    }

    func createConversation() async throws -> Conversation {
        let conversation = Conversation()
        var conversations = try await getConversations()
        conversations.append(conversation)

        let data = try JSONEncoder().encode(conversations)
        UserDefaults.standard.set(data, forKey: conversationsKey)

        // Set as active
        try await setActiveConversation(id: conversation.id.uuidString)

        return conversation
    }

    func deleteConversation(id conversationId: String) async throws {
        var conversations = try await getConversations()
        conversations.removeAll { $0.id.uuidString == conversationId }

        let data = try JSONEncoder().encode(conversations)
        UserDefaults.standard.set(data, forKey: conversationsKey)

        // Delete messages
        let messagesKey = messagesKeyPrefix + conversationId
        UserDefaults.standard.removeObject(forKey: messagesKey)

        // Clear active if this was active
        if let active = UserDefaults.standard.string(forKey: activeConversationKey),
           active == conversationId {
            UserDefaults.standard.removeObject(forKey: activeConversationKey)
        }
    }

    func setActiveConversation(id conversationId: String) async throws {
        UserDefaults.standard.set(conversationId, forKey: activeConversationKey)
    }

    func getActiveConversation() async throws -> Conversation? {
        guard let activeId = UserDefaults.standard.string(forKey: activeConversationKey) else {
            return nil
        }
        return try await getConversation(id: activeId)
    }

    func clearHistory() async throws {
        let conversations = try await getConversations()

        // Delete all message stores
        for conversation in conversations {
            let messagesKey = messagesKeyPrefix + conversation.id.uuidString
            UserDefaults.standard.removeObject(forKey: messagesKey)
        }

        // Clear conversations
        UserDefaults.standard.removeObject(forKey: conversationsKey)
        UserDefaults.standard.removeObject(forKey: activeConversationKey)
    }

    // MARK: - Private Helpers

    private func saveMessage(_ message: ChatMessage) async throws {
        let key = messagesKeyPrefix + message.conversationId.uuidString
        var messages = try await getMessages(forConversation: message.conversationId.uuidString)
        messages.append(message)

        let data = try JSONEncoder().encode(messages)
        UserDefaults.standard.set(data, forKey: key)
    }

    private func updateConversation(_ conversation: Conversation) async throws {
        var conversations = try await getConversations()
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        }

        let data = try JSONEncoder().encode(conversations)
        UserDefaults.standard.set(data, forKey: conversationsKey)
    }

    private func generateTitle(from message: String) -> String {
        // Generate a short title from the first message
        let words = message.split(separator: " ").prefix(5)
        var title = words.joined(separator: " ")
        if message.split(separator: " ").count > 5 {
            title += "..."
        }
        return title
    }
}
