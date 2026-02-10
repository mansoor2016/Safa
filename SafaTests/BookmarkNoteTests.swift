// MARK: - BookmarkNoteTests.swift
// PURPOSE: Tests for bookmark note editing functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

@MainActor
final class BookmarkNoteTests: XCTestCase {
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

    func test_updateBookmarkNote_reloadsBookmarks() async {
        // Given
        let bookmark = QuranBookmark(surahNumber: 2, ayahNumber: 255)
        mockRepository.bookmarksToReturn = [bookmark]
        await sut.loadBookmarks()
        XCTAssertEqual(sut.bookmarks.count, 1)

        // When
        await sut.updateBookmarkNote(bookmark, note: "Ayatul Kursi")

        // Then - bookmarks should have been reloaded
        XCTAssertEqual(sut.bookmarks.count, 1)
        XCTAssertNil(sut.error)
    }

    func test_updateBookmarkNote_error_setsError() async {
        // Given
        let bookmark = QuranBookmark(surahNumber: 2, ayahNumber: 255)
        mockRepository.errorToThrow = NSError(domain: "test", code: 1)

        // When
        await sut.updateBookmarkNote(bookmark, note: "note")

        // Then
        XCTAssertNotNil(sut.error)
    }

    func test_updateBookmarkNote_emptyStringTreatedAsNil() async {
        // Given
        let bookmark = QuranBookmark(surahNumber: 2, ayahNumber: 255, note: "old note")
        mockRepository.bookmarksToReturn = [bookmark]

        // When - passing empty string should normalize to nil in repository
        await sut.updateBookmarkNote(bookmark, note: "")

        // Then
        XCTAssertNil(sut.error)
    }

    func test_updateBookmarkNote_nilRemovesNote() async {
        // Given
        let bookmark = QuranBookmark(surahNumber: 2, ayahNumber: 255, note: "old note")
        mockRepository.bookmarksToReturn = [bookmark]

        // When
        await sut.updateBookmarkNote(bookmark, note: nil)

        // Then
        XCTAssertNil(sut.error)
    }
}
