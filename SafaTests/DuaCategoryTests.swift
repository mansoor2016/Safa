// MARK: - DuaCategoryTests.swift
// PURPOSE: Tests for Dua categories and data integrity
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class DuaCategoryTests: XCTestCase {

    // MARK: - Category Tests

    func test_morningAndEvening_areSeparateCategories() {
        let categories = DuaCategoryData.allCategories
        let morning = categories.first { $0.id == "morning" }
        let evening = categories.first { $0.id == "evening" }
        XCTAssertNotNil(morning, "Morning should be a separate category")
        XCTAssertNotNil(evening, "Evening should be a separate category")
        XCTAssertNotEqual(morning?.id, evening?.id)
    }

    func test_noCombinedMorningEveningCategory() {
        let categories = DuaCategoryData.allCategories
        let combined = categories.first { $0.id == "morning_evening" }
        XCTAssertNil(combined, "Should not have a combined morning_evening category")
    }

    func test_allCategories_hasTenEntries() {
        XCTAssertEqual(DuaCategoryData.allCategories.count, 10)
    }

    func test_allCategories_haveUniqueIds() {
        let ids = DuaCategoryData.allCategories.map { $0.id }
        XCTAssertEqual(Set(ids).count, ids.count, "Category IDs should be unique")
    }

    // MARK: - Dua Count Accuracy

    func test_duaCount_matchesActualDuas() {
        for category in DuaCategoryData.allCategories {
            let actual = DuaData.allDuas.filter { $0.categoryId == category.id }.count
            XCTAssertEqual(category.duaCount, actual,
                           "\(category.name) claims \(category.duaCount) duas but has \(actual)")
        }
    }

    // MARK: - Food & Drink Content

    func test_foodCategory_hasDuas() {
        let foodDuas = DuaData.allDuas.filter { $0.categoryId == "food" }
        XCTAssertGreaterThan(foodDuas.count, 0, "Food category should have duas")
    }

    func test_foodDuas_areAboutFood() {
        let foodDuas = DuaData.allDuas.filter { $0.categoryId == "food" }
        for dua in foodDuas {
            let isRelevant = dua.titleEnglish.lowercased().contains("eat") ||
                             dua.titleEnglish.lowercased().contains("food") ||
                             dua.titleEnglish.lowercased().contains("drink") ||
                             dua.titleEnglish.lowercased().contains("fast") ||
                             dua.titleEnglish.lowercased().contains("bismillah") ||
                             dua.textTranslation.lowercased().contains("fed") ||
                             dua.textTranslation.lowercased().contains("eat") ||
                             dua.textTranslation.lowercased().contains("drink") ||
                             dua.textTranslation.lowercased().contains("thirst") ||
                             dua.textTranslation.lowercased().contains("name of allah")
            XCTAssertTrue(isRelevant,
                          "Food dua '\(dua.titleEnglish)' should be about food/drink")
        }
    }

    // MARK: - Data Integrity

    func test_allDuas_haveCategoryId() {
        for dua in DuaData.allDuas {
            XCTAssertFalse(dua.categoryId.isEmpty, "Dua '\(dua.id)' should have a categoryId")
        }
    }

    func test_allDuas_haveArabicText() {
        for dua in DuaData.allDuas {
            XCTAssertFalse(dua.textArabic.isEmpty, "Dua '\(dua.id)' should have Arabic text")
        }
    }

    func test_allDuas_haveTranslation() {
        for dua in DuaData.allDuas {
            XCTAssertFalse(dua.textTranslation.isEmpty, "Dua '\(dua.id)' should have translation")
        }
    }

    func test_allDuas_haveUniqueIds() {
        let ids = DuaData.allDuas.map { $0.id }
        XCTAssertEqual(Set(ids).count, ids.count, "Dua IDs should be unique")
    }

    func test_allDuas_belongToValidCategory() {
        let validIds = Set(DuaCategoryData.allCategories.map { $0.id })
        for dua in DuaData.allDuas {
            XCTAssertTrue(validIds.contains(dua.categoryId),
                          "Dua '\(dua.id)' has invalid categoryId '\(dua.categoryId)'")
        }
    }
}
