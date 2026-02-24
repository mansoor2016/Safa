// MARK: - PrayerTimelineBoundaryTests.swift
// PURPOSE: Correctness tests for widget timeline boundary generation (including grace windows)
// DEPENDENCIES: XCTest, SafaShared

import XCTest
import SafaShared

final class PrayerTimelineBoundaryTests: XCTestCase {

    private let calculator = NextPrayerCalculator()

    // MARK: - Helpers

    /// Build a standard 5-prayer day with known times relative to a base date.
    /// Fajr 05:00, Dhuhr 12:30, Asr 15:45, Maghrib 18:30, Isha 20:00
    private func makeStandardPrayers(on baseDate: Date = Date()) -> [PrayerInfo] {
        let cal = Calendar.current
        let day = cal.startOfDay(for: baseDate)
        return [
            PrayerInfo(name: "Fajr", time: cal.date(bySettingHour: 5, minute: 0, second: 0, of: day)!),
            PrayerInfo(name: "Dhuhr", time: cal.date(bySettingHour: 12, minute: 30, second: 0, of: day)!),
            PrayerInfo(name: "Asr", time: cal.date(bySettingHour: 15, minute: 45, second: 0, of: day)!),
            PrayerInfo(name: "Maghrib", time: cal.date(bySettingHour: 18, minute: 30, second: 0, of: day)!),
            PrayerInfo(name: "Isha", time: cal.date(bySettingHour: 20, minute: 0, second: 0, of: day)!)
        ]
    }

    /// Create a date at a specific hour:minute today.
    private func timeToday(_ hour: Int, _ minute: Int, _ second: Int = 0) -> Date {
        let cal = Calendar.current
        let day = cal.startOfDay(for: Date())
        return cal.date(bySettingHour: hour, minute: minute, second: second, of: day)!
    }

    // MARK: - Entry Count (with grace entries)

    func test_allPrayersInFuture_generates11Entries() {
        // Given — now is 03:00, all 5 prayers are ahead
        // Expected: 1 initial + 5 prayers × 2 (grace start + grace end) = 11
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        XCTAssertEqual(boundaries.count, 11)
    }

