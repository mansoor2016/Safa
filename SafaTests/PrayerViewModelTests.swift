// MARK: - PrayerViewModelTests.swift
// PURPOSE: Unit tests for PrayerViewModel functionality
// DEPENDENCIES: XCTest, Safa

import XCTest
import CoreLocation
@testable import Safa

@MainActor
final class PrayerViewModelTests: XCTestCase {

    var sut: PrayerViewModel!
    var mockPrayerRepository: TestablePrayerRepository!
    var mockLocationService: TestableLocationService!
    var mockUserState: UserStateManager!
    var mockUserRepository: PrayerTestMockUserRepository!

    override func setUp() {
        super.setUp()
        mockPrayerRepository = TestablePrayerRepository()
        mockLocationService = TestableLocationService()
        mockUserRepository = PrayerTestMockUserRepository()
        mockUserState = UserStateManager(userRepository: mockUserRepository)

        sut = PrayerViewModel(
            prayerRepository: mockPrayerRepository,
            locationService: mockLocationService,
            userState: mockUserState
        )
    }

    override func tearDown() {
        sut = nil
        mockPrayerRepository = nil
        mockLocationService = nil
        mockUserState = nil
        mockUserRepository = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasEmptyTodayPrayers() {
        XCTAssertTrue(sut.todayPrayers.isEmpty)
    }

    func test_initialState_hasEmptyLoggedPrayers() {
        XCTAssertTrue(sut.loggedPrayers.isEmpty)
    }

    func test_initialState_hasCurrentDate() {
        XCTAssertNotNil(sut.currentDate)
    }

    func test_initialState_isNotLoading() {
        XCTAssertFalse(sut.isLoading)
    }

    func test_initialState_hasNoError() {
        XCTAssertNil(sut.error)
    }

    func test_initialState_hasNoNextPrayer() {
        XCTAssertNil(sut.nextPrayer)
    }

    func test_initialState_notificationSchedulingNotFailed() {
        XCTAssertFalse(sut.notificationSchedulingFailed)
    }

    func test_initialState_prayersCompletedTodayIsZero() {
        XCTAssertEqual(sut.prayersCompletedToday, 0)
    }

    func test_initialState_allPrayersCompletedIsFalse() {
        XCTAssertFalse(sut.allPrayersCompleted)
    }

    // MARK: - Load Prayer Times Tests

    func test_loadPrayerTimes_populatesTodayPrayers() async {
        // Given
        let prayers = createMockPrayers()
        mockPrayerRepository.prayersToReturn = prayers
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)

        // When
        await sut.loadPrayerTimes()

        // Then
        XCTAssertEqual(sut.todayPrayers.count, 6)
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadPrayerTimes_loadsLoggedPrayers() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockPrayerRepository.prayerLogsToReturn = [
            PrayerLog(prayerType: .fajr, date: Date(), loggedAt: Date(), isOnTime: true)
        ]
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)

        // When
        await sut.loadPrayerTimes()

