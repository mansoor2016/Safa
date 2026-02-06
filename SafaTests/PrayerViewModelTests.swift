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
    var mockNotificationService: TestableNotificationService!
    var mockUserState: UserStateManager!
    var mockUserRepository: PrayerTestMockUserRepository!

    override func setUp() {
        super.setUp()
        mockPrayerRepository = TestablePrayerRepository()
        mockLocationService = TestableLocationService()
        mockNotificationService = TestableNotificationService()
        mockUserRepository = PrayerTestMockUserRepository()
        mockUserState = UserStateManager(userRepository: mockUserRepository)

        sut = PrayerViewModel(
            prayerRepository: mockPrayerRepository,
            locationService: mockLocationService,
            notificationService: mockNotificationService,
            userState: mockUserState
        )
    }

    override func tearDown() {
        sut = nil
        mockPrayerRepository = nil
        mockLocationService = nil
        mockNotificationService = nil
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

    // MARK: - Notification Permission Tests

    func test_requestNotificationPermission_callsNotificationService() async {
        // Given
        mockNotificationService.authorizationResult = true

        // When
        await sut.requestNotificationPermission()

        // Then
        XCTAssertTrue(mockNotificationService.requestAuthorizationCalled)
    }

    func test_requestNotificationPermission_failure_setsError() async {
        // Given
        mockNotificationService.errorToThrow = PrayerTestError.notificationFailed

        // When
        await sut.requestNotificationPermission()

        // Then
        XCTAssertNotNil(sut.error)
    }

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

    func test_toggleNotification_enablesWhenDisabledAndAuthorized() async {
        // Given - mock is already authorized
        mockNotificationService._isAuthorized = true
        mockNotificationService.authorizationResult = true
        await sut.toggleNotification(for: .fajr) // disable first
        XCTAssertFalse(sut.notificationEnabledPrayers.contains(.fajr))

        // When
        await sut.toggleNotification(for: .fajr) // enable again

        // Then
        XCTAssertTrue(sut.notificationEnabledPrayers.contains(.fajr))
    }

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

    nonisolated func getPrayers(for date: Date, location: Coordinates, method: CalculationMethod) async throws -> [PrayerTime] {
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

// MARK: - Testable Notification Service

@MainActor
final class TestableNotificationService: NotificationServiceProtocol {
    var authorizationResult = false
    var errorToThrow: Error?
    var requestAuthorizationCalled = false
    var scheduleCalled = false
    var _isAuthorized = false

    nonisolated var isAuthorized: Bool {
        return true // Always authorized in tests to avoid UNNotificationCenter issues
    }

    nonisolated func requestAuthorization() async throws -> Bool {
        let error = await errorToThrow
        let result = await authorizationResult
        await MainActor.run { requestAuthorizationCalled = true }
        if let error {
            throw error
        }
        return result
    }

    nonisolated func scheduleDailyPrayerNotifications(prayers: [PrayerTime], offsetMinutes: Int) async throws {
        let error = await errorToThrow
        await MainActor.run { scheduleCalled = true }
        if let error {
            throw error
        }
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

    nonisolated func recordStreakActivity(type: StreakType) async throws {}

    nonisolated func getAchievements() async throws -> [Achievement] {
        return []
    }

    nonisolated func unlockAchievement(_ achievementId: String) async throws {}

    nonisolated func isAchievementUnlocked(_ achievementId: String) async throws -> Bool {
        return false
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
