// MARK: - DuaModelTests.swift
// PURPOSE: Unit tests for Dua domain entities

import XCTest
@testable import Safa

final class DuaModelTests: XCTestCase {

    // MARK: - DuaCategory Tests

    func testDuaCategoryCreation() {
        let category = DuaCategory(
            id: "test",
            nameEnglish: "Test Category",
            nameArabic: "فئة الاختبار",
            iconName: "star",
            duaCount: 5
        )

        XCTAssertEqual(category.id, "test")
        XCTAssertEqual(category.nameEnglish, "Test Category")
        XCTAssertEqual(category.nameArabic, "فئة الاختبار")
        XCTAssertEqual(category.iconName, "star")
        XCTAssertEqual(category.duaCount, 5)
    }

    func testStaticDuaCategories() {
        XCTAssertEqual(DuaCategory.dailyLife.id, "daily")
        XCTAssertEqual(DuaCategory.salah.id, "salah")
        XCTAssertEqual(DuaCategory.protection.id, "protection")
        XCTAssertEqual(DuaCategory.forgiveness.id, "forgiveness")
        XCTAssertEqual(DuaCategory.hardship.id, "hardship")
    }

    func testDuaCategoryHashable() {
        let category1 = DuaCategory.dailyLife
        let category2 = DuaCategory.dailyLife

        XCTAssertEqual(category1, category2)
    }

    // MARK: - Dua Tests

    func testDuaCreation() {
        let dua = Dua(
            id: "dua1",
            categoryId: "morning",
            titleEnglish: "Morning Dua",
            textArabic: "بِسْمِ اللَّهِ",
            textTransliteration: "Bismillah",
            textTranslation: "In the name of Allah"
        )

        XCTAssertEqual(dua.id, "dua1")
        XCTAssertEqual(dua.categoryId, "morning")
        XCTAssertEqual(dua.titleEnglish, "Morning Dua")
        XCTAssertEqual(dua.textArabic, "بِسْمِ اللَّهِ")
        XCTAssertEqual(dua.textTransliteration, "Bismillah")
        XCTAssertEqual(dua.textTranslation, "In the name of Allah")
        XCTAssertNil(dua.source)
        XCTAssertNil(dua.occasion)
        XCTAssertEqual(dua.repetitions, 1)
        XCTAssertNil(dua.audioFileName)
        XCTAssertFalse(dua.isFavorite)
    }

    func testDuaWithAllParameters() {
        let dua = Dua(
            id: "dua2",
            categoryId: "protection",
            titleEnglish: "Protection Dua",
            titleArabic: "دعاء الحماية",
            textArabic: "أعوذ بالله",
            textTransliteration: "A'udhu billah",
            textTranslation: "I seek refuge in Allah",
            source: "Sahih Bukhari 123",
            occasion: "Before sleeping",
            repetitions: 3,
            audioFileName: "protection.mp3",
            isFavorite: true
        )

        XCTAssertEqual(dua.titleArabic, "دعاء الحماية")
        XCTAssertEqual(dua.source, "Sahih Bukhari 123")
        XCTAssertEqual(dua.occasion, "Before sleeping")
        XCTAssertEqual(dua.repetitions, 3)
        XCTAssertEqual(dua.audioFileName, "protection.mp3")
        XCTAssertTrue(dua.isFavorite)
    }

    func testDuaCodable() throws {
        let dua = Dua(
            id: "test",
            categoryId: "daily",
            titleEnglish: "Test",
            textArabic: "اختبار",
            textTransliteration: "Test",
            textTranslation: "Test"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(dua)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Dua.self, from: data)

        XCTAssertEqual(decoded.id, dua.id)
        XCTAssertEqual(decoded.textArabic, dua.textArabic)
    }

    // MARK: - TasbeehSession Tests

    func testTasbeehSessionCreation() {
        let session = TasbeehSession(
            dhikrText: "SubhanAllah",
            targetCount: 33
        )

        XCTAssertEqual(session.dhikrText, "SubhanAllah")
        XCTAssertEqual(session.targetCount, 33)
        XCTAssertEqual(session.currentCount, 0)
        XCTAssertNil(session.completedAt)
    }

    func testTasbeehSessionIsComplete() {
        var session = TasbeehSession(
            dhikrText: "SubhanAllah",
            targetCount: 33,
            currentCount: 32
        )

        XCTAssertFalse(session.isComplete)

        session.currentCount = 33
        XCTAssertTrue(session.isComplete)

        session.currentCount = 50
        XCTAssertTrue(session.isComplete)
    }

    func testTasbeehSessionProgress() {
        let session = TasbeehSession(
            dhikrText: "SubhanAllah",
            targetCount: 100,
            currentCount: 25
        )

        XCTAssertEqual(session.progress, 0.25, accuracy: 0.001)
    }

    func testTasbeehSessionProgressAtZero() {
        let session = TasbeehSession(
            dhikrText: "Test",
            targetCount: 33,
            currentCount: 0
        )

        XCTAssertEqual(session.progress, 0.0, accuracy: 0.001)
    }