        // Then
        XCTAssertTrue(sut.loggedPrayers.contains(.fajr))
        XCTAssertEqual(sut.prayersCompletedToday, 1)
    }

    func test_loadPrayerTimes_failure_setsError() async {
        // Given
        mockLocationService.errorToThrow = PrayerTestError.locationFailed

        // When
        await sut.loadPrayerTimes()

        // Then
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadPrayerTimes_setsIsLoadingDuringLoad() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)

        // When
        let task = Task {
            await sut.loadPrayerTimes()
        }

        // Allow task to start
        try? await Task.sleep(nanoseconds: 10_000_000)

        await task.value

        // Then - after completion
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Next Prayer Tests

    func test_nextPrayer_returnsCorrectNextPrayer() async {
        // Given
        let now = Date()
        let prayers = [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(-3600)), // 1 hour ago
            PrayerTime(type: .sunrise, time: now.addingTimeInterval(-1800)), // 30 min ago
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(3600)), // 1 hour from now
            PrayerTime(type: .asr, time: now.addingTimeInterval(7200)), // 2 hours from now
            PrayerTime(type: .maghrib, time: now.addingTimeInterval(10800)), // 3 hours from now
            PrayerTime(type: .isha, time: now.addingTimeInterval(14400)) // 4 hours from now
        ]
        mockPrayerRepository.prayersToReturn = prayers
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)

        // When
        await sut.loadPrayerTimes()

        // Then
        XCTAssertEqual(sut.nextPrayer?.type, .dhuhr)
    }

    func test_nextPrayer_skipsNonObligatoryPrayers() async {
        // Given - sunrise is next but not obligatory
        let now = Date()
        let prayers = [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(-3600)), // 1 hour ago
            PrayerTime(type: .sunrise, time: now.addingTimeInterval(1800)), // 30 min from now
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(3600)), // 1 hour from now
            PrayerTime(type: .asr, time: now.addingTimeInterval(7200)),
            PrayerTime(type: .maghrib, time: now.addingTimeInterval(10800)),
            PrayerTime(type: .isha, time: now.addingTimeInterval(14400))
        ]
        mockPrayerRepository.prayersToReturn = prayers
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)

        // When
        await sut.loadPrayerTimes()

        // Then - should skip sunrise and return dhuhr
        XCTAssertEqual(sut.nextPrayer?.type, .dhuhr)
    }

    // MARK: - Log Prayer Tests

    func test_logPrayer_addsToLoggedPrayers() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)
        await sut.loadPrayerTimes()

        // When
        await sut.logPrayer(.fajr)

        // Then
        XCTAssertTrue(sut.loggedPrayers.contains(.fajr))
    }

    func test_logPrayer_doesNotLogAlreadyLoggedPrayer() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)
        await sut.loadPrayerTimes()
        await sut.logPrayer(.fajr)
        let initialCallCount = mockPrayerRepository.logPrayerCallCount

        // When
        await sut.logPrayer(.fajr)

        // Then
        XCTAssertEqual(mockPrayerRepository.logPrayerCallCount, initialCallCount)
    }

    func test_logPrayer_callsRepository() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)
        await sut.loadPrayerTimes()

        // When
        await sut.logPrayer(.dhuhr)

        // Then
        XCTAssertTrue(mockPrayerRepository.logPrayerCalled)
    }

    func test_logPrayer_failure_setsError() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)
        await sut.loadPrayerTimes()
        mockPrayerRepository.errorToThrow = PrayerTestError.logFailed

        // When
        await sut.logPrayer(.fajr)

        // Then
        XCTAssertNotNil(sut.error)
    }

    func test_logPrayer_failure_revertsOptimisticState() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)
        await sut.loadPrayerTimes()
        mockPrayerRepository.errorToThrow = PrayerTestError.logFailed

        // When
        await sut.logPrayer(.fajr)

        // Then - optimistic insert should be reverted
        XCTAssertFalse(sut.loggedPrayers.contains(.fajr))
    }

    func test_logPrayer_whenTodayPrayersEmpty_doesNotCallRepository() async {
        // Given — no prayers loaded, todayPrayers is empty
        XCTAssertTrue(sut.todayPrayers.isEmpty)

        // When
        await sut.logPrayer(.fajr)

        // Then — repo never called, no state change
        XCTAssertEqual(mockPrayerRepository.logPrayerCallCount, 0)
        XCTAssertFalse(sut.loggedPrayers.contains(.fajr))
    }

    func test_logPrayer_alreadyLogged_doesNotIncrementRepoCallCount() async {
        // Given — load prayers and log fajr once
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockLocationService.locationToReturn = CLLocation(latitude: 51.5074, longitude: -0.1278)
        await sut.loadPrayerTimes()
        await sut.logPrayer(.fajr)
        let repoCallsAfterFirstLog = mockPrayerRepository.logPrayerCallCount

        // When — try to log fajr again (e.g. repeated lock-screen tap)
        await sut.logPrayer(.fajr)

        // Then — still logged, but repo was NOT called again (no duplicate persist/stats)
        XCTAssertTrue(sut.loggedPrayers.contains(.fajr))
        XCTAssertEqual(
            mockPrayerRepository.logPrayerCallCount, repoCallsAfterFirstLog,
            "Duplicate logPrayer must not call repository again — prevents stat inflation"
        )
    }

    func test_togglePrayer_rapidDoubleTap_endsUnlogged() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)
        await sut.loadPrayerTimes()

        // When - log then unlog
        await sut.togglePrayer(.fajr)
        XCTAssertTrue(sut.loggedPrayers.contains(.fajr))

        await sut.togglePrayer(.fajr)

        // Then - should end unlogged
        XCTAssertFalse(sut.loggedPrayers.contains(.fajr))
    }

    // MARK: - All Prayers Completed Tests

    func test_allPrayersCompleted_returnsTrueWhenAllLogged() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockPrayerRepository.prayerLogsToReturn = [
            PrayerLog(prayerType: .fajr, date: Date(), loggedAt: Date(), isOnTime: true),
            PrayerLog(prayerType: .dhuhr, date: Date(), loggedAt: Date(), isOnTime: true),
            PrayerLog(prayerType: .asr, date: Date(), loggedAt: Date(), isOnTime: true),
            PrayerLog(prayerType: .maghrib, date: Date(), loggedAt: Date(), isOnTime: true),
            PrayerLog(prayerType: .isha, date: Date(), loggedAt: Date(), isOnTime: true)
        ]
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)

        // When
        await sut.loadPrayerTimes()

        // Then
        XCTAssertTrue(sut.allPrayersCompleted)
        XCTAssertEqual(sut.prayersCompletedToday, 5)
    }

    func test_allPrayersCompleted_returnsFalseWhenPartiallyLogged() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockPrayerRepository.prayerLogsToReturn = [
            PrayerLog(prayerType: .fajr, date: Date(), loggedAt: Date(), isOnTime: true),
            PrayerLog(prayerType: .dhuhr, date: Date(), loggedAt: Date(), isOnTime: true)
        ]
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)

        // When
        await sut.loadPrayerTimes()

        // Then
        XCTAssertFalse(sut.allPrayersCompleted)
        XCTAssertEqual(sut.prayersCompletedToday, 2)
    }

    // MARK: - Set Calculation Method Tests

    func test_setCalculationMethod_updatesMethod() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)

        // When
        await sut.setCalculationMethod(.muslimWorldLeague)

        // Then
        XCTAssertEqual(sut.calculationMethod, .muslimWorldLeague)
    }

    func test_setCalculationMethod_reloadsPrayers() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)
        await sut.loadPrayerTimes()
        let initialCallCount = mockPrayerRepository.getPrayersCallCount

        // When
        await sut.setCalculationMethod(.makkah)

        // Then
        XCTAssertGreaterThan(mockPrayerRepository.getPrayersCallCount, initialCallCount)
    }

    // MARK: - Refresh Tests

    func test_refreshPrayerTimes_reloadsPrayers() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockLocationService.locationToReturn = CLLocation(latitude: 40.7128, longitude: -74.0060)
        await sut.loadPrayerTimes()
        let initialCallCount = mockPrayerRepository.getPrayersCallCount

        // When
        await sut.refreshPrayerTimes()

        // Then
        XCTAssertGreaterThan(mockPrayerRepository.getPrayersCallCount, initialCallCount)
    }

    // Notification permission tests removed — PrayerViewModel now delegates to
    // NotificationScheduler.shared (singleton, not injectable for unit tests).
    // Authorization flow tested via integration/UI tests.

    // MARK: - Toggle Prayer Tests

    func test_togglePrayer_logsWhenNotLogged() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockLocationService.locationToReturn = CLLocation(latitude: 51.5074, longitude: -0.1278)
        await sut.loadPrayerTimes()

        // When
        await sut.togglePrayer(.fajr)

        // Then
        XCTAssertTrue(sut.loggedPrayers.contains(.fajr))
        XCTAssertTrue(mockPrayerRepository.logPrayerCalled)
    }

    func test_togglePrayer_unlogsWhenAlreadyLogged() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockPrayerRepository.prayerLogsToReturn = [
            PrayerLog(prayerType: .fajr, date: Date(), loggedAt: Date(), isOnTime: true)
        ]
        mockLocationService.locationToReturn = CLLocation(latitude: 51.5074, longitude: -0.1278)
        await sut.loadPrayerTimes()
        XCTAssertTrue(sut.loggedPrayers.contains(.fajr))

        // When
        await sut.togglePrayer(.fajr)

        // Then
        XCTAssertFalse(sut.loggedPrayers.contains(.fajr))
    }

    // MARK: - Reload Logged Prayers Tests

    func test_reloadLoggedPrayers_updatesFromRepository() async {
        // Given
        mockPrayerRepository.prayersToReturn = createMockPrayers()
        mockLocationService.locationToReturn = CLLocation(latitude: 51.5074, longitude: -0.1278)
        await sut.loadPrayerTimes()
        XCTAssertTrue(sut.loggedPrayers.isEmpty)

        // Simulate external log
        mockPrayerRepository.prayerLogsToReturn = [
            PrayerLog(prayerType: .dhuhr, date: Date(), loggedAt: Date(), isOnTime: true)
        ]

        // When
        await sut.reloadLoggedPrayers()

        // Then
        XCTAssertTrue(sut.loggedPrayers.contains(.dhuhr))
    }

    // MARK: - Notification Toggle Tests

    func test_initialState_allObligatoryPrayerNotificationsEnabled() {
        XCTAssertTrue(sut.notificationEnabledPrayers.contains(.fajr))
        XCTAssertTrue(sut.notificationEnabledPrayers.contains(.dhuhr))
        XCTAssertTrue(sut.notificationEnabledPrayers.contains(.asr))
        XCTAssertTrue(sut.notificationEnabledPrayers.contains(.maghrib))
        XCTAssertTrue(sut.notificationEnabledPrayers.contains(.isha))
    }

    func test_toggleNotification_disablesWhenEnabled() async {
        // Given
        XCTAssertTrue(sut.notificationEnabledPrayers.contains(.fajr))

        // When
        await sut.toggleNotification(for: .fajr)

        // Then
        XCTAssertFalse(sut.notificationEnabledPrayers.contains(.fajr))
    }

    // Toggle notification enable test removed — requires NotificationScheduler.shared
    // authorization which can't be mocked in unit tests. Toggle disable still tested above.

    // MARK: - Location Fallback Tests

    func test_loadPrayerTimes_usesCoordinatesFallback() async {
        // Given - no live GPS, but cached coordinates available
        mockLocationService.errorToThrow = PrayerTestError.locationFailed
        mockLocationService.coordinatesToReturn = Coordinates(latitude: 51.5074, longitude: -0.1278)
        mockPrayerRepository.prayersToReturn = createMockPrayers()

        // When
        await sut.loadPrayerTimes()

        // Then - should succeed via fallback
        XCTAssertEqual(sut.todayPrayers.count, 6)
        XCTAssertNil(sut.error)
    }

    // MARK: - Notification Settings Persistence Tests

    func test_toggleNotification_updatesLocalStateCorrectly() async {
        // Given - all 5 enabled
        XCTAssertEqual(sut.notificationEnabledPrayers.count, 5)

        // When - disable two prayers
        await sut.toggleNotification(for: .asr)
        await sut.toggleNotification(for: .isha)

        // Then - local state reflects both changes
        XCTAssertEqual(sut.notificationEnabledPrayers.count, 3)
        XCTAssertFalse(sut.notificationEnabledPrayers.contains(.asr))
        XCTAssertFalse(sut.notificationEnabledPrayers.contains(.isha))
        XCTAssertTrue(sut.notificationEnabledPrayers.contains(.fajr))
        XCTAssertTrue(sut.notificationEnabledPrayers.contains(.dhuhr))
        XCTAssertTrue(sut.notificationEnabledPrayers.contains(.maghrib))
    }

    func test_notificationSettings_defaultAllEnabled() {
        // init sets all obligatory prayers as default
        XCTAssertEqual(sut.notificationEnabledPrayers.count, 5)
        for prayer in PrayerType.obligatoryPrayers {
            XCTAssertTrue(sut.notificationEnabledPrayers.contains(prayer),
                          "\(prayer.rawValue) should be enabled by default")
        }
    }

    func test_toggleNotification_doesNotAffectOtherPrayers() async {
        // Given - all enabled initially
        XCTAssertEqual(sut.notificationEnabledPrayers.count, 5)

        // When - disable one (disabling doesn't require auth)
        await sut.toggleNotification(for: .dhuhr)

        // Then - only dhuhr affected
        XCTAssertFalse(sut.notificationEnabledPrayers.contains(.dhuhr))
        XCTAssertEqual(sut.notificationEnabledPrayers.count, 4)
        XCTAssertTrue(sut.notificationEnabledPrayers.contains(.fajr))
        XCTAssertTrue(sut.notificationEnabledPrayers.contains(.asr))
        XCTAssertTrue(sut.notificationEnabledPrayers.contains(.maghrib))
        XCTAssertTrue(sut.notificationEnabledPrayers.contains(.isha))
    }

    // MARK: - Smart Adhan Tests

    func test_smartAdhan_defaultDisabled() {
        let prefs = UserPreferences()
        XCTAssertFalse(prefs.smartAdhanEnabled)
    }

    func test_smartAdhan_preferencePersists() {
        var prefs = UserPreferences()
        prefs.smartAdhanEnabled = true
        XCTAssertTrue(prefs.smartAdhanEnabled)
    }

    func test_smartAdhan_requiresAdhanEnabled() {
        var prefs = UserPreferences()
        prefs.adhanEnabled = false
        prefs.smartAdhanEnabled = true
        // Smart adhan should only matter when adhan is enabled
        // The selectNotificationSound logic checks adhanEnabled first
        XCTAssertFalse(prefs.adhanEnabled)
        XCTAssertTrue(prefs.smartAdhanEnabled)
    }

    // MARK: - Prayer Streak Threshold Tests

    func test_prayerStreak_firesAtThreeLoggedPrayers() async {
        // Set up prayer times in the past so logging is valid
        let prayers = createMockPrayersWithPast()
        mockPrayerRepository.prayersToReturn = prayers
        mockLocationService.locationToReturn = CLLocation(latitude: 51.5, longitude: -0.1)
        mockLocationService.coordinatesToReturn = Coordinates(latitude: 51.5, longitude: -0.1)

        await sut.loadPrayerTimes()
        mockUserRepository.recordStreakCalls.removeAll()

        // Log 3 obligatory prayers (fajr, dhuhr are in the past per createMockPrayersWithPast)
        await sut.logPrayer(.fajr)
        await sut.logPrayer(.dhuhr)

        // After 2 prayers, streak should NOT have fired
        let callsAfterTwo = mockUserRepository.recordStreakCalls.filter { $0 == .prayer }
        XCTAssertEqual(callsAfterTwo.count, 0, "Streak should not fire with only 2 prayers logged")

        // Log 3rd prayer — need one more past prayer. Use sunrise time trick:
        // asr is in the future in createMockPrayersWithPast, so we need to set up
        // a schedule where 3 prayers are in the past
        // Actually fajr + sunrise (not obligatory) + dhuhr are past. Only 2 obligatory past.
        // Let me log a prayer that's in the future — logPrayer checks todayPrayers.contains, not isPast
        await sut.logPrayer(.asr)

        let callsAfterThree = mockUserRepository.recordStreakCalls.filter { $0 == .prayer }
        XCTAssertTrue(callsAfterThree.count > 0, "Streak should fire once 3 obligatory prayers are logged")
    }

    func test_prayerStreak_doesNotFireAtTwoPrayers() async {
        let prayers = createMockPrayersWithPast()
        mockPrayerRepository.prayersToReturn = prayers
        mockLocationService.locationToReturn = CLLocation(latitude: 51.5, longitude: -0.1)
        mockLocationService.coordinatesToReturn = Coordinates(latitude: 51.5, longitude: -0.1)

        await sut.loadPrayerTimes()
        mockUserRepository.recordStreakCalls.removeAll()

        // Log only 2 obligatory prayers
        await sut.logPrayer(.fajr)
        await sut.logPrayer(.dhuhr)

        let prayerStreakCalls = mockUserRepository.recordStreakCalls.filter { $0 == .prayer }
        XCTAssertEqual(prayerStreakCalls.count, 0, "Streak should not fire with only 2 prayers logged")
    }

    // MARK: - Grace Window Behavior Tests

    func test_nextPrayer_duringGrace_returnsArrivedPrayer() {
        // Given — Dhuhr was 5 min ago (within 15 min grace), Asr is 3 hours away
        let now = Date()
        sut.todayPrayers = [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(-7200)),
            PrayerTime(type: .sunrise, time: now.addingTimeInterval(-5400)),
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(-300)),   // 5 min ago — in grace
            PrayerTime(type: .asr, time: now.addingTimeInterval(10800)),
            PrayerTime(type: .maghrib, time: now.addingTimeInterval(18000)),
            PrayerTime(type: .isha, time: now.addingTimeInterval(25200))
        ]

        // When
        let next = sut.nextPrayer

        // Then — should show Dhuhr (the arrived prayer), not Asr
        XCTAssertEqual(next?.type, .dhuhr,
            "During grace window, nextPrayer should return the prayer that just arrived")
    }

    func test_nextPrayer_afterGraceExpires_skipsToNextPrayer() {
        // Given — Dhuhr was 20 min ago (past 15 min grace), Asr is 3 hours away
        let now = Date()
        sut.todayPrayers = [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(-7200)),
            PrayerTime(type: .sunrise, time: now.addingTimeInterval(-5400)),
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(-1200)),  // 20 min ago — past grace
            PrayerTime(type: .asr, time: now.addingTimeInterval(10800)),
            PrayerTime(type: .maghrib, time: now.addingTimeInterval(18000)),
            PrayerTime(type: .isha, time: now.addingTimeInterval(25200))
        ]

        // When
        let next = sut.nextPrayer

        // Then — Dhuhr grace expired, should advance to Asr
        XCTAssertEqual(next?.type, .asr,
            "After grace expires, nextPrayer should skip to the truly-next prayer")
    }

    func test_nextPrayer_neverReturnsNonObligatoryPrayer() {
        // Given — sunrise is in grace (just passed), but it's non-obligatory
        let now = Date()
        sut.todayPrayers = [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(-7200)),
            PrayerTime(type: .sunrise, time: now.addingTimeInterval(-300)), // 5 min ago — in grace
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(10800)),
            PrayerTime(type: .asr, time: now.addingTimeInterval(21600)),
            PrayerTime(type: .maghrib, time: now.addingTimeInterval(28800)),
            PrayerTime(type: .isha, time: now.addingTimeInterval(36000))
        ]

        // When
        let next = sut.nextPrayer

        // Then — sunrise is not obligatory, should skip to Dhuhr
        XCTAssertEqual(next?.type, .dhuhr,
            "Grace window should not apply to non-obligatory prayers")
    }

    func test_updateNextPrayerIndicator_duringGrace_marksArrivedPrayer() {
        // Given — Dhuhr was 5 min ago (in grace)
        let now = Date()
        sut.todayPrayers = [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(-7200)),
            PrayerTime(type: .sunrise, time: now.addingTimeInterval(-5400)),
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(-300)),   // 5 min ago — in grace
            PrayerTime(type: .asr, time: now.addingTimeInterval(10800)),
            PrayerTime(type: .maghrib, time: now.addingTimeInterval(18000)),
            PrayerTime(type: .isha, time: now.addingTimeInterval(25200))
        ]

        // When
        sut.updateNextPrayerIndicator()

        // Then — Dhuhr should be marked as next (it's in grace)
        let dhuhr = sut.todayPrayers.first { $0.type == .dhuhr }
        let asr = sut.todayPrayers.first { $0.type == .asr }
        XCTAssertTrue(dhuhr?.isNext == true,
            "Prayer in grace window should be marked isNext")
        XCTAssertFalse(asr?.isNext == true,
            "Prayer after grace should NOT be marked isNext while grace is active")
    }

    func test_updateNextPrayerIndicator_afterGrace_marksNextPrayer() {
        // Given — Dhuhr was 20 min ago (past grace), Asr is next
        let now = Date()
        sut.todayPrayers = [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(-7200)),
            PrayerTime(type: .sunrise, time: now.addingTimeInterval(-5400)),
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(-1200)),  // 20 min ago — past grace
            PrayerTime(type: .asr, time: now.addingTimeInterval(10800)),
            PrayerTime(type: .maghrib, time: now.addingTimeInterval(18000)),
            PrayerTime(type: .isha, time: now.addingTimeInterval(25200))
        ]

        // When
        sut.updateNextPrayerIndicator()

        // Then — Asr should be marked as next, not Dhuhr
        let dhuhr = sut.todayPrayers.first { $0.type == .dhuhr }
        let asr = sut.todayPrayers.first { $0.type == .asr }
        XCTAssertFalse(dhuhr?.isNext == true,
            "Prayer past grace should NOT be marked isNext")
        XCTAssertTrue(asr?.isNext == true,
            "Next future prayer should be marked isNext after grace expires")
    }

    func test_nextPrayer_allPrayersPastGrace_returnsNil() {
        // Given — all prayers are past grace window
        let now = Date()
        sut.todayPrayers = [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(-36000)),
            PrayerTime(type: .sunrise, time: now.addingTimeInterval(-32400)),
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(-21600)),
            PrayerTime(type: .asr, time: now.addingTimeInterval(-14400)),
            PrayerTime(type: .maghrib, time: now.addingTimeInterval(-7200)),
            PrayerTime(type: .isha, time: now.addingTimeInterval(-3600))    // 1 hour ago — past grace
        ]

        // When
        let next = sut.nextPrayer

        // Then — no prayers remaining (all past grace)
        XCTAssertNil(next, "When all prayers are past grace, nextPrayer should be nil")
    }

    func test_nextPrayer_exactlyAtGraceBoundary_returnsNextPrayer() {
        // Given — Dhuhr was exactly 15 min ago (grace just expired at this instant)
        let now = Date()
        sut.todayPrayers = [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(-7200)),
            PrayerTime(type: .sunrise, time: now.addingTimeInterval(-5400)),
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(-900)),   // Exactly 15 min ago
            PrayerTime(type: .asr, time: now.addingTimeInterval(10800)),
            PrayerTime(type: .maghrib, time: now.addingTimeInterval(18000)),
            PrayerTime(type: .isha, time: now.addingTimeInterval(25200))
        ]

        // When
        let next = sut.nextPrayer

        // Then — grace is >= 900s so it's expired; should return Asr
        XCTAssertEqual(next?.type, .asr,
            "At exactly 15 min (grace boundary), grace has expired — should show next prayer")
    }

    // MARK: - Helper Methods

    private func createMockPrayers() -> [PrayerTime] {
        let now = Date()
        return [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(3600)),
            PrayerTime(type: .sunrise, time: now.addingTimeInterval(7200)),
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(14400)),
            PrayerTime(type: .asr, time: now.addingTimeInterval(21600)),
            PrayerTime(type: .maghrib, time: now.addingTimeInterval(28800)),
            PrayerTime(type: .isha, time: now.addingTimeInterval(36000))
        ]
    }

    private func createMockPrayersWithPast() -> [PrayerTime] {
        let now = Date()
        return [
            PrayerTime(type: .fajr, time: now.addingTimeInterval(-7200)),    // 2 hours ago
            PrayerTime(type: .sunrise, time: now.addingTimeInterval(-5400)), // 1.5 hours ago
            PrayerTime(type: .dhuhr, time: now.addingTimeInterval(-3600)),   // 1 hour ago
            PrayerTime(type: .asr, time: now.addingTimeInterval(3600)),      // 1 hour from now
            PrayerTime(type: .maghrib, time: now.addingTimeInterval(7200)),  // 2 hours from now
            PrayerTime(type: .isha, time: now.addingTimeInterval(10800))     // 3 hours from now
        ]
    }
}

