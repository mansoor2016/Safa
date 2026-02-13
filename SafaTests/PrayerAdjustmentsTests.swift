import XCTest
@testable import Safa

final class PrayerAdjustmentsTests: XCTestCase {

    // MARK: - UserPreferences adjustment helpers

    func test_adjustment_returnsZero_whenNoneSet() {
        let prefs = UserPreferences()
        XCTAssertEqual(prefs.adjustment(for: .fajr), 0)
        XCTAssertEqual(prefs.adjustment(for: .maghrib), 0)
    }

    func test_setAdjustment_storesValue() {
        var prefs = UserPreferences()
        prefs.setAdjustment(5, for: .fajr)
        XCTAssertEqual(prefs.adjustment(for: .fajr), 5)
    }

    func test_setAdjustment_negativeValue() {
        var prefs = UserPreferences()
        prefs.setAdjustment(-10, for: .isha)
        XCTAssertEqual(prefs.adjustment(for: .isha), -10)
    }

    func test_setAdjustment_zeroRemovesKey() {
        var prefs = UserPreferences()
        prefs.setAdjustment(5, for: .fajr)
        XCTAssertEqual(prefs.adjustment(for: .fajr), 5)

        prefs.setAdjustment(0, for: .fajr)
        XCTAssertEqual(prefs.adjustment(for: .fajr), 0)
        XCTAssertTrue(prefs.prayerAdjustments.isEmpty)
    }

    func test_setAdjustment_multipleIndependent() {
        var prefs = UserPreferences()
        prefs.setAdjustment(5, for: .fajr)
        prefs.setAdjustment(-3, for: .asr)
        prefs.setAdjustment(10, for: .maghrib)

        XCTAssertEqual(prefs.adjustment(for: .fajr), 5)
        XCTAssertEqual(prefs.adjustment(for: .asr), -3)
        XCTAssertEqual(prefs.adjustment(for: .maghrib), 10)
        XCTAssertEqual(prefs.adjustment(for: .dhuhr), 0) // untouched
    }

    func test_adjustments_defaultIsEmptyDict() {
        let prefs = UserPreferences()
        XCTAssertTrue(prefs.prayerAdjustments.isEmpty)
    }

    // MARK: - Adjustment application to prayer times

    func test_adjustmentsApplied_shiftsPrayerTime() {
        let baseTime = Calendar.current.date(bySettingHour: 5, minute: 30, second: 0, of: Date())!
        let prayer = PrayerTime(type: .fajr, time: baseTime)
        let adjustments: [String: Int] = ["fajr": 10]

        let adjusted = applyAdjustments(to: [prayer], adjustments: adjustments)

        XCTAssertEqual(adjusted.count, 1)
        let expectedTime = baseTime.addingTimeInterval(600) // +10 min
        XCTAssertEqual(adjusted[0].time, expectedTime)
    }

    func test_adjustmentsApplied_negativeOffset() {
        let baseTime = Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date())!
        let prayer = PrayerTime(type: .dhuhr, time: baseTime)
        let adjustments: [String: Int] = ["dhuhr": -5]

        let adjusted = applyAdjustments(to: [prayer], adjustments: adjustments)

        let expectedTime = baseTime.addingTimeInterval(-300) // -5 min
        XCTAssertEqual(adjusted[0].time, expectedTime)
    }

    func test_adjustmentsApplied_zeroOffset_noChange() {
        let baseTime = Calendar.current.date(bySettingHour: 15, minute: 45, second: 0, of: Date())!
        let prayer = PrayerTime(type: .asr, time: baseTime)

        let adjusted = applyAdjustments(to: [prayer], adjustments: [:])

        XCTAssertEqual(adjusted[0].time, baseTime)
    }

    func test_adjustmentsApplied_onlyAffectsMatchingPrayer() {
        let fajrTime = Calendar.current.date(bySettingHour: 5, minute: 30, second: 0, of: Date())!
        let dhuhrTime = Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date())!
        let prayers = [
            PrayerTime(type: .fajr, time: fajrTime),
            PrayerTime(type: .dhuhr, time: dhuhrTime),
        ]
        let adjustments: [String: Int] = ["fajr": 10]

        let adjusted = applyAdjustments(to: prayers, adjustments: adjustments)

        XCTAssertEqual(adjusted[0].time, fajrTime.addingTimeInterval(600))
        XCTAssertEqual(adjusted[1].time, dhuhrTime) // unchanged
    }

    // MARK: - Helper (mirrors PrayerRepository logic)

    private func applyAdjustments(to prayers: [PrayerTime], adjustments: [String: Int]) -> [PrayerTime] {
        prayers.map { prayer in
            guard let offset = adjustments[prayer.type.rawValue], offset != 0 else { return prayer }
            return PrayerTime(
                id: prayer.id,
                type: prayer.type,
                time: prayer.time.addingTimeInterval(TimeInterval(offset * 60)),
                isNext: prayer.isNext
            )
        }
    }
}
