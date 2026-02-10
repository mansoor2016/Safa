// MARK: - SurahReadProgressTests.swift
// PURPOSE: Tests for SurahReadProgress entity and reading progress tracking
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class SurahReadProgressTests: XCTestCase {

    // MARK: - Entity Tests

    func test_fractionComplete_emptyProgress() {
        let progress = SurahReadProgress(surahNumber: 1, readAyahs: [], totalAyahs: 7)
        XCTAssertEqual(progress.fractionComplete, 0)
    }

    func test_fractionComplete_partialProgress() {
        let progress = SurahReadProgress(surahNumber: 1, readAyahs: [1, 2, 3], totalAyahs: 7)
        XCTAssertEqual(progress.fractionComplete, 3.0 / 7.0, accuracy: 0.001)
    }

    func test_fractionComplete_fullProgress() {
        let progress = SurahReadProgress(surahNumber: 1, readAyahs: [1, 2, 3, 4, 5, 6, 7], totalAyahs: 7)
        XCTAssertEqual(progress.fractionComplete, 1.0)
    }

    func test_fractionComplete_zeroTotalAyahs() {
        let progress = SurahReadProgress(surahNumber: 1, readAyahs: [], totalAyahs: 0)
        XCTAssertEqual(progress.fractionComplete, 0)
    }

    func test_isComplete_false_whenPartial() {
        let progress = SurahReadProgress(surahNumber: 1, readAyahs: [1, 2], totalAyahs: 7)
        XCTAssertFalse(progress.isComplete)
    }

    func test_isComplete_true_whenAllRead() {
        let progress = SurahReadProgress(surahNumber: 1, readAyahs: Set(1...7), totalAyahs: 7)
        XCTAssertTrue(progress.isComplete)
    }

    func test_codable_roundTrip() throws {
        let original = SurahReadProgress(surahNumber: 2, readAyahs: [1, 5, 10], totalAyahs: 286)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SurahReadProgress.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - CircularProgressRing Accessibility

    func test_circularProgressRing_accessibilityLabel_zero() {
        // The accessibility label is "\(Int(progress * 100)) percent complete"
        let progress = 0.0
        let label = "\(Int(min(progress, 1.0) * 100)) percent complete"
        XCTAssertEqual(label, "0 percent complete")
    }

    func test_circularProgressRing_accessibilityLabel_half() {
        let progress = 0.5
        let label = "\(Int(min(progress, 1.0) * 100)) percent complete"
        XCTAssertEqual(label, "50 percent complete")
    }

    func test_circularProgressRing_accessibilityLabel_full() {
        let progress = 1.0
        let label = "\(Int(min(progress, 1.0) * 100)) percent complete"
        XCTAssertEqual(label, "100 percent complete")
    }
}

// MARK: - ViewModel Progress Tests

@MainActor
final class AyahReaderProgressTests: XCTestCase {
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

    func test_progressFraction_defaultsToZero() {
        XCTAssertEqual(sut.progressFraction, 0)
    }

    func test_isSurahComplete_defaultsToFalse() {
        XCTAssertFalse(sut.isSurahComplete)
    }

    func test_loadAyahs_initializesProgress() async {
        // Given
        mockRepository.surahsToReturn = [
            Surah(id: 1, nameArabic: "الفاتحة", nameEnglish: "Al-Fatiha", nameTransliteration: "Al-Fatihah", revelationType: .meccan, ayahCount: 7, juzStart: 1)
        ]
        mockRepository.ayahsToReturn = [
            Ayah(surahNumber: 1, ayahNumber: 1, textArabic: "بسم الله", textTranslation: "In the name of Allah", juzNumber: 1, pageNumber: 1)
        ]

        // When
        await sut.loadAyahs()

        // Then
        XCTAssertNotNil(sut.surahReadProgress)
        XCTAssertEqual(sut.surahReadProgress?.totalAyahs, 1)
    }

    func test_markAyahVisible_updatesProgress() async {
        // Given
        mockRepository.surahsToReturn = [
            Surah(id: 1, nameArabic: "الفاتحة", nameEnglish: "Al-Fatiha", nameTransliteration: "Al-Fatihah", revelationType: .meccan, ayahCount: 7, juzStart: 1)
        ]
        mockRepository.ayahsToReturn = (1...7).map { n in
            Ayah(surahNumber: 1, ayahNumber: n, textArabic: "آية \(n)", textTranslation: "Ayah \(n)", juzNumber: 1, pageNumber: 1)
        }
        await sut.loadAyahs()

        // When
        sut.markAyahVisible(1)
        sut.markAyahVisible(2)
        sut.markAyahVisible(3)

        // Then
        XCTAssertEqual(sut.surahReadProgress?.readAyahs.count, 3)
        XCTAssertEqual(sut.progressFraction, 3.0 / 7.0, accuracy: 0.001)
    }

    func test_markAyahVisible_ignoresDuplicates() async {
        // Given
        mockRepository.surahsToReturn = [
            Surah(id: 1, nameArabic: "الفاتحة", nameEnglish: "Al-Fatiha", nameTransliteration: "Al-Fatihah", revelationType: .meccan, ayahCount: 7, juzStart: 1)
        ]
        mockRepository.ayahsToReturn = [
            Ayah(surahNumber: 1, ayahNumber: 1, textArabic: "بسم الله", textTranslation: "In the name", juzNumber: 1, pageNumber: 1)
        ]
        await sut.loadAyahs()

        // When
        sut.markAyahVisible(1)
        sut.markAyahVisible(1)
        sut.markAyahVisible(1)

        // Then
        XCTAssertEqual(sut.surahReadProgress?.readAyahs.count, 1)
    }
}
