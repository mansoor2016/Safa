// MARK: - ChatRepository.swift
// PURPOSE: Core Data persistence layer for AI chat conversations and messages
// DATA SOURCE: Core Data (with one-time migration from UserDefaults)
// NOTE: Generation/inference logic moved to ChatOrchestrator. This is persist-only.

import Foundation
import CoreData

final class ChatRepository: ChatRepositoryProtocol {
    // MARK: - Dependencies
    private let coreData: CoreDataStack

    // MARK: - Legacy Storage Keys (for migration)
    private let conversationsKey = AppConstants.StorageKeys.chatConversations
    private let messagesKeyPrefix = AppConstants.StorageKeys.chatMessagesPrefix
    private let activeConversationKey = AppConstants.StorageKeys.chatActiveConversation
    private let migrationFlagKey = AppConstants.StorageKeys.chatMigratedToCoreData

    // MARK: - Init
    init(coreData: CoreDataStack = .shared) {
        self.coreData = coreData
        migrateFromUserDefaultsIfNeeded()
    }

    // MARK: - Conversations

    func getConversations() async throws -> [Conversation] {
        try await coreData.viewContext.perform {
            let request = ChatConversationMO.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            let results = try self.coreData.viewContext.fetch(request)
            return results.map { $0.toDomain() }
        }
    }

    func getConversation(id conversationId: String) async throws -> Conversation? {
        guard let uuid = UUID(uuidString: conversationId) else { return nil }
        return try await coreData.viewContext.perform {
            try self.fetchConversationMO(id: uuid)?.toDomain()
        }
    }

    func getMessages(forConversation conversationId: String) async throws -> [ChatMessage] {
        guard let uuid = UUID(uuidString: conversationId) else { return [] }
        return try await coreData.viewContext.perform {
            guard let conversationMO = try self.fetchConversationMO(id: uuid) else { return [] }
            let messageSet = conversationMO.messages as? Set<ChatMessageMO> ?? []
            return messageSet
                .map { $0.toDomain() }
                .sorted { $0.timestamp < $1.timestamp }
        }
    }

    func createConversation() async throws -> Conversation {
        let conversation = Conversation()
        try await coreData.viewContext.perform {
            let conversationMO = ChatConversationMO(context: self.coreData.viewContext)
            conversationMO.update(from: conversation)
            try self.coreData.viewContext.saveIfNeeded()
        }

        // Set as active (UserDefaults is thread-safe)
        UserDefaults.standard.set(conversation.id.uuidString, forKey: activeConversationKey)

        return conversation
    }

