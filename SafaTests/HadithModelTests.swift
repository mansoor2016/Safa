// MARK: - HadithModelTests.swift
// PURPOSE: Unit tests for Hadith domain models
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class HadithModelTests: XCTestCase {

    // MARK: - Collection Tests

    func testHadithCollectionInitialization() {
        let collection = HadithCollection(
            id: "bukhari",
            nameEnglish: "Sahih al-Bukhari",
            nameArabic: "صحيح البخاري",
            compilerName: "Imam al-Bukhari",
            totalHadiths: 7563,
            totalBooks: 97
        )

        XCTAssertEqual(collection.id, "bukhari")
        XCTAssertEqual(collection.nameEnglish, "Sahih al-Bukhari")
        XCTAssertEqual(collection.totalHadiths, 7563)
        XCTAssertEqual(collection.totalBooks, 97)
    }

    func testHadithCollectionEquality() {
        let collection1 = HadithCollection(
            id: "bukhari",
            nameEnglish: "Sahih al-Bukhari",
            nameArabic: "صحيح البخاري",
            compilerName: "Imam al-Bukhari",
            totalHadiths: 7563,
            totalBooks: 97
        )

        let collection2 = HadithCollection(
            id: "bukhari",
            nameEnglish: "Sahih al-Bukhari",
            nameArabic: "صحيح البخاري",
            compilerName: "Imam al-Bukhari",
            totalHadiths: 7563,
            totalBooks: 97
        )

        XCTAssertEqual(collection1.id, collection2.id)
    }

    func testStaticCollections() {
        XCTAssertEqual(HadithCollection.sahihBukhari.id, "bukhari")
        XCTAssertEqual(HadithCollection.sahihMuslim.id, "muslim")
    }

    // MARK: - Hadith Tests

    func testHadithInitialization() {
        let hadith = Hadith(
            id: "bukhari_1",
            collectionId: "bukhari",
            bookId: "1",
            hadithNumber: 1,
            textArabic: "إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ",
            textEnglish: "Actions are by intentions",
            narrator: "Umar bin Al-Khattab",
            grading: .sahih,
            reference: "Sahih al-Bukhari 1"
        )

        XCTAssertEqual(hadith.id, "bukhari_1")
        XCTAssertEqual(hadith.hadithNumber, 1)
        XCTAssertEqual(hadith.narrator, "Umar bin Al-Khattab")
        XCTAssertEqual(hadith.grading, .sahih)
    }

    func testHadithGradingRawValues() {
        XCTAssertEqual(HadithGrading.sahih.rawValue, "Sahih")
        XCTAssertEqual(HadithGrading.hasan.rawValue, "Hasan")
        XCTAssertEqual(HadithGrading.daif.rawValue, "Da'if")
        XCTAssertEqual(HadithGrading.mawdu.rawValue, "Mawdu'")
        XCTAssertEqual(HadithGrading.unknown.rawValue, "Unknown")
    }

    func testHadithGradingDescriptions() {
        XCTAssertEqual(HadithGrading.sahih.description, "Authentic")
        XCTAssertEqual(HadithGrading.hasan.description, "Good")
        XCTAssertEqual(HadithGrading.daif.description, "Weak")
        XCTAssertEqual(HadithGrading.mawdu.description, "Fabricated")
    }

    func testHadithHasRequiredFields() {
        let hadith = Hadith(
            id: "test_1",
            collectionId: "test",
            bookId: "1",
            hadithNumber: 1,
            textArabic: "Arabic text",
            textEnglish: "English text",
            narrator: "Narrator",
            grading: .sahih,
            reference: "Reference"
        )

        XCTAssertFalse(hadith.textArabic.isEmpty)
        XCTAssertFalse(hadith.textEnglish.isEmpty)
        XCTAssertFalse(hadith.narrator.isEmpty)
    }

    func testHadithBookmarkDefault() {
        let hadith = Hadith(
            id: "test_1",
            collectionId: "test",
            bookId: "1",
            hadithNumber: 1,
            textArabic: "Arabic text",
            textEnglish: "English text",
            narrator: "Narrator",
            grading: .sahih,
            reference: "Reference"
        )

        XCTAssertFalse(hadith.isBookmarked)
    }

    // MARK: - Book Tests

    func testHadithBookInitialization() {
        let book = HadithBook(
            id: "1",
            collectionId: "bukhari",
            bookNumber: 1,
            nameEnglish: "Revelation",
            nameArabic: "بدء الوحي",
            hadithCount: 7
        )

        XCTAssertEqual(book.id, "1")
        XCTAssertEqual(book.collectionId, "bukhari")
        XCTAssertEqual(book.nameEnglish, "Revelation")
        XCTAssertEqual(book.bookNumber, 1)
        XCTAssertEqual(book.hadithCount, 7)
    }

    // MARK: - Encoding/Decoding Tests

    func testHadithCodable() throws {
        let original = Hadith(
            id: "test_1",
            collectionId: "test",
            bookId: "1",
            hadithNumber: 1,
            textArabic: "عربي",
            textEnglish: "English",
            narrator: "Test",
            grading: .hasan,
            reference: "Test 1"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Hadith.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.textArabic, decoded.textArabic)
        XCTAssertEqual(original.grading, decoded.grading)
    }

    func testHadithCollectionCodable() throws {
        let original = HadithCollection(
            id: "test",
            nameEnglish: "Test Collection",
            nameArabic: "مجموعة اختبار",
            compilerName: "Test",
            totalHadiths: 100,
            totalBooks: 10
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HadithCollection.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.nameEnglish, decoded.nameEnglish)
    }

    func testHadithBookCodable() throws {
        let original = HadithBook(
            id: "1",
            collectionId: "test",
            bookNumber: 1,
            nameEnglish: "Test Book",
            nameArabic: "كتاب اختبار",
            hadithCount: 50
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HadithBook.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.nameEnglish, decoded.nameEnglish)
        XCTAssertEqual(original.bookNumber, decoded.bookNumber)
    }
}