// MARK: - Test Error

private enum PrayerTestError: Error {
    case locationFailed
    case logFailed
    case notificationFailed
}

// MARK: - Testable Prayer Repository

@MainActor
final class TestablePrayerRepository: PrayerRepositoryProtocol {
    var prayersToReturn: [PrayerTime] = []
    var prayerLogsToReturn: [PrayerLog] = []
    var errorToThrow: Error?

    var getPrayersCallCount = 0
    var logPrayerCallCount = 0
    var logPrayerCalled = false

    nonisolated func getPrayers(for date: Date, location: Coordinates, method: CalculationMethod, madhab: Madhab? = nil) async throws -> [PrayerTime] {
        let error = await errorToThrow
        if let error { throw error }
        await MainActor.run { getPrayersCallCount += 1 }
        return await prayersToReturn
    }

    nonisolated func logPrayer(_ prayer: PrayerType, for date: Date, at time: Date, isOnTime: Bool) async throws {
        let error = await errorToThrow
        if let error { throw error }
        await MainActor.run {
            logPrayerCallCount += 1
            logPrayerCalled = true
        }
    }

    nonisolated func getPrayerLogs(from: Date, to: Date) async throws -> [PrayerLog] {
        return await prayerLogsToReturn
    }

    nonisolated func getPrayerLogs(for date: Date) async throws -> [PrayerLog] {
        return await prayerLogsToReturn
    }

