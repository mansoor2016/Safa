// MARK: - ChatMessageMO+Mapping.swift
// PURPOSE: Safe bridging properties and domain ↔ Core Data mapping for chat entities
// DEPENDENCIES: CoreData

import CoreData

// MARK: - ChatMessageMO Extensions

extension ChatMessageMO {

    // MARK: - Safe Bridging Properties
    // These handle nil values from pre-migration rows where new fields don't exist yet.
    // Core Data sets scalar defaults only on insert, not on pre-migration rows fetched
    // before the field existed, so explicit nil-coalescing is required.

    /// Maps the `role` string field to `ChatMessage.Role`, with legacy fallback.
    var messageRole: ChatMessage.Role {
        if let role {
            return ChatMessage.Role(rawValue: role) ?? .user
        }
        // Legacy fallback: use isFromUser boolean for rows created before role field existed
        return isFromUser ? .user : .assistant
    }

    /// Safe accessor for `status` field. Returns "complete" for pre-migration rows.
    var messageStatus: String {
        status ?? "complete"
    }

    /// Safe accessor for `feedbackRating` field. Returns 0 for pre-migration rows.
    var messageFeedback: Int16 {
        let rating = value(forKey: "feedbackRating") as? Int16
        return rating ?? 0
    }

    /// Safe accessor for `citationsJSON` field. Returns nil for pre-migration rows.
    var messageCitationsJSON: String? {
        citationsJSON
    }

    // MARK: - Domain Mapping

    /// Convert this managed object to a domain `ChatMessage`.
    func toDomain() -> ChatMessage {
        let decodedCitations: [Citation]
        if let json = messageCitationsJSON,
           let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([Citation].self, from: data) {
            decodedCitations = decoded
        } else {
            decodedCitations = []
        }

        return ChatMessage(
            id: id ?? UUID(),
            conversationId: conversation?.id ?? UUID(),
            role: messageRole,
            content: content ?? "",
            timestamp: timestamp ?? Date(),
            feedbackRating: messageFeedback,
            citations: decodedCitations,
            status: ChatMessage.Status(rawValue: messageStatus) ?? .complete
        )
    }

    /// Update this managed object from a domain `ChatMessage`.
    func update(from message: ChatMessage) {
        id = message.id
        content = message.content
        timestamp = message.timestamp
        isFromUser = message.role == .user
        role = message.role.rawValue
        feedbackRating = message.feedbackRating
        status = message.status.rawValue

        if !message.citations.isEmpty,
           let data = try? JSONEncoder().encode(message.citations),
           let json = String(data: data, encoding: .utf8) {
            citationsJSON = json
        } else {
            citationsJSON = nil
        }
    }
}

// MARK: - ChatConversationMO Extensions

extension ChatConversationMO {

    /// Convert this managed object to a domain `Conversation`.
    func toDomain() -> Conversation {
        let messageSet = messages as? Set<ChatMessageMO> ?? []
        return Conversation(
            id: id ?? UUID(),
            title: (title?.isEmpty == false) ? title : nil,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            messageCount: messageSet.count
        )
    }

    /// Update this managed object from a domain `Conversation`.
    func update(from conversation: Conversation) {
        id = conversation.id
        title = conversation.title ?? ""
        createdAt = conversation.createdAt
        updatedAt = conversation.updatedAt
    }
}