    func test_somePrayersPassed_generatesCorrectCount() {
        // Given — now is 13:00, Fajr + Dhuhr passed (past grace), 3 remain
        // Expected: 1 initial + 3 prayers × 2 = 7
        let prayers = makeStandardPrayers()
        let now = timeToday(13, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        XCTAssertEqual(boundaries.count, 7)
    }

    func test_onlyIshaPending_generates3Entries() {
        // Given — now is 19:00, only Isha remains
        // Expected: 1 initial + 1 × 2 = 3
        let prayers = makeStandardPrayers()
        let now = timeToday(19, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        XCTAssertEqual(boundaries.count, 3)
    }

    func test_allPrayersPassed_generates1Entry() {
        // Given — now is 21:00, all prayers have passed (including Isha grace)
        let prayers = makeStandardPrayers()
        let now = timeToday(21, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        XCTAssertEqual(boundaries.count, 1)
    }

    func test_emptyPrayers_generates1Entry() {
        let now = timeToday(12, 0)

        let boundaries = calculator.timelineBoundaries(from: [], startingAt: now)

        XCTAssertEqual(boundaries.count, 1)
        XCTAssertNil(boundaries.first?.nextPrayer)
    }

    // MARK: - Correct Next Prayer at Each Boundary

    func test_allPrayersInFuture_correctPrayerNameAtEachBoundary() {
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Verify the prayer name and grace flag sequence
        XCTAssertEqual(boundaries[0].nextPrayer?.name, "Fajr")     // 03:00 → waiting for Fajr
        XCTAssertFalse(boundaries[0].isGrace)

        XCTAssertEqual(boundaries[1].nextPrayer?.name, "Fajr")     // 05:00 → Fajr grace
        XCTAssertTrue(boundaries[1].isGrace)

        XCTAssertEqual(boundaries[2].nextPrayer?.name, "Dhuhr")    // 05:15 → grace end, waiting for Dhuhr
        XCTAssertFalse(boundaries[2].isGrace)

        XCTAssertEqual(boundaries[3].nextPrayer?.name, "Dhuhr")    // 12:30 → Dhuhr grace
        XCTAssertTrue(boundaries[3].isGrace)

        XCTAssertEqual(boundaries[4].nextPrayer?.name, "Asr")      // 12:45 → grace end, waiting for Asr
        XCTAssertFalse(boundaries[4].isGrace)

        // ... pattern continues for remaining prayers
        XCTAssertNil(boundaries[10].nextPrayer)                     // 20:15 → all done
        XCTAssertFalse(boundaries[10].isGrace)
    }

    func test_midDay_correctPrayerSequence() {
        // Given — now is 13:00, between Dhuhr (12:30) and Asr (15:45)
        // Dhuhr grace has expired (30 min after 12:30)
        let prayers = makeStandardPrayers()
        let now = timeToday(13, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        XCTAssertEqual(boundaries[0].nextPrayer?.name, "Asr")      // 13:00 → waiting for Asr
        XCTAssertFalse(boundaries[0].isGrace)
        XCTAssertEqual(boundaries[1].nextPrayer?.name, "Asr")      // 15:45 → Asr grace
        XCTAssertTrue(boundaries[1].isGrace)
        XCTAssertEqual(boundaries[2].nextPrayer?.name, "Maghrib")  // 16:00 → grace end
        XCTAssertFalse(boundaries[2].isGrace)
    }

    // MARK: - Boundary Dates

    func test_allPrayersInFuture_firstEntryDateIsNow() {
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        XCTAssertEqual(boundaries[0].date, now)
    }

    func test_boundaryDatesIncludeGraceEndpoints() {
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Grace start at Fajr time
        XCTAssertEqual(boundaries[1].date, timeToday(5, 0))
        // Grace end at Fajr + 15 min
        XCTAssertEqual(boundaries[2].date, timeToday(5, 15))
        // Grace start at Dhuhr time
        XCTAssertEqual(boundaries[3].date, timeToday(12, 30))
        // Grace end at Dhuhr + 15 min
        XCTAssertEqual(boundaries[4].date, timeToday(12, 45))
    }

    func test_datesAreMonotonicallyIncreasing() {
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        for i in 1..<boundaries.count {
            XCTAssertGreaterThan(
                boundaries[i].date, boundaries[i - 1].date,
                "Entry \(i) date should be after entry \(i - 1)"
            )
        }
    }

    // MARK: - Grace Window Edge Cases

    func test_nowExactlyAtPrayerTime_showsGrace() {
        // Given — now is exactly at Dhuhr time (12:30)
        let prayers = makeStandardPrayers()
        let now = timeToday(12, 30)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // First entry should show Dhuhr in grace (prayer just arrived)
        XCTAssertEqual(boundaries[0].nextPrayer?.name, "Dhuhr")
        XCTAssertTrue(boundaries[0].isGrace)
    }

    func test_nowExactlyAtLastPrayerTime_showsGrace() {
        // Given — now is exactly at Isha time (20:00)
        let prayers = makeStandardPrayers()
        let now = timeToday(20, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // First entry: Isha in grace
        XCTAssertEqual(boundaries[0].nextPrayer?.name, "Isha")
        XCTAssertTrue(boundaries[0].isGrace)
        // Second entry: grace end, no more prayers
        XCTAssertEqual(boundaries.count, 2)
        XCTAssertNil(boundaries[1].nextPrayer)
    }

    func test_oneSecondBeforePrayer_stillShowsThatPrayer() {
        let prayers = makeStandardPrayers()
        let now = timeToday(12, 30).addingTimeInterval(-1)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Dhuhr hasn't arrived yet — first entry shows Dhuhr countdown
        XCTAssertEqual(boundaries[0].nextPrayer?.name, "Dhuhr")
        XCTAssertFalse(boundaries[0].isGrace)
    }

    func test_oneSecondAfterPrayer_showsGrace() {
        let prayers = makeStandardPrayers()
        let now = timeToday(12, 30).addingTimeInterval(1)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Dhuhr just started — first entry shows Dhuhr in grace
        XCTAssertEqual(boundaries[0].nextPrayer?.name, "Dhuhr")
        XCTAssertTrue(boundaries[0].isGrace)
    }

    func test_graceEndDateIs15MinAfterPrayer() {
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // For each grace start, the following entry should be exactly 15 min later
        let graceStarts = boundaries.filter { $0.isGrace }
        for graceEntry in graceStarts {
            guard let prayer = graceEntry.nextPrayer else { continue }
            let expectedGraceEnd = prayer.time.addingTimeInterval(PrayerTimeConstants.graceInterval)
            // Find the entry right after this grace entry
            if let idx = boundaries.firstIndex(where: { $0.date == graceEntry.date && $0.isGrace }),
               idx + 1 < boundaries.count {
                XCTAssertEqual(
                    boundaries[idx + 1].date, expectedGraceEnd,
                    "Grace end for \(prayer.name) should be 15 min after prayer time"
                )
            }
        }
    }

    func test_duringGraceWindow_showsGraceEntry() {
        // Given — now is 5 min after Dhuhr (12:35), within grace
        let prayers = makeStandardPrayers()
        let now = timeToday(12, 35)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // First entry should show Dhuhr in grace
        XCTAssertEqual(boundaries[0].nextPrayer?.name, "Dhuhr")
        XCTAssertTrue(boundaries[0].isGrace)

        // Second entry at grace end (12:45) should show Asr
        XCTAssertEqual(boundaries[1].nextPrayer?.name, "Asr")
        XCTAssertFalse(boundaries[1].isGrace)
        XCTAssertEqual(boundaries[1].date, timeToday(12, 45))
    }

    func test_afterGraceExpired_showsNextPrayer() {
        // Given — now is 16 min after Dhuhr (12:46), grace expired
        let prayers = makeStandardPrayers()
        let now = timeToday(12, 46)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Dhuhr grace expired — first entry shows Asr
        XCTAssertEqual(boundaries[0].nextPrayer?.name, "Asr")
        XCTAssertFalse(boundaries[0].isGrace)
    }

    // MARK: - All Prayers Passed

    func test_allPrayersPassed_showsNilNextPrayer() {
        let prayers = makeStandardPrayers()
        let now = timeToday(23, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        XCTAssertEqual(boundaries.count, 1)
        XCTAssertNil(boundaries[0].nextPrayer)
        XCTAssertEqual(boundaries[0].date, now)
    }

    // MARK: - Final Entry Always Has Nil

    func test_lastBoundaryAlwaysHasNilNextPrayer() {
        let prayers = makeStandardPrayers()

        // Try from different start times (all well outside any grace window)
        let startTimes = [timeToday(3, 0), timeToday(10, 0), timeToday(13, 0), timeToday(19, 0)]

        for now in startTimes {
            let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)
            guard let last = boundaries.last else {
                XCTFail("Should have at least one boundary")
                continue
            }
            // Last entry should always be nil (grace end of last prayer, or all passed)
            if boundaries.count > 1 {
                XCTAssertNil(last.nextPrayer, "Last boundary should have nil nextPrayer for now=\(now)")
            }
        }
    }

    // MARK: - Refresh Policy Date

    func test_refreshDate_isAfterLastBoundary() {
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        let refreshDate = calculator.timelineRefreshDate(from: prayers, startingAt: now)

        let ishaTime = timeToday(20, 0)
        XCTAssertGreaterThan(refreshDate, ishaTime)
        XCTAssertLessThanOrEqual(refreshDate.timeIntervalSince(ishaTime), 1800 + 1)
    }

    func test_refreshDate_allPrayersPassed_is30MinFromNow() {
        let prayers = makeStandardPrayers()
        let now = timeToday(22, 0)

        let refreshDate = calculator.timelineRefreshDate(from: prayers, startingAt: now)

        let expected = now.addingTimeInterval(1800)
        XCTAssertEqual(refreshDate.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 1)
    }

    // MARK: - Live Activity Update Schedule (nextBoundaryDate)

    func test_nextUpdateDate_returnsNextPrayerTime() {
        let prayers = makeStandardPrayers()
        let now = timeToday(13, 0)

        let nextUpdate = calculator.nextBoundaryDate(from: prayers, after: now)

        XCTAssertEqual(nextUpdate, timeToday(15, 45))
    }

    func test_nextUpdateDate_duringGrace_returnsGraceEnd() {
        let prayers = makeStandardPrayers()
        let now = timeToday(12, 35) // 5 min after Dhuhr, within grace

        let nextUpdate = calculator.nextBoundaryDate(from: prayers, after: now)

        // Should return Dhuhr + 15 min = 12:45
        XCTAssertEqual(nextUpdate, timeToday(12, 45))
    }

    func test_nextUpdateDate_allPassed_returnsNil() {
        let prayers = makeStandardPrayers()
        let now = timeToday(21, 0)

        let nextUpdate = calculator.nextBoundaryDate(from: prayers, after: now)

        XCTAssertNil(nextUpdate)
    }

    func test_nextUpdateDate_beforeAllPrayers_returnsFajrTime() {
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        let nextUpdate = calculator.nextBoundaryDate(from: prayers, after: now)

        XCTAssertEqual(nextUpdate, timeToday(5, 0))
    }

    func test_nextUpdateDate_exactlyAtPrayer_returnsGraceEnd() {
        let prayers = makeStandardPrayers()
        let now = timeToday(15, 45) // Exactly at Asr

        let nextUpdate = calculator.nextBoundaryDate(from: prayers, after: now)

        // At Asr time, we're in grace. Next boundary is grace end: 16:00
        XCTAssertEqual(nextUpdate, timeToday(16, 0))
    }
}