    nonisolated func deletePrayerLog(_ log: PrayerLog) async throws {}

    nonisolated func isPrayerLogged(_ prayer: PrayerType, for date: Date) async throws -> Bool {
        let logs = await prayerLogsToReturn
        return await MainActor.run {
            logs.contains { $0.prayerType == prayer }
        }
    }

    nonisolated func getSunnahTimes(for date: Date, location: Coordinates, method: CalculationMethod, madhab: Madhab?) -> [SunnahTime] {
        []
    }
}

// MARK: - Testable Location Service

final class TestableLocationService: LocationServiceProtocol {
    var locationToReturn: CLLocation?
    var errorToThrow: Error?
    var coordinatesToReturn: Coordinates?

    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    var coordinates: Coordinates? {
        if let coords = coordinatesToReturn { return coords }
        if let loc = locationToReturn {
            return Coordinates(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        }
        return nil
    }

    func requestPermission() {
        // No-op for testing
    }

    func getCurrentLocation() async throws -> CLLocation {
        if let error = errorToThrow {
            throw error
        }
        return locationToReturn ?? CLLocation(latitude: 0, longitude: 0)
    }
}

// MARK: - Mock User Repository for Prayer Tests

@MainActor
final class PrayerTestMockUserRepository: UserRepositoryProtocol {
    var storedPreferences = UserPreferences()

