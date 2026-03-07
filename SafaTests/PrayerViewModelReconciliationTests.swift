// MARK: - PrayerViewModelReconciliationTests.swift
// PURPOSE: Tests for widget→app prayer log reconciliation in PrayerViewModel
// DEPENDENCIES: XCTest, CoreLocation, SafaShared, Safa

import XCTest
import CoreLocation
import SafaShared
@testable import Safa

@MainActor
final class PrayerViewModelReconciliationTests: XCTestCase {

    private var mockUserState: UserStateManager!
    private var mockUserRepository: PrayerTestMockUserRepository!

    override func setUp() {
        super.setUp()
        mockUserRepository = PrayerTestMockUserRepository()
        mockUserState = UserStateManager(userRepository: mockUserRepository)
    }

    override func tearDown() {
        mockUserState = nil
        mockUserRepository = nil
        super.tearDown()
    }

    // MARK: - Happy Path

    func test_loadPrayerTimes_reconcilesWidgetLoggedPrayers() async {
        // Given — a WidgetDataService backed by a test-specific UserDefaults
        let testSuiteName = "group.com.safa.app.test.reconcile.\(UUID().uuidString)"
        let testWidgetDataService = WidgetDataService(suiteName: testSuiteName)
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        defer { testDefaults.removePersistentDomain(forName: testSuiteName) }

        let repo = PersistingTestablePrayerRepository()
        let locationService = TestableLocationService()
        locationService.locationToReturn = CLLocation(latitude: 51.5074, longitude: -0.1278)
        repo.prayersToReturn = createMockPrayers()

        let vm = PrayerViewModel(
            prayerRepository: repo,
            locationService: locationService,
            userState: mockUserState,
            widgetDataService: testWidgetDataService
        )

        // Simulate widget intent logging fajr directly to App Group key
        let dateKey = WidgetAppGroupKeys.loggedPrayersKey(for: Date())
        testDefaults.set(["fajr"], forKey: dateKey)

        // When — first load reconciles widget log into repo
        await vm.loadPrayerTimes()

        // Then — fajr should be reconciled into loggedPrayers and persisted to repo
        XCTAssertTrue(vm.loggedPrayers.contains(.fajr),
                       "Widget-logged prayer should be reconciled into loggedPrayers")
        XCTAssertTrue(repo.logPrayerCalled,
                       "Reconciliation should persist widget-logged prayer to repository")

        // Verify persistence survives reload: clear widget key, reload, prayer should come from repo
        testDefaults.removeObject(forKey: dateKey)
        await vm.loadPrayerTimes()
        XCTAssertTrue(vm.loggedPrayers.contains(.fajr),
                       "Reconciled prayer should survive reload via repository persistence")
    }

    // MARK: - Failure Path

    func test_loadPrayerTimes_widgetLogSurvivesRepoFailure() async {
        // Given — repo will throw on logPrayer, so reconciliation should NOT insert into loggedPrayers
        let testSuiteName = "group.com.safa.app.test.reconcile.fail.\(UUID().uuidString)"
        let testWidgetDataService = WidgetDataService(suiteName: testSuiteName)
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        defer { testDefaults.removePersistentDomain(forName: testSuiteName) }

        let repo = TestablePrayerRepository()
        let locationService = TestableLocationService()
        locationService.locationToReturn = CLLocation(latitude: 51.5074, longitude: -0.1278)
        repo.prayersToReturn = createMockPrayers()

        let vm = PrayerViewModel(
            prayerRepository: repo,
            locationService: locationService,
            userState: mockUserState,
            widgetDataService: testWidgetDataService
        )

        // Simulate widget intent logging dhuhr directly to App Group key
        let dateKey = WidgetAppGroupKeys.loggedPrayersKey(for: Date())
        testDefaults.set(["dhuhr"], forKey: dateKey)

        // Make repo throw on logPrayer (after getPrayers succeeds)
        repo.logPrayerErrorToThrow = PrayerTestError.logFailed

        // When
        await vm.loadPrayerTimes()

        // Then — loggedPrayers should NOT contain dhuhr (no in-memory/persistence mismatch)
        XCTAssertFalse(vm.loggedPrayers.contains(.dhuhr),
                        "Failed reconciliation must not insert into loggedPrayers")

        // Widget key should still contain "dhuhr" for retry on next load.
        // reconcileWidgetLoggedPrayers returns failed IDs; writeLoggedPrayers includes
        // them in the overwrite so they survive for retry on next load.
        let widgetLogged = testDefaults.stringArray(forKey: dateKey) ?? []
        XCTAssertTrue(widgetLogged.contains("dhuhr"),
                       "Widget key should retain failed ID for retry on next load")
    }

