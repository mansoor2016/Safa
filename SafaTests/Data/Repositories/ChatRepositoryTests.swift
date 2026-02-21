// MARK: - ChatRepositoryTests.swift
// PURPOSE: Unit tests for ChatRepository — Core Data persistence, migration, and deletion
// DEPENDENCIES: XCTest, CoreData, Safa

import XCTest
import CoreData
@testable import Safa

final class ChatRepositoryTests: XCTestCase {

    private var sut: ChatRepository!

    // MARK: - Helpers

    private func cleanUserDefaults() {
        UserDefaults.standard.removeObject(forKey: AppConstants.StorageKeys.chatMigratedToCoreData)
        UserDefaults.standard.removeObject(forKey: AppConstants.StorageKeys.chatConversations)
        UserDefaults.standard.removeObject(forKey: AppConstants.StorageKeys.chatActiveConversation)
        UserDefaults.standard.removeObject(forKey: "chat_migration_retry_count")
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix(AppConstants.StorageKeys.chatMessagesPrefix) {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    /// Deletes all chat objects from Core Data via fetch-and-delete (works with in-memory stores).
    private func cleanCoreData() {
        let context = CoreDataStack.shared.viewContext
        let convRequest: NSFetchRequest<ChatConversationMO> = ChatConversationMO.fetchRequest()
        if let results = try? context.fetch(convRequest) {
            for obj in results { context.delete(obj) }
        }
        let msgRequest: NSFetchRequest<ChatMessageMO> = ChatMessageMO.fetchRequest()
        if let results = try? context.fetch(msgRequest) {
            for obj in results { context.delete(obj) }
        }
        try? context.save()
    }

    override func setUp() {
        super.setUp()
        cleanUserDefaults()
        cleanCoreData()
        // Set migration flag so sut init doesn't run migration
        UserDefaults.standard.set(true, forKey: AppConstants.StorageKeys.chatMigratedToCoreData)
        sut = ChatRepository(coreData: .shared)
    }

    override func tearDown() {
        sut = nil
        cleanCoreData()
        cleanUserDefaults()
        super.tearDown()
    }

    // MARK: - Round-Trip Persistence

    func test_createAndFetchConversation_roundTrips() async throws {
        let created = try await sut.createConversation()
        let conversations = try await sut.getConversations()

        XCTAssertEqual(conversations.count, 1)
        XCTAssertEqual(conversations.first?.id, created.id)
    }

    func test_saveAndFetchMessage_roundTrips() async throws {
        let conversation = try await sut.createConversation()
        let message = ChatMessage(
            conversationId: conversation.id,
            role: .user,
            content: "What is wudu?"
        )

        try await sut.saveMessage(message)
        let messages = try await sut.getMessages(forConversation: conversation.id.uuidString)

        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages.first?.content, "What is wudu?")
        XCTAssertEqual(messages.first?.role, .user)
        XCTAssertEqual(messages.first?.id, message.id)
    }

    func test_saveMessage_withCitationsAndStatus_roundTrips() async throws {
        let conversation = try await sut.createConversation()
        let citations = [
            Citation(source: "Quran", reference: "Al-Baqarah 2:255", verified: true),
            Citation(source: "Sahih al-Bukhari", reference: "Hadith 1", verified: false)
        ]
        let message = ChatMessage(
            conversationId: conversation.id,
            role: .assistant,
            content: "Ayat al-Kursi is about sovereignty.",
            citations: citations,
            status: .complete
        )

        try await sut.saveMessage(message)
        let messages = try await sut.getMessages(forConversation: conversation.id.uuidString)

        let fetched = try XCTUnwrap(messages.first)
        XCTAssertEqual(fetched.citations.count, 2)
        XCTAssertEqual(fetched.citations[0].source, "Quran")
        XCTAssertEqual(fetched.citations[0].verified, true)
        XCTAssertEqual(fetched.citations[1].verified, false)
        XCTAssertEqual(fetched.status, .complete)
    }

    func test_saveMessage_updatesExistingMessage() async throws {
        let conversation = try await sut.createConversation()
        let message = ChatMessage(
            conversationId: conversation.id,
            role: .assistant,
            content: "Partial response...",
            status: .streaming
        )
        try await sut.saveMessage(message)

        // Update same message with final content
        let updated = ChatMessage(
            id: message.id,
            conversationId: conversation.id,
            role: .assistant,
            content: "Final complete response.",
            status: .complete
        )
        try await sut.saveMessage(updated)
        let messages = try await sut.getMessages(forConversation: conversation.id.uuidString)

        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages.first?.content, "Final complete response.")
        XCTAssertEqual(messages.first?.status, .complete)
    }