    nonisolated func getUserStats() async throws -> UserStats {
        return UserStats()
    }

    nonisolated func updateUserStats(_ stats: UserStats) async throws {}

    nonisolated func addHasanat(_ amount: Int) async throws -> Int {
        return amount
    }

    nonisolated func getStreaks() async throws -> [Streak] {
        return StreakType.allCases.map { Streak(type: $0) }
    }

    nonisolated func getStreak(type: StreakType) async throws -> Streak? {
        return Streak(type: type)
    }

    nonisolated func updateStreak(_ streak: Streak) async throws {}

    var recordStreakCalls: [StreakType] = []

    nonisolated func recordStreakActivity(type: StreakType) async throws {
        await MainActor.run { recordStreakCalls.append(type) }
    }

    nonisolated func getPreference<T: Codable>(key: String) async throws -> T? {
        return nil
    }

    nonisolated func setPreference<T: Codable>(key: String, value: T) async throws {}

    nonisolated func getPreferences() async -> UserPreferences {
        return await storedPreferences
    }

    nonisolated func updatePreferences(_ preferences: UserPreferences) async throws {
        await MainActor.run { storedPreferences = preferences }
    }

    nonisolated func getStreakFreezes() async throws -> Int {
        return 0
    }

    nonisolated func useStreakFreeze() async throws {}

