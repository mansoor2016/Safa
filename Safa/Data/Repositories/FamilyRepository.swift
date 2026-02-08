// MARK: - FamilyRepository.swift
// PURPOSE: Implementation of family circle features and sharing
// DEPENDENCIES: CoreData, CloudKit, FamilyRepositoryProtocol

import Foundation
import CoreData
import CloudKit

final class FamilyRepository: FamilyRepositoryProtocol {
    // MARK: - Dependencies
    private let coreData: CoreDataStack
    private let cloudContainer: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase

    // MARK: - Storage Keys
    private let familyCircleKey = "com.safa.family.circle"
    private let familyMembersKey = "com.safa.family.members"
    private let activityFeedKey = "com.safa.family.activity"
    private let privacySettingsKey = "com.safa.family.privacy"
    private let notificationsEnabledKey = "com.safa.family.notifications"

    // MARK: - CloudKit Record Types
    private let circleRecordType = "FamilyCircle"
    private let memberRecordType = "FamilyMember"
    private let activityRecordType = "FamilyActivity"

    // MARK: - Init
    init(
        coreData: CoreDataStack,
        cloudContainer: CKContainer = CKContainer(identifier: "iCloud.com.safa.app")
    ) {
        self.coreData = coreData
        self.cloudContainer = cloudContainer
        self.privateDatabase = cloudContainer.privateCloudDatabase
        self.sharedDatabase = cloudContainer.sharedCloudDatabase
    }

    // MARK: - Family Circle Management

    func getFamilyCircle() async throws -> FamilyCircle? {
        guard let data = UserDefaults.standard.data(forKey: familyCircleKey),
              let circle = try? JSONDecoder().decode(FamilyCircle.self, from: data) else {
            return nil
        }
        return circle
    }

    func createFamilyCircle(name: String) async throws -> FamilyCircle {
        // Get CloudKit user record ID
        let userRecordID = try await cloudContainer.userRecordID()
        let ownerId = userRecordID.recordName

        let circle = FamilyCircle(name: name, ownerId: ownerId)

        // Save to CloudKit
        let record = CKRecord(recordType: circleRecordType)
        record["id"] = circle.id.uuidString
        record["name"] = circle.name
        record["ownerId"] = ownerId
        record["inviteCode"] = circle.inviteCode
        record["createdAt"] = circle.createdAt
        record["memberCount"] = 1

        try await privateDatabase.save(record)

        // Save locally
        let data = try JSONEncoder().encode(circle)
        UserDefaults.standard.set(data, forKey: familyCircleKey)

        // Add creator as first member
        let member = FamilyMember(
            circleId: circle.id,
            name: "You",
            isOwner: true
        )
        try await saveMember(member)

        return circle
    }

    func joinFamilyCircle(inviteCode: String) async throws {
        // Query CloudKit for the circle with this invite code
        let predicate = NSPredicate(format: "inviteCode == %@", inviteCode)
        let query = CKQuery(recordType: circleRecordType, predicate: predicate)

        let (matchResults, _) = try await sharedDatabase.records(matching: query)

        guard let (_, result) = matchResults.first,
              case .success(let record) = result else {
            throw FamilyError.invalidInviteCode
        }

        // Create local circle from CloudKit record
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = record["name"] as? String,
              let ownerId = record["ownerId"] as? String else {
            throw FamilyError.invalidInviteCode
        }

        let circle = FamilyCircle(
            id: id,
            name: name,
            ownerId: ownerId,
            inviteCode: inviteCode
        )

        // Save locally
        let data = try JSONEncoder().encode(circle)
        UserDefaults.standard.set(data, forKey: familyCircleKey)

        // Create member record for this user
        let userRecordID = try await cloudContainer.userRecordID()
        let member = FamilyMember(
            circleId: circle.id,
            name: "New Member",
            isOwner: false
        )
        try await saveMember(member)

        // Update member count in CloudKit
        record["memberCount"] = (record["memberCount"] as? Int ?? 0) + 1
        try await sharedDatabase.save(record)
    }

    func leaveFamilyCircle() async throws {
        // Remove from CloudKit if exists
        if let circle = try await getFamilyCircle() {
            let recordID = CKRecord.ID(recordName: circle.id.uuidString)
            try? await sharedDatabase.deleteRecord(withID: recordID)
        }

        UserDefaults.standard.removeObject(forKey: familyCircleKey)
        UserDefaults.standard.removeObject(forKey: familyMembersKey)
        UserDefaults.standard.removeObject(forKey: activityFeedKey)
    }

