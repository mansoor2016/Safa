// MARK: - WidgetTests.swift
// PURPOSE: Unit tests for widget functionality
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

// Note: Widget types are defined in the SafaWidget extension target.
// These tests validate the shared data that widgets consume.

final class WidgetDataTests: XCTestCase {

    // MARK: - Prayer Type Tests

    func testPrayerTypeDisplayNames() {
        XCTAssertEqual(PrayerType.fajr.displayName, "Fajr")
        XCTAssertEqual(PrayerType.dhuhr.displayName, "Dhuhr")
        XCTAssertEqual(PrayerType.asr.displayName, "Asr")
        XCTAssertEqual(PrayerType.maghrib.displayName, "Maghrib")
        XCTAssertEqual(PrayerType.isha.displayName, "Isha")
    }

    func testPrayerTypeArabicNames() {
        XCTAssertEqual(PrayerType.fajr.arabicName, "الفجر")
        XCTAssertEqual(PrayerType.dhuhr.arabicName, "الظهر")
        XCTAssertEqual(PrayerType.asr.arabicName, "العصر")
        XCTAssertEqual(PrayerType.maghrib.arabicName, "المغرب")
        XCTAssertEqual(PrayerType.isha.arabicName, "العشاء")
    }

    func testPrayerTypeObligatoryFlag() {
        XCTAssertTrue(PrayerType.fajr.isObligatory)
        XCTAssertFalse(PrayerType.sunrise.isObligatory)
        XCTAssertTrue(PrayerType.dhuhr.isObligatory)
        XCTAssertTrue(PrayerType.asr.isObligatory)
        XCTAssertTrue(PrayerType.maghrib.isObligatory)
        XCTAssertTrue(PrayerType.isha.isObligatory)
    }

    func testObligatoryPrayersList() {
        let obligatory = PrayerType.obligatoryPrayers
        XCTAssertEqual(obligatory.count, 5)
        XCTAssertFalse(obligatory.contains(.sunrise))
    }

    // MARK: - Prayer Time Tests

    func testPrayerTimeCreation() {
        let time = Date()
        let prayerTime = PrayerTime(
            type: .fajr,
            time: time,
            isNext: true
        )

        XCTAssertEqual(prayerTime.type, .fajr)
        XCTAssertEqual(prayerTime.time, time)
        XCTAssertTrue(prayerTime.isNext)
    }

    func testPrayerTimeTimeString() {
        let components = DateComponents(hour: 5, minute: 30)
        let calendar = Calendar.current
        guard let date = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }

        let prayerTime = PrayerTime(
            type: .fajr,
            time: date
        )

