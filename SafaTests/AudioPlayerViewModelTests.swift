// MARK: - AudioPlayerViewModelTests.swift
// PURPOSE: Unit tests for AudioPlayerViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

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

    // MARK: - Initial State Tests

    func test_initialState_isPlayingIsFalse() {
        XCTAssertFalse(sut.isPlaying)
    }

    func test_initialState_isLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func test_initialState_currentTimeIsZero() {
        XCTAssertEqual(sut.currentTime, 0)
    }

    func test_initialState_durationIsZero() {
        XCTAssertEqual(sut.duration, 0)
    }

    func test_initialState_playbackRateIsOne() {
        XCTAssertEqual(sut.playbackRate, 1.0)
    }

    func test_initialState_volumeIsOne() {
        XCTAssertEqual(sut.volume, 1.0)
    }

    func test_initialState_selectedReciterIsMishary() {
        XCTAssertEqual(sut.selectedReciter, .mishary)
    }

    func test_initialState_repeatModeIsNone() {
        XCTAssertEqual(sut.repeatMode, .none)
    }

    func test_initialState_isShuffleEnabledIsFalse() {
        XCTAssertFalse(sut.isShuffleEnabled)
    }

    func test_initialState_currentSurahIsOne() {
        XCTAssertEqual(sut.currentSurah, 1)
    }

    func test_initialState_currentAyahIsOne() {
        XCTAssertEqual(sut.currentAyah, 1)
    }

    func test_initialState_totalAyahsIsSeven() {
        XCTAssertEqual(sut.totalAyahs, 7)
    }

    func test_initialState_surahNameIsAlFatiha() {
        XCTAssertEqual(sut.surahName, "Al-Fatiha")
    }

    // MARK: - Toggle Play/Pause Tests

    func test_togglePlayPause_startsPlaying() {
        XCTAssertFalse(sut.isPlaying)
        sut.togglePlayPause()
        XCTAssertTrue(sut.isPlaying)
    }

    func test_togglePlayPause_stopsPaying() {
        sut.isPlaying = true
        sut.togglePlayPause()
        XCTAssertFalse(sut.isPlaying)
    }

    func test_togglePlayPause_togglesMultipleTimes() {
        sut.togglePlayPause()
        XCTAssertTrue(sut.isPlaying)

        sut.togglePlayPause()
        XCTAssertFalse(sut.isPlaying)

        sut.togglePlayPause()
        XCTAssertTrue(sut.isPlaying)
    }

    // MARK: - Seek Tests

    func test_seek_updatesCurrentTime() {
        sut.duration = 100
        sut.seek(to: 0.5)
        XCTAssertEqual(sut.currentTime, 50)
    }

    func test_seek_toZero() {
        sut.duration = 100
        sut.currentTime = 50
        sut.seek(to: 0)
        XCTAssertEqual(sut.currentTime, 0)
    }

    func test_seek_toEnd() {
        sut.duration = 100
        sut.seek(to: 1.0)
        XCTAssertEqual(sut.currentTime, 100)
    }

    // MARK: - Skip Tests

    func test_skipForward_adds15Seconds() {
        sut.duration = 100
        sut.currentTime = 30
        sut.skipForward()
        XCTAssertEqual(sut.currentTime, 45)
    }

    func test_skipForward_doesNotExceedDuration() {
        sut.duration = 100
        sut.currentTime = 95
        sut.skipForward()
        XCTAssertEqual(sut.currentTime, 100)
    }

    func test_skipBackward_subtracts15Seconds() {
        sut.duration = 100
        sut.currentTime = 45
        sut.skipBackward()
        XCTAssertEqual(sut.currentTime, 30)
    }

    func test_skipBackward_doesNotGoBelowZero() {
        sut.duration = 100
        sut.currentTime = 5
        sut.skipBackward()
        XCTAssertEqual(sut.currentTime, 0)
    }

    // MARK: - Ayah Navigation Tests

    func test_nextAyah_incrementsCurrentAyah() {
        sut.currentAyah = 1
        sut.totalAyahs = 7
        sut.nextAyah()
        XCTAssertEqual(sut.currentAyah, 2)
    }

    func test_nextAyah_doesNotExceedTotalAyahs() {
        sut.currentAyah = 7
        sut.totalAyahs = 7
        sut.nextAyah()
        XCTAssertEqual(sut.currentAyah, 7)
    }

    func test_previousAyah_decrementsCurrentAyah() {
        sut.currentAyah = 3
        sut.previousAyah()
        XCTAssertEqual(sut.currentAyah, 2)
    }

    func test_previousAyah_doesNotGoBelowOne() {
        sut.currentAyah = 1
        sut.previousAyah()
        XCTAssertEqual(sut.currentAyah, 1)
    }

    // MARK: - Repeat Mode Tests

    func test_cycleRepeatMode_fromNoneToOne() {
        sut.repeatMode = .none
        sut.cycleRepeatMode()
        XCTAssertEqual(sut.repeatMode, .one)
    }

    func test_cycleRepeatMode_fromOneToAll() {
        sut.repeatMode = .one
        sut.cycleRepeatMode()
        XCTAssertEqual(sut.repeatMode, .all)
    }

    func test_cycleRepeatMode_fromAllToNone() {
        sut.repeatMode = .all
        sut.cycleRepeatMode()
        XCTAssertEqual(sut.repeatMode, .none)
    }

    func test_cycleRepeatMode_fullCycle() {
        XCTAssertEqual(sut.repeatMode, .none)

        sut.cycleRepeatMode()
        XCTAssertEqual(sut.repeatMode, .one)

        sut.cycleRepeatMode()
        XCTAssertEqual(sut.repeatMode, .all)

        sut.cycleRepeatMode()
        XCTAssertEqual(sut.repeatMode, .none)
    }

    // MARK: - Progress Tests

    func test_progress_calculatesCorrectly() {
        sut.duration = 100
        sut.currentTime = 25
        XCTAssertEqual(sut.progress, 0.25, accuracy: 0.001)
    }

    func test_progress_isZeroWhenDurationIsZero() {
        sut.duration = 0
        sut.currentTime = 50
        XCTAssertEqual(sut.progress, 0)
    }

    func test_progress_atStart() {
        sut.duration = 100
        sut.currentTime = 0
        XCTAssertEqual(sut.progress, 0)
    }

    func test_progress_atEnd() {
        sut.duration = 100
        sut.currentTime = 100
        XCTAssertEqual(sut.progress, 1.0)
    }

    // MARK: - Ayah Progress Tests

    func test_ayahProgress_calculatesCorrectly() {
        sut.totalAyahs = 10
        sut.currentAyah = 5
        XCTAssertEqual(sut.ayahProgress, 0.5, accuracy: 0.001)
    }

    func test_ayahProgress_isZeroWhenTotalAyahsIsZero() {
        sut.totalAyahs = 0
        sut.currentAyah = 1
        XCTAssertEqual(sut.ayahProgress, 0)
    }

    // MARK: - Formatted Time Tests

    func test_formattedCurrentTime_zero() {
        sut.currentTime = 0
        XCTAssertEqual(sut.formattedCurrentTime, "0:00")
    }

    func test_formattedCurrentTime_oneMinute() {
        sut.currentTime = 60
        XCTAssertEqual(sut.formattedCurrentTime, "1:00")
    }

    func test_formattedCurrentTime_mixedMinutesSeconds() {
        sut.currentTime = 125 // 2:05
        XCTAssertEqual(sut.formattedCurrentTime, "2:05")
    }

    func test_formattedDuration_zero() {
        sut.duration = 0
        XCTAssertEqual(sut.formattedDuration, "0:00")
    }

    func test_formattedDuration_tenMinutes() {
        sut.duration = 600
        XCTAssertEqual(sut.formattedDuration, "10:00")
    }

    // MARK: - Playback Rates Tests

    func test_playbackRates_containsExpectedValues() {
        XCTAssertEqual(sut.playbackRates, [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
    }

    // MARK: - QuranReciter Enum Tests

    func test_quranReciter_allCases() {
        XCTAssertEqual(QuranReciter.allCases.count, 6)
    }

    func test_quranReciter_rawValues() {
        XCTAssertEqual(QuranReciter.mishary.rawValue, "Mishary Rashid Alafasy")
        XCTAssertEqual(QuranReciter.sudais.rawValue, "Abdul Rahman Al-Sudais")
        XCTAssertEqual(QuranReciter.ghamdi.rawValue, "Saad Al-Ghamdi")
        XCTAssertEqual(QuranReciter.maher.rawValue, "Maher Al-Muaiqly")
    }

    func test_quranReciter_shortNames() {
        XCTAssertEqual(QuranReciter.mishary.shortName, "Alafasy")
        XCTAssertEqual(QuranReciter.sudais.shortName, "Al-Sudais")
        XCTAssertEqual(QuranReciter.ghamdi.shortName, "Al-Ghamdi")
        XCTAssertEqual(QuranReciter.maher.shortName, "Al-Muaiqly")
    }

    func test_quranReciter_identifiable() {
        XCTAssertEqual(QuranReciter.mishary.id, QuranReciter.mishary.rawValue)
    }

    // MARK: - RepeatMode Enum Tests

    func test_repeatMode_iconNames() {
        XCTAssertEqual(RepeatMode.none.iconName, "repeat")
        XCTAssertEqual(RepeatMode.one.iconName, "repeat.1")
        XCTAssertEqual(RepeatMode.all.iconName, "repeat")
    }

    func test_repeatMode_isActive() {
        XCTAssertFalse(RepeatMode.none.isActive)
        XCTAssertTrue(RepeatMode.one.isActive)
        XCTAssertTrue(RepeatMode.all.isActive)
    }

    // MARK: - State Mutation Tests

    func test_selectedReciter_canBeChanged() {
        sut.selectedReciter = .sudais
        XCTAssertEqual(sut.selectedReciter, .sudais)
    }

    func test_playbackRate_canBeChanged() {
        sut.playbackRate = 1.5
        XCTAssertEqual(sut.playbackRate, 1.5)
    }

    func test_volume_canBeChanged() {
        sut.volume = 0.5
        XCTAssertEqual(sut.volume, 0.5)
    }

    func test_isShuffleEnabled_canBeToggled() {
        sut.isShuffleEnabled = true
        XCTAssertTrue(sut.isShuffleEnabled)
    }
}
