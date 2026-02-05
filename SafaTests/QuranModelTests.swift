// MARK: - QuranModelTests.swift
// PURPOSE: Unit tests for Quran domain entities

import XCTest
@testable import Safa

final class QuranModelTests: XCTestCase {

    // MARK: - Surah Tests

    func testSurahCreation() {
        let surah = Surah(
            id: 1,
            nameArabic: "الفاتحة",
            nameEnglish: "Al-Fatiha",
            nameTransliteration: "Al-Fatihah",
            revelationType: .meccan,
            ayahCount: 7,
            juzStart: 1
        )

        XCTAssertEqual(surah.id, 1)
        XCTAssertEqual(surah.number, 1)
        XCTAssertEqual(surah.nameArabic, "الفاتحة")
        XCTAssertEqual(surah.nameEnglish, "Al-Fatiha")
        XCTAssertEqual(surah.nameTransliteration, "Al-Fatihah")
        XCTAssertEqual(surah.revelationType, .meccan)
        XCTAssertEqual(surah.ayahCount, 7)
        XCTAssertEqual(surah.juzStart, 1)
    }

    func testSurahRevelationTypes() {
        XCTAssertEqual(Surah.RevelationType.meccan.rawValue, "Meccan")
        XCTAssertEqual(Surah.RevelationType.medinan.rawValue, "Medinan")
    }

    func testSurahCodable() throws {
        let original = Surah(
            id: 2,
            nameArabic: "البقرة",
            nameEnglish: "Al-Baqarah",
            nameTransliteration: "Al-Baqara",
            revelationType: .medinan,
            ayahCount: 286,
            juzStart: 1
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Surah.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.nameEnglish, original.nameEnglish)
        XCTAssertEqual(decoded.revelationType, original.revelationType)
        XCTAssertEqual(decoded.ayahCount, original.ayahCount)
    }

    func testSurahHashable() {
        let surah1 = Surah(
            id: 1,
            nameArabic: "الفاتحة",
            nameEnglish: "Al-Fatiha",
            nameTransliteration: "Al-Fatihah",
            revelationType: .meccan,
            ayahCount: 7,
            juzStart: 1
        )

        let surah2 = Surah(
            id: 1,
            nameArabic: "الفاتحة",
            nameEnglish: "Al-Fatiha",
            nameTransliteration: "Al-Fatihah",
            revelationType: .meccan,
            ayahCount: 7,
            juzStart: 1
        )

        XCTAssertEqual(surah1, surah2)
    }

    // MARK: - Ayah Tests

    func testAyahCreation() {
        let ayah = Ayah(
            surahNumber: 2,
            ayahNumber: 255,
            textArabic: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ",
            textTranslation: "Allah - there is no deity except Him",
            textTransliteration: "Allahu la ilaha illa huwa",
            juzNumber: 3,
            pageNumber: 42
        )

        XCTAssertEqual(ayah.id, "2:255")
        XCTAssertEqual(ayah.surahNumber, 2)
        XCTAssertEqual(ayah.ayahNumber, 255)
        XCTAssertEqual(ayah.textArabic, "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ")
        XCTAssertEqual(ayah.textTranslation, "Allah - there is no deity except Him")
        XCTAssertEqual(ayah.textTransliteration, "Allahu la ilaha illa huwa")
        XCTAssertEqual(ayah.juzNumber, 3)
        XCTAssertEqual(ayah.pageNumber, 42)
    }

    func testAyahReference() {
        let ayah = Ayah(
            surahNumber: 112,
            ayahNumber: 1,
            textArabic: "قُلْ هُوَ اللَّهُ أَحَدٌ",
            textTranslation: "Say: He is Allah, the One",
            juzNumber: 30,
            pageNumber: 604
        )

        XCTAssertEqual(ayah.reference, "112:1")
    }

    func testAyahWithoutTransliteration() {
        let ayah = Ayah(
            surahNumber: 1,
            ayahNumber: 1,
            textArabic: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            textTranslation: "In the name of Allah, the Entirely Merciful, the Especially Merciful",
            juzNumber: 1,
            pageNumber: 1
        )

        XCTAssertNil(ayah.textTransliteration)
    }

    func testAyahCodable() throws {
        let original = Ayah(
            surahNumber: 1,
            ayahNumber: 1,
            textArabic: "بِسْمِ اللَّهِ",
            textTranslation: "In the name of Allah",
            textTransliteration: "Bismillah",
            juzNumber: 1,
            pageNumber: 1
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Ayah.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.surahNumber, original.surahNumber)
        XCTAssertEqual(decoded.ayahNumber, original.ayahNumber)
        XCTAssertEqual(decoded.textArabic, original.textArabic)
    }

    // MARK: - Juz Tests

    func testJuzCreation() {
        let juz = Juz(
            id: 1,
            startSurah: 1,
            startAyah: 1,
            endSurah: 2,
            endAyah: 141
        )

        XCTAssertEqual(juz.id, 1)
        XCTAssertEqual(juz.number, 1)
        XCTAssertEqual(juz.startSurah, 1)
        XCTAssertEqual(juz.startAyah, 1)
        XCTAssertEqual(juz.endSurah, 2)
        XCTAssertEqual(juz.endAyah, 141)
    }

