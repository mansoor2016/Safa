import XCTest
@testable import Safa

final class RamadanQadaReminderServiceTests: XCTestCase {

    private var defaults: UserDefaults!
    private let converter = HijriDateConverter.shared

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "RamadanQadaReminderTests")!
        defaults.removePersistentDomain(forName: "RamadanQadaReminderTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "RamadanQadaReminderTests")
        defaults = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Create a Gregorian Date from Hijri components.
    private func hijriDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return converter.gregorianDate(from: components)!
    }

    /// Store fasting days under the key RamadanView uses.
    private func storeFastingDays(_ days: [Int], gregorianYear: Int) {
        defaults.set(days, forKey: "ramadan_fasting_days_\(gregorianYear)")
    }

    /// Get the Gregorian year for a Hijri date.
    private func gregorianYear(hijriYear: Int, hijriMonth: Int, hijriDay: Int) -> Int {
        let date = hijriDate(year: hijriYear, month: hijriMonth, day: hijriDay)
        return Calendar(identifier: .gregorian).component(.year, from: date)
    }

    // MARK: - isEligibleDate

    func test_notEligible_shawwal1() {
        XCTAssertFalse(RamadanQadaReminderService.isEligibleDate(month: 10, day: 1))
    }

    func test_notEligible_shawwal3() {
        XCTAssertFalse(RamadanQadaReminderService.isEligibleDate(month: 10, day: 3))
    }

    func test_eligible_shawwal4() {
        XCTAssertTrue(RamadanQadaReminderService.isEligibleDate(month: 10, day: 4))
    }

    func test_eligible_shawwal15() {
        XCTAssertTrue(RamadanQadaReminderService.isEligibleDate(month: 10, day: 15))
    }

    func test_eligible_dhuAlQidah() {
        XCTAssertTrue(RamadanQadaReminderService.isEligibleDate(month: 11, day: 1))
    }

    func test_notEligible_ramadan() {
        XCTAssertFalse(RamadanQadaReminderService.isEligibleDate(month: 9, day: 15))
    }

    // MARK: - mostRecentRamadanYear

    func test_mostRecentRamadanYear_inShawwal() {
        // In Shawwal (month 10) of 1446, the most recent Ramadan is 1446
        XCTAssertEqual(
            RamadanQadaReminderService.mostRecentRamadanYear(currentHijriYear: 1446, currentHijriMonth: 10),
            1446
        )
    }

    func test_mostRecentRamadanYear_inMuharram() {
        // In Muharram (month 1) of 1447, the most recent Ramadan was 1446
        XCTAssertEqual(
            RamadanQadaReminderService.mostRecentRamadanYear(currentHijriYear: 1447, currentHijriMonth: 1),
            1446
        )
    }

    // MARK: - shouldShowReminder integration

    func test_doesNotShow_beforeShawwal4() {
        let currentHijriYear = converter.hijriComponents(from: Date()).year
        let shawwal2 = hijriDate(year: currentHijriYear, month: 10, day: 2)
        let gregYear = gregorianYear(hijriYear: currentHijriYear, hijriMonth: 9, hijriDay: 15)
        storeFastingDays(Array(1...20), gregorianYear: gregYear)

        let result = RamadanQadaReminderService.shouldShowReminder(
            now: shawwal2, defaults: defaults, hasCompletedOnboarding: true
        )
        XCTAssertNil(result)
    }

    func test_shows_afterShawwal4_whenCountBelow30() {
        let currentHijriYear = converter.hijriComponents(from: Date()).year
        let shawwal5 = hijriDate(year: currentHijriYear, month: 10, day: 5)
        let gregYear = gregorianYear(hijriYear: currentHijriYear, hijriMonth: 9, hijriDay: 15)
        storeFastingDays(Array(1...20), gregorianYear: gregYear)

        let result = RamadanQadaReminderService.shouldShowReminder(
            now: shawwal5, defaults: defaults, hasCompletedOnboarding: true
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.trackedDays, 20)
        XCTAssertEqual(result?.hijriYear, currentHijriYear, "Payload should carry the correct Ramadan Hijri year")
    }

    func test_shows_exactlyOnShawwal4() {
        let currentHijriYear = converter.hijriComponents(from: Date()).year
        let shawwal4 = hijriDate(year: currentHijriYear, month: 10, day: 4)
        let gregYear = gregorianYear(hijriYear: currentHijriYear, hijriMonth: 9, hijriDay: 15)
        storeFastingDays(Array(1...15), gregorianYear: gregYear)

        let result = RamadanQadaReminderService.shouldShowReminder(
            now: shawwal4, defaults: defaults, hasCompletedOnboarding: true
        )
        XCTAssertNotNil(result, "Should show on exactly Shawwal 4")
        XCTAssertEqual(result?.trackedDays, 15)
    }

    func test_shows_monthsLater_inDhuAlQidah() {
        let currentHijriYear = converter.hijriComponents(from: Date()).year
        let dhuAlQidah10 = hijriDate(year: currentHijriYear, month: 11, day: 10)
        let gregYear = gregorianYear(hijriYear: currentHijriYear, hijriMonth: 9, hijriDay: 15)
        storeFastingDays(Array(1...25), gregorianYear: gregYear)

        let result = RamadanQadaReminderService.shouldShowReminder(
            now: dhuAlQidah10, defaults: defaults, hasCompletedOnboarding: true
        )
        XCTAssertNotNil(result, "Should still show if user opens app months after Eid")
        XCTAssertEqual(result?.trackedDays, 25)
    }

    func test_duplicateDays_areDeduplicated() {
        let currentHijriYear = converter.hijriComponents(from: Date()).year
        let shawwal5 = hijriDate(year: currentHijriYear, month: 10, day: 5)
        let gregYear = gregorianYear(hijriYear: currentHijriYear, hijriMonth: 9, hijriDay: 15)
        // Duplicate entries: [1,1,2,2,3,3] should count as 3 unique days
        storeFastingDays([1, 1, 2, 2, 3, 3], gregorianYear: gregYear)

        let result = RamadanQadaReminderService.shouldShowReminder(
            now: shawwal5, defaults: defaults, hasCompletedOnboarding: true
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.trackedDays, 3, "Duplicate day entries should be deduplicated")
    }

    func test_doesNotShow_whenCountIs30() {
        let currentHijriYear = converter.hijriComponents(from: Date()).year
        let shawwal5 = hijriDate(year: currentHijriYear, month: 10, day: 5)
        let gregYear = gregorianYear(hijriYear: currentHijriYear, hijriMonth: 9, hijriDay: 15)
        storeFastingDays(Array(1...30), gregorianYear: gregYear)

        let result = RamadanQadaReminderService.shouldShowReminder(
            now: shawwal5, defaults: defaults, hasCompletedOnboarding: true
        )
        XCTAssertNil(result)
    }

    func test_doesNotShow_whenAlreadyShownForHijriYear() {
        let currentHijriYear = converter.hijriComponents(from: Date()).year
        let shawwal5 = hijriDate(year: currentHijriYear, month: 10, day: 5)
        let gregYear = gregorianYear(hijriYear: currentHijriYear, hijriMonth: 9, hijriDay: 15)
        storeFastingDays(Array(1...20), gregorianYear: gregYear)

        // Mark as already shown
        RamadanQadaReminderService.markShown(hijriYear: currentHijriYear, defaults: defaults)

        let result = RamadanQadaReminderService.shouldShowReminder(
            now: shawwal5, defaults: defaults, hasCompletedOnboarding: true
        )
        XCTAssertNil(result)
    }

    func test_doesNotShow_beforeOnboarding() {
        let currentHijriYear = converter.hijriComponents(from: Date()).year
        let shawwal5 = hijriDate(year: currentHijriYear, month: 10, day: 5)
        let gregYear = gregorianYear(hijriYear: currentHijriYear, hijriMonth: 9, hijriDay: 15)
        storeFastingDays(Array(1...20), gregorianYear: gregYear)

        let result = RamadanQadaReminderService.shouldShowReminder(
            now: shawwal5, defaults: defaults, hasCompletedOnboarding: false
        )
        XCTAssertNil(result)
    }

    func test_ignoresInvalidDayValues() {
        let currentHijriYear = converter.hijriComponents(from: Date()).year
        let shawwal5 = hijriDate(year: currentHijriYear, month: 10, day: 5)
        let gregYear = gregorianYear(hijriYear: currentHijriYear, hijriMonth: 9, hijriDay: 15)
        // Include invalid values: 0, 31, 50, negative
        storeFastingDays([0, -1, 1, 2, 3, 31, 50], gregorianYear: gregYear)

        let result = RamadanQadaReminderService.shouldShowReminder(
            now: shawwal5, defaults: defaults, hasCompletedOnboarding: true
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.trackedDays, 3, "Should only count valid days 1-30")
    }

    func test_doesNotShow_whenNoTrackingData() {
        let currentHijriYear = converter.hijriComponents(from: Date()).year
        let shawwal5 = hijriDate(year: currentHijriYear, month: 10, day: 5)
        // No fasting data stored

        let result = RamadanQadaReminderService.shouldShowReminder(
            now: shawwal5, defaults: defaults, hasCompletedOnboarding: true
        )
        XCTAssertNil(result)
    }

    func test_showsThenMarkShown_preventsReShowing() {
        let currentHijriYear = converter.hijriComponents(from: Date()).year
        let shawwal5 = hijriDate(year: currentHijriYear, month: 10, day: 5)
        let gregYear = gregorianYear(hijriYear: currentHijriYear, hijriMonth: 9, hijriDay: 15)
        storeFastingDays(Array(1...20), gregorianYear: gregYear)

        // First check: should show
        let first = RamadanQadaReminderService.shouldShowReminder(
            now: shawwal5, defaults: defaults, hasCompletedOnboarding: true
        )
        XCTAssertNotNil(first)

        // User taps "Got it" → mark shown
        RamadanQadaReminderService.markShown(hijriYear: first!.hijriYear, defaults: defaults)

        // Second check: should NOT show again
        let second = RamadanQadaReminderService.shouldShowReminder(
            now: shawwal5, defaults: defaults, hasCompletedOnboarding: true
        )
        XCTAssertNil(second, "Reminder must not re-appear after being dismissed")
    }

    func test_shownForPreviousYear_stillShowsForNewYear() {
        let currentHijriYear = converter.hijriComponents(from: Date()).year
        let gregYear = gregorianYear(hijriYear: currentHijriYear, hijriMonth: 9, hijriDay: 15)
        storeFastingDays(Array(1...20), gregorianYear: gregYear)

        // Mark shown for PREVIOUS year
        RamadanQadaReminderService.markShown(hijriYear: currentHijriYear - 1, defaults: defaults)

        // Check for current year: should still show
        let shawwal5 = hijriDate(year: currentHijriYear, month: 10, day: 5)
        let result = RamadanQadaReminderService.shouldShowReminder(
            now: shawwal5, defaults: defaults, hasCompletedOnboarding: true
        )
        XCTAssertNotNil(result, "Shown state from previous Hijri year should not block current year")
    }

    // MARK: - markShown

    func test_markShown_persistsYear() {
        RamadanQadaReminderService.markShown(hijriYear: 1446, defaults: defaults)
        XCTAssertEqual(
            defaults.integer(forKey: AppConstants.StorageKeys.qadaReminderShownHijriYear),
            1446
        )
    }
}
