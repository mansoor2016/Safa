// MARK: - QuranRepositoryProtocol.swift
// PURPOSE: Defines contract for Quran data access and progress tracking

import Foundation

protocol QuranRepositoryProtocol {
    /// Fetches all surahs
    /// - Returns: Array of all 114 surahs
    func getAllSurahs() async throws -> [Surah]

    /// Fetches a specific surah by number
    /// - Parameter number: Surah number (1-114)
    /// - Returns: The surah if found
    func getSurah(number: Int) async throws -> Surah?

    /// Fetches all ayahs for a surah
    /// - Parameter surahNumber: The surah number
    /// - Returns: Array of ayahs
    func getAyahs(forSurah surahNumber: Int) async throws -> [Ayah]

    /// Fetches a specific ayah
    /// - Parameters:
    ///   - surahNumber: The surah number
    ///   - ayahNumber: The ayah number within the surah
    /// - Returns: The ayah if found
    func getAyah(surah surahNumber: Int, ayah ayahNumber: Int) async throws -> Ayah?

    /// Searches ayahs by text query
    /// - Parameter query: The search query
    /// - Returns: Array of matching ayahs
    func searchAyahs(query: String) async throws -> [Ayah]

    /// Fetches all bookmarks
    /// - Returns: Array of bookmarked ayahs
    func getBookmarks() async throws -> [QuranBookmark]

    /// Adds a bookmark
    /// - Parameter ayah: The ayah to bookmark
    func addBookmark(surah: Int, ayah: Int) async throws

    /// Removes a bookmark
    /// - Parameter bookmark: The bookmark to remove
    func removeBookmark(surah: Int, ayah: Int) async throws

    /// Checks if an ayah is bookmarked
    /// - Parameters:
    ///   - surah: Surah number
    ///   - ayah: Ayah number
    /// - Returns: True if bookmarked
    func isBookmarked(surah: Int, ayah: Int) async throws -> Bool

    /// Gets current reading progress
    /// - Returns: The current reading progress
    func getReadingProgress() async throws -> QuranProgress?

    /// Updates reading progress
    /// - Parameters:
    ///   - surah: Current surah number
    ///   - ayah: Current ayah number
    func updateProgress(surah: Int, ayah: Int) async throws

    /// Gets Juz information
    /// - Parameter number: Juz number (1-30)
    /// - Returns: Juz details including start/end surah and ayah
    func getJuz(number: Int) async throws -> Juz?

    /// Gets all Juz
    /// - Returns: Array of all 30 Juz
    func getAllJuz() async throws -> [Juz]

    /// Gets surah read progress
    /// - Parameter surahNumber: The surah number
    /// - Returns: Progress data with set of read ayahs
    func getSurahReadProgress(surahNumber: Int) async throws -> SurahReadProgress?

    /// Marks an ayah as read
    /// - Parameters:
    ///   - surahNumber: The surah number
    ///   - ayahNumber: The ayah number
    ///   - totalAyahs: Total ayahs in the surah
    func markAyahRead(surahNumber: Int, ayahNumber: Int, totalAyahs: Int) async throws

    /// Updates a bookmark's note
    /// - Parameters:
    ///   - surahNumber: Surah number
    ///   - ayahNumber: Ayah number
    ///   - note: The new note text (nil to remove)
    func updateBookmarkNote(surahNumber: Int, ayahNumber: Int, note: String?) async throws
}
