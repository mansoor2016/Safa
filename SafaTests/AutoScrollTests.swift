// MARK: - AutoScrollTests.swift
// PURPOSE: Tests for auto-scroll speed and default state
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class AutoScrollSpeedTests: XCTestCase {

    // MARK: - Label Tests

    func test_quarterSpeed_label() {
        XCTAssertEqual(AutoScrollSpeed.quarter.label, "0.25x")
    }

    func test_halfSpeed_label() {
        XCTAssertEqual(AutoScrollSpeed.half.label, "0.5x")
    }

    func test_threeQuarterSpeed_label() {
        XCTAssertEqual(AutoScrollSpeed.threeQuarter.label, "0.75x")
    }

    func test_normalSpeed_label() {
        XCTAssertEqual(AutoScrollSpeed.normal.label, "1x")
    }

    // MARK: - Raw Value Tests

    func test_quarterSpeed_rawValue() {
        XCTAssertEqual(AutoScrollSpeed.quarter.rawValue, 0.25)
    }

    func test_halfSpeed_rawValue() {
        XCTAssertEqual(AutoScrollSpeed.half.rawValue, 0.5)
    }

    func test_threeQuarterSpeed_rawValue() {
        XCTAssertEqual(AutoScrollSpeed.threeQuarter.rawValue, 0.75)
    }

    func test_normalSpeed_rawValue() {
        XCTAssertEqual(AutoScrollSpeed.normal.rawValue, 1.0)
    }

    // MARK: - All Cases

    func test_allCases_hasFourSpeeds() {
        XCTAssertEqual(AutoScrollSpeed.allCases.count, 4)
    }
}

// MARK: - Progress Ring Mode Tests

final class ProgressRingModeTests: XCTestCase {

    func test_highWaterMark_label() {
        XCTAssertEqual(ProgressRingMode.highWaterMark.label, "Furthest Read")
    }

    func test_currentPosition_label() {
        XCTAssertEqual(ProgressRingMode.currentPosition.label, "Current Position")
    }

    func test_allCases_hasTwoModes() {
        XCTAssertEqual(ProgressRingMode.allCases.count, 2)
    }
}

// MARK: - ViewModel Auto-Scroll State

@MainActor
final class AutoScrollViewModelTests: XCTestCase {
    var sut: AyahReaderViewModel!
    var mockRepository: TestableQuranRepository!

