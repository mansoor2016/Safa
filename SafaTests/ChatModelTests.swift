// MARK: - ChatModelTests.swift
// PURPOSE: Unit tests for Chat domain entities

import XCTest
@testable import Safa

final class ChatModelTests: XCTestCase {

    // MARK: - Conversation Tests

    func testConversationCreation() {
        let conversation = Conversation()

        XCTAssertNotNil(conversation.id)
        XCTAssertNil(conversation.title)
        XCTAssertEqual(conversation.messageCount, 0)
        XCTAssertNotNil(conversation.createdAt)
        XCTAssertNotNil(conversation.updatedAt)
    }

    func testConversationWithTitle() {
        let conversation = Conversation(
            title: "Questions about Ramadan",
            messageCount: 5
        )

        XCTAssertEqual(conversation.title, "Questions about Ramadan")
        XCTAssertEqual(conversation.messageCount, 5)
    }

    func testConversationDisplayTitle() {
        let withTitle = Conversation(title: "My Conversation")
        let withoutTitle = Conversation()

        XCTAssertEqual(withTitle.displayTitle, "My Conversation")
        XCTAssertEqual(withoutTitle.displayTitle, "New Conversation")
    }

    func testConversationCodable() throws {
        let original = Conversation(
            title: "Test Conversation",
            messageCount: 10
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Conversation.self, from: data)

        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.messageCount, original.messageCount)
    }

    // MARK: - ChatMessage Tests

    func testChatMessageCreation() {
        let conversationId = UUID()
        let message = ChatMessage(
            conversationId: conversationId,
            role: .user,
            content: "What is the dua before eating?"
        )

        XCTAssertNotNil(message.id)
        XCTAssertEqual(message.conversationId, conversationId)
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "What is the dua before eating?")
        XCTAssertNotNil(message.timestamp)
    }

    func testChatMessageRoles() {
        XCTAssertEqual(ChatMessage.Role.user.rawValue, "user")
        XCTAssertEqual(ChatMessage.Role.assistant.rawValue, "assistant")
        XCTAssertEqual(ChatMessage.Role.system.rawValue, "system")
    }

    func testChatMessageIsUser() {
        let userMessage = ChatMessage(
            conversationId: UUID(),
            role: .user,
            content: "Hello"
        )
        let assistantMessage = ChatMessage(
            conversationId: UUID(),
            role: .assistant,
            content: "Hello!"
        )

        XCTAssertTrue(userMessage.isUser)
        XCTAssertFalse(userMessage.isAssistant)
        XCTAssertFalse(assistantMessage.isUser)
        XCTAssertTrue(assistantMessage.isAssistant)
    }

    func testChatMessageCodable() throws {
        let original = ChatMessage(
            conversationId: UUID(),
            role: .assistant,
            content: "Bismillah - In the name of Allah"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ChatMessage.self, from: data)

        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.content, original.content)
    }

    // MARK: - ChatError Tests

    func testChatErrorDescriptions() {
        XCTAssertNotNil(ChatError.modelNotLoaded.errorDescription)
        XCTAssertNotNil(ChatError.generationFailed("test").errorDescription)
        XCTAssertNotNil(ChatError.conversationNotFound.errorDescription)
        XCTAssertNotNil(ChatError.messageTooLong.errorDescription)

        XCTAssertTrue(ChatError.modelNotLoaded.errorDescription!.contains("not loaded"))
        XCTAssertTrue(ChatError.generationFailed("reason").errorDescription!.contains("reason"))
        XCTAssertTrue(ChatError.conversationNotFound.errorDescription!.contains("not found"))
        XCTAssertTrue(ChatError.messageTooLong.errorDescription!.contains("too long"))
    }

    // MARK: - ChatSession Tests

    func testChatSessionCreation() {
        let session = ChatSession(title: "New Chat")

        XCTAssertFalse(session.id.isEmpty)
        XCTAssertEqual(session.title, "New Chat")
        XCTAssertTrue(session.messages.isEmpty)
    }

    func testChatSessionWithMessages() {
        let message1 = SimpleChatMessage(role: .user, content: "Hello")
        let message2 = SimpleChatMessage(role: .assistant, content: "Hi!")

        let session = ChatSession(
            title: "Test Session",
            messages: [message1, message2]
        )

        XCTAssertEqual(session.messages.count, 2)
        XCTAssertEqual(session.messages[0].role, .user)
        XCTAssertEqual(session.messages[1].role, .assistant)
    }

    func testChatSessionCodable() throws {
        let original = ChatSession(
            title: "Encoded Session",
            messages: [
                SimpleChatMessage(role: .user, content: "Test")
            ]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ChatSession.self, from: data)

        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.messages.count, original.messages.count)
    }

    // MARK: - SimpleChatMessage Tests

    func testSimpleChatMessageCreation() {
        let message = SimpleChatMessage(
            role: .user,
            content: "What time is Fajr?"
        )

        XCTAssertFalse(message.id.isEmpty)
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "What time is Fajr?")
        XCTAssertNotNil(message.timestamp)
    }

    func testSimpleChatMessageCodable() throws {
        let original = SimpleChatMessage(
            role: .assistant,
            content: "Fajr is at 5:30 AM"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SimpleChatMessage.self, from: data)

        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.content, original.content)
    }

    // MARK: - ChatTopic Tests

    func testChatTopicAllCases() {
        XCTAssertEqual(ChatTopic.allCases.count, 5)
        XCTAssertTrue(ChatTopic.allCases.contains(.general))
        XCTAssertTrue(ChatTopic.allCases.contains(.quran))
        XCTAssertTrue(ChatTopic.allCases.contains(.hadith))
        XCTAssertTrue(ChatTopic.allCases.contains(.fiqh))
        XCTAssertTrue(ChatTopic.allCases.contains(.seerah))
    }

    func testChatTopicDisplayNames() {
        XCTAssertEqual(ChatTopic.general.displayName, "General")
        XCTAssertEqual(ChatTopic.quran.displayName, "Quran")
        XCTAssertEqual(ChatTopic.hadith.displayName, "Hadith")
        XCTAssertEqual(ChatTopic.fiqh.displayName, "Fiqh")
        XCTAssertEqual(ChatTopic.seerah.displayName, "Seerah")
    }

    func testChatTopicRawValues() {
        XCTAssertEqual(ChatTopic.general.rawValue, "general")
        XCTAssertEqual(ChatTopic.quran.rawValue, "quran")
        XCTAssertEqual(ChatTopic.hadith.rawValue, "hadith")
        XCTAssertEqual(ChatTopic.fiqh.rawValue, "fiqh")
        XCTAssertEqual(ChatTopic.seerah.rawValue, "seerah")
    }

    // MARK: - ChatContext Tests

    func testChatContextCreation() {
        let context = ChatContext(topic: .quran)

        XCTAssertEqual(context.topic, .quran)
        XCTAssertNil(context.surahNumber)
        XCTAssertNil(context.ayahNumber)
        XCTAssertNil(context.hadithId)
    }

    func testChatContextWithQuranReference() {
        let context = ChatContext(
            topic: .quran,
            surahNumber: 2,
            ayahNumber: 255
        )

        XCTAssertEqual(context.topic, .quran)
        XCTAssertEqual(context.surahNumber, 2)
        XCTAssertEqual(context.ayahNumber, 255)
        XCTAssertNil(context.hadithId)
    }

    func testChatContextWithHadithReference() {
        let context = ChatContext(
            topic: .hadith,
            hadithId: "bukhari:1"
        )

        XCTAssertEqual(context.topic, .hadith)
        XCTAssertNil(context.surahNumber)
        XCTAssertEqual(context.hadithId, "bukhari:1")
    }

    func testChatContextCodable() throws {
        let original = ChatContext(
            topic: .fiqh,
            surahNumber: 5,
            ayahNumber: 6
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ChatContext.self, from: data)

        XCTAssertEqual(decoded.topic, original.topic)
        XCTAssertEqual(decoded.surahNumber, original.surahNumber)
        XCTAssertEqual(decoded.ayahNumber, original.ayahNumber)
    }

    // MARK: - SuggestedQuestion Tests

    func testSuggestedQuestionCreation() {
        let question = SuggestedQuestion(
            text: "What is the meaning of Bismillah?",
            category: "General"
        )

        XCTAssertFalse(question.id.isEmpty)
        XCTAssertEqual(question.text, "What is the meaning of Bismillah?")
        XCTAssertEqual(question.category, "General")
    }

    func testSuggestedQuestionCodable() throws {
        let original = SuggestedQuestion(
            text: "How do I perform wudu?",
            category: "Fiqh"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SuggestedQuestion.self, from: data)

        XCTAssertEqual(decoded.text, original.text)
        XCTAssertEqual(decoded.category, original.category)
    }
}