    // MARK: - Full Retry Loop

    func test_loadPrayerTimes_widgetLogRetrySucceedsOnSecondLoad() async {
        // Tests the full retry contract: first load fails to persist a widget-logged prayer,
        // second load succeeds — the retained widget key is reconciled and persisted.
        let testSuiteName = "group.com.safa.app.test.reconcile.retry.\(UUID().uuidString)"
        let testWidgetDataService = WidgetDataService(suiteName: testSuiteName)
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        defer { testDefaults.removePersistentDomain(forName: testSuiteName) }

        let repo = PersistingTestablePrayerRepository()
        let locationService = TestableLocationService()
        locationService.locationToReturn = CLLocation(latitude: 51.5074, longitude: -0.1278)
        repo.prayersToReturn = createMockPrayers()

        let vm = PrayerViewModel(
            prayerRepository: repo,
            locationService: locationService,
            userState: mockUserState,
            widgetDataService: testWidgetDataService
        )

        // Simulate widget intent logging asr directly to App Group key
        let dateKey = WidgetAppGroupKeys.loggedPrayersKey(for: Date())
        testDefaults.set(["asr"], forKey: dateKey)

        // First load: repo throws on logPrayer → reconciliation fails, widget key retained
        repo.logPrayerErrorToThrow = PrayerTestError.logFailed
        await vm.loadPrayerTimes()

        XCTAssertFalse(vm.loggedPrayers.contains(.asr),
                        "First load: failed reconciliation must not insert into loggedPrayers")
        XCTAssertTrue((testDefaults.stringArray(forKey: dateKey) ?? []).contains("asr"),
                       "First load: widget key should retain failed ID for retry")

        // Second load: repo succeeds → widget key is reconciled and persisted
        repo.logPrayerErrorToThrow = nil
        await vm.loadPrayerTimes()

        XCTAssertTrue(vm.loggedPrayers.contains(.asr),
                       "Second load: retry should succeed and add prayer to loggedPrayers")
        XCTAssertTrue(repo.logPrayerCalled,
                       "Second load: retry should persist to repository")

        // Verify the prayer is now in the authoritative repo-backed set:
        // clear the widget key and reload — prayer should survive via repo persistence
        testDefaults.removeObject(forKey: dateKey)
        await vm.loadPrayerTimes()

        XCTAssertTrue(vm.loggedPrayers.contains(.asr),
                       "Third load: reconciled prayer should survive from repository after widget key cleared")
    }

    // MARK: - Day Rollover

