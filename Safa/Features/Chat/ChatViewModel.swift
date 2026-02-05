// MARK: - ChatViewModel.swift
// PURPOSE: ViewModel for AI chat feature
// DEPENDENCIES: Foundation, ChatRepository

import Foundation

@Observable
final class ChatViewModel {
    // MARK: - State
    var messages: [ChatMessage] = []
    var conversations: [Conversation] = []
    var activeConversation: Conversation?
    var inputText = ""
    var isGenerating = false
    var showConversations = false
    var error: Error?

    // MARK: - Dependencies
    private let chatRepository: ChatRepositoryProtocol

    // MARK: - Init
    init(chatRepository: ChatRepositoryProtocol) {
        self.chatRepository = chatRepository
    }

    // MARK: - Load Methods

    func loadActiveConversation() async {
        do {
            activeConversation = try await chatRepository.getActiveConversation()

            if let conversation = activeConversation {
                messages = try await chatRepository.getMessages(forConversation: conversation.id.uuidString)
            }
        } catch {
            self.error = error
        }
    }

    func loadConversations() async {
        do {
            conversations = try await chatRepository.getConversations()
        } catch {
            self.error = error
        }
    }

    // MARK: - Send Message

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        isGenerating = true

        // Add user message to UI immediately
        let userMessage = ChatMessage(
            conversationId: activeConversation?.id ?? UUID(),
            role: .user,
            content: text
        )
        messages.append(userMessage)

        do {
            // Send and get response
            let response = try await chatRepository.sendMessage(text)
            messages.append(response)

            // Reload active conversation to get updated state
            await loadActiveConversation()
        } catch {
            self.error = error

            // Add error message
            let errorMessage = ChatMessage(
                conversationId: activeConversation?.id ?? UUID(),
                role: .assistant,
                content: "I apologize, but I encountered an error. Please try again."
            )
            messages.append(errorMessage)
        }

        isGenerating = false
    }

    func sendMessageStreaming() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        isGenerating = true

        // Add user message
        let userMessage = ChatMessage(
            conversationId: activeConversation?.id ?? UUID(),
            role: .user,
            content: text
        )
        messages.append(userMessage)

        // Add placeholder assistant message
        var assistantMessage = ChatMessage(
            conversationId: activeConversation?.id ?? UUID(),
            role: .assistant,
            content: ""
        )
        messages.append(assistantMessage)

        do {
            for try await chunk in chatRepository.sendMessageStreaming(text) {
                // Update the last message with streaming content
                if let lastIndex = messages.indices.last {
                    messages[lastIndex] = ChatMessage(
                        id: assistantMessage.id,
                        conversationId: assistantMessage.conversationId,
                        role: .assistant,
                        content: messages[lastIndex].content + chunk,
                        timestamp: assistantMessage.timestamp
                    )
                }
            }
        } catch {
            self.error = error
        }

        isGenerating = false
    }

    // MARK: - Conversation Management

    func startNewConversation() async {
        do {
            let conversation = try await chatRepository.createConversation()
            activeConversation = conversation
            messages = []
        } catch {
            self.error = error
        }
    }

    func selectConversation(_ conversation: Conversation) async {
        do {
            try await chatRepository.setActiveConversation(id: conversation.id.uuidString)
            activeConversation = conversation
            messages = try await chatRepository.getMessages(forConversation: conversation.id.uuidString)
        } catch {
            self.error = error
        }
    }

    func deleteConversation(_ conversation: Conversation) async {
        do {
            try await chatRepository.deleteConversation(id: conversation.id.uuidString)
            await loadConversations()

            // If we deleted the active conversation, clear messages
            if activeConversation?.id == conversation.id {
                activeConversation = nil
                messages = []
            }
        } catch {
            self.error = error
        }
    }

    func clearHistory() async {
        do {
            try await chatRepository.clearHistory()
            conversations = []
            activeConversation = nil
            messages = []
        } catch {
            self.error = error
        }
    }
}