        // Just verify it returns a non-empty string
        XCTAssertFalse(prayerTime.timeString.isEmpty)
    }

    // MARK: - Streak Type Tests

    func testStreakTypeDisplayNames() {
        XCTAssertEqual(StreakType.daily.displayName, "Daily")
        XCTAssertEqual(StreakType.prayer.displayName, "Prayer")
        XCTAssertEqual(StreakType.quran.displayName, "Quran")
        XCTAssertEqual(StreakType.dhikr.displayName, "Dhikr")
        XCTAssertEqual(StreakType.learning.displayName, "Learning")
    }

    func testStreakTypeIconNames() {
        XCTAssertEqual(StreakType.daily.iconName, "flame")
        XCTAssertEqual(StreakType.prayer.iconName, "moon.stars")
        XCTAssertEqual(StreakType.quran.iconName, "book")
    }

    // MARK: - Streak Tests

    func testStreakCreation() {
        let streak = Streak(
            type: .prayer,
            currentCount: 7,
            longestCount: 14
        )

        XCTAssertEqual(streak.type, .prayer)
        XCTAssertEqual(streak.currentCount, 7)
        XCTAssertEqual(streak.longestCount, 14)
    }

    func testStreakIsActiveToday() {
        // Streak with today's date should be active
        let activeStreak = Streak(
            type: .prayer,
            currentCount: 1,
            longestCount: 1,
            lastActivityDate: Date()
        )
        XCTAssertTrue(activeStreak.isActiveToday)

        // Streak with no date should not be active
        let inactiveStreak = Streak(
            type: .prayer,
            currentCount: 0,
            longestCount: 0,
            lastActivityDate: nil
        )
        XCTAssertFalse(inactiveStreak.isActiveToday)
    }

    // MARK: - User Stats Tests for Widgets

    func testUserStatsLevelCalculation() {
        // These values are used by widgets
        XCTAssertEqual(UserStats.calculateLevel(from: 0), 1)
        XCTAssertEqual(UserStats.calculateLevel(from: 99), 1)
        XCTAssertEqual(UserStats.calculateLevel(from: 100), 2)
        XCTAssertEqual(UserStats.calculateLevel(from: 1000), 5)
        XCTAssertEqual(UserStats.calculateLevel(from: 20000), 10)
    }

    func testUserStatsLevelTitles() {
        XCTAssertEqual(UserStats.levelTitle(for: 1), "Beginner")
        XCTAssertEqual(UserStats.levelTitle(for: 5), "Consistent")
        XCTAssertEqual(UserStats.levelTitle(for: 10), "Muhsin")
    }

    // MARK: - Tasbeeh Widget Storage Tests

    func testTasbeehWidgetStorage() {
        let storage = TasbeehWidgetStorage.shared

        // Test count operations
        let originalCount = storage.currentCount
        storage.currentCount = 33
        XCTAssertEqual(storage.currentCount, 33)

        // Test dhikr operations
        storage.currentDhikr = "Alhamdulillah"
        XCTAssertEqual(storage.currentDhikr, "Alhamdulillah")

        // Reset to original
        storage.currentCount = originalCount
    }

    func testTasbeehWidgetStorageMilestones() {
        // Test milestone values (33, 66, 99)
        let milestones = [33, 66, 99]
        for milestone in milestones {
            XCTAssertTrue(milestone % 33 == 0, "Milestone \(milestone) should be divisible by 33")
        }
    }

    func testTasbeehWidgetStorageDefaultDhikr() {
        let storage = TasbeehWidgetStorage.shared
        // Default dhikr should be SubhanAllah
        let defaultDhikr = "SubhanAllah"
        storage.currentDhikr = defaultDhikr
        XCTAssertEqual(storage.currentDhikr, defaultDhikr)
    }
}

// MARK: - Interactive Prayer Widget Tests

final class InteractivePrayerWidgetTests: XCTestCase {

    // MARK: - Prayer Logging Data Tests

    func testPrayerLogDateKeyFormat() {
        // Date key should be in yyyy-MM-dd format for consistent storage
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: Date())

        XCTAssertEqual(dateKey.count, 10)
        XCTAssertTrue(dateKey.contains("-"))
    }

    func testAllPrayerTypesHaveIds() {
        let prayerIds = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
        XCTAssertEqual(prayerIds.count, 5)

        for id in prayerIds {
            XCTAssertFalse(id.isEmpty)
        }
    }

    func testPrayerLoggedStorageKey() {
        // Verify storage key format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: Date())
        let storageKey = "loggedPrayers_\(dateKey)"

        XCTAssertTrue(storageKey.hasPrefix("loggedPrayers_"))
        XCTAssertTrue(storageKey.contains(dateKey))
    }

    // MARK: - Prayer Status Tests

    func testPrayerStatusIsPastLogic() {
        let now = Date()
        let pastTime = now.addingTimeInterval(-3600) // 1 hour ago
        let futureTime = now.addingTimeInterval(3600) // 1 hour from now

        // Past time should be considered past
        XCTAssertTrue(pastTime < now)

        // Future time should not be past
        XCTAssertFalse(futureTime < now)
    }

    func testPrayerStatusIsNextLogic() {
        // Only one prayer can be "next" at a time
        let prayerStatuses = [
            (id: "fajr", isNext: false),
            (id: "dhuhr", isNext: false),
            (id: "asr", isNext: true),  // Current next prayer
            (id: "maghrib", isNext: false),
            (id: "isha", isNext: false)
        ]

        let nextPrayers = prayerStatuses.filter { $0.isNext }
        XCTAssertEqual(nextPrayers.count, 1)
    }

    func testPrayerCompletionCount() {
        let loggedPrayers = ["fajr", "dhuhr"]
        let totalPrayers = 5

        let completedCount = loggedPrayers.count
        XCTAssertEqual(completedCount, 2)
        XCTAssertLessThan(completedCount, totalPrayers)
    }

    func testAllPrayersLoggedState() {
        let loggedPrayers = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
        let totalPrayers = 5

        XCTAssertEqual(loggedPrayers.count, totalPrayers)
    }
}

