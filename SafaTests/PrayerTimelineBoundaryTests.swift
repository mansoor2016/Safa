// MARK: - PrayerTimelineBoundaryTests.swift
// PURPOSE: Correctness tests for widget timeline boundary generation
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
    private func timeToday(_ hour: Int, _ minute: Int) -> Date {
        let cal = Calendar.current
        let day = cal.startOfDay(for: Date())
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    // MARK: - Entry Count

    func test_allPrayersInFuture_generates6Entries() {
        // Given — now is 03:00, all 5 prayers are ahead
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        // When
        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Then — 1 initial + 5 transitions (at each prayer time, next switches)
        // Entry at 03:00 → Fajr, at 05:00 → Dhuhr, at 12:30 → Asr,
        // at 15:45 → Maghrib, at 18:30 → Isha, at 20:00 → nil
        XCTAssertEqual(boundaries.count, 6)
    }

    func test_somePrayersPassed_generatesCorrectCount() {
        // Given — now is 13:00, Fajr + Dhuhr passed, 3 remain (Asr, Maghrib, Isha)
        let prayers = makeStandardPrayers()
        let now = timeToday(13, 0)

        // When
        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Then — 1 initial (Asr) + 3 transitions (at Asr→Maghrib, Maghrib→Isha, Isha→nil)
        XCTAssertEqual(boundaries.count, 4)
    }

    func test_onlyIshaPending_generates2Entries() {
        // Given — now is 19:00, only Isha remains
        let prayers = makeStandardPrayers()
        let now = timeToday(19, 0)

        // When
        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Then — 1 initial (Isha) + 1 transition (Isha→nil)
        XCTAssertEqual(boundaries.count, 2)
    }

    func test_allPrayersPassed_generates1Entry() {
        // Given — now is 21:00, all prayers have passed
        let prayers = makeStandardPrayers()
        let now = timeToday(21, 0)

        // When
        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Then — 1 entry showing no more prayers
        XCTAssertEqual(boundaries.count, 1)
    }

    func test_emptyPrayers_generates1Entry() {
        // Given — no prayers at all
        let now = timeToday(12, 0)

        // When
        let boundaries = calculator.timelineBoundaries(from: [], startingAt: now)

        // Then — 1 entry with nil next prayer
        XCTAssertEqual(boundaries.count, 1)
        XCTAssertNil(boundaries.first?.nextPrayer)
    }

    // MARK: - Correct Next Prayer at Each Boundary

    func test_allPrayersInFuture_correctPrayerNameAtEachBoundary() {
        // Given — now is 03:00
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        // When
        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Then — verify the prayer name sequence
        XCTAssertEqual(boundaries[0].nextPrayer?.name, "Fajr")     // 03:00 → Fajr
        XCTAssertEqual(boundaries[1].nextPrayer?.name, "Dhuhr")    // 05:00 → Dhuhr
        XCTAssertEqual(boundaries[2].nextPrayer?.name, "Asr")      // 12:30 → Asr
        XCTAssertEqual(boundaries[3].nextPrayer?.name, "Maghrib")  // 15:45 → Maghrib
        XCTAssertEqual(boundaries[4].nextPrayer?.name, "Isha")     // 18:30 → Isha
        XCTAssertNil(boundaries[5].nextPrayer)                      // 20:00 → no more
    }

    func test_midDay_correctPrayerSequence() {
        // Given — now is 13:00, between Dhuhr (12:30) and Asr (15:45)
        let prayers = makeStandardPrayers()
        let now = timeToday(13, 0)

        // When
        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Then
        XCTAssertEqual(boundaries[0].nextPrayer?.name, "Asr")      // 13:00 → Asr
        XCTAssertEqual(boundaries[1].nextPrayer?.name, "Maghrib")  // 15:45 → Maghrib
        XCTAssertEqual(boundaries[2].nextPrayer?.name, "Isha")     // 18:30 → Isha
        XCTAssertNil(boundaries[3].nextPrayer)                      // 20:00 → no more
    }

    // MARK: - Boundary Dates

    func test_allPrayersInFuture_firstEntryDateIsNow() {
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        XCTAssertEqual(boundaries[0].date, now)
    }

    func test_boundaryDatesMatchPrayerTimes() {
        // Given — now is 03:00
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        // When
        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Then — subsequent entries fire at each prayer time
        XCTAssertEqual(boundaries[1].date, timeToday(5, 0))    // Fajr time
        XCTAssertEqual(boundaries[2].date, timeToday(12, 30))  // Dhuhr time
        XCTAssertEqual(boundaries[3].date, timeToday(15, 45))  // Asr time
        XCTAssertEqual(boundaries[4].date, timeToday(18, 30))  // Maghrib time
        XCTAssertEqual(boundaries[5].date, timeToday(20, 0))   // Isha time
    }

    func test_midDay_boundaryDatesStartFromNextPrayer() {
        // Given — now is 16:00, Asr (15:45) already passed
        let prayers = makeStandardPrayers()
        let now = timeToday(16, 0)

        // When
        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Then — first entry is now, subsequent at remaining prayer times
        XCTAssertEqual(boundaries[0].date, now)
        XCTAssertEqual(boundaries[1].date, timeToday(18, 30))  // Maghrib
        XCTAssertEqual(boundaries[2].date, timeToday(20, 0))   // Isha
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

    // MARK: - Edge Cases: Exact Prayer Time

    func test_nowExactlyAtPrayerTime_thatPrayerHasPassed() {
        // Given — now is exactly at Dhuhr time (12:30)
        // The prayer that just started is Dhuhr; the "next" is Asr
        let prayers = makeStandardPrayers()
        let now = timeToday(12, 30)

        // When
        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Then — first entry should show Asr (Dhuhr is current/just passed)
        // NextPrayerCalculator uses `> now`, so a prayer at exactly `now` is NOT "next"
        XCTAssertEqual(boundaries[0].nextPrayer?.name, "Asr")
    }

    func test_nowExactlyAtLastPrayerTime_noMorePrayers() {
        // Given — now is exactly at Isha time (20:00)
        let prayers = makeStandardPrayers()
        let now = timeToday(20, 0)

        // When
        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Then — Isha has begun, no more prayers
        XCTAssertEqual(boundaries.count, 1)
        XCTAssertNil(boundaries[0].nextPrayer)
    }

    // MARK: - Edge Case: One Second Before/After

    func test_oneSecondBeforePrayer_stillShowsThatPrayer() {
        let prayers = makeStandardPrayers()
        let now = timeToday(12, 30).addingTimeInterval(-1) // 12:29:59

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Dhuhr hasn't arrived yet — first entry shows Dhuhr
        XCTAssertEqual(boundaries[0].nextPrayer?.name, "Dhuhr")
    }

    func test_oneSecondAfterPrayer_showsNextPrayer() {
        let prayers = makeStandardPrayers()
        let now = timeToday(12, 30).addingTimeInterval(1) // 12:30:01

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Dhuhr just passed — first entry shows Asr
        XCTAssertEqual(boundaries[0].nextPrayer?.name, "Asr")
    }

    // MARK: - Edge Case: All Prayers Passed

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

        // Try from different start times
        let startTimes = [timeToday(3, 0), timeToday(10, 0), timeToday(16, 0), timeToday(19, 0)]

        for now in startTimes {
            let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)
            guard let last = boundaries.last else {
                XCTFail("Should have at least one boundary")
                continue
            }
            // Last entry should either be nil (no more prayers) or
            // if now is already past all prayers, the single entry is nil
            if boundaries.count > 1 || now > prayers.last!.time {
                XCTAssertNil(last.nextPrayer, "Last boundary should have nil nextPrayer for now=\(now)")
            }
        }
    }

    // MARK: - Transition Correctness: Widget Scenario

    func test_widgetScenario_prayerNameSwitchesAtExactBoundary() {
        // Simulate a widget that pre-renders all entries:
        // At each boundary date, the displayed prayer should be correct
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Verify: for each boundary, the nextPrayer matches what NextPrayerCalculator
        // would return if called at that exact time
        for boundary in boundaries {
            let expected = calculator.nextPrayer(from: prayers, at: boundary.date)
            XCTAssertEqual(
                boundary.nextPrayer, expected,
                "At \(boundary.date), boundary shows \(boundary.nextPrayer?.name ?? "nil") "
                + "but calculator says \(expected?.name ?? "nil")"
            )
        }
    }

    // MARK: - Refresh Policy Date

    func test_refreshDate_isAfterLastBoundary() {
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        let refreshDate = calculator.timelineRefreshDate(from: prayers, startingAt: now)

        // Refresh should be after the last prayer (Isha at 20:00), within 30 min
        let ishaTime = timeToday(20, 0)
        XCTAssertGreaterThan(refreshDate, ishaTime)
        XCTAssertLessThanOrEqual(refreshDate.timeIntervalSince(ishaTime), 1800 + 1)
    }

    func test_refreshDate_allPrayersPassed_is30MinFromNow() {
        let prayers = makeStandardPrayers()
        let now = timeToday(22, 0)

        let refreshDate = calculator.timelineRefreshDate(from: prayers, startingAt: now)

        // Should be roughly 30 minutes from now
        let expected = now.addingTimeInterval(1800)
        XCTAssertEqual(refreshDate.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 1)
    }

    // MARK: - Live Activity Update Schedule

    func test_nextUpdateDate_returnsNextPrayerTime() {
        let prayers = makeStandardPrayers()
        let now = timeToday(13, 0) // Between Dhuhr (12:30) and Asr (15:45)

        let nextUpdate = calculator.nextBoundaryDate(from: prayers, after: now)

        // Next boundary is when Asr arrives (15:45) — that's when the name should change
        XCTAssertEqual(nextUpdate, timeToday(15, 45))
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

    func test_nextUpdateDate_exactlyAtPrayer_returnsFollowingPrayer() {
        let prayers = makeStandardPrayers()
        let now = timeToday(15, 45) // Exactly at Asr

        let nextUpdate = calculator.nextBoundaryDate(from: prayers, after: now)

        // Asr just started, next boundary is Maghrib
        XCTAssertEqual(nextUpdate, timeToday(18, 30))
    }

    // MARK: - Consistency: Boundaries Match Individual Calculator Calls

    func test_everyBoundary_matchesStandaloneCalculation() {
        // The gold standard: for ANY time between two boundaries,
        // the nextPrayer shown should be correct.
        let prayers = makeStandardPrayers()
        let now = timeToday(3, 0)

        let boundaries = calculator.timelineBoundaries(from: prayers, startingAt: now)

        // Check at midpoints between boundaries
        for i in 0..<(boundaries.count - 1) {
            let midpoint = Date(
                timeIntervalSince1970: (boundaries[i].date.timeIntervalSince1970
                + boundaries[i + 1].date.timeIntervalSince1970) / 2
            )
            let expectedAtMidpoint = calculator.nextPrayer(from: prayers, at: midpoint)

            XCTAssertEqual(
                boundaries[i].nextPrayer, expectedAtMidpoint,
                "At midpoint \(midpoint) between boundaries \(i) and \(i + 1), "
                + "expected \(expectedAtMidpoint?.name ?? "nil") "
                + "but got \(boundaries[i].nextPrayer?.name ?? "nil")"
            )
        }
    }
}
