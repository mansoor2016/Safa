// MARK: - AccessibilityTests.swift
// PURPOSE: Verify accessibility label-building logic for VoiceOver correctness
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

// MARK: - Ayah Label Tests

final class AyahAccessibilityLabelTests: XCTestCase {

    func test_ayahLabel_withTranslation_includesSurahAyahAndTranslation() {
        let label = formatAyahAccessibilityLabel(
            surahName: "Al-Fatiha",
            ayahNumber: 1,
            translation: "In the name of Allah"
        )
        XCTAssertEqual(label, "Surah Al-Fatiha, Ayah 1. In the name of Allah")
    }

    func test_ayahLabel_withoutTranslation_omitsTranslation() {
        let label = formatAyahAccessibilityLabel(
            surahName: "Al-Baqarah",
            ayahNumber: 255,
            translation: nil
        )
        XCTAssertEqual(label, "Surah Al-Baqarah, Ayah 255")
    }

    func test_ayahLabel_withEmptyTranslation_omitsTranslation() {
        let label = formatAyahAccessibilityLabel(
            surahName: "Al-Ikhlas",
            ayahNumber: 1,
            translation: ""
        )
        XCTAssertEqual(label, "Surah Al-Ikhlas, Ayah 1")
    }

    func test_ayahLabel_highAyahNumber_correctlyFormatted() {
        let label = formatAyahAccessibilityLabel(
            surahName: "Al-Baqarah",
            ayahNumber: 286,
            translation: "Allah does not burden a soul beyond that it can bear"
        )
        XCTAssertTrue(label.contains("Ayah 286"))
        XCTAssertTrue(label.contains("Al-Baqarah"))
        XCTAssertTrue(label.contains("Allah does not burden"))
    }
}

// MARK: - Prayer Dot Label Tests

final class PrayerDotAccessibilityLabelTests: XCTestCase {

    func test_prayerDot_completed_showsCompleted() {
        let label = formatPrayerDotAccessibilityLabel(
            prayerName: "Fajr",
            isLogged: true,
            isNext: false,
            isPast: true
        )
        XCTAssertEqual(label, "Fajr, completed")
    }

    func test_prayerDot_next_showsNext() {
        let label = formatPrayerDotAccessibilityLabel(
            prayerName: "Asr",
            isLogged: false,
            isNext: true,
            isPast: false
        )
        XCTAssertEqual(label, "Asr, next")
    }

    func test_prayerDot_missed_showsMissed() {
        let label = formatPrayerDotAccessibilityLabel(
            prayerName: "Dhuhr",
            isLogged: false,
            isNext: false,
            isPast: true
        )
        XCTAssertEqual(label, "Dhuhr, missed")
    }

    func test_prayerDot_upcoming_showsUpcoming() {
        let label = formatPrayerDotAccessibilityLabel(
            prayerName: "Isha",
            isLogged: false,
            isNext: false,
            isPast: false
        )
        XCTAssertEqual(label, "Isha, upcoming")
    }

    func test_prayerDot_completedTakesPrecedenceOverNext() {
        // If somehow both isLogged and isNext are true, completed wins
        let label = formatPrayerDotAccessibilityLabel(
            prayerName: "Maghrib",
            isLogged: true,
            isNext: true,
            isPast: false
        )
        XCTAssertEqual(label, "Maghrib, completed")
    }
}

// MARK: - Dhikr Label Tests

final class DhikrAccessibilityLabelTests: XCTestCase {

    func test_dhikrLabel_notCompleted_showsNameAndCount() {
        let label = formatDhikrAccessibilityLabel(
            name: "SubhanAllah",
            count: 33,
            isCompleted: false
        )
        XCTAssertEqual(label, "SubhanAllah, 33 times")
    }

    func test_dhikrLabel_completed_showsCompletedSuffix() {
        let label = formatDhikrAccessibilityLabel(
            name: "Allahu Akbar",
            count: 34,
            isCompleted: true
        )
        XCTAssertEqual(label, "Allahu Akbar, 34 times, completed")
    }

    func test_dhikrLabel_singleRepetition() {
        let label = formatDhikrAccessibilityLabel(
            name: "Ayatul Kursi",
            count: 1,
            isCompleted: false
        )
        XCTAssertEqual(label, "Ayatul Kursi, 1 times")
    }
}

// MARK: - Goal Label Tests

final class GoalAccessibilityLabelTests: XCTestCase {

    func test_goalLabel_completed_showsCompleted() {
        let label = formatGoalAccessibilityLabel(title: "5 Daily Prayers", isCompleted: true)
        XCTAssertEqual(label, "5 Daily Prayers, completed")
    }

    func test_goalLabel_notCompleted_showsNotCompleted() {
        let label = formatGoalAccessibilityLabel(title: "Read Quran", isCompleted: false)
        XCTAssertEqual(label, "Read Quran, not completed")
    }

    func test_goalLabel_ramadanGoal_correctFormat() {
        let label = formatGoalAccessibilityLabel(title: "Taraweeh", isCompleted: true)
        XCTAssertTrue(label.contains("Taraweeh"))
        XCTAssertTrue(label.contains("completed"))
    }
}

// MARK: - Next Prayer Label Tests (existing helper)

final class NextPrayerAccessibilityLabelExtendedTests: XCTestCase {

    func test_nextPrayerLabel_bothHoursAndMinutes() {
        let label = formatNextPrayerAccessibilityLabel(prayerName: "Maghrib", hours: 2, minutes: 30)
        XCTAssertEqual(label, "Next prayer: Maghrib in 2 hours 30 minutes")
    }

    func test_nextPrayerLabel_hoursOnly() {
        let label = formatNextPrayerAccessibilityLabel(prayerName: "Isha", hours: 3, minutes: 0)
        XCTAssertEqual(label, "Next prayer: Isha in 3 hours")
    }

    func test_nextPrayerLabel_minutesOnly() {
        let label = formatNextPrayerAccessibilityLabel(prayerName: "Fajr", hours: 0, minutes: 15)
        XCTAssertEqual(label, "Next prayer: Fajr in 15 minutes")
    }

    func test_nextPrayerLabel_now() {
        let label = formatNextPrayerAccessibilityLabel(prayerName: "Dhuhr", hours: 0, minutes: 0)
        XCTAssertEqual(label, "Next prayer: Dhuhr now")
    }

    func test_nextPrayerLabel_singularHour() {
        let label = formatNextPrayerAccessibilityLabel(prayerName: "Asr", hours: 1, minutes: 0)
        XCTAssertEqual(label, "Next prayer: Asr in 1 hour")
    }

    func test_nextPrayerLabel_singularMinute() {
        let label = formatNextPrayerAccessibilityLabel(prayerName: "Maghrib", hours: 0, minutes: 1)
        XCTAssertEqual(label, "Next prayer: Maghrib in 1 minute")
    }
}