    override func setUp() {
        super.setUp()
        mockRepository = TestableQuranRepository()
        sut = AyahReaderViewModel(surahNumber: 1, repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func test_defaultAutoScrollState_isNotScrolling() {
        XCTAssertFalse(sut.isAutoScrolling)
    }

    func test_defaultAutoScrollSpeed_isNormal() {
        XCTAssertEqual(sut.autoScrollSpeed, .normal)
    }

    // MARK: - Character-Aware Interval Tests

    func test_scrollIntervalForAyah_shortAyah_0_25x() {
        // 10 chars at 0.25x: max(2.0, 10 / (15 * 0.25)) = max(2.0, 2.67) = 2.67s
        sut.autoScrollSpeed = .quarter
        let ayah = Ayah(
            surahNumber: 1, ayahNumber: 1,
            textArabic: String(repeating: "ع", count: 10),
            textTranslation: "In the name",
            juzNumber: 1, pageNumber: 1
        )
        let interval = sut.scrollIntervalForAyah(ayah)
        XCTAssertGreaterThan(interval, 2.0)
        XCTAssertLessThan(interval, 3.0)
    }

    func test_scrollIntervalForAyah_mediumAyah_1x() {
        // 60 chars at 1x: max(2.0, 60 / 15) = max(2.0, 4.0) = 4.0s
        sut.autoScrollSpeed = .normal
        let ayah = Ayah(
            surahNumber: 1, ayahNumber: 1,
            textArabic: String(repeating: "ع", count: 60),
            textTranslation: "Text",
            juzNumber: 1, pageNumber: 1
        )
        let interval = sut.scrollIntervalForAyah(ayah)
        XCTAssertEqual(interval, 4.0, accuracy: 0.01)
    }

    func test_scrollIntervalForAyah_longAyah_halfSpeed() {
        // 200 chars at 0.5x: max(2.0, 200 / (15 * 0.5)) = max(2.0, 26.67) = 26.67s
        sut.autoScrollSpeed = .half
        let ayah = Ayah(
            surahNumber: 1, ayahNumber: 1,
            textArabic: String(repeating: "ع", count: 200),
            textTranslation: "Text",
            juzNumber: 1, pageNumber: 1
        )
        let interval = sut.scrollIntervalForAyah(ayah)
        XCTAssertGreaterThan(interval, 26.0)
        XCTAssertLessThan(interval, 27.0)
    }

    func test_scrollIntervalForAyah_enforcesMinimum() {
        // 3 chars at 1x: max(2.0, 0.2) = 2.0s (enforced minimum)
        sut.autoScrollSpeed = .normal
        let ayah = Ayah(
            surahNumber: 1, ayahNumber: 1,
            textArabic: "أي",
            textTranslation: "Or",
            juzNumber: 1, pageNumber: 1
        )
        let interval = sut.scrollIntervalForAyah(ayah)
        XCTAssertEqual(interval, 2.0)
    }

    // MARK: - Progress Ring Mode Tests

    func test_defaultProgressRingMode_isHighWaterMark() {
        XCTAssertEqual(sut.progressRingMode, .highWaterMark)
    }

    func test_progressFraction_highWaterMark_usesReadAyahs() async {
        // Given: surah with 7 ayahs, 3 read
        mockRepository.surahsToReturn = [
            Surah(id: 1, nameArabic: "الفاتحة", nameEnglish: "Al-Fatiha",
                  nameTransliteration: "Al-Fatihah", revelationType: .meccan, ayahCount: 7, juzStart: 1)
        ]
        mockRepository.ayahsToReturn = (1...7).map {
            Ayah(surahNumber: 1, ayahNumber: $0, textArabic: "آية", textTranslation: "Verse \($0)", juzNumber: 1, pageNumber: 1)
        }
        await sut.loadAyahs()
        sut.markAyahVisible(1)
        sut.markAyahVisible(2)
        sut.markAyahVisible(3)
        sut.progressRingMode = .highWaterMark

        // Then: 3/7 = 0.4286
        XCTAssertEqual(sut.progressFraction, 3.0 / 7.0, accuracy: 0.01)
    }

    func test_progressFraction_currentPosition_usesCurrentAyah() async {
        // Given: surah with 7 ayahs, currently viewing ayah 5
        mockRepository.surahsToReturn = [
            Surah(id: 1, nameArabic: "الفاتحة", nameEnglish: "Al-Fatiha",
                  nameTransliteration: "Al-Fatihah", revelationType: .meccan, ayahCount: 7, juzStart: 1)
        ]
        mockRepository.ayahsToReturn = (1...7).map {
            Ayah(surahNumber: 1, ayahNumber: $0, textArabic: "آية", textTranslation: "Verse \($0)", juzNumber: 1, pageNumber: 1)
        }
        await sut.loadAyahs()
        sut.markAyahVisible(5)
        sut.progressRingMode = .currentPosition

        // Then: 5/7 = 0.714
        XCTAssertEqual(sut.progressFraction, 5.0 / 7.0, accuracy: 0.01)
    }

    func test_progressFraction_currentPosition_scrollBackDecreases() async {
        // Given: user reads to ayah 5, then scrolls back to ayah 2
        mockRepository.surahsToReturn = [
            Surah(id: 1, nameArabic: "الفاتحة", nameEnglish: "Al-Fatiha",
                  nameTransliteration: "Al-Fatihah", revelationType: .meccan, ayahCount: 7, juzStart: 1)
        ]
        mockRepository.ayahsToReturn = (1...7).map {
            Ayah(surahNumber: 1, ayahNumber: $0, textArabic: "آية", textTranslation: "Verse \($0)", juzNumber: 1, pageNumber: 1)
        }
        await sut.loadAyahs()
        sut.markAyahVisible(5)
        sut.markAyahVisible(2)
        sut.progressRingMode = .currentPosition

        // Then: current position = ayah 2, so 2/7
        XCTAssertEqual(sut.progressFraction, 2.0 / 7.0, accuracy: 0.01)
    }

    func test_resetProgress_clearsReadAyahs() async {
        // Given: surah loaded, some ayahs marked read
        mockRepository.surahsToReturn = [
            Surah(id: 1, nameArabic: "الفاتحة", nameEnglish: "Al-Fatiha",
                  nameTransliteration: "Al-Fatihah", revelationType: .meccan, ayahCount: 7, juzStart: 1)
        ]
        mockRepository.ayahsToReturn = (1...7).map {
            Ayah(surahNumber: 1, ayahNumber: $0, textArabic: "آية", textTranslation: "Verse \($0)", juzNumber: 1, pageNumber: 1)
        }
        await sut.loadAyahs()
        sut.markAyahVisible(1)
        sut.markAyahVisible(2)
        sut.markAyahVisible(3)
        XCTAssertGreaterThan(sut.progressFraction, 0)

        // When
        sut.resetProgress()

        // Then: high-water mark resets to 0
        sut.progressRingMode = .highWaterMark
        XCTAssertEqual(sut.progressFraction, 0)
        XCTAssertFalse(sut.isSurahComplete)
    }
}
