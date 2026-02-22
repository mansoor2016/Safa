// MARK: - DuaCategoryTests.swift
// PURPOSE: Tests for Dua categories and data integrity
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class DuaCategoryTests: XCTestCase {

    private var bundle: DuaDataLoader.DuaBundle!

    override func setUp() {
        super.setUp()
        bundle = try! DuaDataLoader.load(from: Bundle.main)
    }

    override func tearDown() {
        bundle = nil
        super.tearDown()
    }

    // MARK: - Category Tests

    func test_morningAndEvening_areSeparateCategories() {
        let morning = bundle.categories.first { $0.id == "morning" }
        let evening = bundle.categories.first { $0.id == "evening" }
        XCTAssertNotNil(morning, "Morning should be a separate category")
        XCTAssertNotNil(evening, "Evening should be a separate category")
        XCTAssertNotEqual(morning?.id, evening?.id)
    }

    func test_noCombinedMorningEveningCategory() {
        let combined = bundle.categories.first { $0.id == "morning_evening" }
        XCTAssertNil(combined, "Should not have a combined morning_evening category")
    }

    func test_allCategories_hasExpectedEntries() {
        XCTAssertGreaterThanOrEqual(bundle.categories.count, 21)
        let ids = Set(bundle.categories.map(\.id))
        let required = ["morning", "evening", "prayer", "daily", "protection",
                        "forgiveness", "travel", "food", "sleep", "anxiety",
                        "funeral", "ramadan", "istikharah", "illness", "parents",
                        "marriage", "children", "knowledge", "hajj", "weather", "gratitude"]
        for id in required {
            XCTAssertTrue(ids.contains(id), "Missing required category: \(id)")
        }
    }

    func test_allCategories_haveUniqueIds() {
        let ids = bundle.categories.map { $0.id }
        XCTAssertEqual(Set(ids).count, ids.count, "Category IDs should be unique")
    }

    // MARK: - Dua Count Accuracy

    func test_duaCount_matchesActualDuas() {
        for category in bundle.categories {
            let actual = bundle.duas.filter { $0.categoryId == category.id }.count
            XCTAssertEqual(category.duaCount, actual,
                           "\(category.nameEnglish) claims \(category.duaCount) duas but has \(actual)")
        }
    }

    // MARK: - Food & Drink Content

    func test_foodCategory_hasDuas() {
        let foodDuas = bundle.duas.filter { $0.categoryId == "food" }
        XCTAssertGreaterThan(foodDuas.count, 0, "Food category should have duas")
    }

    func test_foodDuas_areAboutFood() {
        let foodDuas = bundle.duas.filter { $0.categoryId == "food" }
        for dua in foodDuas {
            let title = dua.titleEnglish.lowercased()
            let translation = dua.textTranslation.lowercased()
            let isRelevant = title.contains("eat") ||
                             title.contains("food") ||
                             title.contains("drink") ||
                             title.contains("fast") ||
                             title.contains("bismillah") ||
                             title.contains("host") ||
                             title.contains("guest") ||
                             title.contains("invit") ||
                             translation.contains("fed") ||
                             translation.contains("eat") ||
                             translation.contains("drink") ||
                             translation.contains("thirst") ||
                             translation.contains("name of allah") ||
                             translation.contains("bless") ||
                             translation.contains("provision")
            XCTAssertTrue(isRelevant,
                          "Food dua '\(dua.titleEnglish)' should be about food/drink")
        }
    }

    // MARK: - Funeral Content

    func test_funeralCategory_hasDuas() {
        let duas = bundle.duas.filter { $0.categoryId == "funeral" }
        XCTAssertGreaterThan(duas.count, 0, "Funeral category should have duas")
    }

    func test_funeralDuas_areRelevant() {
        let duas = bundle.duas.filter { $0.categoryId == "funeral" }
        for dua in duas {
            let relevant = dua.titleEnglish.lowercased().contains("funeral") ||
                           dua.titleEnglish.lowercased().contains("death") ||
                           dua.titleEnglish.lowercased().contains("grave") ||
                           dua.titleEnglish.lowercased().contains("deceased") ||
                           dua.titleEnglish.lowercased().contains("passing") ||
                           dua.textTranslation.lowercased().contains("forgive") ||
                           dua.textTranslation.lowercased().contains("return")
            XCTAssertTrue(relevant, "Funeral dua '\(dua.titleEnglish)' should be relevant")
        }
    }

    // MARK: - Ramadan Content

    func test_ramadanCategory_hasDuas() {
        let duas = bundle.duas.filter { $0.categoryId == "ramadan" }
        XCTAssertGreaterThan(duas.count, 0, "Ramadan category should have duas")
    }

    func test_ramadanDuas_areRelevant() {
        let duas = bundle.duas.filter { $0.categoryId == "ramadan" }
        for dua in duas {
            let relevant = dua.titleEnglish.lowercased().contains("fast") ||
                           dua.titleEnglish.lowercased().contains("iftar") ||
                           dua.titleEnglish.lowercased().contains("suhoor") ||
                           dua.titleEnglish.lowercased().contains("qadr") ||
                           dua.titleEnglish.lowercased().contains("intention") ||
                           dua.titleEnglish.lowercased().contains("qunoot") ||
                           dua.titleEnglish.lowercased().contains("paradise") ||
                           dua.titleEnglish.lowercased().contains("acceptance") ||
                           dua.textTranslation.lowercased().contains("thirst") ||
                           dua.textTranslation.lowercased().contains("forgiv") ||
                           dua.textTranslation.lowercased().contains("fast")
            XCTAssertTrue(relevant, "Ramadan dua '\(dua.titleEnglish)' should be relevant")
        }
    }

    // MARK: - Data Integrity

    func test_allDuas_haveCategoryId() {
        for dua in bundle.duas {
            XCTAssertFalse(dua.categoryId.isEmpty, "Dua '\(dua.id)' should have a categoryId")
        }
    }

    func test_allDuas_haveArabicText() {
        for dua in bundle.duas {
            XCTAssertFalse(dua.textArabic.isEmpty, "Dua '\(dua.id)' should have Arabic text")
        }
    }

    func test_allDuas_haveTranslation() {
        for dua in bundle.duas {
            XCTAssertFalse(dua.textTranslation.isEmpty, "Dua '\(dua.id)' should have translation")
        }
    }

    func test_allDuas_haveUniqueIds() {
        let ids = bundle.duas.map { $0.id }
        XCTAssertEqual(Set(ids).count, ids.count, "Dua IDs should be unique")
    }

    func test_allDuas_belongToValidCategory() {
        let validIds = Set(bundle.categories.map { $0.id })
        for dua in bundle.duas {
            XCTAssertTrue(validIds.contains(dua.categoryId),
                          "Dua '\(dua.id)' has invalid categoryId '\(dua.categoryId)'")
        }
    }
}
