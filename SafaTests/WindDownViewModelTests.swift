// MARK: - WindDownViewModelTests.swift
// PURPOSE: Unit tests for WindDownViewModel
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class WindDownViewModelTests: XCTestCase {

    var sut: WindDownViewModel!

    override func setUp() {
        super.setUp()
        sut = WindDownViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialCompletedDhikrIsEmpty() {
        XCTAssertTrue(sut.completedDhikr.isEmpty)
    }

    func testInitialIsPlayingRecitationIsFalse() {
        XCTAssertFalse(sut.isPlayingRecitation)
    }

    func testInitialFajrAlarmEnabledIsFalse() {
        XCTAssertFalse(sut.fajrAlarmEnabled)
    }

    func testInitialPlaybackProgressIsZero() {
        XCTAssertEqual(sut.playbackProgress, 0.0)
    }

    func testDefaultSelectedReciter() {
        XCTAssertEqual(sut.selectedReciter, "Mishary Rashid Alafasy")
    }

    func testDefaultSelectedSurah() {
        XCTAssertEqual(sut.selectedSurah, "Surah Al-Mulk")
    }

    // MARK: - Sleep Dhikr Data Tests

    func testSleepDhikrIsNotEmpty() {
        XCTAssertFalse(sut.sleepDhikr.isEmpty)
    }

    func testSleepDhikrCount() {
        // Should have 9 dhikr items
        XCTAssertEqual(sut.sleepDhikr.count, 9)
    }

    func testSleepDhikrHasUniqueIds() {
        let ids = sut.sleepDhikr.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count)
    }

    func testSleepDhikrContainsAyatulKursi() {
        let hasAyatulKursi = sut.sleepDhikr.contains { $0.id == "ayat-kursi" }
        XCTAssertTrue(hasAyatulKursi)
    }

    func testSleepDhikrContainsThreeQuls() {
        let hasIkhlas = sut.sleepDhikr.contains { $0.id == "surah-ikhlas" }
        let hasFalaq = sut.sleepDhikr.contains { $0.id == "surah-falaq" }
        let hasNas = sut.sleepDhikr.contains { $0.id == "surah-nas" }

        XCTAssertTrue(hasIkhlas)
        XCTAssertTrue(hasFalaq)
        XCTAssertTrue(hasNas)
    }

    func testSleepDhikrContainsTasbih() {
        let hasSubhanAllah = sut.sleepDhikr.contains { $0.id == "tasbih-33" }
        let hasAlhamdulillah = sut.sleepDhikr.contains { $0.id == "hamd-33" }
        let hasTakbir = sut.sleepDhikr.contains { $0.id == "takbir-34" }

        XCTAssertTrue(hasSubhanAllah)
        XCTAssertTrue(hasAlhamdulillah)
        XCTAssertTrue(hasTakbir)
    }

    func testSleepDhikrHasRequiredFields() {
        for dhikr in sut.sleepDhikr {
            XCTAssertFalse(dhikr.id.isEmpty, "ID should not be empty")
            XCTAssertFalse(dhikr.title.isEmpty, "Title should not be empty")
            XCTAssertFalse(dhikr.arabic.isEmpty, "Arabic should not be empty")
            XCTAssertFalse(dhikr.translation.isEmpty, "Translation should not be empty")
            XCTAssertFalse(dhikr.transliteration.isEmpty, "Transliteration should not be empty")
            XCTAssertGreaterThan(dhikr.count, 0, "Count should be positive")
        }
    }

    func testTasbihCountsAreCorrect() {
        let subhanAllah = sut.sleepDhikr.first { $0.id == "tasbih-33" }
        let alhamdulillah = sut.sleepDhikr.first { $0.id == "hamd-33" }
        let allahuAkbar = sut.sleepDhikr.first { $0.id == "takbir-34" }

        XCTAssertEqual(subhanAllah?.count, 33)
        XCTAssertEqual(alhamdulillah?.count, 33)
        XCTAssertEqual(allahuAkbar?.count, 34)
    }

    // MARK: - Calming Surahs Tests

    func testCalmingSurahsIsNotEmpty() {
        XCTAssertFalse(sut.calmingSurahs.isEmpty)
    }

    func testCalmingSurahsContainsMulk() {
        XCTAssertTrue(sut.calmingSurahs.contains("Surah Al-Mulk"))
    }

    func testCalmingSurahsContainsYasin() {
        XCTAssertTrue(sut.calmingSurahs.contains("Surah Yasin"))
    }

    func testCalmingSurahsContainsRahman() {
        XCTAssertTrue(sut.calmingSurahs.contains("Surah Ar-Rahman"))
    }

    // MARK: - Reciters Tests

    func testRecitersIsNotEmpty() {
        XCTAssertFalse(sut.reciters.isEmpty)
    }

    func testRecitersContainsAlafasy() {
        XCTAssertTrue(sut.reciters.contains("Mishary Rashid Alafasy"))
    }

    func testRecitersContainsSudais() {
        XCTAssertTrue(sut.reciters.contains("Abdul Rahman Al-Sudais"))
    }

    // MARK: - Toggle Dhikr Tests

    func testToggleDhikrAddsToCompleted() {
        let dhikrId = "ayat-kursi"
        XCTAssertFalse(sut.completedDhikr.contains(dhikrId))

        sut.toggleDhikr(dhikrId)

        XCTAssertTrue(sut.completedDhikr.contains(dhikrId))
    }

    func testToggleDhikrRemovesFromCompleted() {
        let dhikrId = "ayat-kursi"
        sut.completedDhikr.insert(dhikrId)

        sut.toggleDhikr(dhikrId)

        XCTAssertFalse(sut.completedDhikr.contains(dhikrId))
    }

    func testToggleDhikrTwiceReturnsToOriginal() {
        let dhikrId = "surah-ikhlas"

        sut.toggleDhikr(dhikrId)
        sut.toggleDhikr(dhikrId)

        XCTAssertFalse(sut.completedDhikr.contains(dhikrId))
    }

    func testToggleMultipleDhikr() {
        sut.toggleDhikr("ayat-kursi")
        sut.toggleDhikr("surah-ikhlas")
        sut.toggleDhikr("sleep-dua")

        XCTAssertEqual(sut.completedDhikr.count, 3)
        XCTAssertTrue(sut.completedDhikr.contains("ayat-kursi"))
        XCTAssertTrue(sut.completedDhikr.contains("surah-ikhlas"))
        XCTAssertTrue(sut.completedDhikr.contains("sleep-dua"))
    }

    // MARK: - Toggle Recitation Tests

    func testToggleRecitationStartsPlaying() {
        XCTAssertFalse(sut.isPlayingRecitation)

        sut.toggleRecitation()

        XCTAssertTrue(sut.isPlayingRecitation)
    }

    func testToggleRecitationStopsPlaying() {
        sut.isPlayingRecitation = true

        sut.toggleRecitation()

        XCTAssertFalse(sut.isPlayingRecitation)
    }

    // MARK: - Completion Percentage Tests

    func testCompletionPercentageInitiallyZero() {
        XCTAssertEqual(sut.completionPercentage, 0.0)
    }

    func testCompletionPercentageAfterOneDhikr() {
        sut.toggleDhikr("ayat-kursi")

        let expectedPercentage = (1.0 / Double(sut.sleepDhikr.count)) * 100
        XCTAssertEqual(sut.completionPercentage, expectedPercentage, accuracy: 0.01)
    }

    func testCompletionPercentageAfterHalfDhikr() {
        let halfCount = sut.sleepDhikr.count / 2
        for i in 0..<halfCount {
            sut.toggleDhikr(sut.sleepDhikr[i].id)
        }

        let expectedPercentage = (Double(halfCount) / Double(sut.sleepDhikr.count)) * 100
        XCTAssertEqual(sut.completionPercentage, expectedPercentage, accuracy: 0.01)
    }

    func testCompletionPercentageAfterAllDhikr() {
        for dhikr in sut.sleepDhikr {
            sut.toggleDhikr(dhikr.id)
        }

        XCTAssertEqual(sut.completionPercentage, 100.0, accuracy: 0.01)
    }

    // MARK: - All Dhikr Completed Tests

    func testAllDhikrCompletedInitiallyFalse() {
        XCTAssertFalse(sut.allDhikrCompleted)
    }

    func testAllDhikrCompletedAfterPartialCompletion() {
        sut.toggleDhikr("ayat-kursi")
        sut.toggleDhikr("surah-ikhlas")

        XCTAssertFalse(sut.allDhikrCompleted)
    }

    func testAllDhikrCompletedAfterFullCompletion() {
        for dhikr in sut.sleepDhikr {
            sut.toggleDhikr(dhikr.id)
        }

        XCTAssertTrue(sut.allDhikrCompleted)
    }

    func testAllDhikrCompletedFalseAfterUnchecking() {
        // Complete all
        for dhikr in sut.sleepDhikr {
            sut.toggleDhikr(dhikr.id)
        }
        XCTAssertTrue(sut.allDhikrCompleted)

        // Uncheck one
        sut.toggleDhikr(sut.sleepDhikr[0].id)
        XCTAssertFalse(sut.allDhikrCompleted)
    }

    // MARK: - Reset Progress Tests

    func testResetProgressClearsCompletedDhikr() {
        sut.toggleDhikr("ayat-kursi")
        sut.toggleDhikr("surah-ikhlas")
        XCTAssertFalse(sut.completedDhikr.isEmpty)

        sut.resetProgress()

        XCTAssertTrue(sut.completedDhikr.isEmpty)
    }

    func testResetProgressStopsRecitation() {
        sut.isPlayingRecitation = true

        sut.resetProgress()

        XCTAssertFalse(sut.isPlayingRecitation)
    }

    func testResetProgressClearsPlaybackProgress() {
        sut.playbackProgress = 0.5

        sut.resetProgress()

        XCTAssertEqual(sut.playbackProgress, 0.0)
    }

    func testResetProgressAfterFullCompletion() {
        // Complete everything
        for dhikr in sut.sleepDhikr {
            sut.toggleDhikr(dhikr.id)
        }
        sut.isPlayingRecitation = true
        sut.playbackProgress = 1.0

        sut.resetProgress()

        XCTAssertTrue(sut.completedDhikr.isEmpty)
        XCTAssertFalse(sut.isPlayingRecitation)
        XCTAssertEqual(sut.playbackProgress, 0.0)
        XCTAssertFalse(sut.allDhikrCompleted)
        XCTAssertEqual(sut.completionPercentage, 0.0)
    }
}

