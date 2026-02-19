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
        // Given
        sut.isGenerating = true

        // When
        sut.abortTurn()

        // Then
        XCTAssertFalse(sut.isGenerating)
        XCTAssertTrue(sut.isAborted)
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

    nonisolated func clearHistory() async throws {
        let error = await errorToThrow
        if let error {
            throw error
        }
    }
}
