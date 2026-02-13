import XCTest
@testable import Safa

final class DailyGoalsHelpersTests: XCTestCase {

    // MARK: - Helpers

    private func date(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(
            bySettingHour: hour, minute: minute, second: 0, of: Date()
        )!
    }

    private func prayerTime(_ type: PrayerType, hour: Int, minute: Int = 0) -> PrayerTime {
        PrayerTime(type: type, time: date(hour: hour, minute: minute))
    }

    private var typicalPrayers: [PrayerTime] {
        [
            prayerTime(.fajr, hour: 5, minute: 30),
            prayerTime(.sunrise, hour: 7, minute: 0),
            prayerTime(.dhuhr, hour: 12, minute: 30),
            prayerTime(.asr, hour: 15, minute: 45),
            prayerTime(.maghrib, hour: 18, minute: 15),
            prayerTime(.isha, hour: 19, minute: 45),
        ]
    }

    // MARK: - With Asr Prayer Time

    func test_beforeAsr_eveningDhikrNotAvailable() {
        let now = date(hour: 14, minute: 0) // 2:00 PM, before Asr at 3:45 PM
        let result = DailyGoalsHelpers.isEveningDhikrAvailable(
            now: now,
            todayPrayers: typicalPrayers
        )
        XCTAssertFalse(result)
    }

    func test_exactlyAtAsr_eveningDhikrAvailable() {
        let now = date(hour: 15, minute: 45) // exactly Asr time
        let result = DailyGoalsHelpers.isEveningDhikrAvailable(
            now: now,
            todayPrayers: typicalPrayers
        )
        XCTAssertTrue(result)
    }

    func test_afterAsr_eveningDhikrAvailable() {
        let now = date(hour: 16, minute: 30) // 4:30 PM, after Asr
        let result = DailyGoalsHelpers.isEveningDhikrAvailable(
            now: now,
            todayPrayers: typicalPrayers
        )
        XCTAssertTrue(result)
    }

    func test_morningBeforeAsr_eveningDhikrNotAvailable() {
        let now = date(hour: 9, minute: 0) // 9 AM
        let result = DailyGoalsHelpers.isEveningDhikrAvailable(
            now: now,
            todayPrayers: typicalPrayers
        )
        XCTAssertFalse(result)
    }

    // MARK: - Fallback (No Prayer Data)

    func test_noPrayerData_before5PM_notAvailable() {
        let now = date(hour: 16, minute: 59)
        let result = DailyGoalsHelpers.isEveningDhikrAvailable(
            now: now,
            todayPrayers: []
        )
        XCTAssertFalse(result)
    }

    func test_noPrayerData_at5PM_available() {
        let now = date(hour: 17, minute: 0)
        let result = DailyGoalsHelpers.isEveningDhikrAvailable(
            now: now,
            todayPrayers: []
        )
        XCTAssertTrue(result)
    }

    func test_noPrayerData_after5PM_available() {
        let now = date(hour: 20, minute: 0)
        let result = DailyGoalsHelpers.isEveningDhikrAvailable(
            now: now,
            todayPrayers: []
        )
        XCTAssertTrue(result)
    }

    // MARK: - Fallback Constant

    func test_fallbackHour_is17() {
        XCTAssertEqual(DailyGoalsHelpers.eveningFallbackHour, 17)
    }
}