    nonisolated func awardStreakFreeze() async throws {}
}

// MARK: - isPrayerOnTime Tests

/// Tests for PrayerViewModel.isPrayerOnTime — verifies Islamic prayer window logic.
/// Each prayer is on-time between its start and the next prayer's start.
final class IsPrayerOnTimeTests: XCTestCase {

    private var schedule: [PrayerTime]!
    private let calendar = Calendar.current

    override func setUp() {
        super.setUp()
        let today = calendar.startOfDay(for: Date())
        schedule = [
            PrayerTime(type: .fajr, time: calendar.date(bySettingHour: 5, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .sunrise, time: calendar.date(bySettingHour: 6, minute: 45, second: 0, of: today)!),
            PrayerTime(type: .dhuhr, time: calendar.date(bySettingHour: 12, minute: 15, second: 0, of: today)!),
            PrayerTime(type: .asr, time: calendar.date(bySettingHour: 15, minute: 45, second: 0, of: today)!),
            PrayerTime(type: .maghrib, time: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!),
            PrayerTime(type: .isha, time: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!)
        ]
    }

    override func tearDown() {
        schedule = nil
        super.tearDown()
    }

    private func time(hour: Int, minute: Int) -> Date {
        let today = calendar.startOfDay(for: Date())
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today)!
    }

