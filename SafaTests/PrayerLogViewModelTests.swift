// MARK: - PrayerLogViewModelTests.swift
// PURPOSE: Unit tests for PrayerLogViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class PrayerLogViewModelTests: XCTestCase {

    var sut: PrayerLogViewModel!

    override func setUp() {
        super.setUp()
        sut = PrayerLogViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_selectedDateIsToday() {
        XCTAssertTrue(Calendar.current.isDateInToday(sut.selectedDate))
    }

    func test_initialState_selectedPrayerIsNil() {
        XCTAssertNil(sut.selectedPrayer)
    }

    func test_initialState_prayerLogsIsEmpty() {
        XCTAssertTrue(sut.prayerLogs.isEmpty)
    }

    func test_initialState_showingLogSheetIsFalse() {
        XCTAssertFalse(sut.showingLogSheet)
    }

    func test_initialState_logQualityIsOnTime() {
        XCTAssertEqual(sut.logQuality, .onTime)
    }

    func test_initialState_logNotesIsEmpty() {
        XCTAssertTrue(sut.logNotes.isEmpty)
    }

    func test_initialState_isLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Log Prayer Tests

    func test_logPrayer_addsEntryForDate() {
        sut.logPrayer(.fajr, quality: .onTime, notes: nil)

        let logs = sut.logs(for: sut.selectedDate)
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.prayerType, .fajr)
    }

    func test_logPrayer_storesQuality() {
        sut.logPrayer(.fajr, quality: .delayed, notes: nil)

        let logs = sut.logs(for: sut.selectedDate)
        XCTAssertEqual(logs.first?.quality, .delayed)
    }

    func test_logPrayer_storesNotes() {
        sut.logPrayer(.fajr, quality: .onTime, notes: "Test note")

        let logs = sut.logs(for: sut.selectedDate)
        XCTAssertEqual(logs.first?.notes, "Test note")
    }

    func test_logPrayer_multipleForSameDay() {
        sut.logPrayer(.fajr, quality: .onTime, notes: nil)
        sut.logPrayer(.dhuhr, quality: .delayed, notes: nil)
        sut.logPrayer(.asr, quality: .onTime, notes: nil)

        let logs = sut.logs(for: sut.selectedDate)
        XCTAssertEqual(logs.count, 3)
    }

    func test_logPrayer_differentDates() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        sut.selectedDate = today
        sut.logPrayer(.fajr, quality: .onTime, notes: nil)

        sut.selectedDate = yesterday
        sut.logPrayer(.dhuhr, quality: .onTime, notes: nil)

        XCTAssertEqual(sut.logs(for: today).count, 1)
        XCTAssertEqual(sut.logs(for: yesterday).count, 1)
    }

    // MARK: - Is Logged Tests

    func test_isLogged_returnsTrueWhenLogged() {
        sut.logPrayer(.fajr, quality: .onTime, notes: nil)

        XCTAssertTrue(sut.isLogged(.fajr, on: sut.selectedDate))
    }

    func test_isLogged_returnsFalseWhenNotLogged() {
        XCTAssertFalse(sut.isLogged(.fajr, on: sut.selectedDate))
    }

    func test_isLogged_returnsFalseForDifferentPrayer() {
        sut.logPrayer(.fajr, quality: .onTime, notes: nil)

        XCTAssertFalse(sut.isLogged(.dhuhr, on: sut.selectedDate))
    }

    func test_isLogged_returnsFalseForDifferentDate() {
        sut.logPrayer(.fajr, quality: .onTime, notes: nil)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(sut.isLogged(.fajr, on: yesterday))
    }

    // MARK: - Remove Log Tests

    func test_removeLog_removesSpecificPrayer() {
        sut.logPrayer(.fajr, quality: .onTime, notes: nil)
        sut.logPrayer(.dhuhr, quality: .onTime, notes: nil)

        sut.removeLog(for: .fajr, on: sut.selectedDate)

        XCTAssertFalse(sut.isLogged(.fajr, on: sut.selectedDate))
        XCTAssertTrue(sut.isLogged(.dhuhr, on: sut.selectedDate))
    }

    func test_removeLog_doesNothingIfNotExists() {
        sut.logPrayer(.fajr, quality: .onTime, notes: nil)

        // Remove non-existent prayer - should not crash
        sut.removeLog(for: .dhuhr, on: sut.selectedDate)

        XCTAssertTrue(sut.isLogged(.fajr, on: sut.selectedDate))
    }

    // MARK: - Logs For Date Tests

    func test_logsForDate_returnsEmptyForNoLogs() {
        let logs = sut.logs(for: Date())
        XCTAssertTrue(logs.isEmpty)
    }

    func test_logsForDate_returnsAllLogsForDate() {
        sut.logPrayer(.fajr, quality: .onTime, notes: nil)
        sut.logPrayer(.dhuhr, quality: .onTime, notes: nil)
        sut.logPrayer(.asr, quality: .onTime, notes: nil)

        let logs = sut.logs(for: sut.selectedDate)
        XCTAssertEqual(logs.count, 3)
    }

    // MARK: - Weekly Stats Tests (using manually inserted test data)

    func test_weeklyStats_emptyByDefault() {
        let stats = sut.weeklyStats
        XCTAssertEqual(stats.totalLogged, 0)
        XCTAssertEqual(stats.onTime, 0)
        XCTAssertEqual(stats.missed, 35) // 7 days × 5 prayers
    }

    func test_weeklyStats_withManualEntries() {
        let today = Calendar.current.startOfDay(for: Date())
        sut.prayerLogs[today] = [
            PrayerLogEntry(id: UUID(), prayerType: .fajr, date: today, quality: .onTime, notes: nil),
            PrayerLogEntry(id: UUID(), prayerType: .dhuhr, date: today, quality: .delayed, notes: nil),
        ]

        let stats = sut.weeklyStats
        XCTAssertEqual(stats.totalLogged, 2)
        XCTAssertEqual(stats.onTime, 1)
        XCTAssertEqual(stats.late, 1)
        XCTAssertEqual(stats.missed, 33) // 35 - 2
    }

    func test_weeklyStats_perfectDay() {
        let today = Calendar.current.startOfDay(for: Date())
        sut.prayerLogs[today] = PrayerType.obligatoryPrayers.map {
            PrayerLogEntry(id: UUID(), prayerType: $0, date: today, quality: .onTime, notes: nil)
        }

        let stats = sut.weeklyStats
        XCTAssertEqual(stats.perfectDays, 1)
        XCTAssertEqual(stats.totalLogged, 5)
    }

    func test_weeklyStats_completionPercentage() {
        let today = Calendar.current.startOfDay(for: Date())
        sut.prayerLogs[today] = [
            PrayerLogEntry(id: UUID(), prayerType: .fajr, date: today, quality: .onTime, notes: nil),
        ]

        let stats = sut.weeklyStats
        let expected = Double(1) / 35.0 * 100
        XCTAssertEqual(stats.completionPercentage, expected, accuracy: 0.01)
    }

    // MARK: - Load Data Tests

    func test_loadData_populatesFromRepository() async {
        await sut.loadData()
        // With real repo, should have entries (may be empty if no prayers logged)
        // Just verify it doesn't crash
        XCTAssertNotNil(sut.prayerLogs)
    }

    // MARK: - PrayerLogEntry Model Tests

    func test_prayerLogEntry_isIdentifiable() {
        let entry = PrayerLogEntry(
            id: UUID(),
            prayerType: .fajr,
            date: Date(),
            quality: .onTime,
            notes: nil
        )
        XCTAssertNotNil(entry.id)
    }

    func test_prayerLogEntry_timestamp() {
        let date = Date()
        let entry = PrayerLogEntry(
            id: UUID(),
            prayerType: .fajr,
            date: date,
            quality: .onTime,
            notes: nil
        )
        XCTAssertEqual(entry.timestamp, date)
    }

    func test_prayerLogEntry_equatable() {
        let id = UUID()
        let date = Date()
        let entry1 = PrayerLogEntry(id: id, prayerType: .fajr, date: date, quality: .onTime, notes: nil)
        let entry2 = PrayerLogEntry(id: id, prayerType: .fajr, date: date, quality: .onTime, notes: nil)
        XCTAssertEqual(entry1, entry2)
    }

    // MARK: - PrayerQuality Enum Tests

    func test_prayerQuality_allCases() {
        XCTAssertEqual(PrayerQuality.allCases.count, 3)
        XCTAssertTrue(PrayerQuality.allCases.contains(.onTime))
        XCTAssertTrue(PrayerQuality.allCases.contains(.delayed))
        XCTAssertTrue(PrayerQuality.allCases.contains(.qada))
    }

    func test_prayerQuality_rawValues() {
        XCTAssertEqual(PrayerQuality.onTime.rawValue, "on_time")
        XCTAssertEqual(PrayerQuality.delayed.rawValue, "delayed")
        XCTAssertEqual(PrayerQuality.qada.rawValue, "qada")
    }

    func test_prayerQuality_displayNames() {
        XCTAssertEqual(PrayerQuality.onTime.displayName, "On Time")
        XCTAssertEqual(PrayerQuality.delayed.displayName, "Delayed")
        XCTAssertEqual(PrayerQuality.qada.displayName, "Qada (Makeup)")
    }

    func test_prayerQuality_iconNames() {
        XCTAssertEqual(PrayerQuality.onTime.iconName, "checkmark.circle.fill")
        XCTAssertEqual(PrayerQuality.delayed.iconName, "clock.fill")
        XCTAssertEqual(PrayerQuality.qada.iconName, "arrow.counterclockwise")
    }

    // MARK: - WeeklyPrayerStats Tests

    func test_weeklyPrayerStats_completionPercentage_zero() {
        let stats = WeeklyPrayerStats(
            totalLogged: 0,
            onTime: 0,
            late: 0,
            missed: 35,
            perfectDays: 0
        )
        XCTAssertEqual(stats.completionPercentage, 0, accuracy: 0.01)
    }

    func test_weeklyPrayerStats_completionPercentage_full() {
        let stats = WeeklyPrayerStats(
            totalLogged: 35,
            onTime: 35,
            late: 0,
            missed: 0,
            perfectDays: 7
        )
        XCTAssertEqual(stats.completionPercentage, 100, accuracy: 0.01)
    }

    func test_weeklyPrayerStats_completionPercentage_partial() {
        let stats = WeeklyPrayerStats(
            totalLogged: 17,
            onTime: 10,
            late: 7,
            missed: 18,
            perfectDays: 2
        )
        // 17/35 * 100 ≈ 48.57%
        XCTAssertEqual(stats.completionPercentage, 48.57, accuracy: 0.1)
    }

    // MARK: - Edge Cases

    func test_logsForDate_handlesDateWithNoLogs() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 100, to: Date())!
        let logs = sut.logs(for: futureDate)
        XCTAssertTrue(logs.isEmpty)
    }

    func test_removeLog_handlesEmptyLogs() {
        // Should not crash
        sut.removeLog(for: .fajr, on: Date())
        XCTAssertTrue(sut.prayerLogs.isEmpty)
    }
}