    func test_loadPrayerTimes_reconcilesYesterdayWidgetLog() async {
        // Verifies that a prayer logged from the widget just before midnight
        // is reconciled when the app opens the next day.
        let testSuiteName = "group.com.safa.app.test.reconcile.rollover.\(UUID().uuidString)"
        let testWidgetDataService = WidgetDataService(suiteName: testSuiteName)
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        defer { testDefaults.removePersistentDomain(forName: testSuiteName) }

        let repo = PersistingTestablePrayerRepository()
        let locationService = TestableLocationService()
        locationService.locationToReturn = CLLocation(latitude: 51.5074, longitude: -0.1278)
        repo.prayersToReturn = createMockPrayers()

        let vm = PrayerViewModel(
            prayerRepository: repo,
            locationService: locationService,
            userState: mockUserState,
            widgetDataService: testWidgetDataService
        )

        // Simulate widget logging isha under yesterday's date key (tap just before midnight)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayKey = WidgetAppGroupKeys.loggedPrayersKey(for: yesterday)
        testDefaults.set(["isha"], forKey: yesterdayKey)

        // When — app opens today, loadPrayerTimes should reconcile yesterday's key too
        await vm.loadPrayerTimes()

        // Then — isha should be persisted to the repository under yesterday's date
        XCTAssertTrue(repo.logPrayerCalled,
                       "Yesterday's widget log should be reconciled into repository")

        // Verify the logPrayer call used yesterday's date, not today's
        XCTAssertNotNil(repo.lastLoggedForDate)
        if let loggedDate = repo.lastLoggedForDate {
            XCTAssertTrue(Calendar.current.isDate(loggedDate, inSameDayAs: yesterday),
                           "logPrayer should be called with yesterday's date, got \(loggedDate)")
        }

        // Yesterday's prayer must NOT appear in today's loggedPrayers set
        XCTAssertFalse(vm.loggedPrayers.contains(.isha),
                        "Yesterday's reconciled prayer must not pollute today's loggedPrayers")

        // Yesterday's widget key should be cleared after successful reconciliation
        // to prevent redundant logPrayer calls on every subsequent app open
        XCTAssertNil(testDefaults.object(forKey: yesterdayKey),
                      "Yesterday's widget key should be cleared after successful reconciliation")
    }

    // MARK: - Mixed Success/Failure Yesterday

    func test_loadPrayerTimes_yesterdayMixedSuccessRetainsFailedIds() async {
        // When yesterday's widget key has two prayers and only one persists successfully,
        // the key should be retained (not cleared) so the failed ID retries on next load.
        // The succeeded ID will be re-attempted on the next load (idempotent in PrayerRepository).
        let testSuiteName = "group.com.safa.app.test.reconcile.mixed.\(UUID().uuidString)"
        let testWidgetDataService = WidgetDataService(suiteName: testSuiteName)
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        defer { testDefaults.removePersistentDomain(forName: testSuiteName) }

        let repo = PersistingTestablePrayerRepository()
        let locationService = TestableLocationService()
        locationService.locationToReturn = CLLocation(latitude: 51.5074, longitude: -0.1278)
        repo.prayersToReturn = createMockPrayers()

        let vm = PrayerViewModel(
            prayerRepository: repo,
            locationService: locationService,
            userState: mockUserState,
            widgetDataService: testWidgetDataService
        )

        // Simulate widget logging fajr + dhuhr under yesterday's key
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayKey = WidgetAppGroupKeys.loggedPrayersKey(for: yesterday)
        testDefaults.set(["fajr", "dhuhr"], forKey: yesterdayKey)

        // Make logPrayer fail only for dhuhr — fajr should succeed
        repo.logPrayerErrorToThrow = PrayerTestError.logFailed
        repo.logPrayerFailForTypes = [.dhuhr]

        await vm.loadPrayerTimes()

        // Fajr should have been persisted (logPrayer succeeded)
        XCTAssertTrue(repo.logPrayerCalled,
                       "Fajr should have been persisted to repository")

        // Yesterday's key should NOT be cleared — dhuhr still needs retry
        let remainingIds = testDefaults.stringArray(forKey: yesterdayKey) ?? []
        XCTAssertFalse(remainingIds.isEmpty,
                        "Yesterday's key must be retained when any ID failed reconciliation")

        // Neither yesterday prayer should appear in today's loggedPrayers
        XCTAssertFalse(vm.loggedPrayers.contains(.fajr),
                        "Yesterday's fajr must not appear in today's loggedPrayers")
        XCTAssertFalse(vm.loggedPrayers.contains(.dhuhr),
                        "Yesterday's failed dhuhr must not appear in today's loggedPrayers")
    }

