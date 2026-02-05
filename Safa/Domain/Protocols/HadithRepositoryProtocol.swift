// MARK: - HadithRepositoryProtocol.swift
// PURPOSE: Defines contract for Hadith data access

import Foundation

protocol HadithRepositoryProtocol {
    /// Fetches all hadith collections
    /// - Returns: Array of hadith collections
    func getCollections() async throws -> [HadithCollection]

    /// Fetches books within a collection
    /// - Parameter collectionId: The collection identifier
    /// - Returns: Array of books
    func getBooks(forCollection collectionId: String) async throws -> [HadithBook]

    /// Fetches hadiths from a specific book
    /// - Parameters:
    ///   - collectionId: The collection identifier
    ///   - bookId: The book identifier
    /// - Returns: Array of hadiths
    func getHadiths(collection collectionId: String, book bookId: String) async throws -> [Hadith]

    /// Fetches a specific hadith
    /// - Parameters:
    ///   - collectionId: The collection identifier
    ///   - hadithNumber: The hadith number
    /// - Returns: The hadith if found
    func getHadith(collection collectionId: String, number hadithNumber: Int) async throws -> Hadith?

    /// Searches hadiths by text query
    /// - Parameter query: The search query
    /// - Returns: Array of matching hadiths
    func searchHadiths(query: String) async throws -> [Hadith]

    /// Gets the daily hadith
    /// - Parameter date: The date to get the daily hadith for
    /// - Returns: The daily hadith
    func getDailyHadith(for date: Date) async throws -> Hadith

    /// Fetches bookmarked hadiths
    /// - Returns: Array of bookmarked hadiths
    func getBookmarks() async throws -> [Hadith]

    /// Adds a hadith bookmark
    /// - Parameter hadith: The hadith to bookmark
    func addBookmark(_ hadith: Hadith) async throws

    /// Removes a hadith bookmark
    /// - Parameter hadith: The hadith to unbookmark
    func removeBookmark(_ hadith: Hadith) async throws
}