    // MARK: - Delete Operations

    func test_deleteConversation_removesConversationAndMessages() async throws {
        let conversation = try await sut.createConversation()
        let message = ChatMessage(conversationId: conversation.id, role: .user, content: "Test")
        try await sut.saveMessage(message)

        try await sut.deleteConversation(id: conversation.id.uuidString)

        let conversations = try await sut.getConversations()
        let messages = try await sut.getMessages(forConversation: conversation.id.uuidString)
        XCTAssertTrue(conversations.isEmpty)
        XCTAssertTrue(messages.isEmpty)
    }

    func test_clearHistory_clearsAllConversations() async throws {
        let conv1 = try await sut.createConversation()
        let conv2 = try await sut.createConversation()
        try await sut.saveMessage(ChatMessage(conversationId: conv1.id, role: .user, content: "Msg 1"))
        try await sut.saveMessage(ChatMessage(conversationId: conv2.id, role: .user, content: "Msg 2"))

        try await sut.clearHistory()

        let conversations = try await sut.getConversations()
        XCTAssertTrue(conversations.isEmpty, "All conversations should be deleted after clearHistory")
    }

    func test_deleteAllData_clearsLegacyUserDefaultsKeys() async throws {
        // Set some legacy keys
        UserDefaults.standard.set(Data(), forKey: AppConstants.StorageKeys.chatConversations)
        UserDefaults.standard.set("test", forKey: AppConstants.StorageKeys.chatMessagesPrefix + "abc")
        UserDefaults.standard.set(true, forKey: AppConstants.StorageKeys.chatMigratedToCoreData)

        try await sut.deleteAllData()

        XCTAssertNil(UserDefaults.standard.data(forKey: AppConstants.StorageKeys.chatConversations))
        XCTAssertNil(UserDefaults.standard.string(forKey: AppConstants.StorageKeys.chatMessagesPrefix + "abc"))
        XCTAssertFalse(UserDefaults.standard.bool(forKey: AppConstants.StorageKeys.chatMigratedToCoreData))
    }

    // MARK: - Feedback Persistence

    func test_updateFeedback_roundTrips() async throws {
        let conversation = try await sut.createConversation()
        let message = ChatMessage(
            conversationId: conversation.id,
            role: .assistant,
            content: "Test response",
            status: .complete
        )
        try await sut.saveMessage(message)

        // When — update feedback to thumbs up
        try await sut.updateFeedback(messageId: message.id, rating: 1)

        // Then — fetch and verify
        let messages = try await sut.getMessages(forConversation: conversation.id.uuidString)
        let fetched = try XCTUnwrap(messages.first)
        XCTAssertEqual(fetched.feedbackRating, 1)
    }

    func test_updateFeedback_togglesOff() async throws {
        let conversation = try await sut.createConversation()
        let message = ChatMessage(
            conversationId: conversation.id,
            role: .assistant,
            content: "Test response",
            status: .complete
        )
        try await sut.saveMessage(message)

        // When — set to 1, then reset to 0
        try await sut.updateFeedback(messageId: message.id, rating: 1)
        try await sut.updateFeedback(messageId: message.id, rating: 0)

        // Then — should be reset
        let messages = try await sut.getMessages(forConversation: conversation.id.uuidString)
        let fetched = try XCTUnwrap(messages.first)
        XCTAssertEqual(fetched.feedbackRating, 0)
    }

    // MARK: - Active Conversation

    func test_createConversation_setsAsActive() async throws {
        let conversation = try await sut.createConversation()
        let active = try await sut.getActiveConversation()

        XCTAssertEqual(active?.id, conversation.id)
    }

    // MARK: - Legacy Pre-Migration Row Safety