    // MARK: - Idempotent Reconciliation

    func test_loadPrayerTimes_doesNotDuplicateAlreadyPersistedPrayer() async {
        // If a prayer exists in both the repo and the widget key,
        // reconciliation should be a no-op — no duplicate logPrayer call.
        let testSuiteName = "group.com.safa.app.test.reconcile.idempotent.\(UUID().uuidString)"
        let testWidgetDataService = WidgetDataService(suiteName: testSuiteName)
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        defer { testDefaults.removePersistentDomain(forName: testSuiteName) }

        let repo = PersistingTestablePrayerRepository()
        let locationService = TestableLocationService()
        locationService.locationToReturn = CLLocation(latitude: 51.5074, longitude: -0.1278)
        repo.prayersToReturn = createMockPrayers()

        // Pre-populate repo with fajr already logged (simulates prior app-side log)
        let existingLog = PrayerLog(prayerType: .fajr, date: Date(), loggedAt: Date(), isOnTime: true)
        repo.prayerLogsToReturn = [existingLog]

        let vm = PrayerViewModel(
            prayerRepository: repo,
            locationService: locationService,
            userState: mockUserState,
            widgetDataService: testWidgetDataService
        )

        // Widget key also contains "fajr" (from an earlier widget tap)
        let dateKey = WidgetAppGroupKeys.loggedPrayersKey(for: Date())
        testDefaults.set(["fajr"], forKey: dateKey)

        await vm.loadPrayerTimes()

        // logPrayer should NOT have been called — fajr was already in loggedPrayers from repo
        XCTAssertEqual(repo.logPrayerCallCount, 0,
                        "Reconciliation must not call logPrayer for already-persisted prayers")
        XCTAssertTrue(vm.loggedPrayers.contains(.fajr),
                       "Fajr should remain in loggedPrayers from repo")
    }

    // MARK: - Tap Timestamp

    func test_reconciliation_usesWidgetTapTimestamp() async {
        // Verifies that reconciliation reads the widget tap timestamp
        // instead of using Date() for the logged-at time.
        let testSuiteName = "group.com.safa.app.test.reconcile.timestamp.\(UUID().uuidString)"
        let testWidgetDataService = WidgetDataService(suiteName: testSuiteName)
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        defer { testDefaults.removePersistentDomain(forName: testSuiteName) }

        let repo = PersistingTestablePrayerRepository()
        let locationService = TestableLocationService()
        locationService.locationToReturn = CLLocation(latitude: 51.5074, longitude: -0.1278)
        repo.prayersToReturn = createMockPrayers()

        let vm = PrayerViewModel(
            prayerRepository: repo,
            locationService: locationService,
            userState: mockUserState,
            widgetDataService: testWidgetDataService
        )

        // Simulate widget logging fajr with a specific tap timestamp
        let dateKey = WidgetAppGroupKeys.loggedPrayersKey(for: Date())
        testDefaults.set(["fajr"], forKey: dateKey)
        let tapTime = Date().addingTimeInterval(-600) // 10 minutes ago
        let timestampKey = WidgetAppGroupKeys.widgetLogTimestampKey(for: "fajr", date: Date())
        testDefaults.set(tapTime, forKey: timestampKey)

        await vm.loadPrayerTimes()

        // Verify the persisted log uses the tap timestamp, not Date()
        let log = repo.prayerLogsToReturn.first { $0.prayerType == .fajr }
        XCTAssertNotNil(log, "Fajr should be reconciled")
        // loggedAt should be close to tapTime (within 1 second tolerance)
        if let loggedAt = log?.loggedAt {
            XCTAssertEqual(loggedAt.timeIntervalSince1970, tapTime.timeIntervalSince1970, accuracy: 1.0,
                           "loggedAt should use widget tap timestamp, not reconciliation time")
        }
    }
}
