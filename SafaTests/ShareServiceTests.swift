// MARK: - ShareServiceTests.swift
// PURPOSE: Unit tests for sharing functionality
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class ShareServiceTests: XCTestCase {

    var sut: ShareService!

    override func setUp() {
        super.setUp()
        sut = ShareService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Quran Verse Share Tests

    func testQuranVerseShareTextGeneration() {
        let content = ShareableContent.quranVerse(
            surah: "Al-Fatiha",
            ayah: 1,
            arabicText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            translation: "In the name of Allah, the Most Gracious, the Most Merciful"
        )

        let shareText = sut.generateShareText(for: content)

        XCTAssertTrue(shareText.contains("بِسْمِ اللَّهِ"), "Should contain Arabic text")
        XCTAssertTrue(shareText.contains("In the name of Allah"), "Should contain translation")
        XCTAssertTrue(shareText.contains("Al-Fatiha:1"), "Should contain reference")
        XCTAssertTrue(shareText.contains("Safa"), "Should contain app name")
    }

    // MARK: - Hadith Share Tests

    func testHadithShareTextGeneration() {
        let content = ShareableContent.hadith(
            collection: "Sahih Bukhari",
            narrator: "Abu Hurairah",
            text: "Actions are judged by intentions"
        )

        let shareText = sut.generateShareText(for: content)

        XCTAssertTrue(shareText.contains("Actions are judged"), "Should contain hadith text")
        XCTAssertTrue(shareText.contains("Abu Hurairah"), "Should contain narrator")
        XCTAssertTrue(shareText.contains("Sahih Bukhari"), "Should contain collection")
    }

    // MARK: - Achievement Share Tests

    func testAchievementShareTextGeneration() {
        let content = ShareableContent.achievement(
            title: "First Prayer",
            description: "Logged your first prayer"
        )

        let shareText = sut.generateShareText(for: content)

        XCTAssertTrue(shareText.contains("Achievement Unlocked"), "Should mention achievement")
        XCTAssertTrue(shareText.contains("First Prayer"), "Should contain title")
        XCTAssertTrue(shareText.contains("Logged your first prayer"), "Should contain description")
    }

    // MARK: - Progress Share Tests

    func testProgressShareTextGeneration() {
        let content = ShareableContent.dailyProgress(hasanat: 150, streak: 7)

        let shareText = sut.generateShareText(for: content)

        XCTAssertTrue(shareText.contains("150"), "Should contain hasanat count")
        XCTAssertTrue(shareText.contains("7"), "Should contain streak count")
        XCTAssertTrue(shareText.contains("Hasanat"), "Should mention Hasanat")
        XCTAssertTrue(shareText.contains("streak"), "Should mention streak")
    }

    // MARK: - Dua Share Tests

    func testDuaShareTextGeneration() {
        let content = ShareableContent.dua(
            title: "Dua Before Eating",
            arabic: "بِسْمِ اللَّهِ",
            translation: "In the name of Allah"
        )

        let shareText = sut.generateShareText(for: content)

        XCTAssertTrue(shareText.contains("Dua Before Eating"), "Should contain title")
        XCTAssertTrue(shareText.contains("بِسْمِ اللَّهِ"), "Should contain Arabic")
        XCTAssertTrue(shareText.contains("In the name of Allah"), "Should contain translation")
    }

    // MARK: - Invite Link Tests

    func testInviteLinkShareTextGeneration() {
        let content = ShareableContent.inviteLink(code: "ABC123")

        let shareText = sut.generateShareText(for: content)

        XCTAssertTrue(shareText.contains("ABC123"), "Should contain invite code")
        XCTAssertTrue(shareText.contains("family circle"), "Should mention family circle")
        XCTAssertTrue(shareText.contains("Safa"), "Should contain app name")
    }

    // MARK: - Share Card Style Tests

    func testShareCardStylesExist() {
        XCTAssertNotNil(ShareCardStyle.quran)
        XCTAssertNotNil(ShareCardStyle.hadith)
        XCTAssertNotNil(ShareCardStyle.achievement)
        XCTAssertNotNil(ShareCardStyle.progress)
        XCTAssertNotNil(ShareCardStyle.dua)
    }

    func testQuranShareCardStyleColors() {
        let style = ShareCardStyle.quran

        // Green-ish background for Quran
        // Just verify they're not nil/default
        XCTAssertNotNil(style.backgroundColor)
        XCTAssertNotNil(style.textColor)
        XCTAssertNotNil(style.accentColor)
    }
}

// MARK: - Shareable Content Tests

final class ShareableContentTests: XCTestCase {

    func testQuranVerseContent() {
        let content = ShareableContent.quranVerse(
            surah: "Al-Baqarah",
            ayah: 255,
            arabicText: "Arabic",
            translation: "Translation"
        )

        if case .quranVerse(let surah, let ayah, _, _) = content {
            XCTAssertEqual(surah, "Al-Baqarah")
            XCTAssertEqual(ayah, 255)
        } else {
            XCTFail("Should be quranVerse content")
        }
    }

    func testHadithContent() {
        let content = ShareableContent.hadith(
            collection: "Bukhari",
            narrator: "Narrator",
            text: "Text"
        )

        if case .hadith(let collection, _, _) = content {
            XCTAssertEqual(collection, "Bukhari")
        } else {
            XCTFail("Should be hadith content")
        }
    }

    func testAchievementContent() {
        let content = ShareableContent.achievement(
            title: "Test",
            description: "Description"
        )

        if case .achievement(let title, _) = content {
            XCTAssertEqual(title, "Test")
        } else {
            XCTFail("Should be achievement content")
        }
    }

    func testProgressContent() {
        let content = ShareableContent.dailyProgress(hasanat: 100, streak: 5)

        if case .dailyProgress(let hasanat, let streak) = content {
            XCTAssertEqual(hasanat, 100)
            XCTAssertEqual(streak, 5)
        } else {
            XCTFail("Should be dailyProgress content")
        }
    }
}

// MARK: - Audio Player Tests

final class AudioPlayerViewModelTests: XCTestCase {

    var sut: AudioPlayerViewModel!

    override func setUp() {
        super.setUp()
        sut = AudioPlayerViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(sut.isPlaying)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.currentTime, 0)
        XCTAssertEqual(sut.playbackRate, 1.0)
    }

    func testTogglePlayPause() {
        XCTAssertFalse(sut.isPlaying)

        sut.togglePlayPause()
        XCTAssertTrue(sut.isPlaying)

        sut.togglePlayPause()
        XCTAssertFalse(sut.isPlaying)
    }

    func testSeek() {
        sut.duration = 100

        sut.seek(to: 0.5)

        XCTAssertEqual(sut.currentTime, 50)
    }

    func testSkipForward() {
        sut.duration = 100
        sut.currentTime = 50

        sut.skipForward()

        XCTAssertEqual(sut.currentTime, 65) // +15 seconds
    }

    func testSkipBackward() {
        sut.duration = 100
        sut.currentTime = 50

        sut.skipBackward()

        XCTAssertEqual(sut.currentTime, 35) // -15 seconds
    }

    func testSkipForwardClampsToEnd() {
        sut.duration = 100
        sut.currentTime = 95

        sut.skipForward()

        XCTAssertEqual(sut.currentTime, 100)
    }

    func testSkipBackwardClampsToStart() {
        sut.duration = 100
        sut.currentTime = 5

        sut.skipBackward()

        XCTAssertEqual(sut.currentTime, 0)
    }

    func testNextAyah() {
        sut.totalAyahs = 7
        sut.currentAyah = 1

        sut.nextAyah()

        XCTAssertEqual(sut.currentAyah, 2)
    }

    func testNextAyahClampsToTotal() {
        sut.totalAyahs = 7
        sut.currentAyah = 7

        sut.nextAyah()

        XCTAssertEqual(sut.currentAyah, 7)
    }

    func testPreviousAyah() {
        sut.currentAyah = 5

        sut.previousAyah()

        XCTAssertEqual(sut.currentAyah, 4)
    }

    func testPreviousAyahClampsToFirst() {
        sut.currentAyah = 1

        sut.previousAyah()

        XCTAssertEqual(sut.currentAyah, 1)
    }

    func testCycleRepeatMode() {
        XCTAssertEqual(sut.repeatMode, .none)

        sut.cycleRepeatMode()
        XCTAssertEqual(sut.repeatMode, .one)

        sut.cycleRepeatMode()
        XCTAssertEqual(sut.repeatMode, .all)

        sut.cycleRepeatMode()
        XCTAssertEqual(sut.repeatMode, .none)
    }

    func testProgressCalculation() {
        sut.duration = 100
        sut.currentTime = 25

        XCTAssertEqual(sut.progress, 0.25)
    }

    func testAyahProgressCalculation() {
        sut.totalAyahs = 10
        sut.currentAyah = 5

        XCTAssertEqual(sut.ayahProgress, 0.5)
    }

    func testFormattedTime() {
        sut.currentTime = 125 // 2:05
        sut.duration = 300 // 5:00

        XCTAssertEqual(sut.formattedCurrentTime, "2:05")
        XCTAssertEqual(sut.formattedDuration, "5:00")
    }
}

// MARK: - Quran Reciter Tests

final class QuranReciterTests: XCTestCase {

    func testAllCasesExist() {
        XCTAssertEqual(QuranReciter.allCases.count, 6)
    }

    func testShortNames() {
        XCTAssertEqual(QuranReciter.mishary.shortName, "Alafasy")
        XCTAssertEqual(QuranReciter.sudais.shortName, "Al-Sudais")
    }

    func testReciterIds() {
        for reciter in QuranReciter.allCases {
            XCTAssertFalse(reciter.id.isEmpty)
        }
    }
}

// MARK: - Repeat Mode Tests

final class RepeatModeTests: XCTestCase {

    func testIconNames() {
        XCTAssertEqual(RepeatMode.none.iconName, "repeat")
        XCTAssertEqual(RepeatMode.one.iconName, "repeat.1")
        XCTAssertEqual(RepeatMode.all.iconName, "repeat")
    }

    func testIsActive() {
        XCTAssertFalse(RepeatMode.none.isActive)
        XCTAssertTrue(RepeatMode.one.isActive)
        XCTAssertTrue(RepeatMode.all.isActive)
    }
}