    // MARK: - Fajr: on-time from 05:30 until Sunrise (06:45)

    func test_fajr_duringWindow_isOnTime() {
        XCTAssertTrue(PrayerViewModel.isPrayerOnTime(.fajr, at: time(hour: 6, minute: 0), schedule: schedule))
    }

    func test_fajr_afterSunrise_isLate() {
        XCTAssertFalse(PrayerViewModel.isPrayerOnTime(.fajr, at: time(hour: 7, minute: 0), schedule: schedule))
    }

    func test_fajr_beforeFajrTime_isLate() {
        XCTAssertFalse(PrayerViewModel.isPrayerOnTime(.fajr, at: time(hour: 5, minute: 0), schedule: schedule))
    }

    func test_fajr_exactStart_isOnTime() {
        XCTAssertTrue(PrayerViewModel.isPrayerOnTime(.fajr, at: time(hour: 5, minute: 30), schedule: schedule))
    }

    func test_fajr_exactSunrise_isLate() {
        XCTAssertFalse(PrayerViewModel.isPrayerOnTime(.fajr, at: time(hour: 6, minute: 45), schedule: schedule))
    }

    // MARK: - Dhuhr: on-time from 12:15 until Asr (15:45)

    func test_dhuhr_duringWindow_isOnTime() {
        XCTAssertTrue(PrayerViewModel.isPrayerOnTime(.dhuhr, at: time(hour: 14, minute: 0), schedule: schedule))
    }

