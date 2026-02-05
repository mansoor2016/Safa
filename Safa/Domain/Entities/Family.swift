// MARK: - Family.swift
// PURPOSE: Domain entities for family circle, members, and sharing

import Foundation
import SwiftUI

// MARK: - Family Circle
struct FamilyCircle: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let createdAt: Date
    let ownerId: String
    let inviteCode: String
    var memberCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        ownerId: String,
        inviteCode: String = UUID().uuidString.prefix(8).lowercased(),
        memberCount: Int = 1
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.ownerId = ownerId
        self.inviteCode = String(inviteCode)
        self.memberCount = memberCount
    }
}

// MARK: - Family Member
struct FamilyMember: Identifiable, Codable, Hashable {
    let id: UUID
    let circleId: UUID
    let name: String
    let joinedAt: Date
    var currentStreak: Int
    var lastActiveAt: Date?
    var isOwner: Bool
    var level: Int
    var totalHasanat: Int
    var weeklyHasanat: Int

    init(
        id: UUID = UUID(),
        circleId: UUID,
        name: String,
        joinedAt: Date = Date(),
        currentStreak: Int = 0,
        lastActiveAt: Date? = nil,
        isOwner: Bool = false,
        level: Int = 1,
        totalHasanat: Int = 0,
        weeklyHasanat: Int = 0
    ) {
        self.id = id
        self.circleId = circleId
        self.name = name
        self.joinedAt = joinedAt
        self.currentStreak = currentStreak
        self.lastActiveAt = lastActiveAt
        self.isOwner = isOwner
        self.level = level
        self.totalHasanat = totalHasanat
        self.weeklyHasanat = weeklyHasanat
    }
}

// MARK: - Family Activity
struct FamilyActivity: Identifiable, Codable, Hashable {
    let id: UUID
    let memberId: UUID
    let memberName: String
    let type: ActivityType
    let timestamp: Date
    let details: String?
    var hasanatEarned: Int

    enum ActivityType: String, Codable {
        case prayerLogged
        case quranReading
        case lessonCompleted
        case streakMilestone
        case achievementUnlocked
        case joined

        var displayText: String {
            switch self {
            case .prayerLogged: return "logged a prayer"
            case .quranReading: return "read Quran"
            case .lessonCompleted: return "completed a lesson"
            case .streakMilestone: return "reached a streak milestone"
            case .achievementUnlocked: return "unlocked an achievement"
            case .joined: return "joined the family circle"
            }
        }

        var iconName: String {
            switch self {
            case .prayerLogged: return "moon.stars"
            case .quranReading: return "book"
            case .lessonCompleted: return "graduationcap"
            case .streakMilestone: return "flame"
            case .achievementUnlocked: return "trophy"
            case .joined: return "person.badge.plus"
            }
        }

        var color: Color {
            switch self {
            case .prayerLogged: return .blue
            case .quranReading: return .green
            case .lessonCompleted: return .purple
            case .streakMilestone: return .orange
            case .achievementUnlocked: return .yellow
            case .joined: return .teal
            }
        }
    }

    /// Computed description combining member name and activity
    var description: String {
        "\(memberName) \(type.displayText)"
    }

    init(
        id: UUID = UUID(),
        memberId: UUID,
        memberName: String,
        type: ActivityType,
        timestamp: Date = Date(),
        details: String? = nil,
        hasanatEarned: Int = 0
    ) {
        self.id = id
        self.memberId = memberId
        self.memberName = memberName
        self.type = type
        self.timestamp = timestamp
        self.details = details
        self.hasanatEarned = hasanatEarned
    }
}

// MARK: - Family Privacy Settings
struct FamilyPrivacySettings: Codable, Hashable {
    var shareStreak: Bool
    var sharePrayers: Bool
    var shareQuranProgress: Bool
    var shareLearningProgress: Bool
    var shareAchievements: Bool
    var receiveNotifications: Bool

    init(
        shareStreak: Bool = true,
        sharePrayers: Bool = true,
        shareQuranProgress: Bool = true,
        shareLearningProgress: Bool = true,
        shareAchievements: Bool = true,
        receiveNotifications: Bool = true
    ) {
        self.shareStreak = shareStreak
        self.sharePrayers = sharePrayers
        self.shareQuranProgress = shareQuranProgress
        self.shareLearningProgress = shareLearningProgress
        self.shareAchievements = shareAchievements
        self.receiveNotifications = receiveNotifications
    }

    static let `default` = FamilyPrivacySettings()

    static let hidden = FamilyPrivacySettings(
        shareStreak: false,
        sharePrayers: false,
        shareQuranProgress: false,
        shareLearningProgress: false,
        shareAchievements: false,
        receiveNotifications: false
    )
}

// MARK: - Family Role
enum FamilyRole: String, Codable, CaseIterable {
    case admin
    case member
    case child

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Simple Family Circle (for views and tests)
struct SimpleFamilyCircle: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let createdBy: String
    let createdAt: Date
    var members: [SimpleFamilyMember]

    init(
        id: String = UUID().uuidString,
        name: String,
        createdBy: String,
        createdAt: Date = Date(),
        members: [SimpleFamilyMember] = []
    ) {
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.members = members
    }
}

// MARK: - Simple Family Member (for views and tests)
struct SimpleFamilyMember: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    let displayName: String
    let role: FamilyRole
    let joinedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        displayName: String,
        role: FamilyRole,
        joinedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.role = role
        self.joinedAt = joinedAt
    }
}

// MARK: - Family Activity Type
enum FamilyActivityType: String, Codable, CaseIterable {
    case prayer
    case quran
    case learning
    case dhikr
    case achievement

    var iconName: String {
        switch self {
        case .prayer: return "moon.stars"
        case .quran: return "book"
        case .learning: return "graduationcap"
        case .dhikr: return "hands.sparkles"
        case .achievement: return "trophy"
        }
    }
}

// MARK: - Simple Family Activity (for views and tests)
struct SimpleFamilyActivity: Identifiable, Codable, Hashable {
    let id: String
    let memberId: String
    let memberName: String
    let type: FamilyActivityType
    let description: String
    let timestamp: Date

    init(
        id: String = UUID().uuidString,
        memberId: String,
        memberName: String,
        type: FamilyActivityType,
        description: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.memberId = memberId
        self.memberName = memberName
        self.type = type
        self.description = description
        self.timestamp = timestamp
    }
}

// MARK: - Invitation Status
enum InvitationStatus: String, Codable, CaseIterable {
    case pending
    case accepted
    case declined
    case expired
}

// MARK: - Family Invitation
struct FamilyInvitation: Identifiable, Codable, Hashable {
    let id: String
    let circleId: String
    let circleName: String
    let invitedBy: String
    let inviteeEmail: String
    var status: InvitationStatus
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        circleId: String,
        circleName: String,
        invitedBy: String,
        inviteeEmail: String,
        status: InvitationStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.circleId = circleId
        self.circleName = circleName
        self.invitedBy = invitedBy
        self.inviteeEmail = inviteeEmail
        self.status = status
        self.createdAt = createdAt
    }
}

// MARK: - Family Leaderboard Entry
struct FamilyLeaderboardEntry: Identifiable, Codable, Hashable {
    let id: String
    let memberId: String
    let memberName: String
    let hasanat: Int
    let rank: Int

    init(
        id: String = UUID().uuidString,
        memberId: String,
        memberName: String,
        hasanat: Int,
        rank: Int
    ) {
        self.id = id
        self.memberId = memberId
        self.memberName = memberName
        self.hasanat = hasanat
        self.rank = rank
    }
}
