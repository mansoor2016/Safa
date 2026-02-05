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

    func testInitialCompletedAdhkarIsEmpty() {
        XCTAssertTrue(sut.completedAdhkar.isEmpty)
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

    // MARK: - Sleep Adhkar Data Tests

    func testSleepAdhkarIsNotEmpty() {
        XCTAssertFalse(sut.sleepAdhkar.isEmpty)
    }

    func testSleepAdhkarCount() {
        // Should have 9 adhkar items
        XCTAssertEqual(sut.sleepAdhkar.count, 9)
    }

    func testSleepAdhkarHasUniqueIds() {
        let ids = sut.sleepAdhkar.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count)
    }

    func testSleepAdhkarContainsAyatulKursi() {
        let hasAyatulKursi = sut.sleepAdhkar.contains { $0.id == "ayat-kursi" }
        XCTAssertTrue(hasAyatulKursi)
    }

    func testSleepAdhkarContainsThreeQuls() {
        let hasIkhlas = sut.sleepAdhkar.contains { $0.id == "surah-ikhlas" }
        let hasFalaq = sut.sleepAdhkar.contains { $0.id == "surah-falaq" }
        let hasNas = sut.sleepAdhkar.contains { $0.id == "surah-nas" }

        XCTAssertTrue(hasIkhlas)
        XCTAssertTrue(hasFalaq)
        XCTAssertTrue(hasNas)
    }

    func testSleepAdhkarContainsTasbih() {
        let hasSubhanAllah = sut.sleepAdhkar.contains { $0.id == "tasbih-33" }
        let hasAlhamdulillah = sut.sleepAdhkar.contains { $0.id == "hamd-33" }
        let hasTakbir = sut.sleepAdhkar.contains { $0.id == "takbir-34" }

        XCTAssertTrue(hasSubhanAllah)
        XCTAssertTrue(hasAlhamdulillah)
        XCTAssertTrue(hasTakbir)
    }

    func testSleepAdhkarHasRequiredFields() {
        for adhkar in sut.sleepAdhkar {
            XCTAssertFalse(adhkar.id.isEmpty, "ID should not be empty")
            XCTAssertFalse(adhkar.title.isEmpty, "Title should not be empty")
            XCTAssertFalse(adhkar.arabic.isEmpty, "Arabic should not be empty")
            XCTAssertFalse(adhkar.translation.isEmpty, "Translation should not be empty")
            XCTAssertFalse(adhkar.transliteration.isEmpty, "Transliteration should not be empty")
            XCTAssertGreaterThan(adhkar.count, 0, "Count should be positive")
        }
    }

    func testTasbihCountsAreCorrect() {
        let subhanAllah = sut.sleepAdhkar.first { $0.id == "tasbih-33" }
        let alhamdulillah = sut.sleepAdhkar.first { $0.id == "hamd-33" }
        let allahuAkbar = sut.sleepAdhkar.first { $0.id == "takbir-34" }

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

    // MARK: - Toggle Adhkar Tests

    func testToggleAdhkarAddsToCompleted() {
        let adhkarId = "ayat-kursi"
        XCTAssertFalse(sut.completedAdhkar.contains(adhkarId))

        sut.toggleAdhkar(adhkarId)

        XCTAssertTrue(sut.completedAdhkar.contains(adhkarId))
    }

    func testToggleAdhkarRemovesFromCompleted() {
        let adhkarId = "ayat-kursi"
        sut.completedAdhkar.insert(adhkarId)

        sut.toggleAdhkar(adhkarId)

        XCTAssertFalse(sut.completedAdhkar.contains(adhkarId))
    }

    func testToggleAdhkarTwiceReturnsToOriginal() {
        let adhkarId = "surah-ikhlas"

        sut.toggleAdhkar(adhkarId)
        sut.toggleAdhkar(adhkarId)

        XCTAssertFalse(sut.completedAdhkar.contains(adhkarId))
    }

    func testToggleMultipleAdhkar() {
        sut.toggleAdhkar("ayat-kursi")
        sut.toggleAdhkar("surah-ikhlas")
        sut.toggleAdhkar("sleep-dua")

        XCTAssertEqual(sut.completedAdhkar.count, 3)
        XCTAssertTrue(sut.completedAdhkar.contains("ayat-kursi"))
        XCTAssertTrue(sut.completedAdhkar.contains("surah-ikhlas"))
        XCTAssertTrue(sut.completedAdhkar.contains("sleep-dua"))
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

    func testCompletionPercentageAfterOneAdhkar() {
        sut.toggleAdhkar("ayat-kursi")

        let expectedPercentage = (1.0 / Double(sut.sleepAdhkar.count)) * 100
        XCTAssertEqual(sut.completionPercentage, expectedPercentage, accuracy: 0.01)
    }

    func testCompletionPercentageAfterHalfAdhkar() {
        let halfCount = sut.sleepAdhkar.count / 2
        for i in 0..<halfCount {
            sut.toggleAdhkar(sut.sleepAdhkar[i].id)
        }

        let expectedPercentage = (Double(halfCount) / Double(sut.sleepAdhkar.count)) * 100
        XCTAssertEqual(sut.completionPercentage, expectedPercentage, accuracy: 0.01)
    }

    func testCompletionPercentageAfterAllAdhkar() {
        for adhkar in sut.sleepAdhkar {
            sut.toggleAdhkar(adhkar.id)
        }

        XCTAssertEqual(sut.completionPercentage, 100.0, accuracy: 0.01)
    }

    // MARK: - All Adhkar Completed Tests

    func testAllAdhkarCompletedInitiallyFalse() {
        XCTAssertFalse(sut.allAdhkarCompleted)
    }

    func testAllAdhkarCompletedAfterPartialCompletion() {
        sut.toggleAdhkar("ayat-kursi")
        sut.toggleAdhkar("surah-ikhlas")

        XCTAssertFalse(sut.allAdhkarCompleted)
    }

    func testAllAdhkarCompletedAfterFullCompletion() {
        for adhkar in sut.sleepAdhkar {
            sut.toggleAdhkar(adhkar.id)
        }

        XCTAssertTrue(sut.allAdhkarCompleted)
    }

    func testAllAdhkarCompletedFalseAfterUnchecking() {
        // Complete all
        for adhkar in sut.sleepAdhkar {
            sut.toggleAdhkar(adhkar.id)
        }
        XCTAssertTrue(sut.allAdhkarCompleted)

        // Uncheck one
        sut.toggleAdhkar(sut.sleepAdhkar[0].id)
        XCTAssertFalse(sut.allAdhkarCompleted)
    }

    // MARK: - Reset Progress Tests

    func testResetProgressClearsCompletedAdhkar() {
        sut.toggleAdhkar("ayat-kursi")
        sut.toggleAdhkar("surah-ikhlas")
        XCTAssertFalse(sut.completedAdhkar.isEmpty)

        sut.resetProgress()

        XCTAssertTrue(sut.completedAdhkar.isEmpty)
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
        for adhkar in sut.sleepAdhkar {
            sut.toggleAdhkar(adhkar.id)
        }
        sut.isPlayingRecitation = true
        sut.playbackProgress = 1.0

        sut.resetProgress()

        XCTAssertTrue(sut.completedAdhkar.isEmpty)
        XCTAssertFalse(sut.isPlayingRecitation)
        XCTAssertEqual(sut.playbackProgress, 0.0)
        XCTAssertFalse(sut.allAdhkarCompleted)
        XCTAssertEqual(sut.completionPercentage, 0.0)
    }
}

// MARK: - SleepAdhkar Model Tests

final class SleepAdhkarTests: XCTestCase {

    func testSleepAdhkarInitialization() {
        let adhkar = SleepAdhkar(
            id: "test-adhkar",
            title: "Test Title",
            arabic: "عربي",
            transliteration: "Transliteration",
            translation: "Translation",
            benefit: "Test benefit",
            count: 3
        )

        XCTAssertEqual(adhkar.id, "test-adhkar")
        XCTAssertEqual(adhkar.title, "Test Title")
        XCTAssertEqual(adhkar.arabic, "عربي")
        XCTAssertEqual(adhkar.transliteration, "Transliteration")
        XCTAssertEqual(adhkar.translation, "Translation")
        XCTAssertEqual(adhkar.benefit, "Test benefit")
        XCTAssertEqual(adhkar.count, 3)
    }

    func testSleepAdhkarIdentifiable() {
        let adhkar1 = SleepAdhkar(
            id: "adhkar-1",
            title: "Title",
            arabic: "عربي",
            transliteration: "Trans",
            translation: "Trans",
            benefit: "Benefit",
            count: 1
        )

        let adhkar2 = SleepAdhkar(
            id: "adhkar-2",
            title: "Title",
            arabic: "عربي",
            transliteration: "Trans",
            translation: "Trans",
            benefit: "Benefit",
            count: 1
        )

        XCTAssertNotEqual(adhkar1.id, adhkar2.id)
    }

    func testSleepAdhkarCountVariations() {
        // Single count adhkar
        let singleCount = SleepAdhkar(
            id: "single",
            title: "Single",
            arabic: "أ",
            transliteration: "A",
            translation: "A",
            benefit: "Once",
            count: 1
        )
        XCTAssertEqual(singleCount.count, 1)

        // Multiple count adhkar (like tasbih)
        let multipleCount = SleepAdhkar(
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
