// MARK: - FamilyModelTests.swift
// PURPOSE: Unit tests for Family domain models
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class FamilyModelTests: XCTestCase {

    // MARK: - Simple Family Circle Tests

    func testSimpleFamilyCircleInitialization() {
        let circle = SimpleFamilyCircle(
            name: "Smith Family",
            createdBy: "user123"
        )

        XCTAssertEqual(circle.name, "Smith Family")
        XCTAssertEqual(circle.createdBy, "user123")
        XCTAssertNotNil(circle.createdAt)
        XCTAssertTrue(circle.members.isEmpty)
    }

    func testSimpleFamilyCircleWithMembers() {
        var circle = SimpleFamilyCircle(name: "Test Family", createdBy: "admin")

        let member1 = SimpleFamilyMember(
            userId: "user1",
            displayName: "Ahmed",
            role: .admin
        )
        let member2 = SimpleFamilyMember(
            userId: "user2",
            displayName: "Fatima",
            role: .member
        )

        circle.members.append(member1)
        circle.members.append(member2)

        XCTAssertEqual(circle.members.count, 2)
    }

    // MARK: - Family Circle (Original) Tests

    func testFamilyCircleInitialization() {
        let circle = FamilyCircle(
            name: "Smith Family",
            ownerId: "user123"
        )

        XCTAssertEqual(circle.name, "Smith Family")
        XCTAssertEqual(circle.ownerId, "user123")
        XCTAssertNotNil(circle.createdAt)
        XCTAssertFalse(circle.inviteCode.isEmpty)
    }

    // MARK: - Simple Family Member Tests

    func testSimpleFamilyMemberInitialization() {
        let member = SimpleFamilyMember(
            userId: "user123",
            displayName: "Ahmed",
            role: .member
        )

        XCTAssertEqual(member.userId, "user123")
        XCTAssertEqual(member.displayName, "Ahmed")
        XCTAssertEqual(member.role, .member)
        XCTAssertNotNil(member.joinedAt)
    }

    func testFamilyMemberRoles() {
        XCTAssertEqual(FamilyRole.admin.rawValue, "admin")
        XCTAssertEqual(FamilyRole.member.rawValue, "member")
        XCTAssertEqual(FamilyRole.child.rawValue, "child")
    }

    func testFamilyMemberRoleDisplayNames() {
        XCTAssertEqual(FamilyRole.admin.displayName, "Admin")
        XCTAssertEqual(FamilyRole.member.displayName, "Member")
        XCTAssertEqual(FamilyRole.child.displayName, "Child")
    }

    // MARK: - Simple Family Activity Tests

    func testSimpleFamilyActivityInitialization() {
        let activity = SimpleFamilyActivity(
            memberId: "user123",
            memberName: "Ahmed",
            type: .prayer,
            description: "Completed Fajr prayer"
        )

        XCTAssertEqual(activity.memberId, "user123")
        XCTAssertEqual(activity.memberName, "Ahmed")
        XCTAssertEqual(activity.type, .prayer)
        XCTAssertEqual(activity.description, "Completed Fajr prayer")
        XCTAssertNotNil(activity.timestamp)
    }

    func testFamilyActivityTypes() {
        XCTAssertEqual(FamilyActivityType.prayer.rawValue, "prayer")
        XCTAssertEqual(FamilyActivityType.quran.rawValue, "quran")
        XCTAssertEqual(FamilyActivityType.learning.rawValue, "learning")
        XCTAssertEqual(FamilyActivityType.dhikr.rawValue, "dhikr")
        XCTAssertEqual(FamilyActivityType.achievement.rawValue, "achievement")
    }

    func testFamilyActivityTypeIcons() {
        XCTAssertFalse(FamilyActivityType.prayer.iconName.isEmpty)
        XCTAssertFalse(FamilyActivityType.quran.iconName.isEmpty)
        XCTAssertFalse(FamilyActivityType.learning.iconName.isEmpty)
    }

    // MARK: - Family Invitation Tests

    func testFamilyInvitationInitialization() {
        let invitation = FamilyInvitation(
            circleId: "circle123",
            circleName: "Smith Family",
            invitedBy: "Ahmed",
            inviteeEmail: "fatima@example.com"
        )

        XCTAssertEqual(invitation.circleId, "circle123")
        XCTAssertEqual(invitation.circleName, "Smith Family")
        XCTAssertEqual(invitation.invitedBy, "Ahmed")
        XCTAssertEqual(invitation.inviteeEmail, "fatima@example.com")
        XCTAssertEqual(invitation.status, .pending)
    }

    func testFamilyInvitationStatuses() {
        XCTAssertEqual(InvitationStatus.pending.rawValue, "pending")
        XCTAssertEqual(InvitationStatus.accepted.rawValue, "accepted")
        XCTAssertEqual(InvitationStatus.declined.rawValue, "declined")
        XCTAssertEqual(InvitationStatus.expired.rawValue, "expired")
    }

    // MARK: - Family Leaderboard Tests

    func testFamilyLeaderboardEntryInitialization() {
        let entry = FamilyLeaderboardEntry(
            memberId: "user123",
            memberName: "Ahmed",
            hasanat: 1500,
            rank: 1
        )

        XCTAssertEqual(entry.memberId, "user123")
        XCTAssertEqual(entry.memberName, "Ahmed")
        XCTAssertEqual(entry.hasanat, 1500)
        XCTAssertEqual(entry.rank, 1)
    }

    func testLeaderboardRanking() {
        let entries = [
            FamilyLeaderboardEntry(memberId: "1", memberName: "Ahmed", hasanat: 1500, rank: 1),
            FamilyLeaderboardEntry(memberId: "2", memberName: "Fatima", hasanat: 1200, rank: 2),
            FamilyLeaderboardEntry(memberId: "3", memberName: "Omar", hasanat: 800, rank: 3)
        ]

        XCTAssertTrue(entries[0].hasanat > entries[1].hasanat)
        XCTAssertTrue(entries[1].hasanat > entries[2].hasanat)
        XCTAssertEqual(entries[0].rank, 1)
        XCTAssertEqual(entries[2].rank, 3)
    }

    // MARK: - Family Privacy Settings Tests

    func testFamilyPrivacySettingsDefault() {
        let settings = FamilyPrivacySettings.default

        XCTAssertTrue(settings.shareStreak)
        XCTAssertTrue(settings.sharePrayers)
        XCTAssertTrue(settings.shareQuranProgress)
        XCTAssertTrue(settings.receiveNotifications)
    }

    func testFamilyPrivacySettingsHidden() {
        let settings = FamilyPrivacySettings.hidden

        XCTAssertFalse(settings.shareStreak)
        XCTAssertFalse(settings.sharePrayers)
        XCTAssertFalse(settings.shareQuranProgress)
        XCTAssertFalse(settings.receiveNotifications)
    }

    // MARK: - Encoding/Decoding Tests

    func testSimpleFamilyCircleCodable() throws {
        let original = SimpleFamilyCircle(name: "Test Family", createdBy: "user1")

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SimpleFamilyCircle.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.name, decoded.name)
    }

    func testSimpleFamilyMemberCodable() throws {
        let original = SimpleFamilyMember(userId: "user1", displayName: "Ahmed", role: .admin)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SimpleFamilyMember.self, from: data)

        XCTAssertEqual(original.userId, decoded.userId)
        XCTAssertEqual(original.role, decoded.role)
    }

    func testSimpleFamilyActivityCodable() throws {
        let original = SimpleFamilyActivity(
            memberId: "user1",
            memberName: "Ahmed",
            type: .prayer,
            description: "Test"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SimpleFamilyActivity.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.type, decoded.type)
    }

    // MARK: - Original Family Activity Tests

    func testFamilyActivityInitialization() {
        let activity = FamilyActivity(
            memberId: UUID(),
            memberName: "Ahmed",
            type: .prayerLogged,
            details: "Fajr"
        )

        XCTAssertEqual(activity.memberName, "Ahmed")
        XCTAssertEqual(activity.type, .prayerLogged)
        XCTAssertEqual(activity.type.displayText, "logged a prayer")
    }
}
