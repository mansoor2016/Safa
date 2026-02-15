import XCTest
@testable import Safa

@MainActor
final class PrayerSettingsActionHandlerTests: XCTestCase {

    // MARK: - Mocks

    final class MockPrefsSaver: PrayerPreferencesSaving {
        private(set) var savedMethods: [CalculationMethod] = []
        private(set) var savedMadhabs: [Madhab] = []
        private(set) var savedLocationSettings: [(method: CalculationMethod, madhab: Madhab, language: String)] = []
        private(set) var callOrder: [String] = []

        func saveCalculationMethod(_ method: CalculationMethod) async {
            savedMethods.append(method)
            callOrder.append("saveMethod")
        }

        func saveMadhab(_ madhab: Madhab) async {
            savedMadhabs.append(madhab)
            callOrder.append("saveMadhab")
        }

        func saveLocationSettings(method: CalculationMethod, madhab: Madhab, language: String) async {
            savedLocationSettings.append((method, madhab, language))
            callOrder.append("saveLocationSettings")
        }
    }

    final class MockScheduler: NotificationScheduling {
        var authorizationResult = true
        private(set) var forceRescheduleCallCount = 0
        private(set) var callOrder: [String] = []

        func requestAuthorization() async -> Bool {
            callOrder.append("requestAuth")
            return authorizationResult
        }

        func forceReschedule() async {
            forceRescheduleCallCount += 1
            callOrder.append("forceReschedule")
        }
    }

    final class MockLiveActivity: LiveActivityManaging {
        private(set) var ensureCallCount = 0
        private(set) var callOrder: [String] = []

        func ensureActivityIfNeeded() async {
            ensureCallCount += 1
            callOrder.append("ensureActivity")
        }
    }

    // MARK: - applyPrayerSettings: method changed

    func test_applyPrayerSettings_methodChanged_savesMethodAndReschedules() async {
        let saver = MockPrefsSaver()
        let scheduler = MockScheduler()
        let liveActivity = MockLiveActivity()

        await PrayerSettingsActionHandler.applyPrayerSettings(
            method: .isna,
            madhab: .hanafi,
            current: (method: .muslimWorldLeague, madhab: .hanafi),
            preferenceSaver: saver,
            scheduler: scheduler,
            liveActivity: liveActivity
        )

        XCTAssertEqual(saver.savedMethods, [.isna])
        XCTAssertTrue(saver.savedMadhabs.isEmpty)
        XCTAssertEqual(scheduler.forceRescheduleCallCount, 1)
        XCTAssertEqual(liveActivity.ensureCallCount, 1)
    }

    // MARK: - applyPrayerSettings: madhab changed

    func test_applyPrayerSettings_madhabChanged_savesMadhabAndReschedules() async {
        let saver = MockPrefsSaver()
        let scheduler = MockScheduler()
        let liveActivity = MockLiveActivity()

        await PrayerSettingsActionHandler.applyPrayerSettings(
            method: .muslimWorldLeague,
            madhab: .shafi,
            current: (method: .muslimWorldLeague, madhab: .hanafi),
            preferenceSaver: saver,
            scheduler: scheduler,
            liveActivity: liveActivity
        )

        XCTAssertTrue(saver.savedMethods.isEmpty)
        XCTAssertEqual(saver.savedMadhabs, [.shafi])
        XCTAssertEqual(scheduler.forceRescheduleCallCount, 1)
        XCTAssertEqual(liveActivity.ensureCallCount, 1)
    }

    // MARK: - applyPrayerSettings: both changed

    func test_applyPrayerSettings_bothChanged_savesBothWithSingleReschedule() async {
        let saver = MockPrefsSaver()
        let scheduler = MockScheduler()
        let liveActivity = MockLiveActivity()

        await PrayerSettingsActionHandler.applyPrayerSettings(
            method: .isna,
            madhab: .shafi,
            current: (method: .muslimWorldLeague, madhab: .hanafi),
            preferenceSaver: saver,
            scheduler: scheduler,
            liveActivity: liveActivity
        )

        XCTAssertEqual(saver.savedMethods, [.isna])
        XCTAssertEqual(saver.savedMadhabs, [.shafi])
        // Only one reschedule + one liveActivity call
        XCTAssertEqual(scheduler.forceRescheduleCallCount, 1)
        XCTAssertEqual(liveActivity.ensureCallCount, 1)
    }

    // MARK: - applyPrayerSettings: no-op guard

    func test_applyPrayerSettings_nothingChanged_noSideEffects() async {
        let saver = MockPrefsSaver()
        let scheduler = MockScheduler()
        let liveActivity = MockLiveActivity()

        await PrayerSettingsActionHandler.applyPrayerSettings(
            method: .muslimWorldLeague,
            madhab: .hanafi,
            current: (method: .muslimWorldLeague, madhab: .hanafi),
            preferenceSaver: saver,
            scheduler: scheduler,
            liveActivity: liveActivity
        )

        XCTAssertTrue(saver.savedMethods.isEmpty)
        XCTAssertTrue(saver.savedMadhabs.isEmpty)
        XCTAssertEqual(scheduler.forceRescheduleCallCount, 0)
        XCTAssertEqual(liveActivity.ensureCallCount, 0)
    }

    // MARK: - applyPrayerSettings: call ordering