    func testTasbeehSessionProgressAtComplete() {
        let session = TasbeehSession(
            dhikrText: "Test",
            targetCount: 33,
            currentCount: 33
        )

        XCTAssertEqual(session.progress, 1.0, accuracy: 0.001)
    }

    // MARK: - DhikrType Tests

    func testDhikrTypeAllCases() {
        XCTAssertEqual(DhikrType.allCases.count, 3)
        XCTAssertTrue(DhikrType.allCases.contains(.morning))
        XCTAssertTrue(DhikrType.allCases.contains(.evening))
        XCTAssertTrue(DhikrType.allCases.contains(.sleep))
    }

    func testDhikrTypeDisplayNames() {
        XCTAssertEqual(DhikrType.morning.displayName, "Morning Dhikr")
        XCTAssertEqual(DhikrType.evening.displayName, "Evening Dhikr")
        XCTAssertEqual(DhikrType.sleep.displayName, "Sleep Dhikr")
    }

    func testDhikrTypeRawValues() {
        XCTAssertEqual(DhikrType.morning.rawValue, "morning")
        XCTAssertEqual(DhikrType.evening.rawValue, "evening")
        XCTAssertEqual(DhikrType.sleep.rawValue, "sleep")
    }

    // MARK: - DuaCategoryEnum Tests

    func testDuaCategoryEnumAllCases() {
        XCTAssertEqual(DuaCategoryEnum.allCases.count, 7)
    }

    func testDuaCategoryEnumDisplayNames() {
        XCTAssertEqual(DuaCategoryEnum.morning.displayName, "Morning")
        XCTAssertEqual(DuaCategoryEnum.evening.displayName, "Evening")
        XCTAssertEqual(DuaCategoryEnum.prayer.displayName, "Prayer")
        XCTAssertEqual(DuaCategoryEnum.sleep.displayName, "Sleep")
        XCTAssertEqual(DuaCategoryEnum.food.displayName, "Food")
        XCTAssertEqual(DuaCategoryEnum.travel.displayName, "Travel")
        XCTAssertEqual(DuaCategoryEnum.general.displayName, "General")
    }

    // MARK: - CommonDhikr Tests

    func testCommonDhikrAllCases() {
        XCTAssertEqual(CommonDhikr.allCases.count, 5)
    }

    func testCommonDhikrArabicText() {
        XCTAssertEqual(CommonDhikr.subhanAllah.arabic, "سُبْحَانَ اللهِ")
        XCTAssertEqual(CommonDhikr.alhamdulillah.arabic, "الْحَمْدُ للهِ")
        XCTAssertEqual(CommonDhikr.allahuAkbar.arabic, "اللهُ أَكْبَرُ")
        XCTAssertEqual(CommonDhikr.laIlahaIllallah.arabic, "لَا إِلَٰهَ إِلَّا اللهُ")
        XCTAssertEqual(CommonDhikr.astaghfirullah.arabic, "أَسْتَغْفِرُ اللهَ")
    }

    func testCommonDhikrTranslations() {
        XCTAssertEqual(CommonDhikr.subhanAllah.translation, "Glory be to Allah")
        XCTAssertEqual(CommonDhikr.alhamdulillah.translation, "All praise is due to Allah")
        XCTAssertEqual(CommonDhikr.allahuAkbar.translation, "Allah is the Greatest")
        XCTAssertEqual(CommonDhikr.laIlahaIllallah.translation, "There is no god but Allah")
        XCTAssertEqual(CommonDhikr.astaghfirullah.translation, "I seek forgiveness from Allah")
    }

    func testCommonDhikrDefaultCounts() {
        XCTAssertEqual(CommonDhikr.subhanAllah.defaultCount, 33)
        XCTAssertEqual(CommonDhikr.alhamdulillah.defaultCount, 33)
        XCTAssertEqual(CommonDhikr.allahuAkbar.defaultCount, 33)
        XCTAssertEqual(CommonDhikr.laIlahaIllallah.defaultCount, 100)
        XCTAssertEqual(CommonDhikr.astaghfirullah.defaultCount, 100)
    }

    func testCommonDhikrRawValues() {
        XCTAssertEqual(CommonDhikr.subhanAllah.rawValue, "SubhanAllah")
        XCTAssertEqual(CommonDhikr.alhamdulillah.rawValue, "Alhamdulillah")
        XCTAssertEqual(CommonDhikr.allahuAkbar.rawValue, "Allahu Akbar")
    }

    // MARK: - SimpleDua Tests

    func testSimpleDuaCreation() {
        let dua = SimpleDua(
            id: "simple1",
            category: .morning,
            arabic: "بِسْمِ اللَّهِ",
            transliteration: "Bismillah",
            translation: "In the name of Allah",
            reference: "Sahih Bukhari",
            repeatCount: 1,
            benefit: "Protection"
        )

        XCTAssertEqual(dua.id, "simple1")
        XCTAssertEqual(dua.category, .morning)
        XCTAssertEqual(dua.arabic, "بِسْمِ اللَّهِ")
        XCTAssertEqual(dua.repeatCount, 1)
        XCTAssertEqual(dua.benefit, "Protection")
    }
}
