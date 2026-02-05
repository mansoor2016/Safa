// MARK: - DuaRepositoryProtocol.swift
// PURPOSE: Defines contract for Dua and Adhkar data access

import Foundation

protocol DuaRepositoryProtocol {
    /// Fetches all dua categories
    /// - Returns: Array of dua categories
    func getCategories() async throws -> [DuaCategory]

    /// Fetches duas in a category
    /// - Parameter categoryId: The category identifier
    /// - Returns: Array of duas
    func getDuas(forCategory categoryId: String) async throws -> [Dua]

    /// Fetches a specific dua
    /// - Parameter id: The dua identifier
    /// - Returns: The dua if found
    func getDua(id: String) async throws -> Dua?

    /// Fetches morning adhkar
    /// - Returns: Array of morning adhkar
    func getMorningAdhkar() async throws -> [Dua]

    /// Fetches evening adhkar
    /// - Returns: Array of evening adhkar
    func getEveningAdhkar() async throws -> [Dua]

    /// Fetches sleep adhkar
    /// - Returns: Array of sleep adhkar
    func getSleepAdhkar() async throws -> [Dua]

    /// Fetches favorite duas
    /// - Returns: Array of favorited duas
    func getFavorites() async throws -> [Dua]

    /// Adds a dua to favorites
    /// - Parameter dua: The dua to favorite
    func addToFavorites(_ dua: Dua) async throws

    /// Removes a dua from favorites
    /// - Parameter dua: The dua to unfavorite
    func removeFromFavorites(_ dua: Dua) async throws

    /// Searches duas by text
    /// - Parameter query: The search query
    /// - Returns: Array of matching duas
    func searchDuas(query: String) async throws -> [Dua]

    /// Marks an adhkar item as completed for today
    /// - Parameter dua: The adhkar dua
    /// - Parameter type: Morning, evening, or sleep
    func markAdhkarCompleted(_ dua: Dua, type: AdhkarType) async throws

    /// Gets completion status for adhkar today
    /// - Parameter type: Morning, evening, or sleep
    /// - Returns: Array of completed dua IDs
    func getAdhkarCompletionStatus(for type: AdhkarType) async throws -> [String]

    /// Resets adhkar completion for a new day
    func resetAdhkarCompletion() async throws
}
