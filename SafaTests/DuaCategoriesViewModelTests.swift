// MARK: - DuaCategoriesViewModelTests.swift
// PURPOSE: Unit tests for DuaCategoriesViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class DuaCategoriesViewModelTests: XCTestCase {

    var sut: DuaCategoriesViewModel!

    override func setUp() {
        super.setUp()
        sut = DuaCategoriesViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_loadsCategories() {
        XCTAssertFalse(sut.categories.isEmpty)
    }

    func test_initialState_searchTextIsEmpty() {
        XCTAssertTrue(sut.searchText.isEmpty)
    }

    func test_initialState_filteredCategoriesEqualsAllCategories() {
        XCTAssertEqual(sut.filteredCategories.count, sut.categories.count)
    }

    func test_initialState_hasTenCategories() {
        XCTAssertEqual(sut.categories.count, 10)
    }

    // MARK: - Category Data Tests

    func test_categories_containsMorningEvening() {
        let category = sut.categories.first { $0.id == "morning_evening" }
        XCTAssertNotNil(category)
        XCTAssertEqual(category?.name, "Morning & Evening")
    }

    func test_categories_containsPrayer() {
        let category = sut.categories.first { $0.id == "prayer" }
        XCTAssertNotNil(category)
        XCTAssertEqual(category?.name, "Prayer")
    }

    func test_categories_containsDaily() {
        let category = sut.categories.first { $0.id == "daily" }
        XCTAssertNotNil(category)
        XCTAssertEqual(category?.name, "Daily Activities")
    }

    func test_categories_containsProtection() {
        let category = sut.categories.first { $0.id == "protection" }
        XCTAssertNotNil(category)
        XCTAssertEqual(category?.name, "Protection")
    }

    func test_categories_containsForgiveness() {
        let category = sut.categories.first { $0.id == "forgiveness" }
        XCTAssertNotNil(category)
    }

    func test_categories_containsTravel() {
        let category = sut.categories.first { $0.id == "travel" }
        XCTAssertNotNil(category)
    }

    func test_categories_containsFood() {
        let category = sut.categories.first { $0.id == "food" }
        XCTAssertNotNil(category)
    }

    func test_categories_containsSleep() {
        let category = sut.categories.first { $0.id == "sleep" }
        XCTAssertNotNil(category)
    }

    func test_categories_containsAnxiety() {
        let category = sut.categories.first { $0.id == "anxiety" }
        XCTAssertNotNil(category)
    }

    func test_categories_containsGratitude() {
        let category = sut.categories.first { $0.id == "gratitude" }
        XCTAssertNotNil(category)
    }

    func test_categories_allHaveValidIds() {
        for category in sut.categories {
            XCTAssertFalse(category.id.isEmpty, "Category should have non-empty id")
        }
    }

    func test_categories_allHaveValidNames() {
        for category in sut.categories {
            XCTAssertFalse(category.name.isEmpty, "Category \(category.id) should have name")
        }
    }

    func test_categories_allHaveValidArabicNames() {
        for category in sut.categories {
            XCTAssertFalse(category.arabicName.isEmpty, "Category \(category.id) should have Arabic name")
        }
    }

    func test_categories_allHaveValidIconNames() {
        for category in sut.categories {
            XCTAssertFalse(category.iconName.isEmpty, "Category \(category.id) should have icon")
        }
    }

    func test_categories_allHavePositiveDuaCounts() {
        for category in sut.categories {
            XCTAssertGreaterThan(category.duaCount, 0, "Category \(category.id) should have positive dua count")
        }
    }

    // MARK: - Search Filter Tests

    func test_filteredCategories_returnsAll_whenSearchEmpty() {
        sut.searchText = ""
        XCTAssertEqual(sut.filteredCategories.count, sut.categories.count)
    }

    func test_filteredCategories_filtersByName() {
        sut.searchText = "Morning"
        let results = sut.filteredCategories
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.name.contains("Morning") })
    }

    func test_filteredCategories_filtersByArabicName() {
        sut.searchText = "الصباح"
        let results = sut.filteredCategories
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.arabicName.contains("الصباح") })
    }

    func test_filteredCategories_isCaseInsensitive() {
        sut.searchText = "MORNING"
        let upperResults = sut.filteredCategories

        sut.searchText = "morning"
        let lowerResults = sut.filteredCategories

        XCTAssertEqual(upperResults.count, lowerResults.count)
    }

    func test_filteredCategories_returnsEmpty_forNoMatch() {
        sut.searchText = "xyz123nonexistent"
        XCTAssertTrue(sut.filteredCategories.isEmpty)
    }

    func test_filteredCategories_partialMatch() {
        sut.searchText = "Pro"
        let results = sut.filteredCategories
        XCTAssertTrue(results.contains { $0.name.contains("Protection") })
    }

    func test_filteredCategories_filtersByPrayer() {
        sut.searchText = "Prayer"
        let results = sut.filteredCategories
        XCTAssertFalse(results.isEmpty)
    }

    func test_filteredCategories_filtersBySleep() {
        sut.searchText = "Sleep"
        let results = sut.filteredCategories
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.id == "sleep" })
    }

    // MARK: - Search State Tests

    func test_searchText_canBeSet() {
        sut.searchText = "Test"
        XCTAssertEqual(sut.searchText, "Test")
    }

    func test_searchText_canBeCleared() {
        sut.searchText = "Test"
        XCTAssertFalse(sut.searchText.isEmpty)

        sut.searchText = ""
        XCTAssertTrue(sut.searchText.isEmpty)
    }

    // MARK: - DuaCategoryCollection Model Tests

    func test_duaCategoryCollection_isIdentifiable() {
        let category = DuaCategoryCollection(
            id: "test",
            name: "Test",
            arabicName: "اختبار",
            iconName: "star",
            duaCount: 5
        )
        XCTAssertEqual(category.id, "test")
    }

    func test_duaCategoryCollection_isHashable() {
        let category1 = DuaCategoryCollection(
            id: "test",
            name: "Test",
            arabicName: "اختبار",
            iconName: "star",
            duaCount: 5
        )
        let category2 = DuaCategoryCollection(
            id: "test",
            name: "Test",
            arabicName: "اختبار",
            iconName: "star",
            duaCount: 5
        )
        XCTAssertEqual(category1.hashValue, category2.hashValue)
    }

    func test_duaCategoryCollection_isCodable() throws {
        let category = DuaCategoryCollection(
            id: "test",
            name: "Test Category",
            arabicName: "فئة الاختبار",
            iconName: "star",
            duaCount: 10
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(category)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DuaCategoryCollection.self, from: data)

        XCTAssertEqual(decoded.id, category.id)
        XCTAssertEqual(decoded.name, category.name)
        XCTAssertEqual(decoded.arabicName, category.arabicName)
        XCTAssertEqual(decoded.iconName, category.iconName)
        XCTAssertEqual(decoded.duaCount, category.duaCount)
    }

    func test_duaCategoryCollection_storesAllProperties() {
        let category = DuaCategoryCollection(
            id: "custom",
            name: "Custom Name",
            arabicName: "اسم مخصص",
            iconName: "heart",
            duaCount: 15
        )

        XCTAssertEqual(category.id, "custom")
        XCTAssertEqual(category.name, "Custom Name")
        XCTAssertEqual(category.arabicName, "اسم مخصص")
        XCTAssertEqual(category.iconName, "heart")
        XCTAssertEqual(category.duaCount, 15)
    }

    // MARK: - Sample Categories Tests

    func test_sampleCategories_hasTenCategories() {
        XCTAssertEqual(DuaCategoryCollection.sampleCategories.count, 10)
    }

    func test_sampleCategories_allHaveUniqueIds() {
        let ids = DuaCategoryCollection.sampleCategories.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count)
    }

    func test_sampleCategories_totalDuaCount() {
        let totalCount = DuaCategoryCollection.sampleCategories.reduce(0) { $0 + $1.duaCount }
        // 15 + 12 + 20 + 8 + 10 + 6 + 8 + 10 + 7 + 5 = 101
        XCTAssertEqual(totalCount, 101)
    }

    // MARK: - Edge Cases

    func test_filteredCategories_handlesEmptyCategories() {
        sut.categories = []
        sut.searchText = "Test"
        XCTAssertTrue(sut.filteredCategories.isEmpty)
    }

    func test_filteredCategories_handlesWhitespaceSearch() {
        sut.searchText = "   "
        // Whitespace is not empty, so it will filter
        // But it won't match anything
        XCTAssertTrue(sut.filteredCategories.isEmpty)
    }
}
