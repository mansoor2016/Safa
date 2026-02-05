// MARK: - FamilyViewModelTests.swift
// PURPOSE: Unit tests for FamilyViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

// MARK: - Test Error

enum FamilyTestError: Error {
    case network
    case notFound
    case invalidInput
}

// MARK: - Test Repository

final class FamilyTestRepository: FamilyRepositoryProtocol {
    var familyCircleToReturn: FamilyCircle?
    var membersToReturn: [FamilyMember] = []
    var activitiesToReturn: [FamilyActivity] = []
    var inviteCodeToReturn = "ABC123"
    var errorToThrow: Error?

    var getFamilyCircleCallCount = 0
    var getMembersCallCount = 0
    var getActivityFeedCallCount = 0
    var createCircleCallCount = 0
    var joinCircleCallCount = 0
    var lastCreatedCircleName: String?
    var lastJoinedCode: String?

    func getFamilyCircle() async throws -> FamilyCircle? {
        getFamilyCircleCallCount += 1
        if let error = errorToThrow { throw error }
        return familyCircleToReturn
    }

    func createFamilyCircle(name: String) async throws -> FamilyCircle {
        createCircleCallCount += 1
        lastCreatedCircleName = name
        if let error = errorToThrow { throw error }
        let circle = FamilyCircle(name: name, ownerId: "user123")
        familyCircleToReturn = circle
        return circle
    }

    func joinFamilyCircle(inviteCode: String) async throws {
        joinCircleCallCount += 1
        lastJoinedCode = inviteCode
        if let error = errorToThrow { throw error }
    }

    func leaveFamilyCircle() async throws {
        if let error = errorToThrow { throw error }
    }

    func getInviteCode() async throws -> String {
        if let error = errorToThrow { throw error }
        return inviteCodeToReturn
    }

    func generateInviteLink() async throws -> URL {
        if let error = errorToThrow { throw error }
        return URL(string: "https://safa.app/invite/\(inviteCodeToReturn)")!
    }

    func getFamilyMembers() async throws -> [FamilyMember] {
        getMembersCallCount += 1
        if let error = errorToThrow { throw error }
        return membersToReturn
    }

    func getMember(id memberId: String) async throws -> FamilyMember? {
        if let error = errorToThrow { throw error }
        return membersToReturn.first { $0.id.uuidString == memberId }
    }

    func removeMember(id memberId: String) async throws {
        if let error = errorToThrow { throw error }
    }

    func getActivityFeed(limit: Int) async throws -> [FamilyActivity] {
        getActivityFeedCallCount += 1
        if let error = errorToThrow { throw error }
        return Array(activitiesToReturn.prefix(limit))
    }

    func shareActivity(_ activity: FamilyActivity) async throws {
        if let error = errorToThrow { throw error }
    }

    func getPrivacySettings() async throws -> FamilyPrivacySettings {
        if let error = errorToThrow { throw error }
        return .default
    }

    func updatePrivacySettings(_ settings: FamilyPrivacySettings) async throws {
        if let error = errorToThrow { throw error }
    }

    func setFamilyNotifications(enabled: Bool) async throws {
        if let error = errorToThrow { throw error }
    }
}

// MARK: - Test Cases

final class FamilyViewModelTests: XCTestCase {

    var sut: FamilyViewModel!
    var testRepository: FamilyTestRepository!

    override func setUp() {
        super.setUp()
        testRepository = FamilyTestRepository()
        sut = FamilyViewModel(familyRepository: testRepository)
    }