    func getInviteCode() async throws -> String {
        guard let circle = try await getFamilyCircle() else {
            throw FamilyError.noCircle
        }
        return circle.inviteCode
    }

    func generateInviteLink() async throws -> URL {
        guard let circle = try await getFamilyCircle() else {
            throw FamilyError.noCircle
        }

        // Create a CKShare for the circle
        let recordID = CKRecord.ID(recordName: circle.id.uuidString)

        do {
            // Try to fetch existing record
            let record = try await privateDatabase.record(for: recordID)

            // Create a share
            let share = CKShare(rootRecord: record)
            share[CKShare.SystemFieldKey.title] = "\(circle.name) Family Circle"
            share.publicPermission = .readWrite

            // Save the share
            let operation = CKModifyRecordsOperation(
                recordsToSave: [record, share],
                recordIDsToDelete: nil
            )

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                privateDatabase.add(operation)
            }

            // Return the share URL
            if let shareURL = share.url {
                return shareURL
            }
        } catch {
            // Fall back to deep link if CloudKit sharing fails
        }

        // Fallback: Use deep link with invite code
        let code = circle.inviteCode
        guard let url = URL(string: "safa://family/join?code=\(code)") else {
            throw FamilyError.invalidInviteCode
        }
        return url
    }

    // MARK: - Members

    func getFamilyMembers() async throws -> [FamilyMember] {
        guard let data = UserDefaults.standard.data(forKey: familyMembersKey),
              let members = try? JSONDecoder().decode([FamilyMember].self, from: data) else {
            return []
        }
        return members.sorted { $0.joinedAt < $1.joinedAt }
    }

    func getMember(id memberId: String) async throws -> FamilyMember? {
        let members = try await getFamilyMembers()
        return members.first { $0.id.uuidString == memberId }
    }

    func removeMember(id memberId: String) async throws {
        var members = try await getFamilyMembers()
        members.removeAll { $0.id.uuidString == memberId }

        let data = try JSONEncoder().encode(members)
        UserDefaults.standard.set(data, forKey: familyMembersKey)

        // Update member count
        if var circle = try await getFamilyCircle() {
            circle.memberCount = members.count
            let circleData = try JSONEncoder().encode(circle)
            UserDefaults.standard.set(circleData, forKey: familyCircleKey)
        }
    }

    // MARK: - Activity Feed

    func getActivityFeed(limit: Int) async throws -> [FamilyActivity] {
        guard let data = UserDefaults.standard.data(forKey: activityFeedKey),
              let activities = try? JSONDecoder().decode([FamilyActivity].self, from: data) else {
            return []
        }
        return Array(activities.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
    }

    func shareActivity(_ activity: FamilyActivity) async throws {
        var activities = (try? await getActivityFeed(limit: 1000)) ?? []
        activities.append(activity)

        // Keep only last 100 activities
        if activities.count > 100 {
            activities = Array(activities.suffix(100))
        }

        let data = try JSONEncoder().encode(activities)
        UserDefaults.standard.set(data, forKey: activityFeedKey)
    }

    // MARK: - Privacy Settings

    func getPrivacySettings() async throws -> FamilyPrivacySettings {
        guard let data = UserDefaults.standard.data(forKey: privacySettingsKey),
              let settings = try? JSONDecoder().decode(FamilyPrivacySettings.self, from: data) else {
            return .default
        }
        return settings
    }

    func updatePrivacySettings(_ settings: FamilyPrivacySettings) async throws {
        let data = try JSONEncoder().encode(settings)
        UserDefaults.standard.set(data, forKey: privacySettingsKey)
    }

    // MARK: - Notifications

    func setFamilyNotifications(enabled: Bool) async throws {
        UserDefaults.standard.set(enabled, forKey: notificationsEnabledKey)
    }

    // MARK: - Private Helpers

    private func saveMember(_ member: FamilyMember) async throws {
        var members = try await getFamilyMembers()
        members.append(member)

        let data = try JSONEncoder().encode(members)
        UserDefaults.standard.set(data, forKey: familyMembersKey)
    }
}

// MARK: - Family Errors

enum FamilyError: LocalizedError {
    case noCircle
    case invalidInviteCode
    case notOwner
    case alreadyMember

    var errorDescription: String? {
        switch self {
        case .noCircle:
            return String(localized: "You are not part of a family circle.")
        case .invalidInviteCode:
            return String(localized: "The invite code is invalid or expired.")
        case .notOwner:
            return String(localized: "Only the circle owner can perform this action.")
        case .alreadyMember:
            return String(localized: "You are already a member of this circle.")
        }
    }
}
