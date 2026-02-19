// MARK: - ChatViewModel.swift
// PURPOSE: ViewModel for AI chat feature with orchestrator-based pipeline
// DEPENDENCIES: Foundation, ChatRepositoryProtocol, ChatOrchestratorProtocol

import Foundation

@MainActor
@Observable
final class ChatViewModel {
    // MARK: - State
    var messages: [ChatMessage] = []
    var conversations: [Conversation] = []
    var activeConversation: Conversation?
    var inputText = ""
    var isGenerating = false
    var isAborted = false
    var showConversations = false
    var error: Error?
    var cautionMessage: String?
    var pendingContext: ChatContext?

    // MARK: - Dependencies
    private let chatRepository: ChatRepositoryProtocol
    private let orchestrator: ChatOrchestratorProtocol?
    private var streamingTask: Task<Void, Never>?

    // MARK: - Init
    init(chatRepository: ChatRepositoryProtocol, orchestrator: ChatOrchestratorProtocol? = nil) {
        self.chatRepository = chatRepository
        self.orchestrator = orchestrator
    }

    // MARK: - Load Methods

    func loadActiveConversation() async {
        cautionMessage = nil
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

    // MARK: - Turn Lifecycle

    /// Begin a new turn: add user message to UI, start pipeline.
    func beginTurn() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        isGenerating = true
        isAborted = false
        cautionMessage = nil

        // Ensure we have a conversation
        if activeConversation == nil {
            do {
                activeConversation = try await chatRepository.createConversation()
            } catch {
                self.error = error
                isGenerating = false
                return
            }
        }

        let conversationId = activeConversation!.id

        // Add user message to UI immediately
        let userMessage = ChatMessage(
            conversationId: conversationId,
            role: .user,
            content: text
        )
        messages.append(userMessage)

        // Persist user message — abort turn if save fails
        do {
            try await chatRepository.saveMessage(userMessage)
        } catch {
            self.error = error
            messages.removeLast() // Remove unsaved user message from UI
            isGenerating = false
            return
        }

        // Add placeholder assistant message for streaming
        let assistantMessage = ChatMessage(
            conversationId: conversationId,
            role: .assistant,
            content: ""
        )
        messages.append(assistantMessage)

        // Run through orchestrator if available, otherwise fall back to simple send
        if orchestrator != nil {
            let context = pendingContext
            pendingContext = nil
            let request = ChatRequest(
                text: text,
                conversationId: conversationId,
                context: context,
                conversationHistory: messages
            )

            streamingTask = Task { [weak self] in
                await self?.processOrchestrator(request: request, assistantMessage: assistantMessage)
            }
        } else {
            // Legacy path: no orchestrator available (e.g. testing)
            commitTurn(
                assistantMessage: assistantMessage,
                content: "AI Companion requires iOS 26 or later.",
                citations: []
            )
        }
    }

    /// Commit the turn: persist the final response.
    private func commitTurn(assistantMessage: ChatMessage, content: String, citations: [Citation], status: ChatMessage.Status = .complete) {
        guard !isAborted else { return }

        let finalMessage = ChatMessage(
            id: assistantMessage.id,
            conversationId: assistantMessage.conversationId,
            role: .assistant,
            content: content,
            timestamp: assistantMessage.timestamp,
            citations: citations,
            status: status
        )

        // Update the assistant message in the list
        if let lastIndex = messages.lastIndex(where: { $0.id == assistantMessage.id }) {
            messages[lastIndex] = finalMessage
        }
        Task {
            do {
                try await chatRepository.saveMessage(finalMessage)

                // Update conversation metadata
                if var conversation = activeConversation {
                    conversation.messageCount += 2
                    conversation.updatedAt = Date()
                    if conversation.title == nil && conversation.messageCount >= 2 {
                        conversation.title = generateTitle(from: messages.first(where: { $0.role == .user })?.content ?? "")
                    }
                    try await chatRepository.updateConversation(conversation)
                    activeConversation = conversation
                }
            } catch {
                self.error = error
            }
        }

        isGenerating = false
    }