    func test_applyPrayerSettings_savesCompleteBeforeReschedule() async {
        let saver = MockPrefsSaver()
        let scheduler = MockScheduler()
        let liveActivity = MockLiveActivity()

        await PrayerSettingsActionHandler.applyPrayerSettings(
            method: .isna,
            madhab: .shafi,
            current: (method: .muslimWorldLeague, madhab: .hanafi),
            preferenceSaver: saver,
            scheduler: scheduler,
            liveActivity: liveActivity
        )

        // Saves happen before reschedule and live activity
        XCTAssertEqual(saver.callOrder, ["saveMethod", "saveMadhab"])
        XCTAssertEqual(scheduler.callOrder, ["forceReschedule"])
        XCTAssertEqual(liveActivity.callOrder, ["ensureActivity"])
    }

    // MARK: - applyRecommendations: changed values

    func test_applyRecommendations_valuesChanged_savesAllAndReschedules() async {
        let saver = MockPrefsSaver()
        let scheduler = MockScheduler()
        let liveActivity = MockLiveActivity()

        await PrayerSettingsActionHandler.applyRecommendations(
            method: .isna,
            madhab: .hanafi,
            language: "Arabic",
            current: (method: .muslimWorldLeague, madhab: .hanafi, language: "English"),
            preferenceSaver: saver,
            scheduler: scheduler,
            liveActivity: liveActivity
        )

        XCTAssertEqual(saver.savedLocationSettings.count, 1)
        XCTAssertEqual(saver.savedLocationSettings[0].method, .isna)
        XCTAssertEqual(saver.savedLocationSettings[0].language, "Arabic")
        XCTAssertEqual(scheduler.forceRescheduleCallCount, 1)
        XCTAssertEqual(liveActivity.ensureCallCount, 1)
    }

    // MARK: - applyRecommendations: no-op guard

    func test_applyRecommendations_nothingChanged_noSideEffects() async {
        let saver = MockPrefsSaver()
        let scheduler = MockScheduler()
        let liveActivity = MockLiveActivity()

        await PrayerSettingsActionHandler.applyRecommendations(
            method: .muslimWorldLeague,
            madhab: .hanafi,
            language: "English",
            current: (method: .muslimWorldLeague, madhab: .hanafi, language: "English"),
            preferenceSaver: saver,
            scheduler: scheduler,
            liveActivity: liveActivity
        )

        XCTAssertTrue(saver.savedLocationSettings.isEmpty)
        XCTAssertEqual(scheduler.forceRescheduleCallCount, 0)
        XCTAssertEqual(liveActivity.ensureCallCount, 0)
    }

    // MARK: - applyRecommendations: only language changed

    func test_applyRecommendations_onlyLanguageChanged_stillSavesAndReschedules() async {
        let saver = MockPrefsSaver()
        let scheduler = MockScheduler()
        let liveActivity = MockLiveActivity()

        await PrayerSettingsActionHandler.applyRecommendations(
            method: .muslimWorldLeague,
            madhab: .hanafi,
            language: "Arabic",
            current: (method: .muslimWorldLeague, madhab: .hanafi, language: "English"),
            preferenceSaver: saver,
            scheduler: scheduler,
            liveActivity: liveActivity
        )

        XCTAssertEqual(saver.savedLocationSettings.count, 1)
        XCTAssertEqual(saver.savedLocationSettings[0].language, "Arabic")
        XCTAssertEqual(scheduler.forceRescheduleCallCount, 1)
        XCTAssertEqual(liveActivity.ensureCallCount, 1)
    }

    // MARK: - Regression: current language must be captured BEFORE state update

    func test_applyRecommendations_sameLanguageAsCurrent_isNoOp() async {
        // Regression: if the View passes the NEW language as both `language` and `current.language`,
        // the handler sees no diff and skips the save. This verifies the no-op guard works,
        // which is the failure mode when language is NOT captured before the state update.
        let saver = MockPrefsSaver()
        let scheduler = MockScheduler()
        let liveActivity = MockLiveActivity()

        await PrayerSettingsActionHandler.applyRecommendations(
            method: .muslimWorldLeague,
            madhab: .hanafi,
            language: "Arabic",
            current: (method: .muslimWorldLeague, madhab: .hanafi, language: "Arabic"),
            preferenceSaver: saver,
            scheduler: scheduler,
            liveActivity: liveActivity
        )

        // If current == new for ALL fields, nothing should be saved
        XCTAssertTrue(saver.savedLocationSettings.isEmpty,
            "When current.language == language, no save should occur — this is the broken case " +
            "when View fails to capture previousLanguage before updating state")
        XCTAssertEqual(scheduler.forceRescheduleCallCount, 0)
    }

    func test_applyRecommendations_languageDiffers_savesNewLanguage() async {
        // Companion to the above: when current.language != language, save MUST occur.
        // Together these two tests prove the handler correctly detects language-only changes.
        let saver = MockPrefsSaver()
        let scheduler = MockScheduler()
        let liveActivity = MockLiveActivity()

        await PrayerSettingsActionHandler.applyRecommendations(
            method: .muslimWorldLeague,
            madhab: .hanafi,
            language: "Urdu",
            current: (method: .muslimWorldLeague, madhab: .hanafi, language: "English"),
            preferenceSaver: saver,
            scheduler: scheduler,
            liveActivity: liveActivity
        )

        XCTAssertEqual(saver.savedLocationSettings.count, 1)
        XCTAssertEqual(saver.savedLocationSettings[0].language, "Urdu",
            "New language must be persisted when it differs from current")
        XCTAssertEqual(scheduler.forceRescheduleCallCount, 1)
    }
}
