// MARK: - DuaDataLoaderTests.swift
// PURPOSE: Tests for DuaDataLoader JSON parsing and data integrity

import XCTest
@testable import Safa

final class DuaDataLoaderTests: XCTestCase {

    private var bundle: DuaDataLoader.DuaBundle!

    override func setUp() {
        super.setUp()
        bundle = try! DuaDataLoader.load(from: Bundle.main)
    }

    override func tearDown() {
        bundle = nil
        super.tearDown()
    }

    // MARK: - Parsing

    func test_load_parsesWithoutError() {
        XCTAssertNoThrow(try DuaDataLoader.load(from: Bundle.main))
    }

    func test_load_returnsCategoriesAndDuas() {
        XCTAssertGreaterThan(bundle.categories.count, 0)
        XCTAssertGreaterThan(bundle.duas.count, 0)
    }

    // MARK: - Categories

    func test_categories_hasTwelveEntries() {
        XCTAssertEqual(bundle.categories.count, 12)
    }

    func test_categories_haveUniqueIds() {
        let ids = bundle.categories.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Category IDs should be unique")
    }

    func test_categories_duaCountMatchesActualDuas() {
        for category in bundle.categories {
            let actual = bundle.duas.filter { $0.categoryId == category.id }.count
            XCTAssertEqual(category.duaCount, actual,
                           "\(category.nameEnglish) claims \(category.duaCount) duas but has \(actual)")
        }
    }

    // MARK: - Duas

    func test_duas_haveUniqueIds() {
        let ids = bundle.duas.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Dua IDs should be unique")
    }

    func test_duas_allBelongToValidCategory() {
        let validIds = Set(bundle.categories.map(\.id))
        for dua in bundle.duas {
            XCTAssertTrue(validIds.contains(dua.categoryId),
                          "Dua '\(dua.id)' has invalid categoryId '\(dua.categoryId)'")
        }
    }

    func test_duas_allHaveRequiredFields() {
        for dua in bundle.duas {
            XCTAssertFalse(dua.id.isEmpty, "Dua should have an ID")
            XCTAssertFalse(dua.categoryId.isEmpty, "Dua '\(dua.id)' should have categoryId")
            XCTAssertFalse(dua.titleEnglish.isEmpty, "Dua '\(dua.id)' should have titleEnglish")
            XCTAssertFalse(dua.textArabic.isEmpty, "Dua '\(dua.id)' should have textArabic")
            XCTAssertFalse(dua.textTransliteration.isEmpty, "Dua '\(dua.id)' should have transliteration")
            XCTAssertFalse(dua.textTranslation.isEmpty, "Dua '\(dua.id)' should have translation")
        }
    }

    func test_duas_isFavoriteDefaultsToFalse() {
        for dua in bundle.duas {
            XCTAssertFalse(dua.isFavorite, "Dua '\(dua.id)' should default isFavorite to false")
        }
    }

    func test_duas_repetitionsDefaultToOne() {
        let duasWithoutExplicitRepetitions = bundle.duas.filter { dua in
            // These are the ones that should have explicit repetitions > 1
            !["m2", "m3", "m4", "e2", "p1", "p4", "pr1", "pr2", "pr3", "pr4",
              "fg2", "t3", "rm3", "ax4", "s3"].contains(dua.id)
        }
        for dua in duasWithoutExplicitRepetitions {
            XCTAssertEqual(dua.repetitions, 1,
                           "Dua '\(dua.id)' should default to repetitions=1")
        }
    }

    // MARK: - Existing ID Preservation

    func test_existingIds_arePreserved() {
        let existingIds = [
            "m1", "m2", "m3", "e1", "e2", "p1", "p2",
            "s_ayatul_kursi", "s1", "s2",
            "f1", "f2", "f3", "f4", "f5",
            "pr_ayatul_kursi", "pr1", "fg1", "ax1", "t1",
            "d1", "d2", "fn1", "fn2", "fn3", "fn4",
            "rm1", "rm2", "rm3", "rm4"
        ]
        let loadedIds = Set(bundle.duas.map(\.id))
        for id in existingIds {
            XCTAssertTrue(loadedIds.contains(id),
                          "Existing dua ID '\(id)' should be preserved in JSON")
        }
    }

    // MARK: - Category Coverage

    func test_morningCategory_hasExpectedCount() {
        let count = bundle.duas.filter { $0.categoryId == "morning" }.count
        XCTAssertEqual(count, 5)
    }

    func test_eveningCategory_hasExpectedCount() {
        let count = bundle.duas.filter { $0.categoryId == "evening" }.count
        XCTAssertEqual(count, 4)
    }

    func test_ramadanCategory_hasExpectedCount() {
        let count = bundle.duas.filter { $0.categoryId == "ramadan" }.count
        XCTAssertEqual(count, 7)
    }

    func test_anxietyCategory_hasExpectedCount() {
        let count = bundle.duas.filter { $0.categoryId == "anxiety" }.count
        XCTAssertEqual(count, 5)
    }

    // MARK: - Ramadan Occasion Strings

    func test_ramadanDuas_haveValidOccasions() {
        let validOccasions: Set<String> = ["Iftar", "Suhoor", "Taraweeh", "Laylatul Qadr"]
        let ramadanDuas = bundle.duas.filter { $0.categoryId == "ramadan" }
        for dua in ramadanDuas {
            XCTAssertNotNil(dua.occasion,
                            "Ramadan dua '\(dua.id)' should have an occasion")
            if let occasion = dua.occasion {
                XCTAssertTrue(validOccasions.contains(occasion),
                              "Ramadan dua '\(dua.id)' has invalid occasion '\(occasion)'")
            }
        }
    }

    // MARK: - Content Relevance

    func test_foodDuas_areAboutFood() {
        let foodDuas = bundle.duas.filter { $0.categoryId == "food" }
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
}