    func testJuzCodable() throws {
        let original = Juz(
            id: 30,
            startSurah: 78,
            startAyah: 1,
            endSurah: 114,
            endAyah: 6
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Juz.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.startSurah, original.startSurah)
        XCTAssertEqual(decoded.endSurah, original.endSurah)
    }

    // MARK: - QuranBookmark Tests

    func testQuranBookmarkCreation() {
        let bookmark = QuranBookmark(
            surahNumber: 2,
            ayahNumber: 255,
            note: "Ayatul Kursi"
        )

        XCTAssertEqual(bookmark.surahNumber, 2)
        XCTAssertEqual(bookmark.ayahNumber, 255)
        XCTAssertEqual(bookmark.note, "Ayatul Kursi")
        XCTAssertNotNil(bookmark.id)
        XCTAssertNotNil(bookmark.createdAt)
    }

    func testQuranBookmarkReference() {
        let bookmark = QuranBookmark(
            surahNumber: 18,
            ayahNumber: 10
        )

        XCTAssertEqual(bookmark.reference, "18:10")
    }

    func testQuranBookmarkWithoutNote() {
        let bookmark = QuranBookmark(
            surahNumber: 36,
            ayahNumber: 1
        )

        XCTAssertNil(bookmark.note)
    }

    func testQuranBookmarkCodable() throws {
        let original = QuranBookmark(
            surahNumber: 55,
            ayahNumber: 13,
            note: "Test note"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(QuranBookmark.self, from: data)

        XCTAssertEqual(decoded.surahNumber, original.surahNumber)
        XCTAssertEqual(decoded.ayahNumber, original.ayahNumber)
        XCTAssertEqual(decoded.note, original.note)
    }

    // MARK: - QuranProgress Tests

    func testQuranProgressDefaults() {
        let progress = QuranProgress()

        XCTAssertEqual(progress.lastSurah, 1)
        XCTAssertEqual(progress.lastAyah, 1)
        XCTAssertEqual(progress.totalAyahsRead, 0)
        XCTAssertEqual(progress.khatmCount, 0)
    }

    func testQuranProgressCreation() {
        let progress = QuranProgress(
            lastSurah: 2,
            lastAyah: 100,
            totalAyahsRead: 107, // 7 from Al-Fatiha + 100 from Al-Baqarah
            khatmCount: 0
        )

        XCTAssertEqual(progress.lastSurah, 2)
        XCTAssertEqual(progress.lastAyah, 100)
        XCTAssertEqual(progress.totalAyahsRead, 107)
        XCTAssertEqual(progress.khatmCount, 0)
    }

    func testQuranProgressPercentage() {
        // Total ayahs in Quran: 6236
        let progress = QuranProgress(
            lastSurah: 1,
            lastAyah: 1,
            totalAyahsRead: 623, // ~10%
            khatmCount: 0
        )

        let percentage = progress.progressPercentage
        XCTAssertEqual(percentage, 623.0 / 6236.0 * 100.0, accuracy: 0.001)
    }

    func testQuranProgressPercentageComplete() {
        let progress = QuranProgress(
            lastSurah: 114,
            lastAyah: 6,
            totalAyahsRead: 6236,
            khatmCount: 1
        )

        XCTAssertEqual(progress.progressPercentage, 100.0, accuracy: 0.001)
    }

    func testQuranProgressPercentageZero() {
        let progress = QuranProgress()

        XCTAssertEqual(progress.progressPercentage, 0.0, accuracy: 0.001)
    }

    func testQuranProgressCodable() throws {
        let original = QuranProgress(
            lastSurah: 36,
            lastAyah: 83,
            totalAyahsRead: 3000,
            khatmCount: 2
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(QuranProgress.self, from: data)

        XCTAssertEqual(decoded.lastSurah, original.lastSurah)
        XCTAssertEqual(decoded.lastAyah, original.lastAyah)
        XCTAssertEqual(decoded.totalAyahsRead, original.totalAyahsRead)
        XCTAssertEqual(decoded.khatmCount, original.khatmCount)
    }

    // MARK: - Reciter Tests

    func testReciterCreation() {
        let reciter = Reciter(
            id: "mishary",
            nameEnglish: "Mishary Rashid Alafasy",
            nameArabic: "مشاري راشد العفاسي",
            style: "Murattal",
            audioBaseURL: URL(string: "https://example.com/audio")
        )

        XCTAssertEqual(reciter.id, "mishary")
        XCTAssertEqual(reciter.nameEnglish, "Mishary Rashid Alafasy")
        XCTAssertEqual(reciter.nameArabic, "مشاري راشد العفاسي")
        XCTAssertEqual(reciter.style, "Murattal")
        XCTAssertNotNil(reciter.audioBaseURL)
    }

    func testReciterWithoutStyle() {
        let reciter = Reciter(
            id: "test",
            nameEnglish: "Test Reciter",
            nameArabic: "قارئ اختبار",
            style: nil,
            audioBaseURL: nil
        )

        XCTAssertNil(reciter.style)
        XCTAssertNil(reciter.audioBaseURL)
    }

    func testReciterCodable() throws {
        let original = Reciter(
            id: "sudais",
            nameEnglish: "Abdul Rahman Al-Sudais",
            nameArabic: "عبد الرحمن السديس",
            style: "Mujawwad",
            audioBaseURL: URL(string: "https://example.com")
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Reciter.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.nameEnglish, original.nameEnglish)
        XCTAssertEqual(decoded.style, original.style)
    }
}
