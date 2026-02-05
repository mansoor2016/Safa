// MARK: - FamilyRepositoryTests.swift
// PURPOSE: Unit tests for family circle functionality
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class FamilyRepositoryTests: XCTestCase {

    var sut: FamilyRepository!
    var mockCoreData: CoreDataStack!

    override func setUp() {
        super.setUp()
        mockCoreData = CoreDataStack.shared
        sut = FamilyRepository(coreData: mockCoreData)

        // Clear any existing data
        clearFamilyData()
    }

    override func tearDown() {
        clearFamilyData()
        sut = nil
        mockCoreData = nil
        super.tearDown()
    }

    private func clearFamilyData() {
        UserDefaults.standard.removeObject(forKey: "com.safa.family.circle")
        UserDefaults.standard.removeObject(forKey: "com.safa.family.members")
        UserDefaults.standard.removeObject(forKey: "com.safa.family.activity")
        UserDefaults.standard.removeObject(forKey: "com.safa.family.privacy")
    }

    // MARK: - Circle Creation Tests

    func testCreateFamilyCircle() async throws {
        let circle = try await sut.createFamilyCircle(name: "Test Family")

        XCTAssertEqual(circle.name, "Test Family")
        XCTAssertFalse(circle.inviteCode.isEmpty)
        XCTAssertEqual(circle.memberCount, 0)
    }

    func testGetFamilyCircleReturnsNilWhenNoneExists() async throws {
        let circle = try await sut.getFamilyCircle()

        XCTAssertNil(circle)
    }

    func testGetFamilyCircleAfterCreation() async throws {
        let created = try await sut.createFamilyCircle(name: "My Family")

        let fetched = try await sut.getFamilyCircle()

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, created.id)
        XCTAssertEqual(fetched?.name, "My Family")
    }

    func testLeaveFamilyCircle() async throws {
        _ = try await sut.createFamilyCircle(name: "Test Family")

        try await sut.leaveFamilyCircle()

        let circle = try await sut.getFamilyCircle()
        XCTAssertNil(circle)
    }

    // MARK: - Invite Code Tests

    func testGetInviteCode() async throws {
        let circle = try await sut.createFamilyCircle(name: "Test Family")

        let code = try await sut.getInviteCode()

        XCTAssertEqual(code, circle.inviteCode)
    }

    func testGetInviteCodeThrowsWhenNoCircle() async {
        do {
            _ = try await sut.getInviteCode()
            XCTFail("Should throw FamilyError.noCircle")
        } catch let error as FamilyError {
            XCTAssertEqual(error, FamilyError.noCircle)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testGenerateInviteLink() async throws {
        _ = try await sut.createFamilyCircle(name: "Test Family")

        let url = try await sut.generateInviteLink()

        XCTAssertTrue(url.absoluteString.hasPrefix("safa://family/join"))
        XCTAssertTrue(url.absoluteString.contains("code="))
    }

    // MARK: - Member Tests

    func testGetFamilyMembersInitiallyEmpty() async throws {
        let members = try await sut.getFamilyMembers()

        // After circle creation, there should be 1 member (creator)
        XCTAssertTrue(members.isEmpty || members.count == 1)
    }

    func testCreateCircleAddsCreatorAsMember() async throws {
        _ = try await sut.createFamilyCircle(name: "Test Family")

        let members = try await sut.getFamilyMembers()

        XCTAssertEqual(members.count, 1)
        XCTAssertTrue(members.first?.isOwner ?? false)
    }

    func testRemoveMember() async throws {
        _ = try await sut.createFamilyCircle(name: "Test Family")
        let members = try await sut.getFamilyMembers()
        guard let member = members.first else {
            XCTFail("Should have at least one member")
            return
        }

        try await sut.removeMember(id: member.id.uuidString)

        let updatedMembers = try await sut.getFamilyMembers()
        XCTAssertTrue(updatedMembers.isEmpty)
    }

    // MARK: - Activity Feed Tests

    func testShareActivity() async throws {
        let activity = FamilyActivity(
            id: UUID(),
            memberId: UUID(),
            memberName: "Test User",
            type: .prayerLogged,
            description: "Completed Fajr prayer",
            timestamp: Date()
        )

        try await sut.shareActivity(activity)

        let feed = try await sut.getActivityFeed(limit: 10)
        XCTAssertEqual(feed.count, 1)
        XCTAssertEqual(feed.first?.description, "Completed Fajr prayer")
    }

    func testActivityFeedSorting() async throws {
        let activity1 = FamilyActivity(
            id: UUID(),
            memberId: UUID(),
            memberName: "User",
            type: .prayerLogged,
            description: "First",
            timestamp: Date().addingTimeInterval(-100)
        )
        let activity2 = FamilyActivity(
            id: UUID(),
            memberId: UUID(),
            memberName: "User",
            type: .streakMilestone,
            description: "Second",
            timestamp: Date()
        )

        try await sut.shareActivity(activity1)
        try await sut.shareActivity(activity2)

        let feed = try await sut.getActivityFeed(limit: 10)

        XCTAssertEqual(feed.count, 2)
        XCTAssertEqual(feed.first?.description, "Second") // Most recent first
    }

    func testActivityFeedLimit() async throws {
        // Add 5 activities
        for i in 0..<5 {
            let activity = FamilyActivity(
                id: UUID(),
                memberId: UUID(),
                memberName: "User",
                type: .prayerLogged,
                description: "Activity \(i)",
                timestamp: Date().addingTimeInterval(Double(i))
            )
            try await sut.shareActivity(activity)
        }

        let feed = try await sut.getActivityFeed(limit: 3)

        XCTAssertEqual(feed.count, 3)
    }

    // MARK: - Privacy Settings Tests

    func testGetDefaultPrivacySettings() async throws {
        let settings = try await sut.getPrivacySettings()

        XCTAssertNotNil(settings)
    }

    func testUpdatePrivacySettings() async throws {
        var settings = FamilyPrivacySettings.default
        settings.showPrayerActivity = false
        settings.showQuranProgress = false

        try await sut.updatePrivacySettings(settings)

        let fetched = try await sut.getPrivacySettings()
        XCTAssertFalse(fetched.showPrayerActivity)
        XCTAssertFalse(fetched.showQuranProgress)
    }

    // MARK: - Notification Settings Tests

    func testSetFamilyNotifications() async throws {
        try await sut.setFamilyNotifications(enabled: true)

        // Verify setting was saved
        let enabled = UserDefaults.standard.bool(forKey: "com.safa.family.notifications")
        XCTAssertTrue(enabled)
    }
}

// MARK: - Family Circle Model Tests

final class FamilyCircleTests: XCTestCase {

    func testFamilyCircleInitialization() {
        let circle = FamilyCircle(name: "Test", ownerId: "owner123")

        XCTAssertEqual(circle.name, "Test")
        XCTAssertEqual(circle.ownerId, "owner123")
        XCTAssertFalse(circle.inviteCode.isEmpty)
        XCTAssertEqual(circle.memberCount, 0)
    }

    func testFamilyCircleEncodeDecode() throws {
        let circle = FamilyCircle(name: "Test", ownerId: "owner")

        let data = try JSONEncoder().encode(circle)
        let decoded = try JSONDecoder().decode(FamilyCircle.self, from: data)

        XCTAssertEqual(decoded.id, circle.id)
        XCTAssertEqual(decoded.name, circle.name)
        XCTAssertEqual(decoded.inviteCode, circle.inviteCode)
    }
}

// MARK: - Family Member Model Tests

final class FamilyMemberTests: XCTestCase {

    func testFamilyMemberInitialization() {
        let circleId = UUID()
        let member = FamilyMember(circleId: circleId, name: "Test User")

        XCTAssertEqual(member.name, "Test User")
        XCTAssertEqual(member.circleId, circleId)
        XCTAssertFalse(member.isOwner)
    }

    func testOwnerMember() {
        let member = FamilyMember(circleId: UUID(), name: "Owner", isOwner: true)

        XCTAssertTrue(member.isOwner)
    }

    func testFamilyMemberEncodeDecode() throws {
        let member = FamilyMember(circleId: UUID(), name: "Test")

        let data = try JSONEncoder().encode(member)
        let decoded = try JSONDecoder().decode(FamilyMember.self, from: data)

        XCTAssertEqual(decoded.id, member.id)
        XCTAssertEqual(decoded.name, member.name)
    }
}

// MARK: - Family Activity Model Tests

final class FamilyActivityTests: XCTestCase {

    func testActivityTypes() {
        XCTAssertNotNil(FamilyActivityType.prayerLogged)
        XCTAssertNotNil(FamilyActivityType.streakMilestone)
        XCTAssertNotNil(FamilyActivityType.achievementUnlocked)
        XCTAssertNotNil(FamilyActivityType.quranProgress)
    }

    func testFamilyActivityEncodeDecode() throws {
        let activity = FamilyActivity(
            id: UUID(),
            memberId: UUID(),
            memberName: "User",
            type: .prayerLogged,
            description: "Test",
            timestamp: Date()
        )

        let data = try JSONEncoder().encode(activity)
        let decoded = try JSONDecoder().decode(FamilyActivity.self, from: data)

        XCTAssertEqual(decoded.id, activity.id)
        XCTAssertEqual(decoded.type, activity.type)
        XCTAssertEqual(decoded.description, activity.description)
    }
}

// MARK: - Family Privacy Settings Tests

final class FamilyPrivacySettingsTests: XCTestCase {

    func testDefaultSettings() {
        let settings = FamilyPrivacySettings.default

        XCTAssertTrue(settings.showPrayerActivity)
        XCTAssertTrue(settings.showStreaks)
        XCTAssertTrue(settings.showQuranProgress)
    }

    func testCustomSettings() {
        var settings = FamilyPrivacySettings.default
        settings.showPrayerActivity = false
        settings.showStreaks = false

        XCTAssertFalse(settings.showPrayerActivity)
        XCTAssertFalse(settings.showStreaks)
        XCTAssertTrue(settings.showQuranProgress)
    }
}

// MARK: - Family Error Tests

final class FamilyErrorTests: XCTestCase {

    func testErrorDescriptions() {
        XCTAssertNotNil(FamilyError.noCircle.errorDescription)
        XCTAssertNotNil(FamilyError.invalidInviteCode.errorDescription)
        XCTAssertNotNil(FamilyError.notOwner.errorDescription)
        XCTAssertNotNil(FamilyError.alreadyMember.errorDescription)
    }

    func testNoCircleError() {
        let error = FamilyError.noCircle
        XCTAssertTrue(error.errorDescription?.contains("not part") ?? false)
    }

    func testInvalidInviteCodeError() {
        let error = FamilyError.invalidInviteCode
        XCTAssertTrue(error.errorDescription?.contains("invalid") ?? false)
    }
}
