// MARK: - ChatViewModelTests.swift
// PURPOSE: Unit tests for ChatViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

@MainActor
final class ChatViewModelTests: XCTestCase {

    var sut: ChatViewModel!
    var mockRepository: TestableChatRepository!

    override func setUp() {
        super.setUp()
        mockRepository = TestableChatRepository()
        sut = ChatViewModel(chatRepository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasEmptyMessages() {
        XCTAssertTrue(sut.messages.isEmpty)
    }

    func test_initialState_hasEmptyConversations() {
        XCTAssertTrue(sut.conversations.isEmpty)
    }

    func test_initialState_hasNoActiveConversation() {
        XCTAssertNil(sut.activeConversation)
    }

    func test_initialState_hasEmptyInputText() {
        XCTAssertTrue(sut.inputText.isEmpty)
    }

    func test_initialState_isNotGenerating() {
        XCTAssertFalse(sut.isGenerating)
    }

    func test_initialState_showConversationsIsFalse() {
        XCTAssertFalse(sut.showConversations)
    }

    func test_initialState_hasNoError() {
        XCTAssertNil(sut.error)
    }

    // MARK: - Load Active Conversation Tests

    func test_loadActiveConversation_success_setsActiveConversation() async {
        // Given
        let conversation = Conversation(title: "Test Conversation")
        mockRepository.activeConversationToReturn = conversation

        // When
        await sut.loadActiveConversation()

        // Then
        XCTAssertNotNil(sut.activeConversation)
        XCTAssertEqual(sut.activeConversation?.title, "Test Conversation")
    }

    func test_loadActiveConversation_loadsMessages() async {
        // Given
        let conversation = Conversation(title: "Test")
        let messages = [
            ChatMessage(conversationId: conversation.id, role: .user, content: "Hello"),
            ChatMessage(conversationId: conversation.id, role: .assistant, content: "Hi there!")
        ]
        mockRepository.activeConversationToReturn = conversation
        mockRepository.messagesToReturn = messages

        // When
        await sut.loadActiveConversation()

        // Then
        XCTAssertEqual(sut.messages.count, 2)
    }

    func test_loadActiveConversation_failure_setsError() async {
        // Given
        mockRepository.errorToThrow = TestError.loadFailed

        // When
        await sut.loadActiveConversation()

        // Then
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Load Conversations Tests

    func test_loadConversations_success_populatesConversations() async {
        // Given
        let conversations = [
            Conversation(title: "Conversation 1"),
            Conversation(title: "Conversation 2")
        ]
        mockRepository.conversationsToReturn = conversations

        // When
        await sut.loadConversations()

        // Then
        XCTAssertEqual(sut.conversations.count, 2)
    }

    func test_loadConversations_failure_setsError() async {
        // Given
        mockRepository.errorToThrow = TestError.loadFailed

        // When
        await sut.loadConversations()

        // Then
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Send Message Tests

    func test_sendMessage_withEmptyInput_doesNothing() async {
        // Given
        sut.inputText = "   "

        // When
        await sut.sendMessage()

        // Then
        XCTAssertTrue(sut.messages.isEmpty)
    }

    func test_sendMessage_addsUserMessageImmediately() async {
        // Given
        sut.inputText = "Hello"
        mockRepository.createdConversationToReturn = Conversation(title: "New")

        // When
        await sut.sendMessage()

        // Then - user message should be added
        XCTAssertTrue(sut.messages.contains { $0.content == "Hello" && $0.role == .user })
    }

    func test_sendMessage_clearsInputText() async {
        // Given
        sut.inputText = "Hello"
        mockRepository.createdConversationToReturn = Conversation(title: "New")

        // When
        await sut.sendMessage()

        // Then
        XCTAssertTrue(sut.inputText.isEmpty)
    }

    // MARK: - Abort Turn Tests

    func test_abortTurn_stopsGenerating() {
        // Given — must have currentTurnAssistantId for abort to take effect
        let msg = ChatMessage(conversationId: UUID(), role: .assistant, content: "", status: .streaming)
        sut.isGenerating = true
        sut.currentTurnAssistantId = msg.id
        sut.messages = [msg]

        // When
        sut.abortTurn()

        // Then
        XCTAssertFalse(sut.isGenerating)
        XCTAssertTrue(sut.isAborted)
        XCTAssertNil(sut.currentTurnAssistantId)
    }

    // MARK: - Start New Conversation Tests

    func test_startNewConversation_success_setsActiveConversation() async {
        // Given
        let newConversation = Conversation(title: "New Chat")
        mockRepository.createdConversationToReturn = newConversation

        // When
        await sut.startNewConversation()

        // Then
        XCTAssertNotNil(sut.activeConversation)
        XCTAssertEqual(sut.activeConversation?.title, "New Chat")
        XCTAssertTrue(sut.messages.isEmpty)
    }

    func test_startNewConversation_failure_setsError() async {
        // Given
        mockRepository.errorToThrow = TestError.createFailed

        // When
        await sut.startNewConversation()

        // Then
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Select Conversation Tests

    func test_selectConversation_setsActiveConversation() async {
        // Given
        let conversation = Conversation(title: "Selected Chat")
        let messages = [
            ChatMessage(conversationId: conversation.id, role: .user, content: "Previous message")
        ]
        mockRepository.messagesToReturn = messages

        // When
        await sut.selectConversation(conversation)

        // Then
        XCTAssertEqual(sut.activeConversation?.id, conversation.id)
        XCTAssertEqual(sut.messages.count, 1)
    }

    // MARK: - Delete Conversation Tests

    func test_deleteConversation_clearsActiveIfDeleted() async {
        // Given
        let conversation = Conversation(title: "To Delete")
        sut.activeConversation = conversation
        sut.messages = [
            ChatMessage(conversationId: conversation.id, role: .user, content: "Test")
        ]

        // When
        await sut.deleteConversation(conversation)

        // Then
        XCTAssertNil(sut.activeConversation)
        XCTAssertTrue(sut.messages.isEmpty)
    }

    func test_deleteConversation_doesNotClearActiveIfDifferent() async {
        // Given
        let activeConversation = Conversation(title: "Active")
        let conversationToDelete = Conversation(title: "To Delete")
        sut.activeConversation = activeConversation
        sut.messages = [
            ChatMessage(conversationId: activeConversation.id, role: .user, content: "Test")
        ]

        // When
        await sut.deleteConversation(conversationToDelete)

        // Then
        XCTAssertNotNil(sut.activeConversation)
        XCTAssertFalse(sut.messages.isEmpty)
    }

    // MARK: - Clear History Tests

    func test_clearHistory_clearsAllData() async {
        // Given
        sut.conversations = [Conversation(title: "Chat 1")]
        sut.activeConversation = Conversation(title: "Active")
        sut.messages = [ChatMessage(conversationId: UUID(), role: .user, content: "Test")]

        // When
        await sut.clearHistory()

        // Then
        XCTAssertTrue(sut.conversations.isEmpty)
        XCTAssertNil(sut.activeConversation)
        XCTAssertTrue(sut.messages.isEmpty)
    }

    func test_clearHistory_failure_setsError() async {
        // Given
        mockRepository.errorToThrow = TestError.clearFailed

        // When
        await sut.clearHistory()

        // Then
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Feedback Tests

    func test_saveFeedback_updatesMessageRating() {
        // Given — add a completed assistant message
        let conversationId = UUID()
        sut.messages = [
            ChatMessage(conversationId: conversationId, role: .assistant, content: "Response", status: .complete)
        ]
        let messageId = sut.messages[0].id

        // When
        sut.saveFeedback(messageId: messageId, rating: 1)

        // Then
        XCTAssertEqual(sut.messages[0].feedbackRating, 1)
    }

    func test_saveFeedback_togglesOff_whenSameRatingTapped() {
        // Given
        let conversationId = UUID()
        sut.messages = [
            ChatMessage(conversationId: conversationId, role: .assistant, content: "Response", feedbackRating: 1, status: .complete)
        ]
        let messageId = sut.messages[0].id

        // When — tap the same rating again
        sut.saveFeedback(messageId: messageId, rating: 1)

        // Then — should toggle to 0
        XCTAssertEqual(sut.messages[0].feedbackRating, 0)
    }

    func test_saveFeedback_switchesRating() {
        // Given
        let conversationId = UUID()
        sut.messages = [
            ChatMessage(conversationId: conversationId, role: .assistant, content: "Response", feedbackRating: 1, status: .complete)
        ]
        let messageId = sut.messages[0].id

        // When — tap different rating
        sut.saveFeedback(messageId: messageId, rating: -1)

        // Then — should switch to new rating
        XCTAssertEqual(sut.messages[0].feedbackRating, -1)
    }

    func test_saveFeedback_callsRepositoryUpdateFeedback() async {
        // Given
        let conversationId = UUID()
        sut.messages = [
            ChatMessage(conversationId: conversationId, role: .assistant, content: "Response", status: .complete)
        ]
        let messageId = sut.messages[0].id

        // When
        sut.saveFeedback(messageId: messageId, rating: 1)

        // Wait for the fire-and-forget Task to complete
        try? await Task.sleep(for: .milliseconds(100))

        // Then — repository should have received the update
        XCTAssertEqual(mockRepository.feedbackUpdates.count, 1)
        XCTAssertEqual(mockRepository.feedbackUpdates.first?.messageId, messageId)
        XCTAssertEqual(mockRepository.feedbackUpdates.first?.rating, 1)
    }

    func test_saveFeedback_toggleCallsRepositoryWithZero() async {
        // Given — already rated 1
        let conversationId = UUID()
        sut.messages = [
            ChatMessage(conversationId: conversationId, role: .assistant, content: "Response", feedbackRating: 1, status: .complete)
        ]
        let messageId = sut.messages[0].id

        // When — tap same rating to toggle off
        sut.saveFeedback(messageId: messageId, rating: 1)

        try? await Task.sleep(for: .milliseconds(100))

        // Then — repository should get rating 0
        XCTAssertEqual(mockRepository.feedbackUpdates.count, 1)
        XCTAssertEqual(mockRepository.feedbackUpdates.first?.rating, 0)
    }

    func test_saveFeedback_nonexistentMessageId_doesNotCrash() {
        // Given — no messages
        sut.messages = []

        // When — call with a random ID (should be a no-op)
        sut.saveFeedback(messageId: UUID(), rating: 1)

        // Then — no crash, no updates
        XCTAssertTrue(mockRepository.feedbackUpdates.isEmpty)
    }

    // MARK: - Context Threading Tests

    func test_beginTurn_passesContextToOrchestrator() async {
        // Given — ViewModel with a capturing orchestrator
        let capturingOrchestrator = CapturingChatOrchestrator()
        let vm = ChatViewModel(chatRepository: mockRepository, orchestrator: capturingOrchestrator)
        mockRepository.createdConversationToReturn = Conversation(title: "New")
        vm.pendingContext = ChatContext(topic: .quran, surahNumber: 2, ayahNumber: 255)
        vm.inputText = "Explain this ayah"

        // When — beginTurn spawns a streaming task; wait for it to complete
        await vm.beginTurn()
        // Allow the streaming task to run and capture the request
        try? await Task.sleep(for: .milliseconds(200))

        // Then — orchestrator should have received the context
        XCTAssertNotNil(capturingOrchestrator.lastRequest)
        XCTAssertEqual(capturingOrchestrator.lastRequest?.context?.topic, .quran)
        XCTAssertEqual(capturingOrchestrator.lastRequest?.context?.surahNumber, 2)
        XCTAssertEqual(capturingOrchestrator.lastRequest?.context?.ayahNumber, 255)
    }

    func test_beginTurn_clearsContextAfterUse() async {
        // Given
        let capturingOrchestrator = CapturingChatOrchestrator()
        let vm = ChatViewModel(chatRepository: mockRepository, orchestrator: capturingOrchestrator)
        mockRepository.createdConversationToReturn = Conversation(title: "New")
        vm.pendingContext = ChatContext(topic: .dua, duaId: "dua_sleep_001")
        vm.inputText = "Tell me about this dua"

        // When — pendingContext is consumed synchronously in beginTurn before the Task spawns
        await vm.beginTurn()

        // Then — pendingContext should be nil after use
        XCTAssertNil(vm.pendingContext, "pendingContext should be cleared after beginTurn consumes it")
    }

    func test_beginTurn_withoutContext_passesNilContext() async {
        // Given — no pending context
        let capturingOrchestrator = CapturingChatOrchestrator()
        let vm = ChatViewModel(chatRepository: mockRepository, orchestrator: capturingOrchestrator)
        mockRepository.createdConversationToReturn = Conversation(title: "New")
        vm.inputText = "General question"

        // When
        await vm.beginTurn()
        try? await Task.sleep(for: .milliseconds(200))

        // Then — request context should be nil
        XCTAssertNotNil(capturingOrchestrator.lastRequest)
        XCTAssertNil(capturingOrchestrator.lastRequest?.context)
    }

    // MARK: - Dismiss Error Tests

    func test_dismissError_clearsGenerationError() {
        // Given — generation error is set
        sut.generationError = TestError.sendFailed

        // When
        sut.dismissError()

        // Then
        XCTAssertNil(sut.generationError)
    }

    // MARK: - Retry Tests

    func test_retryLastMessage_sendsNewTurn() async {
        // Given — a conversation with a user message and a failed assistant message
        let conversation = Conversation(title: "Test")
        mockRepository.createdConversationToReturn = conversation
        sut.activeConversation = conversation
        sut.messages = [
            ChatMessage(conversationId: conversation.id, role: .user, content: "What is wudu?"),
            ChatMessage(conversationId: conversation.id, role: .assistant, content: "I apologize, but I encountered an error.", status: .complete)
        ]
        sut.generationError = TestError.sendFailed

        // When
        await sut.retryLastMessage()

        // Then — generation error cleared, fresh conversation with retried Q&A pair
        XCTAssertNil(sut.generationError)
        // Single-turn: fresh conversation clears old messages, retried pair is the only content
        let userMessages = sut.messages.filter { $0.role == .user }
        XCTAssertEqual(userMessages.count, 1, "Retry in single-turn mode should have exactly 1 user message")
        XCTAssertEqual(userMessages.first?.content, "What is wudu?")
    }

    func test_retryLastMessage_clearsError() async {
        // Given
        let conversation = Conversation(title: "Test")
        mockRepository.createdConversationToReturn = conversation
        sut.activeConversation = conversation
        sut.messages = [
            ChatMessage(conversationId: conversation.id, role: .user, content: "Question")
        ]
        sut.generationError = TestError.sendFailed

        // When
        await sut.retryLastMessage()

        // Then
        XCTAssertNil(sut.generationError)
    }

    func test_retryLastMessage_noUserMessages_doesNothing() async {
        // Given — no messages at all
        sut.messages = []
        sut.generationError = TestError.sendFailed

        // When
        await sut.retryLastMessage()

        // Then — no crash, generationError remains (retry was a no-op)
        XCTAssertNotNil(sut.generationError)
        XCTAssertTrue(sut.messages.isEmpty)
    }

    // MARK: - Stop/Abort Tests

    func test_abortTurn_marksCurrentTurnAssistantAsAborted() {
        // Given — a streaming assistant message with currentTurnAssistantId set
        let conversationId = UUID()
        let assistantMsg = ChatMessage(conversationId: conversationId, role: .assistant, content: "Partial response...", status: .streaming)
        sut.isGenerating = true
        sut.currentTurnAssistantId = assistantMsg.id
        sut.messages = [
            ChatMessage(conversationId: conversationId, role: .user, content: "Question"),
            assistantMsg
        ]

        // When
        sut.abortTurn()

        // Then — current turn's assistant message should have .aborted status
        XCTAssertFalse(sut.isGenerating)
        XCTAssertNil(sut.currentTurnAssistantId)
        let lastAssistant = sut.messages.last(where: { $0.isAssistant })
        XCTAssertEqual(lastAssistant?.status, .aborted)
        XCTAssertEqual(lastAssistant?.content, "Partial response...")
    }

    func test_abortTurn_withoutCurrentTurnId_doesNotCorruptOldMessages() {
        // Given — isGenerating is true but currentTurnAssistantId is nil
        // (e.g. stop tapped during conversation creation, before placeholder appended)
        let conversationId = UUID()
        sut.isGenerating = true
        sut.currentTurnAssistantId = nil
        sut.messages = [
            ChatMessage(conversationId: conversationId, role: .user, content: "Old question"),
            ChatMessage(conversationId: conversationId, role: .assistant, content: "Old complete answer", status: .complete)
        ]

        // When
        sut.abortTurn()

        // Then — old assistant message should NOT be modified
        let lastAssistant = sut.messages.last(where: { $0.isAssistant })
        XCTAssertEqual(lastAssistant?.status, .complete, "Old message should not be corrupted")
        XCTAssertEqual(lastAssistant?.content, "Old complete answer")
    }

    // MARK: - Force Error Tests

    func test_forceError_setsErrorState() async {
        // Given — ViewModel with orchestrator and forceError flag
        let capturingOrchestrator = CapturingChatOrchestrator()
        let vm = ChatViewModel(chatRepository: mockRepository, orchestrator: capturingOrchestrator)
        mockRepository.createdConversationToReturn = Conversation(title: "New")
        vm.inputText = "Test question"
        vm.forceError = true

        // When
        await vm.beginTurn()
        // Allow the streaming task to complete
        try? await Task.sleep(for: .milliseconds(300))

        // Then — generation error should be set
        XCTAssertNotNil(vm.generationError)
        XCTAssertFalse(vm.isGenerating)
    }

    // MARK: - Prefill + Context Ordering Tests (Gap 1)

    func test_prefillAndSend_withPendingContext_sendsTextAndContextTogether() async {
        // Given — simulate the ChatView .task flow: set context, then prefillAndSend
        let capturingOrchestrator = CapturingChatOrchestrator()
        let vm = ChatViewModel(chatRepository: mockRepository, orchestrator: capturingOrchestrator)
        mockRepository.createdConversationToReturn = Conversation(title: "New")

        // Set context first (simulating ChatView reading pendingChatContext)
        vm.pendingContext = ChatContext(topic: .quran, surahNumber: 2, ayahNumber: 255)

        // When — prefillAndSend (simulating ChatView reading pendingChatInput)
        vm.prefillAndSend("Explain Al-Baqarah 2:255")

        // Allow the fire-and-forget Task inside prefillAndSend to complete
        try? await Task.sleep(for: .milliseconds(300))

        // Then — orchestrator should have received BOTH the text and context
        XCTAssertNotNil(capturingOrchestrator.lastRequest, "Orchestrator should have received a request")
        XCTAssertEqual(capturingOrchestrator.lastRequest?.text, "Explain Al-Baqarah 2:255")
        XCTAssertEqual(capturingOrchestrator.lastRequest?.context?.topic, .quran)
        XCTAssertEqual(capturingOrchestrator.lastRequest?.context?.surahNumber, 2)
        XCTAssertEqual(capturingOrchestrator.lastRequest?.context?.ayahNumber, 255)
    }

    func test_prefillAndSend_withoutContext_sendsTextOnly() async {
        // Given — no pending context (Siri path: only text, no context)
        let capturingOrchestrator = CapturingChatOrchestrator()
        let vm = ChatViewModel(chatRepository: mockRepository, orchestrator: capturingOrchestrator)
        mockRepository.createdConversationToReturn = Conversation(title: "New")

        // When — prefillAndSend without setting context
        vm.prefillAndSend("How many rakats in Fajr?")
        try? await Task.sleep(for: .milliseconds(300))

        // Then — text sent, context is nil
        XCTAssertNotNil(capturingOrchestrator.lastRequest)
        XCTAssertEqual(capturingOrchestrator.lastRequest?.text, "How many rakats in Fajr?")
        XCTAssertNil(capturingOrchestrator.lastRequest?.context)
    }
}

// MARK: - Capturing Chat Orchestrator

/// Test double that captures the ChatRequest for inspection without performing real LLM work.
@MainActor
final class CapturingChatOrchestrator: ChatOrchestratorProtocol {
    var lastRequest: ChatRequest?

    nonisolated func process(_ request: ChatRequest) -> AsyncThrowingStream<OrchestratorEvent, Error> {
        // Capture on main actor
        let stream = AsyncThrowingStream<OrchestratorEvent, Error> { continuation in
            Task { @MainActor in
                self.lastRequest = request
                continuation.yield(.completed(AIResponse(
                    answer: "Test response",
                    citations: [],
                    confidence: .low
                )))
                continuation.finish()
            }
        }
        return stream
    }
}

// MARK: - Test Error

private enum TestError: Error {
    case loadFailed
    case sendFailed
    case createFailed
    case clearFailed
}

// MARK: - Testable Chat Repository

@MainActor
final class TestableChatRepository: ChatRepositoryProtocol {
    var activeConversationToReturn: Conversation?
    var conversationsToReturn: [Conversation] = []
    var messagesToReturn: [ChatMessage] = []
    var createdConversationToReturn: Conversation?
    var savedMessages: [ChatMessage] = []
    var errorToThrow: Error?

    nonisolated func getConversations() async throws -> [Conversation] {
        let error = await errorToThrow
        if let error {
            throw error
        }
        return await conversationsToReturn
    }

    nonisolated func getConversation(id conversationId: String) async throws -> Conversation? {
        return await conversationsToReturn.first { $0.id.uuidString == conversationId }
    }

    nonisolated func getMessages(forConversation conversationId: String) async throws -> [ChatMessage] {
        return await messagesToReturn
    }

    nonisolated func createConversation() async throws -> Conversation {
        let error = await errorToThrow
        let created = await createdConversationToReturn
        if let error {
            throw error
        }
        return created ?? Conversation()
    }

    nonisolated func deleteConversation(id conversationId: String) async throws {
        let error = await errorToThrow
        if let error {
            throw error
        }
    }

    nonisolated func setActiveConversation(id conversationId: String) async throws {
        let error = await errorToThrow
        if let error {
            throw error
        }
    }

    nonisolated func getActiveConversation() async throws -> Conversation? {
        let error = await errorToThrow
        if let error {
            throw error
        }
        return await activeConversationToReturn
    }

    nonisolated func saveMessage(_ message: ChatMessage) async throws {
        let error = await errorToThrow
        if let error {
            throw error
        }
        await MainActor.run { savedMessages.append(message) }
    }

    nonisolated func updateConversation(_ conversation: Conversation) async throws {
        let error = await errorToThrow
        if let error {
            throw error
        }
    }

    var feedbackUpdates: [(messageId: UUID, rating: Int16)] = []

    nonisolated func updateFeedback(messageId: UUID, rating: Int16) async throws {
        let error = await errorToThrow
        if let error {
            throw error
        }
        await MainActor.run { feedbackUpdates.append((messageId: messageId, rating: rating)) }
    }

    nonisolated func clearHistory() async throws {
        let error = await errorToThrow
        if let error {
            throw error
        }
    }
}