// MARK: - SleepDhikr Model Tests

final class SleepDhikrTests: XCTestCase {

    func testSleepDhikrInitialization() {
        let dhikr = SleepDhikr(
            id: "test-dhikr",
            title: "Test Title",
            arabic: "عربي",
            transliteration: "Transliteration",
            translation: "Translation",
            benefit: "Test benefit",
            count: 3
        )

        XCTAssertEqual(dhikr.id, "test-dhikr")
        XCTAssertEqual(dhikr.title, "Test Title")
        XCTAssertEqual(dhikr.arabic, "عربي")
        XCTAssertEqual(dhikr.transliteration, "Transliteration")
        XCTAssertEqual(dhikr.translation, "Translation")
        XCTAssertEqual(dhikr.benefit, "Test benefit")
        XCTAssertEqual(dhikr.count, 3)
    }

    func testSleepDhikrIdentifiable() {
        let dhikr1 = SleepDhikr(
            id: "dhikr-1",
            title: "Title",
            arabic: "عربي",
            transliteration: "Trans",
            translation: "Trans",
            benefit: "Benefit",
            count: 1
        )

        let dhikr2 = SleepDhikr(
            id: "dhikr-2",
            title: "Title",
            arabic: "عربي",
            transliteration: "Trans",
            translation: "Trans",
            benefit: "Benefit",
            count: 1
        )

        XCTAssertNotEqual(dhikr1.id, dhikr2.id)
    }

    func testSleepDhikrCountVariations() {
        // Single count dhikr
        let singleCount = SleepDhikr(
            id: "single",
            title: "Single",
            arabic: "أ",
            transliteration: "A",
            translation: "A",
            benefit: "Once",
            count: 1
        )
        XCTAssertEqual(singleCount.count, 1)

        // Multiple count dhikr (like tasbih)
        let multipleCount = SleepDhikr(
            id: "multiple",
            title: "Multiple",
            arabic: "أ",
            transliteration: "A",
            translation: "A",
            benefit: "33 times",
            count: 33
        )
        XCTAssertEqual(multipleCount.count, 33)
    }
}
