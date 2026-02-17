// MARK: - QuranViewModelTests.swift
// PURPOSE: Unit tests for QuranViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

@MainActor
final class QuranViewModelTests: XCTestCase {

    var sut: QuranViewModel!
    var mockRepository: TestableQuranRepository!
    var mockUserState: UserStateManager!

    override func setUp() {
        super.setUp()
        mockRepository = TestableQuranRepository()
        mockUserState = UserStateManager(userRepository: StubUserRepository())
        sut = QuranViewModel(quranRepository: mockRepository, userState: mockUserState)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        mockUserState = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasEmptySurahs() {
        XCTAssertTrue(sut.surahs.isEmpty)
    }

    func test_initialState_hasEmptyJuzList() {
        XCTAssertTrue(sut.juzList.isEmpty)
    }

    func test_initialState_hasEmptyBookmarks() {
        XCTAssertTrue(sut.bookmarks.isEmpty)
    }

    func test_initialState_hasNoReadingProgress() {
        XCTAssertNil(sut.readingProgress)
    }

    func test_initialState_hasEmptySearchResults() {
        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    func test_initialState_isNotLoading() {
        XCTAssertFalse(sut.isLoading)
    }

    func test_initialState_hasNoError() {
        XCTAssertNil(sut.error)
    }

    func test_initialState_hasEmptySearchQuery() {
        XCTAssertTrue(sut.searchQuery.isEmpty)
    }

    // MARK: - Load Surahs Tests

    func test_loadSurahs_populatesSurahs() async {
        // Given
        let expectedSurahs = [
            Surah(
                id: 1,
                nameArabic: "الفاتحة",
                nameEnglish: "The Opening",
                nameTransliteration: "Al-Fatihah",
                revelationType: .meccan,
                ayahCount: 7,
                juzStart: 1
            )
        ]
        mockRepository.surahsToReturn = expectedSurahs

        // When
        await sut.loadSurahs()

        // Then
        XCTAssertEqual(sut.surahs.count, 1)
        XCTAssertEqual(sut.surahs.first?.nameEnglish, "The Opening")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func test_loadSurahs_doesNotReloadIfAlreadyLoaded() async {
        // Given
        mockRepository.surahsToReturn = [
            Surah(
                id: 1,
                nameArabic: "الفاتحة",
                nameEnglish: "The Opening",
                nameTransliteration: "Al-Fatihah",
                revelationType: .meccan,
                ayahCount: 7,
                juzStart: 1
            )
        ]
        await sut.loadSurahs()
        let callCount = mockRepository.getAllSurahsCallCount

        // When
        await sut.loadSurahs()

        // Then - should not call repository again
        XCTAssertEqual(mockRepository.getAllSurahsCallCount, callCount)
    }

    func test_loadSurahs_failure_setsError() async {
        // Given
        mockRepository.errorToThrow = TestError.loadFailed

        // When
        await sut.loadSurahs()

        // Then
        XCTAssertTrue(sut.surahs.isEmpty)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Load Juz Tests

    func test_loadJuz_populatesJuzList() async {
        // Given
        let expectedJuz = [
            Juz(id: 1, startSurah: 1, startAyah: 1, endSurah: 2, endAyah: 141)
        ]
        mockRepository.juzListToReturn = expectedJuz

        // When
        await sut.loadJuz()

        // Then
        XCTAssertEqual(sut.juzList.count, 1)
        XCTAssertEqual(sut.juzList.first?.number, 1)
    }

    func test_loadJuz_doesNotReloadIfAlreadyLoaded() async {
        // Given
        mockRepository.juzListToReturn = [
            Juz(id: 1, startSurah: 1, startAyah: 1, endSurah: 2, endAyah: 141)
        ]
        await sut.loadJuz()
        let callCount = mockRepository.getAllJuzCallCount

        // When
        await sut.loadJuz()

        // Then
        XCTAssertEqual(mockRepository.getAllJuzCallCount, callCount)
    }

    // MARK: - Search Tests

    func test_search_withEmptyQuery_clearsResults() async {
        // Given
        sut.searchResults = [
            Ayah(surahNumber: 1, ayahNumber: 1, textArabic: "Arabic", textTranslation: "English", juzNumber: 1, pageNumber: 1)
        ]

        // When
        await sut.search(query: "")

        // Then
        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    func test_search_withQuery_updatesSearchQuery() async {
        // When
        await sut.search(query: "test")

        // Then
        XCTAssertEqual(sut.searchQuery, "test")
    }

    func test_search_success_populatesSearchResults() async {
        // Given
        let expectedResults = [
            Ayah(surahNumber: 1, ayahNumber: 1, textArabic: "بسم الله", textTranslation: "In the name of Allah", juzNumber: 1, pageNumber: 1),
            Ayah(surahNumber: 1, ayahNumber: 2, textArabic: "الحمد لله", textTranslation: "Praise be to Allah", juzNumber: 1, pageNumber: 1)
        ]
        mockRepository.searchResultsToReturn = expectedResults

        // When
        await sut.search(query: "Allah")

        // Then
        XCTAssertEqual(sut.searchResults.count, 2)
        XCTAssertNil(sut.error)
    }

    func test_search_failure_setsError() async {
        // Given
        mockRepository.errorToThrow = TestError.searchFailed

        // When
        await sut.search(query: "test")

        // Then
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Filtered Surahs Tests

    func test_filteredSurahs_withEmptyQuery_returnsAllSurahs() async {
        // Given
        mockRepository.surahsToReturn = [
            Surah(id: 1, nameArabic: "الفاتحة", nameEnglish: "The Opening", nameTransliteration: "Al-Fatihah", revelationType: .meccan, ayahCount: 7, juzStart: 1),
            Surah(id: 2, nameArabic: "البقرة", nameEnglish: "The Cow", nameTransliteration: "Al-Baqarah", revelationType: .medinan, ayahCount: 286, juzStart: 1)
        ]
        await sut.loadSurahs()

        // When
        sut.searchQuery = ""

        // Then
        XCTAssertEqual(sut.filteredSurahs.count, 2)
    }

    func test_filteredSurahs_withQuery_filtersResults() async {
        // Given
        mockRepository.surahsToReturn = [
            Surah(id: 1, nameArabic: "الفاتحة", nameEnglish: "The Opening", nameTransliteration: "Al-Fatihah", revelationType: .meccan, ayahCount: 7, juzStart: 1),
            Surah(id: 2, nameArabic: "البقرة", nameEnglish: "The Cow", nameTransliteration: "Al-Baqarah", revelationType: .medinan, ayahCount: 286, juzStart: 1)
        ]
        await sut.loadSurahs()

        // When
        sut.searchQuery = "Opening"

        // Then
        XCTAssertEqual(sut.filteredSurahs.count, 1)
        XCTAssertEqual(sut.filteredSurahs.first?.nameEnglish, "The Opening")
    }

    func test_filteredSurahs_caseInsensitive() async {
        // Given
        mockRepository.surahsToReturn = [
            Surah(id: 1, nameArabic: "الفاتحة", nameEnglish: "The Opening", nameTransliteration: "Al-Fatihah", revelationType: .meccan, ayahCount: 7, juzStart: 1)
        ]
        await sut.loadSurahs()

        // When
        sut.searchQuery = "opening"

        // Then
        XCTAssertEqual(sut.filteredSurahs.count, 1)
    }

    func test_filteredSurahs_matchesTransliteration() async {
        // Given
        mockRepository.surahsToReturn = [
            Surah(id: 1, nameArabic: "الفاتحة", nameEnglish: "The Opening", nameTransliteration: "Al-Fatihah", revelationType: .meccan, ayahCount: 7, juzStart: 1),
            Surah(id: 2, nameArabic: "البقرة", nameEnglish: "The Cow", nameTransliteration: "Al-Baqarah", revelationType: .medinan, ayahCount: 286, juzStart: 1)
        ]
        await sut.loadSurahs()

        // When
        sut.searchQuery = "Baqarah"

        // Then
        XCTAssertEqual(sut.filteredSurahs.count, 1)
        XCTAssertEqual(sut.filteredSurahs.first?.number, 2)
    }

    // MARK: - Bookmark Tests

    func test_loadBookmarks_populatesBookmarks() async {
        // Given
        let expectedBookmarks = [
            QuranBookmark(surahNumber: 2, ayahNumber: 255)
        ]
        mockRepository.bookmarksToReturn = expectedBookmarks

        // When
        await sut.loadBookmarks()

        // Then
        XCTAssertEqual(sut.bookmarks.count, 1)
        XCTAssertEqual(sut.bookmarks.first?.ayahNumber, 255)
    }

    func test_isBookmarked_callsRepository() async {
        // Given
        mockRepository.isBookmarkedResult = true

        // When
        let result = await sut.isBookmarked(surah: 2, ayah: 255)

        // Then
        XCTAssertTrue(result)
    }

    // MARK: - Navigation Helper Tests

    func test_navigationTargetForJuz_returnsCorrectTarget() async {
        // Given
        mockRepository.juzListToReturn = [
            Juz(id: 1, startSurah: 1, startAyah: 1, endSurah: 2, endAyah: 141),
            Juz(id: 2, startSurah: 2, startAyah: 142, endSurah: 2, endAyah: 252)
        ]
        await sut.loadJuz()

        // When
        let target = sut.navigationTargetForJuz(2)

        // Then
        XCTAssertEqual(target?.surahNumber, 2)
        XCTAssertEqual(target?.startAyah, 142)
    }

    func test_navigationTargetForJuz_returnsNilForInvalidJuz() async {
        // Given
        mockRepository.juzListToReturn = [
            Juz(id: 1, startSurah: 1, startAyah: 1, endSurah: 2, endAyah: 141)
        ]
        await sut.loadJuz()

        // When
        let target = sut.navigationTargetForJuz(99)

        // Then
        XCTAssertNil(target)
    }

    // MARK: - QuranNavigationTarget Tests

    func test_quranNavigationTarget_equality() {
        let a = QuranNavigationTarget(surahNumber: 2, startAyah: 255)
        let b = QuranNavigationTarget(surahNumber: 2, startAyah: 255)
        XCTAssertEqual(a, b)
    }

    func test_quranNavigationTarget_defaultStartAyah() {
        let target = QuranNavigationTarget(surahNumber: 1)
        XCTAssertEqual(target.startAyah, 1)
    }

    func test_quranNavigationTarget_hashable() {
        let a = QuranNavigationTarget(surahNumber: 1, startAyah: 1)
        let b = QuranNavigationTarget(surahNumber: 2, startAyah: 142)
        let set: Set<QuranNavigationTarget> = [a, b]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Helper Tests

    func test_getSurahName_returnsSurahName() async {
        // Given
        mockRepository.surahsToReturn = [
            Surah(id: 1, nameArabic: "الفاتحة", nameEnglish: "The Opening", nameTransliteration: "Al-Fatihah", revelationType: .meccan, ayahCount: 7, juzStart: 1)
        ]
        await sut.loadSurahs()

        // When
        let name = sut.getSurahName(1)

        // Then
        XCTAssertEqual(name, "The Opening")
    }

    func test_getSurahName_returnsDefault_whenSurahNotFound() {
        // When
        let name = sut.getSurahName(999)

        // Then
        XCTAssertEqual(name, "Surah 999")
    }
}

// MARK: - Test Error

private enum TestError: Error {
    case loadFailed
    case searchFailed
}

// MARK: - Testable Quran Repository

@MainActor
final class TestableQuranRepository: QuranRepositoryProtocol {
    var surahsToReturn: [Surah] = []
    var juzListToReturn: [Juz] = []
    var ayahsToReturn: [Ayah] = []
    var searchResultsToReturn: [Ayah] = []
    var bookmarksToReturn: [QuranBookmark] = []
    var readingProgressToReturn: QuranProgress?
    var isBookmarkedResult: Bool = false
    var errorToThrow: Error?

    var getAllSurahsCallCount = 0
    var getAllJuzCallCount = 0

    nonisolated func getAllSurahs() async throws -> [Surah] {
        let error = await errorToThrow
        if let error {
            throw error
        }
        await MainActor.run { getAllSurahsCallCount += 1 }
        return await surahsToReturn
    }

    nonisolated func getSurah(number: Int) async throws -> Surah? {
        return await surahsToReturn.first { $0.number == number }
    }

    nonisolated func getAyahs(forSurah surahNumber: Int) async throws -> [Ayah] {
        let error = await errorToThrow
        if let error {
            throw error
        }
        return await ayahsToReturn
    }

    nonisolated func getAyah(surah surahNumber: Int, ayah ayahNumber: Int) async throws -> Ayah? {
        return nil
    }

    nonisolated func getAllJuz() async throws -> [Juz] {
        let error = await errorToThrow
        if let error {
            throw error
        }
        await MainActor.run { getAllJuzCallCount += 1 }
        return await juzListToReturn
    }

    nonisolated func getJuz(number: Int) async throws -> Juz? {
        return await juzListToReturn.first { $0.number == number }
    }

    nonisolated func searchAyahs(query: String) async throws -> [Ayah] {
        let error = await errorToThrow
        if let error {
            throw error
        }
        return await searchResultsToReturn
    }

    nonisolated func getBookmarks() async throws -> [QuranBookmark] {
        let error = await errorToThrow
        if let error {
            throw error
        }
        return await bookmarksToReturn
    }

    nonisolated func addBookmark(surah: Int, ayah: Int) async throws {
        let error = await errorToThrow
        if let error {
            throw error
        }
    }

    nonisolated func removeBookmark(surah: Int, ayah: Int) async throws {
        let error = await errorToThrow
        if let error {
            throw error
        }
    }

    nonisolated func isBookmarked(surah: Int, ayah: Int) async throws -> Bool {
        return await isBookmarkedResult
    }

    nonisolated func getReadingProgress() async throws -> QuranProgress? {
        return await readingProgressToReturn
    }

    nonisolated func updateProgress(surah: Int, ayah: Int) async throws {
    }

    nonisolated func getSurahReadProgress(surahNumber: Int) async throws -> SurahReadProgress? {
        return nil
    }

    nonisolated func markAyahRead(surahNumber: Int, ayahNumber: Int, totalAyahs: Int) async throws {
    }

    nonisolated func updateBookmarkNote(surahNumber: Int, ayahNumber: Int, note: String?) async throws {
    }

    nonisolated func getCompletedSurahNumbers() async throws -> Set<Int> {
        return []
    }

    nonisolated func resetSurahProgress(surahNumber: Int) async throws {}
}

// MARK: - Stub User Repository

@MainActor
final class StubUserRepository: UserRepositoryProtocol {
    nonisolated func getUserStats() async throws -> UserStats {
        return UserStats()
    }

    nonisolated func updateUserStats(_ stats: UserStats) async throws {}

    nonisolated func addHasanat(_ amount: Int) async throws -> Int {
        return amount
    }

    nonisolated func getStreaks() async throws -> [Streak] {
        return StreakType.allCases.map { Streak(type: $0) }
    }

    nonisolated func getStreak(type: StreakType) async throws -> Streak? {
        return Streak(type: type)
    }

    nonisolated func updateStreak(_ streak: Streak) async throws {}

    nonisolated func recordStreakActivity(type: StreakType) async throws {}

    nonisolated func getPreference<T: Codable>(key: String) async throws -> T? {
        return nil
    }

    nonisolated func setPreference<T: Codable>(key: String, value: T) async throws {}

    nonisolated func getPreferences() async -> UserPreferences {
        return UserPreferences()
    }

    nonisolated func updatePreferences(_ preferences: UserPreferences) async throws {}

    nonisolated func getStreakFreezes() async throws -> Int {
        return 0
    }

    nonisolated func useStreakFreeze() async throws {}

    nonisolated func awardStreakFreeze() async throws {}
}
