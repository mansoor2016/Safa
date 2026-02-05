// MARK: - DuaModelTests.swift
// PURPOSE: Unit tests for Dua domain models
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class DuaModelTests: XCTestCase {

    // MARK: - Simple Dua Tests

    func testSimpleDuaInitialization() {
        let dua = SimpleDua(
            id: "morning_1",
            category: .morning,
            arabic: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
            transliteration: "Asbahna wa asbahal-mulku lillah",
            translation: "We have reached the morning and the kingdom belongs to Allah",
            reference: "Abu Dawud 4:317",
            repeatCount: 1,
            benefit: "Morning remembrance"
        )

        XCTAssertEqual(dua.id, "morning_1")
        XCTAssertEqual(dua.category, .morning)
        XCTAssertEqual(dua.repeatCount, 1)
        XCTAssertFalse(dua.arabic.isEmpty)
    }

    func testDuaCategoryEnumRawValues() {
        XCTAssertEqual(DuaCategoryEnum.morning.rawValue, "morning")
        XCTAssertEqual(DuaCategoryEnum.evening.rawValue, "evening")
        XCTAssertEqual(DuaCategoryEnum.prayer.rawValue, "prayer")
        XCTAssertEqual(DuaCategoryEnum.sleep.rawValue, "sleep")
        XCTAssertEqual(DuaCategoryEnum.food.rawValue, "food")
        XCTAssertEqual(DuaCategoryEnum.travel.rawValue, "travel")
    }

    func testDuaCategoryEnumDisplayNames() {
        XCTAssertEqual(DuaCategoryEnum.morning.displayName, "Morning")
        XCTAssertEqual(DuaCategoryEnum.evening.displayName, "Evening")
        XCTAssertEqual(DuaCategoryEnum.prayer.displayName, "Prayer")
    }

    func testSimpleDuaHasRequiredFields() {
        let dua = SimpleDua(
            id: "test",
            category: .general,
            arabic: "عربي",
            transliteration: "transliteration",
            translation: "translation",
            reference: "reference",
            repeatCount: 3,
            benefit: nil
        )

        XCTAssertFalse(dua.arabic.isEmpty)
        XCTAssertFalse(dua.transliteration.isEmpty)
        XCTAssertFalse(dua.translation.isEmpty)
        XCTAssertGreaterThan(dua.repeatCount, 0)
    }

    func testSimpleDuaOptionalBenefit() {
        let duaWithBenefit = SimpleDua(
            id: "test1",
            category: .morning,
            arabic: "Arabic",
            transliteration: "Trans",
            translation: "Trans",
            reference: "Ref",
            repeatCount: 1,
            benefit: "Some benefit"
        )

        let duaWithoutBenefit = SimpleDua(
            id: "test2",
            category: .morning,
            arabic: "Arabic",
            transliteration: "Trans",
            translation: "Trans",
            reference: "Ref",
            repeatCount: 1,
            benefit: nil
        )

        XCTAssertNotNil(duaWithBenefit.benefit)
        XCTAssertNil(duaWithoutBenefit.benefit)
    }

    // MARK: - Dua Category Struct Tests

    func testDuaCategoryStructInitialization() {
        let category = DuaCategory(
            id: "morning_evening",
            nameEnglish: "Morning & Evening",
            nameArabic: "أذكار الصباح والمساء",
            iconName: "sunrise",
            duaCount: 15
        )

        XCTAssertEqual(category.id, "morning_evening")
        XCTAssertEqual(category.nameEnglish, "Morning & Evening")
        XCTAssertEqual(category.duaCount, 15)
    }

    // MARK: - Adhkar Type Tests

    func testAdhkarTypeRawValues() {
        XCTAssertEqual(AdhkarType.morning.rawValue, "morning")
        XCTAssertEqual(AdhkarType.evening.rawValue, "evening")
        XCTAssertEqual(AdhkarType.sleep.rawValue, "sleep")
    }

    func testAdhkarTypeDisplayNames() {
        XCTAssertEqual(AdhkarType.morning.displayName, "Morning Adhkar")
        XCTAssertEqual(AdhkarType.evening.displayName, "Evening Adhkar")
        XCTAssertEqual(AdhkarType.sleep.displayName, "Sleep Adhkar")
    }

    // MARK: - Encoding/Decoding Tests

    func testSimpleDuaCodable() throws {
        let original = SimpleDua(
            id: "test",
            category: .morning,
            arabic: "عربي",
            transliteration: "test",
            translation: "test",
            reference: "test ref",
            repeatCount: 3,
            benefit: "test benefit"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SimpleDua.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.category, decoded.category)
        XCTAssertEqual(original.repeatCount, decoded.repeatCount)
    }

    // MARK: - Repeat Count Tests

    func testDuaRepeatCountVariations() {
        let singleRepeat = SimpleDua(
            id: "1",
            category: .morning,
            arabic: "Arabic",
            transliteration: "Trans",
            translation: "Trans",
            reference: "Ref",
            repeatCount: 1,
            benefit: nil
        )

        let tripleRepeat = SimpleDua(
            id: "2",
            category: .morning,
            arabic: "Arabic",
            transliteration: "Trans",
            translation: "Trans",
            reference: "Ref",
            repeatCount: 3,
            benefit: nil
        )

        let hundredRepeat = SimpleDua(
            id: "3",
            category: .morning,
            arabic: "SubhanAllah",
            transliteration: "SubhanAllah",
            translation: "Glory to Allah",
            reference: "Ref",
            repeatCount: 100,
            benefit: nil
        )

        XCTAssertEqual(singleRepeat.repeatCount, 1)
        XCTAssertEqual(tripleRepeat.repeatCount, 3)
        XCTAssertEqual(hundredRepeat.repeatCount, 100)
    }

    // MARK: - Tasbeeh Session Tests

    func testTasbeehSessionInitialization() {
        let session = TasbeehSession(
            dhikrText: "SubhanAllah",
            targetCount: 33
        )

        XCTAssertEqual(session.dhikrText, "SubhanAllah")
        XCTAssertEqual(session.targetCount, 33)
        XCTAssertEqual(session.currentCount, 0)
        XCTAssertFalse(session.isComplete)
    }

    func testTasbeehSessionProgress() {
        var session = TasbeehSession(
            dhikrText: "SubhanAllah",
            targetCount: 100,
            currentCount: 50
        )

        XCTAssertEqual(session.progress, 0.5, accuracy: 0.01)

        session.currentCount = 100
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.progress, 1.0, accuracy: 0.01)
    }

    // MARK: - Common Dhikr Tests

    func testCommonDhikrValues() {
        XCTAssertEqual(CommonDhikr.subhanAllah.arabic, "سُبْحَانَ اللهِ")
        XCTAssertEqual(CommonDhikr.alhamdulillah.translation, "All praise is due to Allah")
        XCTAssertEqual(CommonDhikr.subhanAllah.defaultCount, 33)
    }
}