    func deleteConversation(id conversationId: String) async throws {
        guard let uuid = UUID(uuidString: conversationId) else { return }
        try await coreData.viewContext.perform {
            if let conversationMO = try self.fetchConversationMO(id: uuid) {
                self.coreData.viewContext.delete(conversationMO)
                try self.coreData.viewContext.saveIfNeeded()
            }
        }

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

    // MARK: - Messages

    func saveMessage(_ message: ChatMessage) async throws {
        try await coreData.viewContext.perform {
            guard let conversationMO = try self.fetchConversationMO(id: message.conversationId) else {
                throw ChatError.conversationNotFound
            }

            if let existing = try self.fetchMessageMO(id: message.id) {
                existing.update(from: message)
            } else {
                let messageMO = ChatMessageMO(context: self.coreData.viewContext)
                messageMO.update(from: message)
                messageMO.conversation = conversationMO
            }

            try self.coreData.viewContext.saveIfNeeded()
        }
    }

    func updateConversation(_ conversation: Conversation) async throws {
        try await coreData.viewContext.perform {
            if let conversationMO = try self.fetchConversationMO(id: conversation.id) {
                conversationMO.update(from: conversation)
                try self.coreData.viewContext.saveIfNeeded()
            }
        }
    }

    // MARK: - Feedback

    func updateFeedback(messageId: UUID, rating: Int16) async throws {
        try await coreData.viewContext.perform {
            guard let messageMO = try self.fetchMessageMO(id: messageId) else {
                throw ChatError.conversationNotFound
            }
            messageMO.feedbackRating = rating
            try self.coreData.viewContext.saveIfNeeded()
        }
    }

    // MARK: - Clear History

    func clearHistory() async throws {
        try await deleteAllData()
    }

    /// Batch delete all chat data from Core Data and clean up legacy UserDefaults keys.
    func deleteAllData() async throws {
        try await coreData.viewContext.perform {
            let context = self.coreData.viewContext

            // Batch delete conversations (cascade deletes messages)
            let conversationRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatConversationMO")
            let conversationDelete = NSBatchDeleteRequest(fetchRequest: conversationRequest)
            conversationDelete.resultType = .resultTypeObjectIDs
            let convResult = try context.execute(conversationDelete) as? NSBatchDeleteResult

            // Also batch delete messages explicitly (safety net for orphans)
            let messageRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatMessageMO")
            let messageDelete = NSBatchDeleteRequest(fetchRequest: messageRequest)
            messageDelete.resultType = .resultTypeObjectIDs
            let msgResult = try context.execute(messageDelete) as? NSBatchDeleteResult

            // Merge deleted object IDs into context to avoid stale in-memory objects
            var deletedIDs: [NSManagedObjectID] = []
            if let convIDs = convResult?.result as? [NSManagedObjectID] { deletedIDs.append(contentsOf: convIDs) }
            if let msgIDs = msgResult?.result as? [NSManagedObjectID] { deletedIDs.append(contentsOf: msgIDs) }

            if !deletedIDs.isEmpty {
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: deletedIDs],
                    into: [context]
                )
            }

            context.reset()
        }

        // Clean up legacy UserDefaults keys
        cleanupLegacyUserDefaultsKeys()

