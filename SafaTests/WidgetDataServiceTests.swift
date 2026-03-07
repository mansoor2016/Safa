// MARK: - WidgetDataServiceTests.swift
// PURPOSE: Unit tests for WidgetDataService App Group data sharing
// DEPENDENCIES: XCTest, Safa

import XCTest
import SafaShared
@testable import Safa

final class WidgetDataServiceTests: XCTestCase {

    private var sut: WidgetDataService!
    private let testSuiteName = "group.com.safa.app.test.\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        sut = WidgetDataService(suiteName: testSuiteName)
    }

    override func tearDown() {
        // Clean up test UserDefaults
        if let defaults = UserDefaults(suiteName: testSuiteName) {
            defaults.removePersistentDomain(forName: testSuiteName)
        }
        sut = nil
        super.tearDown()
    }

    // MARK: - Write Prayer Times Tests

    func test_writePrayerTimes_storesAllFivePrayers() {
        let prayers = makeSamplePrayers()
        sut.writePrayerTimes(prayers)

        let stored = sut.readPrayerTimes()
        XCTAssertEqual(stored.count, 5)
        XCTAssertNotNil(stored["Fajr"])
        XCTAssertNotNil(stored["Dhuhr"])
        XCTAssertNotNil(stored["Asr"])
        XCTAssertNotNil(stored["Maghrib"])
        XCTAssertNotNil(stored["Isha"])
    }

    func test_writePrayerTimes_storesCorrectTimes() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let fajrTime = calendar.date(bySettingHour: 5, minute: 30, second: 0, of: today)!

        let prayers = [
            PrayerTime(type: .fajr, time: fajrTime),
            PrayerTime(type: .dhuhr, time: calendar.date(bySettingHour: 12, minute: 15, second: 0, of: today)!),
            PrayerTime(type: .asr, time: calendar.date(bySettingHour: 15, minute: 45, second: 0, of: today)!),
            PrayerTime(type: .maghrib, time: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .isha, time: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!)
        ]

        sut.writePrayerTimes(prayers)

        let stored = sut.readPrayerTimes()
        XCTAssertEqual(stored["Fajr"], fajrTime)
    }

    func test_writePrayerTimes_includesSunrise() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let prayers = [
            PrayerTime(type: .fajr, time: calendar.date(bySettingHour: 5, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .sunrise, time: calendar.date(bySettingHour: 6, minute: 45, second: 0, of: today)!),
            PrayerTime(type: .dhuhr, time: calendar.date(bySettingHour: 12, minute: 15, second: 0, of: today)!),
            PrayerTime(type: .asr, time: calendar.date(bySettingHour: 15, minute: 45, second: 0, of: today)!),
            PrayerTime(type: .maghrib, time: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .isha, time: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!)
        ]

        sut.writePrayerTimes(prayers)

        // readPrayerTimes only returns obligatory prayers (no sunrise)
        let stored = sut.readPrayerTimes()
        XCTAssertEqual(stored.count, 5)
    }

    func test_writePrayerTimes_updatesLastUpdated() {
        let before = Date()
        sut.writePrayerTimes(makeSamplePrayers())
        let after = Date()

        let lastUpdated = sut.lastUpdated()
        XCTAssertNotNil(lastUpdated)
        XCTAssertGreaterThanOrEqual(lastUpdated!, before)
        XCTAssertLessThanOrEqual(lastUpdated!, after)
    }

    // MARK: - Next Prayer Tests

    func test_writePrayerTimes_setsNextPrayer() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Set all times in the future
        let futurePrayers = [
            PrayerTime(type: .fajr, time: Date().addingTimeInterval(3600)),
            PrayerTime(type: .dhuhr, time: Date().addingTimeInterval(7200)),
            PrayerTime(type: .asr, time: Date().addingTimeInterval(10800)),
            PrayerTime(type: .maghrib, time: Date().addingTimeInterval(14400)),
            PrayerTime(type: .isha, time: Date().addingTimeInterval(18000))
        ]

        sut.writePrayerTimes(futurePrayers)

        let defaults = UserDefaults(suiteName: testSuiteName)
        let nextName = defaults?.string(forKey: "nextPrayerName")
        let nextId = defaults?.string(forKey: "nextPrayerId")
        let nextTime = defaults?.object(forKey: "nextPrayerTime") as? Date

        // Use stable ID (locale-independent) rather than localized display name
        XCTAssertEqual(nextId, "fajr")
        XCTAssertNotNil(nextName)
        XCTAssertNotNil(nextTime)
    }

    // MARK: - Hijri Date Tests

    func test_writeHijriDate_storesValue() {
        sut.writeHijriDate("15 Rajab 1447")

        let defaults = UserDefaults(suiteName: testSuiteName)
        let stored = defaults?.string(forKey: "hijriDate")
        XCTAssertEqual(stored, "15 Rajab 1447")
    }

    // MARK: - Logged Prayers Tests

    func test_writeLoggedPrayers_storesValues() {
        let logged: Set<PrayerType> = [.fajr, .dhuhr]
        sut.writeLoggedPrayers(logged, for: Date())

        let stored = sut.readLoggedPrayers(for: Date())
        XCTAssertEqual(stored.count, 2)
        XCTAssertTrue(stored.contains("fajr"))
        XCTAssertTrue(stored.contains("dhuhr"))
    }

    func test_writeLoggedPrayers_emptySetClearsExisting() {
        // First write some logged prayers
        sut.writeLoggedPrayers([.fajr, .dhuhr], for: Date())
        XCTAssertEqual(sut.readLoggedPrayers(for: Date()).count, 2)

        // Writing empty set should clear existing (overwrite semantics — enables unlog).
        // Widget-only logs are safe: reconcileWidgetLoggedPrayers() merges them into
        // loggedPrayers before writeLoggedPrayers is called.
        sut.writeLoggedPrayers([], for: Date())
        XCTAssertEqual(sut.readLoggedPrayers(for: Date()).count, 0,
                       "Overwrite semantics: empty write should clear widget key for unlog support")
    }

    func test_writeLoggedPrayers_separatesByDate() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        sut.writeLoggedPrayers([.fajr], for: today)
        sut.writeLoggedPrayers([.isha], for: yesterday)

        let todayLogs = sut.readLoggedPrayers(for: today)
        let yesterdayLogs = sut.readLoggedPrayers(for: yesterday)

        XCTAssertTrue(todayLogs.contains("fajr"))
        XCTAssertFalse(todayLogs.contains("isha"))
        XCTAssertTrue(yesterdayLogs.contains("isha"))
        XCTAssertFalse(yesterdayLogs.contains("fajr"))
    }

    func test_readLoggedPrayers_returnsEmptyForNoData() {
        let stored = sut.readLoggedPrayers(for: Date())
        XCTAssertTrue(stored.isEmpty)
    }

    // MARK: - Read Prayer Times Tests

    func test_readPrayerTimes_returnsEmptyWhenNoData() {
        let stored = sut.readPrayerTimes()
        XCTAssertTrue(stored.isEmpty)
    }

    func test_lastUpdated_returnsNilWhenNoData() {
        XCTAssertNil(sut.lastUpdated())
    }

    // MARK: - Overwrite Tests

    func test_writePrayerTimes_overwritesPreviousValues() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Write first set
        let firstPrayers = [
            PrayerTime(type: .fajr, time: calendar.date(bySettingHour: 5, minute: 0, second: 0, of: today)!),
            PrayerTime(type: .dhuhr, time: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!),
            PrayerTime(type: .asr, time: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today)!),
            PrayerTime(type: .maghrib, time: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!),
            PrayerTime(type: .isha, time: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!)
        ]
        sut.writePrayerTimes(firstPrayers)

        // Write second set with different times
        let newFajrTime = calendar.date(bySettingHour: 4, minute: 30, second: 0, of: today)!
        let secondPrayers = [
            PrayerTime(type: .fajr, time: newFajrTime),
            PrayerTime(type: .dhuhr, time: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .asr, time: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: today)!),
            PrayerTime(type: .maghrib, time: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today)!),
            PrayerTime(type: .isha, time: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: today)!)
        ]
        sut.writePrayerTimes(secondPrayers)

        let stored = sut.readPrayerTimes()
        XCTAssertEqual(stored["Fajr"], newFajrTime)
    }

    // MARK: - Streak Data Tests

    func test_writeStreakData_storesValues() {
        sut.writeStreakData(currentCount: 7, longestCount: 14, isActiveToday: true)

        let data = sut.readStreakData()
        XCTAssertEqual(data.currentCount, 7)
        XCTAssertEqual(data.longestCount, 14)
        XCTAssertTrue(data.isActiveToday)
    }

    func test_writeStreakData_zeroValues() {
        sut.writeStreakData(currentCount: 0, longestCount: 0, isActiveToday: false)

        let data = sut.readStreakData()
        XCTAssertEqual(data.currentCount, 0)
        XCTAssertEqual(data.longestCount, 0)
        XCTAssertFalse(data.isActiveToday)
    }

    func test_writeStreakData_overwrites() {
        sut.writeStreakData(currentCount: 5, longestCount: 10, isActiveToday: true)
        sut.writeStreakData(currentCount: 6, longestCount: 10, isActiveToday: false)

        let data = sut.readStreakData()
        XCTAssertEqual(data.currentCount, 6)
        XCTAssertFalse(data.isActiveToday)
    }

    func test_readStreakData_defaultsToZero() {
        let data = sut.readStreakData()
        XCTAssertEqual(data.currentCount, 0)
        XCTAssertEqual(data.longestCount, 0)
        XCTAssertFalse(data.isActiveToday)
    }

    // MARK: - Next Prayer ID Tests

    func test_writePrayerTimes_writesNextPrayerId() {
        let futurePrayers = [
            PrayerTime(type: .fajr, time: Date().addingTimeInterval(3600)),
            PrayerTime(type: .dhuhr, time: Date().addingTimeInterval(7200)),
            PrayerTime(type: .asr, time: Date().addingTimeInterval(10800)),
            PrayerTime(type: .maghrib, time: Date().addingTimeInterval(14400)),
            PrayerTime(type: .isha, time: Date().addingTimeInterval(18000))
        ]

        sut.writePrayerTimes(futurePrayers)

        let prayerId = sut.readNextPrayerId()
        XCTAssertEqual(prayerId, "fajr")
    }

    func test_writePrayerTimes_removesNextPrayerIdWhenNoPrayer() {
        // First write future prayers to set the ID
        let futurePrayers = [
            PrayerTime(type: .fajr, time: Date().addingTimeInterval(3600)),
            PrayerTime(type: .dhuhr, time: Date().addingTimeInterval(7200)),
            PrayerTime(type: .asr, time: Date().addingTimeInterval(10800)),
            PrayerTime(type: .maghrib, time: Date().addingTimeInterval(14400)),
            PrayerTime(type: .isha, time: Date().addingTimeInterval(18000))
        ]
        sut.writePrayerTimes(futurePrayers)
        XCTAssertNotNil(sut.readNextPrayerId())

        // Now write all-past prayers (beyond grace window) to clear the ID
        let pastPrayers = [
            PrayerTime(type: .fajr, time: Date().addingTimeInterval(-86400)),
            PrayerTime(type: .dhuhr, time: Date().addingTimeInterval(-72000)),
            PrayerTime(type: .asr, time: Date().addingTimeInterval(-57600)),
            PrayerTime(type: .maghrib, time: Date().addingTimeInterval(-43200)),
            PrayerTime(type: .isha, time: Date().addingTimeInterval(-28800))
        ]
        sut.writePrayerTimes(pastPrayers)

        XCTAssertNil(sut.readNextPrayerId())
    }

    func test_writePrayerTimes_nextPrayerIdMatchesType() {
        // Set Fajr in the past, Dhuhr should be next
        let prayers = [
            PrayerTime(type: .fajr, time: Date().addingTimeInterval(-3600)),
            PrayerTime(type: .dhuhr, time: Date().addingTimeInterval(3600)),
            PrayerTime(type: .asr, time: Date().addingTimeInterval(7200)),
            PrayerTime(type: .maghrib, time: Date().addingTimeInterval(10800)),
            PrayerTime(type: .isha, time: Date().addingTimeInterval(14400))
        ]

        sut.writePrayerTimes(prayers)

        XCTAssertEqual(sut.readNextPrayerId(), "dhuhr")
    }

    func test_readNextPrayerId_missingKey_returnsNil() {
        // Fresh defaults with no data written
        XCTAssertNil(sut.readNextPrayerId())
    }

    // MARK: - Snippet Tests

    func test_readSnippet_returnsNilWhenNoData() {
        XCTAssertNil(sut.readSnippet())
    }

    func test_readSnippet_returnsWrittenData() {
        guard let defaults = UserDefaults(suiteName: testSuiteName) else {
            XCTFail("Could not create test defaults")
            return
        }

        defaults.set("بِسْمِ اللَّهِ", forKey: WidgetAppGroupKeys.snippetArabic)
        defaults.set("In the name of Allah", forKey: WidgetAppGroupKeys.snippetTranslation)
        defaults.set("Quran 1:1", forKey: WidgetAppGroupKeys.snippetReference)
        defaults.set("fajr", forKey: WidgetAppGroupKeys.snippetPrayerId)
        defaults.set("safa://quran", forKey: WidgetAppGroupKeys.snippetDeepLink)

        let snippet = sut.readSnippet()
        XCTAssertNotNil(snippet)
        XCTAssertEqual(snippet?.arabic, "بِسْمِ اللَّهِ")
        XCTAssertEqual(snippet?.translation, "In the name of Allah")
        XCTAssertEqual(snippet?.reference, "Quran 1:1")
        XCTAssertEqual(snippet?.prayerId, "fajr")
        XCTAssertEqual(snippet?.deepLink, "safa://quran")
    }

    func test_readSnippet_returnsNilWhenPartialData() {
        guard let defaults = UserDefaults(suiteName: testSuiteName) else {
            XCTFail("Could not create test defaults")
            return
        }

        // Only write arabic — missing translation, reference, prayerId
        defaults.set("بِسْمِ اللَّهِ", forKey: WidgetAppGroupKeys.snippetArabic)

        XCTAssertNil(sut.readSnippet())
    }

    func test_readSnippet_defaultsDeepLinkToQuran() {
        guard let defaults = UserDefaults(suiteName: testSuiteName) else {
            XCTFail("Could not create test defaults")
            return
        }

        defaults.set("text", forKey: WidgetAppGroupKeys.snippetArabic)
        defaults.set("text", forKey: WidgetAppGroupKeys.snippetTranslation)
        defaults.set("ref", forKey: WidgetAppGroupKeys.snippetReference)
        defaults.set("dhuhr", forKey: WidgetAppGroupKeys.snippetPrayerId)
        // No deep link key set

        let snippet = sut.readSnippet()
        XCTAssertEqual(snippet?.deepLink, "safa://quran")
    }

    // MARK: - Write Post-Prayer Content Tests

    func test_writePostPrayerContent_writesAllSnippetKeys() {
        sut.writePostPrayerContent(for: "dhuhr")

        let defaults = UserDefaults(suiteName: testSuiteName)
        XCTAssertNotNil(defaults?.string(forKey: WidgetAppGroupKeys.snippetArabic))
        XCTAssertNotNil(defaults?.string(forKey: WidgetAppGroupKeys.snippetTranslation))
        XCTAssertNotNil(defaults?.string(forKey: WidgetAppGroupKeys.snippetReference))
        XCTAssertEqual(defaults?.string(forKey: WidgetAppGroupKeys.snippetPrayerId), "dhuhr")
        XCTAssertNotNil(defaults?.string(forKey: WidgetAppGroupKeys.snippetDeepLink))
    }

    func test_writePostPrayerContent_fajrSelectsMorningContext() {
        sut.writePostPrayerContent(for: "fajr")

        let reference = sut.readSnippet()?.reference ?? ""
        let morningRefs = WidgetSnippetCatalog.snippets
            .filter { $0.context == "morning" }
            .map { $0.reference }
        XCTAssertTrue(morningRefs.contains(reference),
                       "Fajr should select a morning snippet, got: \(reference)")
    }

    func test_writePostPrayerContent_ishaSelectsNightContext() {
        sut.writePostPrayerContent(for: "isha")

        let reference = sut.readSnippet()?.reference ?? ""
        let nightRefs = WidgetSnippetCatalog.snippets
            .filter { $0.context == "night" }
            .map { $0.reference }
        XCTAssertTrue(nightRefs.contains(reference),
                       "Isha should select a night snippet, got: \(reference)")
    }

    func test_writePostPrayerContent_isDeterministic() {
        sut.writePostPrayerContent(for: "dhuhr")
        let first = sut.readSnippet()?.translation

        sut.writePostPrayerContent(for: "dhuhr")
        let second = sut.readSnippet()?.translation

        XCTAssertEqual(first, second, "Same prayer on same day should produce same snippet")
    }

    // MARK: - Pruning Tests

    func test_pruneStaleKeys_removesOldDateKeys() {
        guard let defaults = UserDefaults(suiteName: testSuiteName) else {
            XCTFail("Could not create test defaults")
            return
        }

        let calendar = Calendar.current
        let today = Date()
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: today)!

        // Write old and recent logged-prayer keys
        let oldKey = WidgetAppGroupKeys.loggedPrayersKey(for: tenDaysAgo)
        let recentKey = WidgetAppGroupKeys.loggedPrayersKey(for: today)
        defaults.set(["fajr"], forKey: oldKey)
        defaults.set(["dhuhr"], forKey: recentKey)

        // Write old and recent timestamp keys
        let oldTimestamp = WidgetAppGroupKeys.widgetLogTimestampKey(for: "fajr", date: tenDaysAgo)
        let recentTimestamp = WidgetAppGroupKeys.widgetLogTimestampKey(for: "dhuhr", date: today)
        defaults.set(tenDaysAgo, forKey: oldTimestamp)
        defaults.set(today, forKey: recentTimestamp)

        sut.pruneStaleKeys(daysToKeep: 7)

        XCTAssertNil(defaults.object(forKey: oldKey),
                     "Keys older than 7 days should be pruned")
        XCTAssertNil(defaults.object(forKey: oldTimestamp),
                     "Timestamp keys older than 7 days should be pruned")
        XCTAssertNotNil(defaults.object(forKey: recentKey),
                        "Recent keys should be preserved")
        XCTAssertNotNil(defaults.object(forKey: recentTimestamp),
                        "Recent timestamp keys should be preserved")
    }

    func test_pruneStaleKeys_doesNotRemoveNonDateKeys() {
        guard let defaults = UserDefaults(suiteName: testSuiteName) else {
            XCTFail("Could not create test defaults")
            return
        }

        defaults.set("value", forKey: WidgetAppGroupKeys.hijriDate)
        defaults.set(42, forKey: WidgetAppGroupKeys.streakCurrentCount)

        sut.pruneStaleKeys(daysToKeep: 0)

        XCTAssertEqual(defaults.string(forKey: WidgetAppGroupKeys.hijriDate), "value")
        XCTAssertEqual(defaults.integer(forKey: WidgetAppGroupKeys.streakCurrentCount), 42)
    }

    // MARK: - Helpers

    private func makeSamplePrayers() -> [PrayerTime] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return [
            PrayerTime(type: .fajr, time: calendar.date(bySettingHour: 5, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .sunrise, time: calendar.date(bySettingHour: 6, minute: 45, second: 0, of: today)!),
            PrayerTime(type: .dhuhr, time: calendar.date(bySettingHour: 12, minute: 15, second: 0, of: today)!),
            PrayerTime(type: .asr, time: calendar.date(bySettingHour: 15, minute: 45, second: 0, of: today)!),
            PrayerTime(type: .maghrib, time: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .isha, time: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!)
        ]
    }
}
