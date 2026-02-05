// MARK: - FamilyModelTests.swift
// PURPOSE: Unit tests for Family domain entities

import XCTest
@testable import Safa

final class FamilyModelTests: XCTestCase {

    // MARK: - FamilyCircle Tests

    func testFamilyCircleCreation() {
        let circle = FamilyCircle(
            name: "Test Family",
            ownerId: "user123"
        )

        XCTAssertEqual(circle.name, "Test Family")
        XCTAssertEqual(circle.ownerId, "user123")
        XCTAssertEqual(circle.memberCount, 1)
        XCTAssertNotNil(circle.id)
        XCTAssertNotNil(circle.createdAt)
        XCTAssertFalse(circle.inviteCode.isEmpty)
    }

    func testFamilyCircleInviteCodeFormat() {
        let circle = FamilyCircle(
            name: "Test",
            ownerId: "user1"
        )

        // Invite code should be 8 characters, lowercased
        XCTAssertEqual(circle.inviteCode.count, 8)
        XCTAssertEqual(circle.inviteCode, circle.inviteCode.lowercased())
    }

    func testFamilyCircleCodable() throws {
        let original = FamilyCircle(
            name: "Smith Family",
            ownerId: "owner123",
            memberCount: 5
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FamilyCircle.self, from: data)

        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.ownerId, original.ownerId)
        XCTAssertEqual(decoded.memberCount, original.memberCount)
    }

    // MARK: - FamilyMember Tests

    func testFamilyMemberCreation() {
        let circleId = UUID()
        let member = FamilyMember(
            circleId: circleId,
            name: "Ahmed",
            isOwner: true
        )

        XCTAssertEqual(member.circleId, circleId)
        XCTAssertEqual(member.name, "Ahmed")
        XCTAssertTrue(member.isOwner)
        XCTAssertEqual(member.currentStreak, 0)
        XCTAssertEqual(member.level, 1)
        XCTAssertEqual(member.totalHasanat, 0)
        XCTAssertEqual(member.weeklyHasanat, 0)
        XCTAssertNil(member.lastActiveAt)
    }

    func testFamilyMemberWithStats() {
        let member = FamilyMember(
            circleId: UUID(),
            name: "Fatima",
            currentStreak: 10,
            lastActiveAt: Date(),
            isOwner: false,
            level: 5,
            totalHasanat: 1500,
            weeklyHasanat: 200
        )

        XCTAssertEqual(member.currentStreak, 10)
        XCTAssertEqual(member.level, 5)
        XCTAssertEqual(member.totalHasanat, 1500)
        XCTAssertEqual(member.weeklyHasanat, 200)
        XCTAssertFalse(member.isOwner)
        XCTAssertNotNil(member.lastActiveAt)
    }

    func testFamilyMemberCodable() throws {
        let original = FamilyMember(
            circleId: UUID(),
            name: "Test Member",
            currentStreak: 5,
            level: 3,
            totalHasanat: 500
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FamilyMember.self, from: data)

        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.currentStreak, original.currentStreak)
        XCTAssertEqual(decoded.level, original.level)
    }

    // MARK: - FamilyActivity Tests

    func testFamilyActivityCreation() {
        let memberId = UUID()
        let activity = FamilyActivity(
            memberId: memberId,
            memberName: "Omar",
            type: .prayerLogged,
            hasanatEarned: 10
        )

        XCTAssertEqual(activity.memberId, memberId)
        XCTAssertEqual(activity.memberName, "Omar")
        XCTAssertEqual(activity.type, .prayerLogged)
        XCTAssertEqual(activity.hasanatEarned, 10)
        XCTAssertNil(activity.details)
    }

    func testFamilyActivityDescription() {
        let activity = FamilyActivity(
            memberId: UUID(),
            memberName: "Aisha",
            type: .quranReading
        )

        XCTAssertEqual(activity.description, "Aisha read Quran")
    }

    func testFamilyActivityTypeDisplayText() {
        XCTAssertEqual(FamilyActivity.ActivityType.prayerLogged.displayText, "logged a prayer")
        XCTAssertEqual(FamilyActivity.ActivityType.quranReading.displayText, "read Quran")
        XCTAssertEqual(FamilyActivity.ActivityType.lessonCompleted.displayText, "completed a lesson")
        XCTAssertEqual(FamilyActivity.ActivityType.streakMilestone.displayText, "reached a streak milestone")
        XCTAssertEqual(FamilyActivity.ActivityType.achievementUnlocked.displayText, "unlocked an achievement")
        XCTAssertEqual(FamilyActivity.ActivityType.joined.displayText, "joined the family circle")
    }

    func testFamilyActivityTypeIcons() {
        XCTAssertEqual(FamilyActivity.ActivityType.prayerLogged.iconName, "moon.stars")
        XCTAssertEqual(FamilyActivity.ActivityType.quranReading.iconName, "book")
        XCTAssertEqual(FamilyActivity.ActivityType.lessonCompleted.iconName, "graduationcap")
        XCTAssertEqual(FamilyActivity.ActivityType.streakMilestone.iconName, "flame")
        XCTAssertEqual(FamilyActivity.ActivityType.achievementUnlocked.iconName, "trophy")
        XCTAssertEqual(FamilyActivity.ActivityType.joined.iconName, "person.badge.plus")
    }

    func testFamilyActivityCodable() throws {
        let original = FamilyActivity(
            memberId: UUID(),
            memberName: "Test",
            type: .lessonCompleted,
            details: "Arabic lesson",
            hasanatEarned: 15
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FamilyActivity.self, from: data)

        XCTAssertEqual(decoded.memberName, original.memberName)
        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.hasanatEarned, original.hasanatEarned)
    }

    // MARK: - FamilyPrivacySettings Tests

    func testFamilyPrivacySettingsDefaults() {
        let settings = FamilyPrivacySettings()

        XCTAssertTrue(settings.shareStreak)
        XCTAssertTrue(settings.sharePrayers)
        XCTAssertTrue(settings.shareQuranProgress)
        XCTAssertTrue(settings.shareLearningProgress)
        XCTAssertTrue(settings.shareAchievements)
        XCTAssertTrue(settings.receiveNotifications)
    }

    func testFamilyPrivacySettingsHidden() {
        let settings = FamilyPrivacySettings.hidden

        XCTAssertFalse(settings.shareStreak)
        XCTAssertFalse(settings.sharePrayers)
        XCTAssertFalse(settings.shareQuranProgress)
        XCTAssertFalse(settings.shareLearningProgress)
        XCTAssertFalse(settings.shareAchievements)
        XCTAssertFalse(settings.receiveNotifications)
    }

    func testFamilyPrivacySettingsCodable() throws {
        let original = FamilyPrivacySettings(
            shareStreak: true,
            sharePrayers: false,
            shareQuranProgress: true,
            shareLearningProgress: false,
            shareAchievements: true,
            receiveNotifications: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FamilyPrivacySettings.self, from: data)

        XCTAssertEqual(decoded.shareStreak, original.shareStreak)
        XCTAssertEqual(decoded.sharePrayers, original.sharePrayers)
        XCTAssertEqual(decoded.receiveNotifications, original.receiveNotifications)
    }

    // MARK: - FamilyRole Tests

    func testFamilyRoleAllCases() {
        XCTAssertEqual(FamilyRole.allCases.count, 3)
        XCTAssertTrue(FamilyRole.allCases.contains(.admin))
        XCTAssertTrue(FamilyRole.allCases.contains(.member))
        XCTAssertTrue(FamilyRole.allCases.contains(.child))
    }

    func testFamilyRoleDisplayNames() {
        XCTAssertEqual(FamilyRole.admin.displayName, "Admin")
        XCTAssertEqual(FamilyRole.member.displayName, "Member")
        XCTAssertEqual(FamilyRole.child.displayName, "Child")
    }

    func testFamilyRoleRawValues() {
        XCTAssertEqual(FamilyRole.admin.rawValue, "admin")
        XCTAssertEqual(FamilyRole.member.rawValue, "member")
        XCTAssertEqual(FamilyRole.child.rawValue, "child")
    }

    // MARK: - SimpleFamilyCircle Tests

    func testSimpleFamilyCircleCreation() {
        let circle = SimpleFamilyCircle(
            name: "Test Circle",
            createdBy: "user1"
        )

        XCTAssertEqual(circle.name, "Test Circle")
        XCTAssertEqual(circle.createdBy, "user1")
        XCTAssertTrue(circle.members.isEmpty)
    }

    func testSimpleFamilyCircleWithMembers() {
        let member1 = SimpleFamilyMember(
            userId: "user1",
            displayName: "Ahmed",
            role: .admin
        )
        let member2 = SimpleFamilyMember(
            userId: "user2",
            displayName: "Sara",
            role: .member
        )

        let circle = SimpleFamilyCircle(
            name: "Test Circle",
            createdBy: "user1",
            members: [member1, member2]
        )

        XCTAssertEqual(circle.members.count, 2)
    }

    // MARK: - InvitationStatus Tests

    func testInvitationStatusAllCases() {
        XCTAssertEqual(InvitationStatus.allCases.count, 4)
        XCTAssertTrue(InvitationStatus.allCases.contains(.pending))
        XCTAssertTrue(InvitationStatus.allCases.contains(.accepted))
        XCTAssertTrue(InvitationStatus.allCases.contains(.declined))
        XCTAssertTrue(InvitationStatus.allCases.contains(.expired))
    }

    // MARK: - FamilyInvitation Tests

    func testFamilyInvitationCreation() {
        let invitation = FamilyInvitation(
            circleId: "circle123",
            circleName: "Smith Family",
            invitedBy: "Ahmed",
            inviteeEmail: "test@example.com"
        )

        XCTAssertEqual(invitation.circleId, "circle123")
        XCTAssertEqual(invitation.circleName, "Smith Family")
        XCTAssertEqual(invitation.invitedBy, "Ahmed")
        XCTAssertEqual(invitation.inviteeEmail, "test@example.com")
        XCTAssertEqual(invitation.status, .pending)
    }

    func testFamilyInvitationCodable() throws {
        let original = FamilyInvitation(
            circleId: "test",
            circleName: "Test Family",
            invitedBy: "Inviter",
            inviteeEmail: "invitee@test.com",
            status: .accepted
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FamilyInvitation.self, from: data)

        XCTAssertEqual(decoded.circleId, original.circleId)
        XCTAssertEqual(decoded.status, original.status)
    }

    // MARK: - FamilyLeaderboardEntry Tests

    func testFamilyLeaderboardEntryCreation() {
        let entry = FamilyLeaderboardEntry(
            memberId: "member1",
            memberName: "Ahmed",
            hasanat: 1500,
            rank: 1
        )

        XCTAssertEqual(entry.memberId, "member1")
        XCTAssertEqual(entry.memberName, "Ahmed")
        XCTAssertEqual(entry.hasanat, 1500)
        XCTAssertEqual(entry.rank, 1)
    }

    func testFamilyLeaderboardEntryCodable() throws {
        let original = FamilyLeaderboardEntry(
            memberId: "test",
            memberName: "Test User",
            hasanat: 500,
            rank: 3
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FamilyLeaderboardEntry.self, from: data)

        XCTAssertEqual(decoded.memberName, original.memberName)
        XCTAssertEqual(decoded.hasanat, original.hasanat)
        XCTAssertEqual(decoded.rank, original.rank)
    }

    // MARK: - FamilyActivityType Tests

    func testFamilyActivityTypeAllCases() {
        XCTAssertEqual(FamilyActivityType.allCases.count, 5)
    }

    func testFamilyActivityTypeIconNames() {
        XCTAssertEqual(FamilyActivityType.prayer.iconName, "moon.stars")
        XCTAssertEqual(FamilyActivityType.quran.iconName, "book")
        XCTAssertEqual(FamilyActivityType.learning.iconName, "graduationcap")
        XCTAssertEqual(FamilyActivityType.dhikr.iconName, "hands.sparkles")
        XCTAssertEqual(FamilyActivityType.achievement.iconName, "trophy")
    }

    // MARK: - SimpleFamilyActivity Tests

    func testSimpleFamilyActivityCreation() {
        let activity = SimpleFamilyActivity(
            memberId: "member1",
            memberName: "Ahmed",
            type: .prayer,
            description: "Logged Fajr prayer"
        )

        XCTAssertEqual(activity.memberId, "member1")
        XCTAssertEqual(activity.memberName, "Ahmed")
        XCTAssertEqual(activity.type, .prayer)
        XCTAssertEqual(activity.description, "Logged Fajr prayer")
    }
}