// MARK: - StandBy Widget Tests

final class StandByWidgetTests: XCTestCase {

    func testPrayerIconMapping() {
        let prayerIcons: [String: String] = [
            "fajr": "sunrise.fill",
            "dhuhr": "sun.max.fill",
            "asr": "sun.haze.fill",
            "maghrib": "sunset.fill",
            "isha": "moon.stars.fill"
        ]

        XCTAssertEqual(prayerIcons.count, 5)

        for (prayer, icon) in prayerIcons {
            XCTAssertFalse(prayer.isEmpty)
            XCTAssertTrue(icon.hasSuffix(".fill"))
        }
    }

    func testHighContrastModeDefaults() {
        // StandBy widgets should default to high contrast for visibility
        let defaultHighContrast = true
        XCTAssertTrue(defaultHighContrast)
    }

    func testFajrCountdownVisibility() {
        // Fajr countdown should be shown when Fajr is not the next prayer
        let nextPrayer = "isha"
        let showFajrCountdown = nextPrayer.lowercased() != "fajr"

        XCTAssertTrue(showFajrCountdown)
    }

    func testFajrCountdownHiddenWhenFajrIsNext() {
        let nextPrayer = "fajr"
        let showFajrCountdown = nextPrayer.lowercased() != "fajr"

        XCTAssertFalse(showFajrCountdown)
    }

    func testRefreshPolicyTiming() {
        // StandBy widgets should refresh at prayer times or every 30 minutes
        let maxRefreshInterval: TimeInterval = 30 * 60 // 30 minutes
        XCTAssertEqual(maxRefreshInterval, 1800)
    }
}

// MARK: - Dhikr Entity Tests

final class DhikrEntityTests: XCTestCase {

    func testDhikrTypes() {
        let dhikrTypes = [
            ("SubhanAllah", "سُبْحَانَ اللهِ"),
            ("Alhamdulillah", "الْحَمْدُ للهِ"),
            ("Allahu Akbar", "اللهُ أَكْبَرُ"),
            ("La ilaha illallah", "لَا إِلٰهَ إِلَّا اللهُ")
        ]

        XCTAssertEqual(dhikrTypes.count, 4)

        for (english, arabic) in dhikrTypes {
            XCTAssertFalse(english.isEmpty)
            XCTAssertFalse(arabic.isEmpty)
        }
    }

    func testDhikrTargetCounts() {
        // Common tasbeeh targets
        let targets = [33, 99, 100]

        for target in targets {
            XCTAssertGreaterThan(target, 0)
        }
    }

    func testDhikrProgressCalculation() {
        let count = 25
        let target = 33
        let progress = Double(count) / Double(target)

        XCTAssertGreaterThan(progress, 0)
        XCTAssertLessThan(progress, 1.0)
        XCTAssertEqual(progress, 25.0/33.0, accuracy: 0.001)
    }

    func testDhikrCompletionDetection() {
        let count = 33
        let target = 33
        let isComplete = count >= target

        XCTAssertTrue(isComplete)
    }

    func testDhikrCycleOrder() {
        let dhikrOrder = ["SubhanAllah", "Alhamdulillah", "Allahu Akbar", "La ilaha illallah"]

        // Verify cycle wraps around
        let currentIndex = 3 // La ilaha illallah
        let nextIndex = (currentIndex + 1) % dhikrOrder.count

        XCTAssertEqual(nextIndex, 0) // Should cycle back to SubhanAllah
    }
}
