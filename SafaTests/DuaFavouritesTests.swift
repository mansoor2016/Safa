// MARK: - DuaFavouritesTests.swift
// PURPOSE: Behavioural correctness tests for dua favourites feature.
// Tests add/remove, persistence, idempotency, and filtering.

import XCTest
@testable import Safa

final class DuaFavouritesTests: XCTestCase {
    private var sut: DuaRepository!
    private var allDuas: [Dua]!
    private let favoritesKey = AppConstants.StorageKeys.duaFavorites

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: favoritesKey)
        sut = DuaRepository(coreData: CoreDataStack.shared)
        allDuas = try! DuaDataLoader.load(from: Bundle.main).duas
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: favoritesKey)
        sut = nil
        allDuas = nil
        super.tearDown()
    }

    // MARK: - Add Favourite

    func test_addFavourite_thenGetFavourites_returnsThatDua() async throws {
        let dua = allDuas[0]

        try await sut.addToFavorites(dua)
        let favourites = try await sut.getFavorites()

        XCTAssertTrue(favourites.contains { $0.id == dua.id },
                      "Added dua should appear in favourites")
    }

    // MARK: - Remove Favourite

    func test_removeFavourite_noLongerInFavourites() async throws {
        let dua = allDuas[0]

        try await sut.addToFavorites(dua)
        try await sut.removeFromFavorites(dua)
        let favourites = try await sut.getFavorites()

        XCTAssertFalse(favourites.contains { $0.id == dua.id },
                       "Removed dua should not appear in favourites")
    }

    // MARK: - Idempotent Add

    func test_addDuplicate_countStaysOne() async throws {
        let dua = allDuas[0]

        try await sut.addToFavorites(dua)
        try await sut.addToFavorites(dua)
        let favourites = try await sut.getFavorites()

        let matchCount = favourites.filter { $0.id == dua.id }.count
        XCTAssertEqual(matchCount, 1,
                       "Adding same dua twice should not duplicate it")
    }

    // MARK: - Toggle On Then Off

    func test_toggleOnThenOff_emptyFavourites() async throws {
        let dua = allDuas[0]

        try await sut.addToFavorites(dua)
        try await sut.removeFromFavorites(dua)
        let favourites = try await sut.getFavorites()

        XCTAssertTrue(favourites.isEmpty,
                      "Toggling on then off should leave favourites empty")
    }

    // MARK: - Multiple Favourites

    func test_multipleFavourites_allReturned() async throws {
        let dua1 = allDuas[0]
        let dua2 = allDuas[1]
        let dua3 = allDuas[2]

        try await sut.addToFavorites(dua1)
        try await sut.addToFavorites(dua2)
        try await sut.addToFavorites(dua3)
        let favourites = try await sut.getFavorites()

        XCTAssertEqual(favourites.count, 3,
                       "All three favourited duas should be returned")
        let ids = Set(favourites.map(\.id))
        XCTAssertTrue(ids.contains(dua1.id))
        XCTAssertTrue(ids.contains(dua2.id))
        XCTAssertTrue(ids.contains(dua3.id))
    }

    // MARK: - Persistence Across Instances

    func test_favouritePersistsAcrossNewRepositoryInstance() async throws {
        let dua = allDuas[0]

        try await sut.addToFavorites(dua)

        // Create a fresh repository instance (same UserDefaults)
        let newRepo = DuaRepository(coreData: CoreDataStack.shared)
        let favourites = try await newRepo.getFavorites()

        XCTAssertTrue(favourites.contains { $0.id == dua.id },
                      "Favourite should persist across repository instances")
    }

    // MARK: - UI State Tests

    func test_favoriteIdsSetContainsIdAfterAdd() async throws {
        let dua = allDuas[0]
        var favoriteIds: Set<String> = []

        try await sut.addToFavorites(dua)
        if let favs = try? await sut.getFavorites() {
            favoriteIds = Set(favs.map(\.id))
        }

        XCTAssertTrue(favoriteIds.contains(dua.id),
                      "favoriteIds set should contain the added dua's id")
    }

    func test_emptyFavourites_filterReturnsEmptyList() async throws {
        let favourites = try await sut.getFavorites()
        let filtered = allDuas.filter { favourites.map(\.id).contains($0.id) }

        XCTAssertTrue(filtered.isEmpty,
                      "With no favourites, filtered list should be empty")
    }

    func test_favouritesFromDifferentCategories_allAppearInCombinedList() async throws {
        let morningDua = allDuas.first { $0.categoryId == "morning" }!
        let eveningDua = allDuas.first { $0.categoryId == "evening" }!
        let sleepDua = allDuas.first { $0.categoryId == "sleep" }!

        try await sut.addToFavorites(morningDua)
        try await sut.addToFavorites(eveningDua)
        try await sut.addToFavorites(sleepDua)

        let favourites = try await sut.getFavorites()
        let categoryIds = Set(favourites.map(\.categoryId))

        XCTAssertTrue(categoryIds.contains("morning"))
        XCTAssertTrue(categoryIds.contains("evening"))
        XCTAssertTrue(categoryIds.contains("sleep"))
    }
}
