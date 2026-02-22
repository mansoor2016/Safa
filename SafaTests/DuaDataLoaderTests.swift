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

    func test_categories_hasExpectedEntries() {
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

    func test_duas_repetitionsArePositive() {
        for dua in bundle.duas {
            XCTAssertGreaterThan(dua.repetitions, 0,
                "Dua '\(dua.id)' should have positive repetitions")
        }
    }

    // MARK: - Existing ID Preservation

    func test_existingIds_arePreserved() {
        let existingIds = [
            // Original 57
            "m1", "m2", "m3", "m4", "m5",
            "e1", "e2", "e3", "e4",
            "p1", "p2", "p3", "p4",
            "d1", "d2", "d3", "d4",
            "pr_ayatul_kursi", "pr1", "pr2", "pr3", "pr4",
            "fg1", "fg2", "fg3", "fg4",
            "t1", "t2", "t3", "t4",
            "f1", "f2", "f3", "f4", "f5",
            "s_ayatul_kursi", "s1", "s2", "s3", "s4",
            "ax1", "ax2", "ax3", "ax4", "ax5",
            "fn1", "fn2", "fn3", "fn4", "fn5",
            "rm1", "rm2", "rm3", "rm4", "rm5", "rm6", "rm7",
            // New additions
            "m6", "m7", "m8", "e5", "e6", "e7",
            "p5", "p6", "p7", "p8", "p9", "p10",
            "d5", "d6", "d7", "d8", "d9", "d10", "d11", "d12",
            "f6", "f7", "f8", "f9", "s5", "s6", "pr5", "pr6", "t5", "t6",
            "ax6", "ax7",
            "ik1", "ik2", "ik3",
            "il1", "il2", "il3", "il4", "il5",
            "pa1", "pa2", "pa3",
            "mg1", "mg2", "mg3", "mg4",
            "ch1", "ch2", "ch3",
            "kn1", "kn2", "kn3",
            "hj1", "hj2", "hj3", "hj4",
            "wt1", "wt2", "wt3",
            "gr1", "gr2", "gr3"
        ]
        let loadedIds = Set(bundle.duas.map(\.id))
        for id in existingIds {
            XCTAssertTrue(loadedIds.contains(id),
                          "Dua ID '\(id)' should be present in JSON")
        }
    }

    // MARK: - Category Coverage

    func test_morningCategory_hasExpectedCount() {
        let count = bundle.duas.filter { $0.categoryId == "morning" }.count
        XCTAssertEqual(count, 8)
    }

    func test_eveningCategory_hasExpectedCount() {
        let count = bundle.duas.filter { $0.categoryId == "evening" }.count
        XCTAssertEqual(count, 7)
    }

    func test_ramadanCategory_hasExpectedCount() {
        let count = bundle.duas.filter { $0.categoryId == "ramadan" }.count
        XCTAssertEqual(count, 7)
    }

    func test_anxietyCategory_hasExpectedCount() {
        let count = bundle.duas.filter { $0.categoryId == "anxiety" }.count
        XCTAssertEqual(count, 7)
    }

    func test_prayerCategory_hasExpectedCount() {
        let count = bundle.duas.filter { $0.categoryId == "prayer" }.count
        XCTAssertEqual(count, 10)
    }

    func test_dailyCategory_hasExpectedCount() {
        let count = bundle.duas.filter { $0.categoryId == "daily" }.count
        XCTAssertEqual(count, 12)
    }

    func test_foodCategory_hasExpectedCount() {
        let count = bundle.duas.filter { $0.categoryId == "food" }.count
        XCTAssertEqual(count, 9)
    }

    func test_sleepCategory_hasExpectedCount() {
        let count = bundle.duas.filter { $0.categoryId == "sleep" }.count
        XCTAssertEqual(count, 7)
    }

    func test_protectionCategory_hasExpectedCount() {
        let count = bundle.duas.filter { $0.categoryId == "protection" }.count
        XCTAssertEqual(count, 7)
    }

    func test_travelCategory_hasExpectedCount() {
        let count = bundle.duas.filter { $0.categoryId == "travel" }.count
        XCTAssertEqual(count, 6)
    }

    func test_newCategories_haveExpectedCounts() {
        let expected: [(String, Int)] = [
            ("istikharah", 3), ("illness", 5), ("parents", 3),
            ("marriage", 4), ("children", 3), ("knowledge", 3),
            ("hajj", 4), ("weather", 3), ("gratitude", 3)
        ]
        for (categoryId, expectedCount) in expected {
            let count = bundle.duas.filter { $0.categoryId == categoryId }.count
            XCTAssertEqual(count, expectedCount,
                           "\(categoryId) should have \(expectedCount) duas but has \(count)")
        }
    }

    // MARK: - Every Category Has Sources

    func test_allCategories_haveAtLeastOneDuaWithSource() {
        for category in bundle.categories {
            let duas = bundle.duas.filter { $0.categoryId == category.id }
            let hasSource = duas.contains { $0.source != nil && !$0.source!.isEmpty }
            XCTAssertTrue(hasSource,
                          "\(category.nameEnglish) should have at least one dua with a source")
        }
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

    func test_illnessDuas_areRelevant() {
        let duas = bundle.duas.filter { $0.categoryId == "illness" }
        for dua in duas {
            let title = dua.titleEnglish.lowercased()
            let translation = dua.textTranslation.lowercased()
            let relevant = title.contains("sick") || title.contains("heal") ||
                           title.contains("pain") || title.contains("illness") ||
                           title.contains("ruqyah") || title.contains("afflict") ||
                           title.contains("visit") ||
                           translation.contains("heal") || translation.contains("afflict") ||
                           translation.contains("harm") || translation.contains("purif") ||
                           translation.contains("refuge") || translation.contains("ruqyah")
            XCTAssertTrue(relevant, "Illness dua '\(dua.titleEnglish)' should be relevant")
        }
    }

    func test_marriageDuas_areRelevant() {
        let duas = bundle.duas.filter { $0.categoryId == "marriage" }
        for dua in duas {
            let title = dua.titleEnglish.lowercased()
            let translation = dua.textTranslation.lowercased()
            let relevant = title.contains("newlywed") || title.contains("spouse") ||
                           title.contains("marriage") || title.contains("wedding") ||
                           title.contains("love") ||
                           translation.contains("bless") || translation.contains("spouse") ||
                           translation.contains("hearts") || translation.contains("goodness")
            XCTAssertTrue(relevant, "Marriage dua '\(dua.titleEnglish)' should be relevant")
        }
    }

    func test_hajjDuas_areRelevant() {
        let duas = bundle.duas.filter { $0.categoryId == "hajj" }
        for dua in duas {
            let title = dua.titleEnglish.lowercased()
            let translation = dua.textTranslation.lowercased()
            let relevant = title.contains("talbiyah") || title.contains("arafat") ||
                           title.contains("tawaf") || title.contains("safa") ||
                           title.contains("marwa") ||
                           translation.contains("here i am") || translation.contains("symbol") ||
                           translation.contains("good") || translation.contains("fire")
            XCTAssertTrue(relevant, "Hajj dua '\(dua.titleEnglish)' should be relevant")
        }
    }

    func test_weatherDuas_areRelevant() {
        let duas = bundle.duas.filter { $0.categoryId == "weather" }
        for dua in duas {
            let title = dua.titleEnglish.lowercased()
            let translation = dua.textTranslation.lowercased()
            let relevant = title.contains("rain") || title.contains("wind") ||
                           title.contains("weather") ||
                           translation.contains("rain") || translation.contains("wind") ||
                           translation.contains("grace") || translation.contains("mercy")
            XCTAssertTrue(relevant, "Weather dua '\(dua.titleEnglish)' should be relevant")
        }
    }

    func test_knowledgeDuas_areRelevant() {
        let duas = bundle.duas.filter { $0.categoryId == "knowledge" }
        for dua in duas {
            let title = dua.titleEnglish.lowercased()
            let translation = dua.textTranslation.lowercased()
            let relevant = title.contains("knowledge") || title.contains("understand") ||
                           title.contains("study") ||
                           translation.contains("knowledge") || translation.contains("understand") ||
                           translation.contains("teach")
            XCTAssertTrue(relevant, "Knowledge dua '\(dua.titleEnglish)' should be relevant")
        }
    }

    func test_parentsDuas_areRelevant() {
        let duas = bundle.duas.filter { $0.categoryId == "parents" }
        for dua in duas {
            let title = dua.titleEnglish.lowercased()
            let translation = dua.textTranslation.lowercased()
            let relevant = title.contains("parent") || title.contains("mercy") ||
                           title.contains("family") || title.contains("forgiv") ||
                           translation.contains("parent") || translation.contains("brought me up") ||
                           translation.contains("spouse") || translation.contains("offspring")
            XCTAssertTrue(relevant, "Parents dua '\(dua.titleEnglish)' should be relevant")
        }
    }

    func test_gratitudeDuas_areRelevant() {
        let duas = bundle.duas.filter { $0.categoryId == "gratitude" }
        for dua in duas {
            let title = dua.titleEnglish.lowercased()
            let translation = dua.textTranslation.lowercased()
            let relevant = title.contains("gratitude") || title.contains("good news") ||
                           title.contains("pleased") ||
                           translation.contains("grateful") || translation.contains("praise") ||
                           translation.contains("thank") || translation.contains("good deeds")
            XCTAssertTrue(relevant, "Gratitude dua '\(dua.titleEnglish)' should be relevant")
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