        // Reset migration flag so future migration logic starts clean
        UserDefaults.standard.removeObject(forKey: migrationFlagKey)
        UserDefaults.standard.removeObject(forKey: Self.migrationRetryKey)
        UserDefaults.standard.removeObject(forKey: activeConversationKey)
    }

    // MARK: - Private Fetch Helpers

    private func fetchConversationMO(id: UUID) throws -> ChatConversationMO? {
        let context = coreData.viewContext
        let request = ChatConversationMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func fetchMessageMO(id: UUID) throws -> ChatMessageMO? {
        let context = coreData.viewContext
        let request = ChatMessageMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    // MARK: - UserDefaults → Core Data Migration

    /// One-time, crash-safe, idempotent migration from UserDefaults to Core Data.
    /// Retries up to 3 times across app launches for transient failures.
    /// If messages are permanently undecodable, finishes after max retries
    /// (successfully decoded messages are already persisted from earlier attempts).
    private static let migrationRetryKey = "chat_migration_retry_count"
    private static let maxMigrationRetries = 3

    private func migrateFromUserDefaultsIfNeeded() {
        // Step 1: Check flag
        guard !UserDefaults.standard.bool(forKey: migrationFlagKey) else { return }

        // Cap retries to avoid running migration on every launch for permanently bad data
        let retryCount = UserDefaults.standard.integer(forKey: Self.migrationRetryKey)
        if retryCount >= Self.maxMigrationRetries {
            // Give up retrying — mark migration complete so we stop running on every launch.
            // Preserve legacy keys: if a future build improves decoding, a manual
            // re-migration can be triggered by clearing the flag.
            UserDefaults.standard.set(true, forKey: migrationFlagKey)
            return
        }
        UserDefaults.standard.set(retryCount + 1, forKey: Self.migrationRetryKey)

        // Step 2: Read existing data from UserDefaults
        guard let conversationsData = UserDefaults.standard.data(forKey: conversationsKey) else {
            // No data key at all — nothing to migrate, set flag and return
            UserDefaults.standard.set(true, forKey: migrationFlagKey)
            return
        }

        guard let legacyConversations = try? JSONDecoder().decode([Conversation].self, from: conversationsData),
              !legacyConversations.isEmpty else {
            // Data key exists but decode failed or array is empty — don't set flag on decode failure.
            // If the data is genuinely empty (decoded to []), set flag. Otherwise leave for retry.
            if let decoded = try? JSONDecoder().decode([Conversation].self, from: conversationsData),
               decoded.isEmpty {
                UserDefaults.standard.set(true, forKey: migrationFlagKey)
            }
            // Decode failure: don't set flag — retry on next launch
            return
        }

        let context = coreData.viewContext

        // Step 3: Fetch-or-insert each conversation and its messages
        context.performAndWait {
            var expectedMessageCount = 0
            var hadDecodeFailures = false

            for conversation in legacyConversations {
                // Fetch-or-insert conversation
                let conversationMO: ChatConversationMO
                let convRequest = ChatConversationMO.fetchRequest()
                convRequest.predicate = NSPredicate(format: "id == %@", conversation.id as CVarArg)
                convRequest.fetchLimit = 1

                if let existing = try? context.fetch(convRequest).first {
                    conversationMO = existing
                    conversationMO.update(from: conversation)
                } else {
                    conversationMO = ChatConversationMO(context: context)
                    conversationMO.update(from: conversation)
                }

                // Load messages for this conversation
                let messagesKey = messagesKeyPrefix + conversation.id.uuidString
                if let messagesData = UserDefaults.standard.data(forKey: messagesKey) {
                    let decoder = JSONDecoder()
                    // Fast path: decode entire array at once
                    let legacyMessages: [ChatMessage]
                    if let allMessages = try? decoder.decode([ChatMessage].self, from: messagesData) {
                        legacyMessages = allMessages
                    } else if let jsonArray = try? JSONSerialization.jsonObject(with: messagesData) as? [[String: Any]] {
                        // Fallback: decode each message individually, skip failures
                        legacyMessages = jsonArray.compactMap { dict in
                            guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
                            return try? decoder.decode(ChatMessage.self, from: data)
                        }
                        if legacyMessages.count < jsonArray.count {
                            hadDecodeFailures = true
                        }
                    } else {
                        legacyMessages = []
                    }

                    expectedMessageCount += legacyMessages.count

                    for message in legacyMessages {
                        // Fetch-or-insert message
                        let msgRequest = ChatMessageMO.fetchRequest()
                        msgRequest.predicate = NSPredicate(format: "id == %@", message.id as CVarArg)
                        msgRequest.fetchLimit = 1

                        if let existing = try? context.fetch(msgRequest).first {
                            existing.update(from: message)
                            existing.conversation = conversationMO
                        } else {
                            let messageMO = ChatMessageMO(context: context)
                            messageMO.update(from: message)
                            messageMO.conversation = conversationMO
                        }
                    }
                }
            }

            // Step 4: Save
            do {
                try context.saveIfNeeded()
            } catch {
                // Save failed — return without setting flag, retry on next launch
                return
            }

            // Step 5: Verify count
            let convCount = (try? context.count(for: ChatConversationMO.fetchRequest())) ?? 0
            let msgCount = (try? context.count(for: ChatMessageMO.fetchRequest())) ?? 0

            guard convCount == legacyConversations.count else {
                // Mismatch — don't set flag, don't delete keys, retry next launch
                return
            }

            guard msgCount == expectedMessageCount else {
                // Message count mismatch — don't set flag, retry next launch
                return
            }

            // If any messages failed to decode, don't finalize migration.
            // Successfully decoded messages are saved (so progress is preserved),
            // but legacy keys are kept so a future app update can re-attempt.
            guard !hadDecodeFailures else { return }

            // Step 6: Set flag
            UserDefaults.standard.set(true, forKey: migrationFlagKey)

            // Step 7: Delete legacy keys
            cleanupLegacyUserDefaultsKeys()
        }
    }

    /// Remove legacy UserDefaults chat keys.
    private func cleanupLegacyUserDefaultsKeys() {
        // Remove conversation list
        UserDefaults.standard.removeObject(forKey: conversationsKey)

        // Remove all message keys (prefix-based)
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix(messagesKeyPrefix) {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