    /// Abort the current turn: cancel the stream, mark message as aborted, stop generating.
    func abortTurn() {
        isAborted = true
        streamingTask?.cancel()
        streamingTask = nil
        isGenerating = false

        // Update the last assistant message status to .aborted and persist
        if let lastIndex = messages.lastIndex(where: { $0.isAssistant }) {
            let msg = messages[lastIndex]
            let abortedMessage = ChatMessage(
                id: msg.id,
                conversationId: msg.conversationId,
                role: .assistant,
                content: msg.content,
                timestamp: msg.timestamp,
                citations: msg.citations,
                status: .aborted
            )
            messages[lastIndex] = abortedMessage

            Task {
                try? await chatRepository.saveMessage(abortedMessage)
            }
        }
    }

    // MARK: - Prefill and Send (for Siri intent / contextual entry points)

    func prefillAndSend(_ text: String) {
        inputText = text
        Task { await beginTurn() }
    }

    // MARK: - Feedback

    func saveFeedback(messageId: UUID, rating: Int16) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        // Toggle: tapping same thumb again resets to 0
        let newRating: Int16 = messages[index].feedbackRating == rating ? 0 : rating
        messages[index].feedbackRating = newRating
        Task { try? await chatRepository.updateFeedback(messageId: messageId, rating: newRating) }
    }

    // MARK: - Legacy Send (backwards compat for existing UI)

    func sendMessage() async {
        await beginTurn()
    }

    func sendMessageStreaming() async {
        await beginTurn()
    }

    // MARK: - Conversation Management

    func startNewConversation() async {
        cautionMessage = nil
        do {
            let conversation = try await chatRepository.createConversation()
            activeConversation = conversation
            messages = []
        } catch {
            self.error = error
        }
    }

    func selectConversation(_ conversation: Conversation) async {
        cautionMessage = nil
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

    // MARK: - Private Methods

    private func processOrchestrator(request: ChatRequest, assistantMessage: ChatMessage) async {
        guard let orchestrator else { return }

        var fullContent = ""

        do {
            for try await event in orchestrator.process(request) {
                guard !isAborted else { break }

                switch event {
                case .safetyDeclined(let refusalText):
                    commitTurn(assistantMessage: assistantMessage, content: refusalText, citations: [])
                    return

                case .cautionBanner(let warning):
                    cautionMessage = warning

                case .streamingChunk(let chunk):
                    fullContent += chunk
                    // Update the placeholder message with streaming content
                    if let lastIndex = messages.lastIndex(where: { $0.id == assistantMessage.id }) {
                        messages[lastIndex] = ChatMessage(
                            id: assistantMessage.id,
                            conversationId: assistantMessage.conversationId,
                            role: .assistant,
                            content: fullContent,
                            timestamp: assistantMessage.timestamp,
                            status: .streaming
                        )
                    }

                case .ragContextRetrieved:
                    break // Informational only

                case .completed(let response):
                    commitTurn(assistantMessage: assistantMessage, content: response.answer, citations: response.citations)
                    return

                case .fallback(_, let response):
                    commitTurn(assistantMessage: assistantMessage, content: response.answer, citations: [])
                    return
                }
            }

            // If stream ended without a .completed event, commit what we have
            if isGenerating && !isAborted {
                commitTurn(assistantMessage: assistantMessage, content: fullContent, citations: [])
            }
        } catch {
            if !isAborted {
                self.error = error
                commitTurn(
                    assistantMessage: assistantMessage,
                    content: "I apologize, but I encountered an error. Please try again.",
                    citations: []
                )
            }
        }
    }

    private func generateTitle(from message: String) -> String {
        let words = message.split(separator: " ").prefix(5)
        var title = words.joined(separator: " ")
        if message.split(separator: " ").count > 5 {
            title += "..."
        }
        return title
    }
}