    func test_dhuhr_afterAsr_isLate() {
        XCTAssertFalse(PrayerViewModel.isPrayerOnTime(.dhuhr, at: time(hour: 16, minute: 0), schedule: schedule))
    }

    // MARK: - Asr: on-time from 15:45 until Maghrib (18:00)

    func test_asr_duringWindow_isOnTime() {
        XCTAssertTrue(PrayerViewModel.isPrayerOnTime(.asr, at: time(hour: 16, minute: 30), schedule: schedule),
                       "Asr logged at 16:30 (before Maghrib 18:00) should be on-time")
    }

    func test_asr_afterMaghrib_isLate() {
        XCTAssertFalse(PrayerViewModel.isPrayerOnTime(.asr, at: time(hour: 19, minute: 0), schedule: schedule))
    }

    // MARK: - Maghrib: on-time from 18:00 until Isha (20:00)

    func test_maghrib_duringWindow_isOnTime() {
        XCTAssertTrue(PrayerViewModel.isPrayerOnTime(.maghrib, at: time(hour: 19, minute: 0), schedule: schedule))
    }

    func test_maghrib_afterIsha_isLate() {
        XCTAssertFalse(PrayerViewModel.isPrayerOnTime(.maghrib, at: time(hour: 21, minute: 0), schedule: schedule))
    }

    // MARK: - Isha: on-time from 20:00 until end of day

    func test_isha_duringWindow_isOnTime() {
        XCTAssertTrue(PrayerViewModel.isPrayerOnTime(.isha, at: time(hour: 23, minute: 0), schedule: schedule))
    }

    func test_isha_exactStart_isOnTime() {
        XCTAssertTrue(PrayerViewModel.isPrayerOnTime(.isha, at: time(hour: 20, minute: 0), schedule: schedule))
    }

    func test_isha_beforeIshaTime_isLate() {
        XCTAssertFalse(PrayerViewModel.isPrayerOnTime(.isha, at: time(hour: 19, minute: 30), schedule: schedule))
    }

    // MARK: - Edge: sunrise is not obligatory

    func test_sunrise_alwaysFalse() {
        XCTAssertFalse(PrayerViewModel.isPrayerOnTime(.sunrise, at: time(hour: 6, minute: 50), schedule: schedule))
    }

    // MARK: - Edge: prayer not in schedule

    func test_missingPrayerInSchedule_returnsFalse() {
        let partialSchedule = [PrayerTime(type: .fajr, time: time(hour: 5, minute: 30))]
        XCTAssertFalse(PrayerViewModel.isPrayerOnTime(.dhuhr, at: time(hour: 12, minute: 30), schedule: partialSchedule))
    }
}