    func test_preMigrationRow_userRole_fallsBack() throws {
        let context = CoreDataStack.shared.viewContext

        let conversationMO = ChatConversationMO(context: context)
        conversationMO.id = UUID()
        conversationMO.createdAt = Date()
        conversationMO.updatedAt = Date()

        let messageMO = ChatMessageMO(context: context)
        messageMO.id = UUID()
        messageMO.content = "Legacy message"
        messageMO.timestamp = Date()
        messageMO.isFromUser = true
        messageMO.conversation = conversationMO
        // Simulate pre-migration row: nil out fields that wouldn't exist in old schema.
        // Core Data auto-sets defaults on insert, so explicit nil is needed.
        messageMO.role = nil
        messageMO.status = nil
        messageMO.citationsJSON = nil

        try context.save()

        let domain = messageMO.toDomain()
        XCTAssertEqual(domain.role, .user, "Should fall back to isFromUser for legacy rows")
        XCTAssertEqual(domain.status, .complete, "Should default to .complete")
        XCTAssertEqual(domain.feedbackRating, 0, "Should default to 0")
        XCTAssertTrue(domain.citations.isEmpty, "Should default to empty citations")
    }

    func test_preMigrationRow_assistantRole_fallsBack() throws {
        let context = CoreDataStack.shared.viewContext

        let conversationMO = ChatConversationMO(context: context)
        conversationMO.id = UUID()
        conversationMO.createdAt = Date()
        conversationMO.updatedAt = Date()

        let messageMO = ChatMessageMO(context: context)
        messageMO.id = UUID()
        messageMO.content = "AI response"
        messageMO.timestamp = Date()
        messageMO.isFromUser = false
        messageMO.conversation = conversationMO
        // Simulate pre-migration row: nil out role so legacy fallback triggers
        messageMO.role = nil

        try context.save()

        let domain = messageMO.toDomain()
        XCTAssertEqual(domain.role, .assistant, "Should fall back to .assistant when isFromUser is false")
    }

    // MARK: - Migration

    func test_migration_emptyUserDefaults_setsFlagImmediately() async throws {
        // Tear down existing sut to avoid two repos on same stack
        sut = nil
        cleanUserDefaults()
        cleanCoreData()
        // Ensure flag is not set
        UserDefaults.standard.removeObject(forKey: AppConstants.StorageKeys.chatMigratedToCoreData)

        let repo = ChatRepository(coreData: .shared)

        // Verify migration set the flag immediately when nothing to migrate
        XCTAssertTrue(
            UserDefaults.standard.bool(forKey: AppConstants.StorageKeys.chatMigratedToCoreData),
            "Flag should be set when there's nothing to migrate"
        )

        // Verify no conversations were created
        let conversations = try await repo.getConversations()
        XCTAssertTrue(conversations.isEmpty, "No conversations should exist after empty migration")
    }

    func test_migration_withLegacyData_migratesAndSetsFlag() async throws {
        sut = nil
        cleanUserDefaults()
        cleanCoreData()

        let conversation = Conversation(title: "Test Chat")
        let message = ChatMessage(conversationId: conversation.id, role: .user, content: "Legacy message")

        let convData = try JSONEncoder().encode([conversation])
        let msgData = try JSONEncoder().encode([message])

        UserDefaults.standard.set(convData, forKey: AppConstants.StorageKeys.chatConversations)
        UserDefaults.standard.set(msgData, forKey: AppConstants.StorageKeys.chatMessagesPrefix + conversation.id.uuidString)

        let repo = ChatRepository(coreData: .shared)

        XCTAssertTrue(
            UserDefaults.standard.bool(forKey: AppConstants.StorageKeys.chatMigratedToCoreData),
            "Flag should be set after successful migration"
        )

        let conversations = try await repo.getConversations()
        XCTAssertFalse(conversations.isEmpty, "Should have migrated at least one conversation")

        let messages = try await repo.getMessages(forConversation: conversation.id.uuidString)
        XCTAssertEqual(messages.first?.content, "Legacy message")
    }

    func test_migration_alreadyMigrated_skips() async throws {
        sut = nil
        cleanUserDefaults()
        cleanCoreData()
        UserDefaults.standard.set(true, forKey: AppConstants.StorageKeys.chatMigratedToCoreData)

        let conversation = Conversation(title: "Should Not Migrate")
        let convData = try JSONEncoder().encode([conversation])
        UserDefaults.standard.set(convData, forKey: AppConstants.StorageKeys.chatConversations)

        let repo = ChatRepository(coreData: .shared)

        let conversations = try await repo.getConversations()
        XCTAssertTrue(conversations.isEmpty, "Should skip migration when flag is already set")
    }
}
