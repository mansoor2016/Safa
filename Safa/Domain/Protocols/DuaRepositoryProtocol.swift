// MARK: - DuaRepositoryProtocol.swift
// PURPOSE: Defines contract for Dua and Dhikr data access

import Foundation

protocol DuaRepositoryProtocol {
    /// Fetches all dua categories
    /// - Returns: Array of dua categories
    func getCategories() async throws -> [DuaCategory]

    /// Fetches all duas
    /// - Returns: Array of all duas
    func getAllDuas() async throws -> [Dua]

    /// Fetches duas in a category
    /// - Parameter categoryId: The category identifier
    /// - Returns: Array of duas
    func getDuas(forCategory categoryId: String) async throws -> [Dua]

    /// Fetches a specific dua
    /// - Parameter id: The dua identifier
    /// - Returns: The dua if found
    func getDua(id: String) async throws -> Dua?

    /// Fetches morning dhikr
    /// - Returns: Array of morning dhikr
    func getMorningDhikr() async throws -> [Dua]

    /// Fetches evening dhikr
    /// - Returns: Array of evening dhikr
    func getEveningDhikr() async throws -> [Dua]

    /// Fetches sleep dhikr
    /// - Returns: Array of sleep dhikr
    func getSleepDhikr() async throws -> [Dua]

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

    /// Marks an dhikr item as completed for today
    /// - Parameter dua: The dhikr dua
    /// - Parameter type: Morning, evening, or sleep
    func markDhikrCompleted(_ dua: Dua, type: DhikrType) async throws

    /// Gets completion status for dhikr today
    /// - Parameter type: Morning, evening, or sleep
    /// - Returns: Array of completed dua IDs
    func getDhikrCompletionStatus(for type: DhikrType) async throws -> [String]

    /// Resets dhikr completion for a new day
    func resetDhikrCompletion() async throws
}
