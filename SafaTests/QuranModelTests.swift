// MARK: - QuranModelTests.swift
// PURPOSE: Unit tests for Quran domain models
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class QuranModelTests: XCTestCase {

    // MARK: - Surah Tests

    func testSurahAllSurahsCount() {
        let surahs = Surah.allSurahs
        XCTAssertEqual(surahs.count, 114, "Quran should have exactly 114 surahs")
    }

    func testSurahFirstSurah() {
        let surahs = Surah.allSurahs
        guard let first = surahs.first else {
            XCTFail("Should have at least one surah")
            return
        }

        XCTAssertEqual(first.number, 1)
        XCTAssertEqual(first.nameEnglish, "Al-Fatihah")
        XCTAssertEqual(first.ayahCount, 7)
        XCTAssertEqual(first.revelationType, .meccan)
    }

    func testSurahLastSurah() {
        let surahs = Surah.allSurahs
        guard let last = surahs.last else {
            XCTFail("Should have at least one surah")
            return
        }

        XCTAssertEqual(last.number, 114)
        XCTAssertEqual(last.nameEnglish, "An-Nas")
    }

    func testSurahNumbersAreSequential() {
        let surahs = Surah.allSurahs

        for (index, surah) in surahs.enumerated() {
            XCTAssertEqual(surah.number, index + 1, "Surah number should be sequential")
        }
    }

    func testSurahAyahCountsArePositive() {
        for surah in Surah.allSurahs {
            XCTAssertGreaterThan(surah.ayahCount, 0, "Surah \(surah.number) should have positive ayah count")
        }
    }

    func testSurahHasArabicName() {
        for surah in Surah.allSurahs {
            XCTAssertFalse(surah.nameArabic.isEmpty, "Surah \(surah.number) should have Arabic name")
        }
    }

    func testSurahHasEnglishName() {
        for surah in Surah.allSurahs {
            XCTAssertFalse(surah.nameEnglish.isEmpty, "Surah \(surah.number) should have English name")
        }
    }

    // MARK: - Revelation Type Tests

    func testRevelationTypeDisplayNames() {
        XCTAssertEqual(RevelationType.meccan.rawValue, "Meccan")
        XCTAssertEqual(RevelationType.medinan.rawValue, "Medinan")
    }

    func testMeccanSurahsExist() {
        let meccanSurahs = Surah.allSurahs.filter { $0.revelationType == .meccan }
        XCTAssertGreaterThan(meccanSurahs.count, 0)
    }

    func testMedinanSurahsExist() {
        let medinanSurahs = Surah.allSurahs.filter { $0.revelationType == .medinan }
        XCTAssertGreaterThan(medinanSurahs.count, 0)
    }

    // MARK: - Juz Tests

    func testJuzAllJuzCount() {
        let juzList = Juz.allJuz
        XCTAssertEqual(juzList.count, 30, "Quran should have exactly 30 juz")
    }

    func testJuzNumbersAreSequential() {
        let juzList = Juz.allJuz

        for (index, juz) in juzList.enumerated() {
            XCTAssertEqual(juz.number, index + 1, "Juz number should be sequential")
        }
    }

    func testJuzStartAndEndValid() {
        for juz in Juz.allJuz {
            XCTAssertGreaterThan(juz.startSurah, 0)
            XCTAssertLessThanOrEqual(juz.startSurah, 114)
            XCTAssertGreaterThan(juz.startAyah, 0)

            XCTAssertGreaterThan(juz.endSurah, 0)
            XCTAssertLessThanOrEqual(juz.endSurah, 114)
            XCTAssertGreaterThan(juz.endAyah, 0)
        }
    }

    func testFirstJuzStartsAtBeginning() {
        guard let firstJuz = Juz.allJuz.first else {
            XCTFail("Should have at least one juz")
            return
        }

        XCTAssertEqual(firstJuz.startSurah, 1)
        XCTAssertEqual(firstJuz.startAyah, 1)
    }

    // MARK: - Ayah Tests

    func testAyahAlFatihaExists() {
        let fatiha = Ayah.alFatiha
        XCTAssertEqual(fatiha.count, 7, "Al-Fatiha should have 7 ayahs")
    }

    func testAyahHasRequiredFields() {
        for ayah in Ayah.alFatiha {
            XCTAssertEqual(ayah.surahNumber, 1)
            XCTAssertGreaterThan(ayah.ayahNumber, 0)
            XCTAssertFalse(ayah.textArabic.isEmpty)
            XCTAssertFalse(ayah.textTranslation.isEmpty)
        }
    }

    func testAyahIdFormat() {
        for ayah in Ayah.alFatiha {
            XCTAssertEqual(ayah.id, "\(ayah.surahNumber):\(ayah.ayahNumber)")
        }
    }

    // MARK: - Bookmark Tests

    func testQuranBookmarkInitialization() {
        let bookmark = QuranBookmark(
            surahNumber: 2,
            ayahNumber: 255,
            note: "Ayat Al-Kursi"
        )

        XCTAssertEqual(bookmark.surahNumber, 2)
        XCTAssertEqual(bookmark.ayahNumber, 255)
        XCTAssertEqual(bookmark.note, "Ayat Al-Kursi")
        XCTAssertNotNil(bookmark.createdAt)
    }

    func testQuranBookmarkReference() {
        let bookmark = QuranBookmark(
            surahNumber: 1,
            ayahNumber: 1,
            note: nil
        )

        XCTAssertEqual(bookmark.reference, "Surah 1:1")
    }

    // MARK: - Reading Progress Tests

    func testReadingProgressInitialization() {
        let progress = QuranReadingProgress(
            lastSurah: 2,
            lastAyah: 100,
            totalAyahsRead: 350
        )

        XCTAssertEqual(progress.lastSurah, 2)
        XCTAssertEqual(progress.lastAyah, 100)
        XCTAssertEqual(progress.totalAyahsRead, 350)
    }

    func testReadingProgressDefaultValues() {
        let progress = QuranReadingProgress()

        XCTAssertEqual(progress.lastSurah, 1)
        XCTAssertEqual(progress.lastAyah, 1)
        XCTAssertEqual(progress.totalAyahsRead, 0)
    }
}
