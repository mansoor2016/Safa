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
            name: "Sahih al-Bukhari",
            arabicName: "صحيح البخاري",
            compiler: "Imam al-Bukhari",
            totalHadith: 7563,
            description: "Most authentic collection"
        )

        XCTAssertEqual(collection.id, "bukhari")
        XCTAssertEqual(collection.name, "Sahih al-Bukhari")
        XCTAssertEqual(collection.totalHadith, 7563)
    }

    func testHadithCollectionEquality() {
        let collection1 = HadithCollection(
            id: "bukhari",
            name: "Sahih al-Bukhari",
            arabicName: "صحيح البخاري",
            compiler: "Imam al-Bukhari",
            totalHadith: 7563,
            description: "Most authentic"
        )

        let collection2 = HadithCollection(
            id: "bukhari",
            name: "Sahih al-Bukhari",
            arabicName: "صحيح البخاري",
            compiler: "Imam al-Bukhari",
            totalHadith: 7563,
            description: "Most authentic"
        )

        XCTAssertEqual(collection1.id, collection2.id)
    }

    // MARK: - Hadith Tests

    func testHadithInitialization() {
        let hadith = Hadith(
            id: "bukhari_1",
            collection: "Sahih al-Bukhari",
            bookId: "1",
            number: 1,
            arabic: "إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ",
            english: "Actions are by intentions",
            narrator: "Umar bin Al-Khattab",
            grade: .sahih,
            reference: "Sahih al-Bukhari 1",
            topics: ["intentions", "deeds"]
        )

        XCTAssertEqual(hadith.id, "bukhari_1")
        XCTAssertEqual(hadith.number, 1)
        XCTAssertEqual(hadith.narrator, "Umar bin Al-Khattab")
        XCTAssertEqual(hadith.grade, .sahih)
        XCTAssertEqual(hadith.topics.count, 2)
    }

    func testHadithGradeRawValues() {
        XCTAssertEqual(HadithGrade.sahih.rawValue, "sahih")
        XCTAssertEqual(HadithGrade.hasan.rawValue, "hasan")
        XCTAssertEqual(HadithGrade.daif.rawValue, "daif")
    }

    func testHadithGradeDisplayNames() {
        XCTAssertEqual(HadithGrade.sahih.displayName, "Authentic")
        XCTAssertEqual(HadithGrade.hasan.displayName, "Good")
        XCTAssertEqual(HadithGrade.daif.displayName, "Weak")
    }

    func testHadithHasRequiredFields() {
        let hadith = Hadith(
            id: "test_1",
            collection: "Test Collection",
            bookId: "1",
            number: 1,
            arabic: "Arabic text",
            english: "English text",
            narrator: "Narrator",
            grade: .sahih,
            reference: "Reference",
            topics: []
        )

        XCTAssertFalse(hadith.arabic.isEmpty)
        XCTAssertFalse(hadith.english.isEmpty)
        XCTAssertFalse(hadith.narrator.isEmpty)
    }

    // MARK: - Book Tests

    func testHadithBookInitialization() {
        let book = HadithBook(
            id: "1",
            collectionId: "bukhari",
            name: "Revelation",
            arabicName: "بدء الوحي",
            hadithCount: 7
        )

        XCTAssertEqual(book.id, "1")
        XCTAssertEqual(book.collectionId, "bukhari")
        XCTAssertEqual(book.name, "Revelation")
        XCTAssertEqual(book.hadithCount, 7)
    }

    // MARK: - Bookmark Tests

    func testHadithBookmarkInitialization() {
        let bookmark = HadithBookmark(
            hadithId: "bukhari_1",
            note: "Important hadith"
        )

        XCTAssertEqual(bookmark.hadithId, "bukhari_1")
        XCTAssertEqual(bookmark.note, "Important hadith")
        XCTAssertNotNil(bookmark.createdAt)
    }

    func testHadithBookmarkWithoutNote() {
        let bookmark = HadithBookmark(
            hadithId: "muslim_45",
            note: nil
        )

        XCTAssertEqual(bookmark.hadithId, "muslim_45")
        XCTAssertNil(bookmark.note)
    }

    // MARK: - Topic Tests

    func testHadithTopicsAreValid() {
        let hadith = Hadith(
            id: "test",
            collection: "Test",
            bookId: "1",
            number: 1,
            arabic: "Arabic",
            english: "English",
            narrator: "Narrator",
            grade: .sahih,
            reference: "Ref",
            topics: ["faith", "prayer", "charity"]
        )

        XCTAssertTrue(hadith.topics.contains("faith"))
        XCTAssertTrue(hadith.topics.contains("prayer"))
        XCTAssertTrue(hadith.topics.contains("charity"))
    }

    // MARK: - Encoding/Decoding Tests

    func testHadithCodable() throws {
        let original = Hadith(
            id: "test_1",
            collection: "Test",
            bookId: "1",
            number: 1,
            arabic: "عربي",
            english: "English",
            narrator: "Test",
            grade: .hasan,
            reference: "Test 1",
            topics: ["test"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Hadith.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.arabic, decoded.arabic)
        XCTAssertEqual(original.grade, decoded.grade)
    }

    func testHadithCollectionCodable() throws {
        let original = HadithCollection(
            id: "test",
            name: "Test Collection",
            arabicName: "مجموعة اختبار",
            compiler: "Test",
            totalHadith: 100,
            description: "Test description"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HadithCollection.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.name, decoded.name)
    }
}
