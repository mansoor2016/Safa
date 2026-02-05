// MARK: - FamilyRepositoryProtocol.swift
// PURPOSE: Defines contract for family circle features and sharing

import Foundation

protocol FamilyRepositoryProtocol {
    // MARK: - Family Circle Management

    /// Gets the current family circle
    /// - Returns: The family circle if joined
    func getFamilyCircle() async throws -> FamilyCircle?

    /// Creates a new family circle
    /// - Parameter name: The circle name
    /// - Returns: The created circle
    func createFamilyCircle(name: String) async throws -> FamilyCircle

    /// Joins an existing family circle
    /// - Parameter inviteCode: The invite code
    func joinFamilyCircle(inviteCode: String) async throws

    /// Leaves the current family circle
    func leaveFamilyCircle() async throws

    /// Gets the invite code for the current circle
    /// - Returns: The invite code
    func getInviteCode() async throws -> String

    /// Generates a shareable invite link
    /// - Returns: The invite URL
    func generateInviteLink() async throws -> URL

    // MARK: - Members

    /// Gets members of the family circle
    /// - Returns: Array of family members
    func getFamilyMembers() async throws -> [FamilyMember]

    /// Gets a specific member's details
    /// - Parameter memberId: The member identifier
    /// - Returns: The family member
    func getMember(id memberId: String) async throws -> FamilyMember?

    /// Removes a member from the circle (owner only)
    /// - Parameter memberId: The member identifier
    func removeMember(id memberId: String) async throws

    // MARK: - Activity Feed

    /// Gets family activity feed
    /// - Parameter limit: Maximum number of items
    /// - Returns: Array of activity items
    func getActivityFeed(limit: Int) async throws -> [FamilyActivity]

    /// Shares an activity with the family
    /// - Parameter activity: The activity to share
    func shareActivity(_ activity: FamilyActivity) async throws

    // MARK: - Privacy Settings

    /// Gets current privacy settings
    /// - Returns: Privacy settings
    func getPrivacySettings() async throws -> FamilyPrivacySettings

    /// Updates privacy settings
    /// - Parameter settings: The new settings
    func updatePrivacySettings(_ settings: FamilyPrivacySettings) async throws

    // MARK: - Notifications

    /// Enables/disables family notifications
    /// - Parameter enabled: Whether notifications are enabled
    func setFamilyNotifications(enabled: Bool) async throws
}
