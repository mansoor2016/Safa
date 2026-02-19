// MARK: - Chat.swift
// PURPOSE: Domain entities for AI chat conversations and messages

import Foundation

// MARK: - Conversation
struct Conversation: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String?
    let createdAt: Date
    var updatedAt: Date
    var messageCount: Int

    init(
        id: UUID = UUID(),
        title: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messageCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messageCount = messageCount
    }

    var displayTitle: String {
        title ?? "New Conversation"
    }
}

// MARK: - Chat Message
struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let conversationId: UUID
    let role: Role
    let content: String
    let timestamp: Date
    var feedbackRating: Int16
    var citations: [Citation]
    var status: Status

    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    enum Status: String, Codable {
        case pending
        case streaming
        case complete
        case aborted
        case error
    }

    init(
        id: UUID = UUID(),
        conversationId: UUID,
        role: Role,
        content: String,
        timestamp: Date = Date(),
        feedbackRating: Int16 = 0,
        citations: [Citation] = [],
        status: Status = .complete
    ) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.feedbackRating = feedbackRating
        self.citations = citations
        self.status = status
    }

    var isUser: Bool {
        role == .user
    }

    var isAssistant: Bool {
        role == .assistant
    }
}

// MARK: - Chat Error
enum ChatError: LocalizedError {
    case modelNotLoaded
    case generationFailed(String)
    case conversationNotFound
    case messageTooLong

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return String(localized: "The AI model is not loaded. Please wait.")
        case .generationFailed(let reason):
            return String(localized: "Failed to generate response: \(reason)")
        case .conversationNotFound:
            return String(localized: "Conversation not found.")
        case .messageTooLong:
            return String(localized: "Message is too long. Please shorten it.")
        }
    }
}

// MARK: - Message Role (alias for ChatMessage.Role)
typealias MessageRole = ChatMessage.Role

// MARK: - Chat Session (for views)
struct ChatSession: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    let createdAt: Date
    var messages: [SimpleChatMessage]

    init(
        id: String = UUID().uuidString,
        title: String,
        createdAt: Date = Date(),
        messages: [SimpleChatMessage] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.messages = messages
    }
}

// MARK: - Simple Chat Message (for views)
struct SimpleChatMessage: Identifiable, Codable, Hashable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date

    init(
        id: String = UUID().uuidString,
        role: MessageRole,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - Chat Topic
enum ChatTopic: String, Codable, CaseIterable {
    case general
    case quran
    case hadith
    case fiqh
    case seerah
    case dua

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Chat Context
struct ChatContext: Codable, Hashable {
    let topic: ChatTopic
    var surahNumber: Int?
    var ayahNumber: Int?
    var hadithId: String?
    var duaId: String?

    init(
        topic: ChatTopic,
        surahNumber: Int? = nil,
        ayahNumber: Int? = nil,
        hadithId: String? = nil,
        duaId: String? = nil
    ) {
        self.topic = topic
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.hadithId = hadithId
        self.duaId = duaId
    }
}

// MARK: - Suggested Question
struct SuggestedQuestion: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    let category: String

    init(
        id: String = UUID().uuidString,
        text: String,
        category: String
    ) {
        self.id = id
        self.text = text
        self.category = category
    }
}
