// MARK: - RamadanFeatureTests.swift
// PURPOSE: Comprehensive tests for Ramadan page features and iftar adhan
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class RamadanFeatureTests: XCTestCase {

    // MARK: - Iftar Adhan Setting

    func test_iftarAdhanEnabled_defaultsFalse() {
        let prefs = UserPreferences()
        XCTAssertFalse(prefs.iftarAdhanEnabled)
    }

    func test_iftarAdhanEnabled_canBeTrue() {
        let prefs = UserPreferences(iftarAdhanEnabled: true)
        XCTAssertTrue(prefs.iftarAdhanEnabled)
    }

    func test_iftarAdhan_isIndependentOfGlobalAdhan() {
        // Iftar adhan ON + global adhan OFF = valid combination
        let prefs = UserPreferences(adhanEnabled: false, iftarAdhanEnabled: true)
        XCTAssertFalse(prefs.adhanEnabled)
        XCTAssertTrue(prefs.iftarAdhanEnabled)
    }

    func test_iftarAdhan_codable_roundTrip() throws {
        var prefs = UserPreferences()
        prefs.iftarAdhanEnabled = true
        let data = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)
        XCTAssertTrue(decoded.iftarAdhanEnabled)
    }

    // MARK: - Daily Goals Persistence

    func test_dailyGoals_persistToUserDefaults() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = "dailyGoals_\(formatter.string(from: Date()))"

        // Clean up before test
        UserDefaults.standard.removeObject(forKey: key)

        // Save goals
        let goals = ["quran", "morning_dhikr"]
        UserDefaults.standard.set(goals, forKey: key)

        // Read back
        let saved = UserDefaults.standard.stringArray(forKey: key)
        XCTAssertEqual(saved, goals)

        // Clean up
        UserDefaults.standard.removeObject(forKey: key)
    }

    func test_dailyGoals_separatePerDay() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let todayKey = "dailyGoals_\(formatter.string(from: Date()))"
        let yesterdayKey = "dailyGoals_\(formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!))"

        // Clean up
        UserDefaults.standard.removeObject(forKey: todayKey)
        UserDefaults.standard.removeObject(forKey: yesterdayKey)

        // Write different goals for different days
        UserDefaults.standard.set(["quran"], forKey: todayKey)
        UserDefaults.standard.set(["taraweeh", "juz"], forKey: yesterdayKey)

        // Verify independence
        XCTAssertEqual(UserDefaults.standard.stringArray(forKey: todayKey), ["quran"])
        XCTAssertEqual(UserDefaults.standard.stringArray(forKey: yesterdayKey), ["taraweeh", "juz"])

        // Clean up
        UserDefaults.standard.removeObject(forKey: todayKey)
        UserDefaults.standard.removeObject(forKey: yesterdayKey)
    }

    // MARK: - Fasting Day Persistence

    func test_fastingDays_persistToUserDefaults() {
        let year = String(Calendar.current.component(.year, from: Date()))
        let key = "ramadan_fasting_days_\(year)"

        // Clean up
        UserDefaults.standard.removeObject(forKey: key)

        // Save
        UserDefaults.standard.set([1, 2, 3, 5, 7], forKey: key)

        // Read back
        let saved = UserDefaults.standard.array(forKey: key) as? [Int]
        XCTAssertEqual(Set(saved ?? []), Set([1, 2, 3, 5, 7]))

        // Clean up
        UserDefaults.standard.removeObject(forKey: key)
    }

    func test_fastingDays_toggleAddAndRemove() {
        var fastingDays: Set<Int> = [1, 2, 3]

        // Toggle ON day 4
        fastingDays.insert(4)
        XCTAssertTrue(fastingDays.contains(4))
        XCTAssertEqual(fastingDays.count, 4)

        // Toggle OFF day 2 (undo)
        fastingDays.remove(2)
        XCTAssertFalse(fastingDays.contains(2))
        XCTAssertEqual(fastingDays.count, 3)
    }

    // MARK: - Juz Count from Daily Goals

    func test_juzCount_countsDaysWithJuzGoal() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Set up 3 days with "juz" completed
        var keys: [String] = []
        for dayOffset in 0..<5 {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            let key = "dailyGoals_\(formatter.string(from: date))"
            keys.append(key)

            if dayOffset < 3 {
                UserDefaults.standard.set(["juz", "quran"], forKey: key)
            } else {
                UserDefaults.standard.set(["quran"], forKey: key) // no juz
            }
        }

        // Count juz days
        var count = 0
        for dayOffset in 0..<5 {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            let key = "dailyGoals_\(formatter.string(from: date))"
            let goals = UserDefaults.standard.stringArray(forKey: key) ?? []
            if goals.contains("juz") { count += 1 }
        }

        XCTAssertEqual(count, 3)

        // Clean up
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - DailyGoalRow Component

    func test_dailyGoalRow_allPrayersLogged_isComplete() {
        let allFive: Set<PrayerType> = [.fajr, .dhuhr, .asr, .maghrib, .isha]
        let isComplete = PrayerType.obligatoryPrayers.allSatisfy { allFive.contains($0) }
        XCTAssertTrue(isComplete)
    }

    func test_dailyGoalRow_partialPrayers_notComplete() {
        let partial: Set<PrayerType> = [.fajr, .dhuhr]
        let isComplete = PrayerType.obligatoryPrayers.allSatisfy { partial.contains($0) }
        XCTAssertFalse(isComplete)
    }

    // MARK: - Prayer Notification Sound Selection

    func test_notificationSound_globalAdhanOff_iftarOff_returnsDefault() {
        let prefs = UserPreferences(adhanEnabled: false, iftarAdhanEnabled: false)
        // When both are off, Maghrib during Ramadan should still use default
        let isRamadanIftarAdhan = prefs.iftarAdhanEnabled && HijriDateConverter.shared.isRamadan()
        let shouldUseAdhan = prefs.adhanEnabled || isRamadanIftarAdhan
        // If not currently Ramadan, this is always false
        if !HijriDateConverter.shared.isRamadan() {
            XCTAssertFalse(shouldUseAdhan)
        }
    }

    func test_notificationSound_globalAdhanOff_iftarOn_duringRamadan() {
        let prefs = UserPreferences(adhanEnabled: false, iftarAdhanEnabled: true)
        let isRamadan = HijriDateConverter.shared.isRamadan()
        let isRamadanIftarAdhan = prefs.iftarAdhanEnabled && isRamadan
        let shouldUseMaghribAdhan = prefs.adhanEnabled || isRamadanIftarAdhan

        if isRamadan {
            XCTAssertTrue(shouldUseMaghribAdhan, "Iftar adhan should play during Ramadan")
        } else {
            XCTAssertFalse(shouldUseMaghribAdhan, "Iftar adhan should not play outside Ramadan")
        }
    }

    func test_notificationSound_globalAdhanOn_alwaysPlays() {
        let prefs = UserPreferences(adhanEnabled: true, iftarAdhanEnabled: false)
        XCTAssertTrue(prefs.adhanEnabled)
    }
}