    override func tearDown() {
        sut = nil
        testRepository = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_familyCircleIsNil() {
        XCTAssertNil(sut.familyCircle)
    }

    func test_initialState_membersIsEmpty() {
        XCTAssertTrue(sut.members.isEmpty)
    }

    func test_initialState_activitiesIsEmpty() {
        XCTAssertTrue(sut.activities.isEmpty)
    }

    func test_initialState_leaderboardIsEmpty() {
        XCTAssertTrue(sut.leaderboard.isEmpty)
    }

    func test_initialState_isLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func test_initialState_errorIsNil() {
        XCTAssertNil(sut.error)
    }

    func test_initialState_currentUserIdIsNotEmpty() {
        XCTAssertFalse(sut.currentUserId.isEmpty)
    }

    // MARK: - Total Circle Hasanat Tests

    func test_totalCircleHasanat_withNoMembers() {
        XCTAssertEqual(sut.totalCircleHasanat, 0)
    }

    func test_totalCircleHasanat_calculatesCorrectly() {
        let circleId = UUID()
        sut.members = [
            FamilyMember(circleId: circleId, name: "User 1", totalHasanat: 100),
            FamilyMember(circleId: circleId, name: "User 2", totalHasanat: 250),
            FamilyMember(circleId: circleId, name: "User 3", totalHasanat: 150)
        ]
        XCTAssertEqual(sut.totalCircleHasanat, 500)
    }

    func test_totalCircleHasanat_withSingleMember() {
        let circleId = UUID()
        sut.members = [FamilyMember(circleId: circleId, name: "User 1", totalHasanat: 1000)]
        XCTAssertEqual(sut.totalCircleHasanat, 1000)
    }

    // MARK: - Load Family Circle Tests

    func test_loadFamilyCircle_setsIsLoadingTrue() async {
        testRepository.familyCircleToReturn = FamilyCircle(name: "Test", ownerId: "123")

        let expectation = XCTestExpectation(description: "Load")
        Task {
            await sut.loadFamilyCircle()
            expectation.fulfill()
        }

        // Small delay to check isLoading state
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        await fulfillment(of: [expectation], timeout: 5.0)

        XCTAssertFalse(sut.isLoading)
    }

    func test_loadFamilyCircle_setsFamilyCircle() async {
        let circle = FamilyCircle(name: "My Family", ownerId: "owner123")
        testRepository.familyCircleToReturn = circle

        await sut.loadFamilyCircle()

        XCTAssertNotNil(sut.familyCircle)
        XCTAssertEqual(sut.familyCircle?.name, "My Family")
    }

    func test_loadFamilyCircle_loadsMembers() async {
        let circle = FamilyCircle(name: "Test", ownerId: "123")
        testRepository.familyCircleToReturn = circle
        testRepository.membersToReturn = [
            FamilyMember(circleId: circle.id, name: "Member 1")
        ]

        await sut.loadFamilyCircle()

        XCTAssertEqual(testRepository.getMembersCallCount, 1)
    }

    func test_loadFamilyCircle_loadsActivityFeed() async {
        let circle = FamilyCircle(name: "Test", ownerId: "123")
        testRepository.familyCircleToReturn = circle

        await sut.loadFamilyCircle()

        XCTAssertEqual(testRepository.getActivityFeedCallCount, 1)
    }

    func test_loadFamilyCircle_populatesLeaderboard() async {
        let circle = FamilyCircle(name: "Test", ownerId: "123")
        testRepository.familyCircleToReturn = circle
        testRepository.membersToReturn = [
            FamilyMember(circleId: circle.id, name: "Low", weeklyHasanat: 50),
            FamilyMember(circleId: circle.id, name: "High", weeklyHasanat: 200),
            FamilyMember(circleId: circle.id, name: "Medium", weeklyHasanat: 100)
        ]

        await sut.loadFamilyCircle()

        XCTAssertEqual(sut.leaderboard.count, 3)
        XCTAssertEqual(sut.leaderboard.first?.name, "High")
        XCTAssertEqual(sut.leaderboard.last?.name, "Low")
    }

    func test_loadFamilyCircle_whenNoCircle_doesNotLoadMembers() async {
        testRepository.familyCircleToReturn = nil

        await sut.loadFamilyCircle()

        XCTAssertEqual(testRepository.getMembersCallCount, 0)
        XCTAssertEqual(testRepository.getActivityFeedCallCount, 0)
    }

    func test_loadFamilyCircle_setsError_onFailure() async {
        testRepository.errorToThrow = FamilyTestError.network

        await sut.loadFamilyCircle()

        XCTAssertNotNil(sut.error)
    }

    func test_loadFamilyCircle_setsIsLoadingFalse_afterCompletion() async {
        testRepository.familyCircleToReturn = FamilyCircle(name: "Test", ownerId: "123")

        await sut.loadFamilyCircle()

        XCTAssertFalse(sut.isLoading)
    }

    func test_loadFamilyCircle_setsIsLoadingFalse_onError() async {
        testRepository.errorToThrow = FamilyTestError.network

        await sut.loadFamilyCircle()

        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Load Members Tests

    func test_loadMembers_populatesMembersArray() async {
        let circleId = UUID()
        testRepository.membersToReturn = [
            FamilyMember(circleId: circleId, name: "User 1"),
            FamilyMember(circleId: circleId, name: "User 2")
        ]

        await sut.loadMembers()

        XCTAssertEqual(sut.members.count, 2)
    }

    func test_loadMembers_setsError_onFailure() async {
        testRepository.errorToThrow = FamilyTestError.notFound

        await sut.loadMembers()

        XCTAssertNotNil(sut.error)
    }

    // MARK: - Load Activity Feed Tests

    func test_loadActivityFeed_populatesActivitiesArray() async {
        let memberId = UUID()
        testRepository.activitiesToReturn = [
            FamilyActivity(memberId: memberId, memberName: "Test", type: .prayerLogged),
            FamilyActivity(memberId: memberId, memberName: "Test", type: .quranReading)
        ]

        await sut.loadActivityFeed()

        XCTAssertEqual(sut.activities.count, 2)
    }

    func test_loadActivityFeed_setsError_onFailure() async {
        testRepository.errorToThrow = FamilyTestError.network

        await sut.loadActivityFeed()

        XCTAssertNotNil(sut.error)
    }

    // MARK: - Load Leaderboard Tests

    func test_loadLeaderboard_sortsDescendingByWeeklyHasanat() async {
        let circleId = UUID()
        sut.members = [
            FamilyMember(circleId: circleId, name: "C", weeklyHasanat: 100),
            FamilyMember(circleId: circleId, name: "A", weeklyHasanat: 300),
            FamilyMember(circleId: circleId, name: "B", weeklyHasanat: 200)
        ]

        await sut.loadLeaderboard()

        XCTAssertEqual(sut.leaderboard[0].name, "A")
        XCTAssertEqual(sut.leaderboard[1].name, "B")
        XCTAssertEqual(sut.leaderboard[2].name, "C")
    }

    func test_loadLeaderboard_emptyWhenNoMembers() async {
        sut.members = []

        await sut.loadLeaderboard()

        XCTAssertTrue(sut.leaderboard.isEmpty)
    }

    // MARK: - Create Circle Tests

    func test_createCircle_callsRepository() async {
        await sut.createCircle(name: "New Circle")

        XCTAssertEqual(testRepository.createCircleCallCount, 1)
        XCTAssertEqual(testRepository.lastCreatedCircleName, "New Circle")
    }

    func test_createCircle_setsFamilyCircle() async {
        await sut.createCircle(name: "Test Family")

        XCTAssertNotNil(sut.familyCircle)
        XCTAssertEqual(sut.familyCircle?.name, "Test Family")
    }

    func test_createCircle_loadsMembersAfterCreation() async {
        await sut.createCircle(name: "Test")

        XCTAssertEqual(testRepository.getMembersCallCount, 1)
    }

    func test_createCircle_setsError_onFailure() async {
        testRepository.errorToThrow = FamilyTestError.network

        await sut.createCircle(name: "Test")

        XCTAssertNotNil(sut.error)
    }

    // MARK: - Invite Member Tests

    func test_inviteMember_returnsInviteCode() async {
        testRepository.inviteCodeToReturn = "XYZ789"

        let code = await sut.inviteMember(email: "test@example.com")

        XCTAssertEqual(code, "XYZ789")
    }

    func test_inviteMember_returnsNil_onError() async {
        testRepository.errorToThrow = FamilyTestError.network

        let code = await sut.inviteMember(email: "test@example.com")

        XCTAssertNil(code)
    }

    func test_inviteMember_setsError_onFailure() async {
        testRepository.errorToThrow = FamilyTestError.network

        _ = await sut.inviteMember(email: "test@example.com")

        XCTAssertNotNil(sut.error)
    }

    // MARK: - Join Circle Tests

    func test_joinCircle_callsRepositoryWithCode() async {
        await sut.joinCircle(code: "ABC123")

        XCTAssertEqual(testRepository.joinCircleCallCount, 1)
        XCTAssertEqual(testRepository.lastJoinedCode, "ABC123")
    }

    func test_joinCircle_reloadsFamilyCircle() async {
        await sut.joinCircle(code: "ABC123")

        XCTAssertGreaterThanOrEqual(testRepository.getFamilyCircleCallCount, 1)
    }

    func test_joinCircle_setsError_onFailure() async {
        testRepository.errorToThrow = FamilyTestError.invalidInput

        await sut.joinCircle(code: "INVALID")

        XCTAssertNotNil(sut.error)
    }

    // MARK: - FamilyCircle Model Tests

    func test_familyCircle_isIdentifiable() {
        let circle = FamilyCircle(name: "Test", ownerId: "123")
        XCTAssertNotNil(circle.id)
    }

    func test_familyCircle_defaultMemberCountIsOne() {
        let circle = FamilyCircle(name: "Test", ownerId: "123")
        XCTAssertEqual(circle.memberCount, 1)
    }

    func test_familyCircle_generatesInviteCode() {
        let circle = FamilyCircle(name: "Test", ownerId: "123")
        XCTAssertFalse(circle.inviteCode.isEmpty)
        XCTAssertEqual(circle.inviteCode.count, 8)
    }

    // MARK: - FamilyMember Model Tests

    func test_familyMember_isIdentifiable() {
        let member = FamilyMember(circleId: UUID(), name: "Test")
        XCTAssertNotNil(member.id)
    }

    func test_familyMember_defaultValues() {
        let member = FamilyMember(circleId: UUID(), name: "Test")
        XCTAssertEqual(member.currentStreak, 0)
        XCTAssertEqual(member.level, 1)
        XCTAssertEqual(member.totalHasanat, 0)
        XCTAssertEqual(member.weeklyHasanat, 0)
        XCTAssertFalse(member.isOwner)
    }

    func test_familyMember_storesAllProperties() {
        let circleId = UUID()
        let member = FamilyMember(
            circleId: circleId,
            name: "Test User",
            currentStreak: 7,
            isOwner: true,
            level: 5,
            totalHasanat: 1000,
            weeklyHasanat: 200
        )

        XCTAssertEqual(member.circleId, circleId)
        XCTAssertEqual(member.name, "Test User")
        XCTAssertEqual(member.currentStreak, 7)
        XCTAssertTrue(member.isOwner)
        XCTAssertEqual(member.level, 5)
        XCTAssertEqual(member.totalHasanat, 1000)
        XCTAssertEqual(member.weeklyHasanat, 200)
    }

    // MARK: - FamilyActivity Model Tests

    func test_familyActivity_isIdentifiable() {
        let activity = FamilyActivity(memberId: UUID(), memberName: "Test", type: .prayerLogged)
        XCTAssertNotNil(activity.id)
    }

    func test_familyActivity_descriptionCombinesNameAndType() {
        let activity = FamilyActivity(memberId: UUID(), memberName: "John", type: .quranReading)
        XCTAssertEqual(activity.description, "John read Quran")
    }

    func test_familyActivity_defaultHasanatIsZero() {
        let activity = FamilyActivity(memberId: UUID(), memberName: "Test", type: .joined)
        XCTAssertEqual(activity.hasanatEarned, 0)
    }

    // MARK: - ActivityType Tests

    func test_activityType_displayText() {
        XCTAssertEqual(FamilyActivity.ActivityType.prayerLogged.displayText, "logged a prayer")
        XCTAssertEqual(FamilyActivity.ActivityType.quranReading.displayText, "read Quran")
        XCTAssertEqual(FamilyActivity.ActivityType.lessonCompleted.displayText, "completed a lesson")
        XCTAssertEqual(FamilyActivity.ActivityType.streakMilestone.displayText, "reached a streak milestone")
        XCTAssertEqual(FamilyActivity.ActivityType.achievementUnlocked.displayText, "unlocked an achievement")
        XCTAssertEqual(FamilyActivity.ActivityType.joined.displayText, "joined the family circle")
    }

    func test_activityType_iconName() {
        XCTAssertEqual(FamilyActivity.ActivityType.prayerLogged.iconName, "moon.stars")
        XCTAssertEqual(FamilyActivity.ActivityType.quranReading.iconName, "book")
        XCTAssertEqual(FamilyActivity.ActivityType.lessonCompleted.iconName, "graduationcap")
        XCTAssertEqual(FamilyActivity.ActivityType.streakMilestone.iconName, "flame")
        XCTAssertEqual(FamilyActivity.ActivityType.achievementUnlocked.iconName, "trophy")
        XCTAssertEqual(FamilyActivity.ActivityType.joined.iconName, "person.badge.plus")
    }

    // MARK: - FamilyPrivacySettings Tests

    func test_familyPrivacySettings_defaultValues() {
        let settings = FamilyPrivacySettings.default
        XCTAssertTrue(settings.shareStreak)
        XCTAssertTrue(settings.sharePrayers)
        XCTAssertTrue(settings.shareQuranProgress)
        XCTAssertTrue(settings.shareLearningProgress)
        XCTAssertTrue(settings.shareAchievements)
        XCTAssertTrue(settings.receiveNotifications)
    }

    func test_familyPrivacySettings_hiddenValues() {
        let settings = FamilyPrivacySettings.hidden
        XCTAssertFalse(settings.shareStreak)
        XCTAssertFalse(settings.sharePrayers)
        XCTAssertFalse(settings.shareQuranProgress)
        XCTAssertFalse(settings.shareLearningProgress)
        XCTAssertFalse(settings.shareAchievements)
        XCTAssertFalse(settings.receiveNotifications)
    }

    // MARK: - FamilyRole Tests

    func test_familyRole_allCases() {
        XCTAssertEqual(FamilyRole.allCases.count, 3)
        XCTAssertTrue(FamilyRole.allCases.contains(.admin))
        XCTAssertTrue(FamilyRole.allCases.contains(.member))
        XCTAssertTrue(FamilyRole.allCases.contains(.child))
    }

    func test_familyRole_displayNames() {
        XCTAssertEqual(FamilyRole.admin.displayName, "Admin")
        XCTAssertEqual(FamilyRole.member.displayName, "Member")
        XCTAssertEqual(FamilyRole.child.displayName, "Child")
    }

    // MARK: - InvitationStatus Tests

    func test_invitationStatus_allCases() {
        XCTAssertEqual(InvitationStatus.allCases.count, 4)
        XCTAssertTrue(InvitationStatus.allCases.contains(.pending))
        XCTAssertTrue(InvitationStatus.allCases.contains(.accepted))
        XCTAssertTrue(InvitationStatus.allCases.contains(.declined))
        XCTAssertTrue(InvitationStatus.allCases.contains(.expired))
    }

    // MARK: - FamilyInvitation Tests

    func test_familyInvitation_isIdentifiable() {
        let invitation = FamilyInvitation(
            circleId: "circle1",
            circleName: "Test Circle",
            invitedBy: "user1",
            inviteeEmail: "test@test.com"
        )
        XCTAssertFalse(invitation.id.isEmpty)
    }

    func test_familyInvitation_defaultStatusIsPending() {
        let invitation = FamilyInvitation(
            circleId: "circle1",
            circleName: "Test Circle",
            invitedBy: "user1",
            inviteeEmail: "test@test.com"
        )
        XCTAssertEqual(invitation.status, .pending)
    }

    // MARK: - FamilyLeaderboardEntry Tests

    func test_familyLeaderboardEntry_isIdentifiable() {
        let entry = FamilyLeaderboardEntry(
            memberId: "member1",
            memberName: "Test User",
            hasanat: 100,
            rank: 1
        )
        XCTAssertFalse(entry.id.isEmpty)
    }

    func test_familyLeaderboardEntry_storesAllProperties() {
        let entry = FamilyLeaderboardEntry(
            memberId: "member1",
            memberName: "Test User",
            hasanat: 500,
            rank: 2
        )

        XCTAssertEqual(entry.memberId, "member1")
        XCTAssertEqual(entry.memberName, "Test User")
        XCTAssertEqual(entry.hasanat, 500)
        XCTAssertEqual(entry.rank, 2)
    }

    // MARK: - FamilyActivityType Tests

    func test_familyActivityType_allCases() {
        XCTAssertEqual(FamilyActivityType.allCases.count, 5)
    }

    func test_familyActivityType_iconNames() {
        XCTAssertEqual(FamilyActivityType.prayer.iconName, "moon.stars")
        XCTAssertEqual(FamilyActivityType.quran.iconName, "book")
        XCTAssertEqual(FamilyActivityType.learning.iconName, "graduationcap")
        XCTAssertEqual(FamilyActivityType.dhikr.iconName, "hands.sparkles")
        XCTAssertEqual(FamilyActivityType.achievement.iconName, "trophy")
    }

    // MARK: - SimpleFamilyCircle Tests

    func test_simpleFamilyCircle_isIdentifiable() {
        let circle = SimpleFamilyCircle(name: "Test", createdBy: "user1")
        XCTAssertFalse(circle.id.isEmpty)
    }

    func test_simpleFamilyCircle_defaultMembersIsEmpty() {
        let circle = SimpleFamilyCircle(name: "Test", createdBy: "user1")
        XCTAssertTrue(circle.members.isEmpty)
    }

    // MARK: - SimpleFamilyMember Tests

    func test_simpleFamilyMember_isIdentifiable() {
        let member = SimpleFamilyMember(userId: "user1", displayName: "Test", role: .member)
        XCTAssertFalse(member.id.isEmpty)
    }

    // MARK: - SimpleFamilyActivity Tests

    func test_simpleFamilyActivity_isIdentifiable() {
        let activity = SimpleFamilyActivity(
            memberId: "member1",
            memberName: "Test",
            type: .prayer,
            description: "Test description"
        )
        XCTAssertFalse(activity.id.isEmpty)
    }
}
