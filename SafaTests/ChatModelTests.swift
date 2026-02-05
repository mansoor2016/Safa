// MARK: - ChatModelTests.swift
// PURPOSE: Unit tests for Chat domain models
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class ChatModelTests: XCTestCase {

    // MARK: - Chat Message Tests

    func testChatMessageUserInitialization() {
        let conversationId = UUID()
        let message = ChatMessage(
            conversationId: conversationId,
            role: .user,
            content: "What is the significance of Ramadan?"
        )

        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "What is the significance of Ramadan?")
        XCTAssertNotNil(message.timestamp)
    }

    func testChatMessageAssistantInitialization() {
        let conversationId = UUID()
        let message = ChatMessage(
            conversationId: conversationId,
            role: .assistant,
            content: "Ramadan is the ninth month of the Islamic calendar..."
        )

        XCTAssertEqual(message.role, .assistant)
        XCTAssertFalse(message.content.isEmpty)
    }

    func testChatMessageRoles() {
        XCTAssertEqual(MessageRole.user.rawValue, "user")
        XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
        XCTAssertEqual(MessageRole.system.rawValue, "system")
    }

    // MARK: - Simple Chat Message Tests

    func testSimpleChatMessageInitialization() {
        let message = SimpleChatMessage(
            role: .user,
            content: "Hello"
        )

        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Hello")
        XCTAssertFalse(message.id.isEmpty)
    }

    // MARK: - Chat Session Tests

    func testChatSessionInitialization() {
        let session = ChatSession(
            title: "Learning about Prayer"
        )

        XCTAssertEqual(session.title, "Learning about Prayer")
        XCTAssertNotNil(session.createdAt)
        XCTAssertTrue(session.messages.isEmpty)
    }

    func testChatSessionWithMessages() {
        var session = ChatSession(title: "Test Session")

        let userMessage = SimpleChatMessage(role: .user, content: "Hello")
        let assistantMessage = SimpleChatMessage(role: .assistant, content: "Hello! How can I help?")

        session.messages.append(userMessage)
        session.messages.append(assistantMessage)

        XCTAssertEqual(session.messages.count, 2)
        XCTAssertEqual(session.messages.first?.role, .user)
        XCTAssertEqual(session.messages.last?.role, .assistant)
    }

    func testChatSessionLastMessage() {
        var session = ChatSession(title: "Test")

        XCTAssertNil(session.messages.last)

        session.messages.append(SimpleChatMessage(role: .user, content: "Test message"))

        XCTAssertNotNil(session.messages.last)
        XCTAssertEqual(session.messages.last?.content, "Test message")
    }

    // MARK: - Chat Context Tests

    func testChatContextInitialization() {
        let context = ChatContext(
            topic: .quran,
            surahNumber: 1,
            ayahNumber: 5
        )

        XCTAssertEqual(context.topic, .quran)
        XCTAssertEqual(context.surahNumber, 1)
        XCTAssertEqual(context.ayahNumber, 5)
    }

    func testChatContextTopics() {
        XCTAssertEqual(ChatTopic.general.rawValue, "general")
        XCTAssertEqual(ChatTopic.quran.rawValue, "quran")
        XCTAssertEqual(ChatTopic.hadith.rawValue, "hadith")
        XCTAssertEqual(ChatTopic.fiqh.rawValue, "fiqh")
        XCTAssertEqual(ChatTopic.seerah.rawValue, "seerah")
    }

    // MARK: - Suggested Question Tests

    func testSuggestedQuestionInitialization() {
        let question = SuggestedQuestion(
            text: "What are the pillars of Islam?",
            category: "Basics"
        )

        XCTAssertEqual(question.text, "What are the pillars of Islam?")
        XCTAssertEqual(question.category, "Basics")
    }

    // MARK: - Conversation Tests

    func testConversationInitialization() {
        let conversation = Conversation(title: "Test Conversation")

        XCTAssertEqual(conversation.displayTitle, "Test Conversation")
        XCTAssertNotNil(conversation.createdAt)
    }

    func testConversationDefaultTitle() {
        let conversation = Conversation()

        XCTAssertEqual(conversation.displayTitle, "New Conversation")
    }

    // MARK: - Encoding/Decoding Tests

    func testChatMessageCodable() throws {
        let conversationId = UUID()
        let original = ChatMessage(
            conversationId: conversationId,
            role: .user,
            content: "Test content"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ChatMessage.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.role, decoded.role)
        XCTAssertEqual(original.content, decoded.content)
    }

    func testChatSessionCodable() throws {
        var original = ChatSession(title: "Test Session")
        original.messages.append(SimpleChatMessage(role: .user, content: "Hello"))

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ChatSession.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.title, decoded.title)
        XCTAssertEqual(original.messages.count, decoded.messages.count)
    }

    // MARK: - Chat Error Tests

    func testChatErrorDescriptions() {
        XCTAssertNotNil(ChatError.modelNotLoaded.errorDescription)
        XCTAssertNotNil(ChatError.conversationNotFound.errorDescription)
        XCTAssertNotNil(ChatError.messageTooLong.errorDescription)
        XCTAssertNotNil(ChatError.generationFailed("test").errorDescription)
    }
}
