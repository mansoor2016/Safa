// MARK: - HasanatTrackingTests.swift
// PURPOSE: Tests for HasanatTracker deduplication logic
// DEPENDENCIES: XCTest, @testable import Safa

import XCTest
@testable import Safa

final class HasanatTrackingTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        clearTrackerKeys()
    }

    override func tearDown() {
        clearTrackerKeys()
        super.tearDown()
    }

    /// Remove all tracker keys from UserDefaults
    private func clearTrackerKeys() {
        let prefix = "com.safa.hasanat.awarded."
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix(prefix) {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - hasAwarded / markAwarded

    func test_hasAwarded_returnsFalseInitially() {
        let key = HasanatTracker.dailyKey("test_prayer_fajr")
        XCTAssertFalse(HasanatTracker.hasAwarded(key))
    }

    func test_markAwarded_setsKeyToTrue() {
        let key = HasanatTracker.dailyKey("test_prayer_fajr")
        HasanatTracker.markAwarded(key)
        XCTAssertTrue(HasanatTracker.hasAwarded(key))
    }

    func test_differentKeys_areIndependent() {
        let keyA = HasanatTracker.dailyKey("prayer_fajr")
        let keyB = HasanatTracker.dailyKey("prayer_dhuhr")

        HasanatTracker.markAwarded(keyA)

        XCTAssertTrue(HasanatTracker.hasAwarded(keyA))
        XCTAssertFalse(HasanatTracker.hasAwarded(keyB))
    }

    func test_differentDates_areIndependent() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let keyToday = HasanatTracker.dailyKey("prayer_fajr", on: today)
        let keyYesterday = HasanatTracker.dailyKey("prayer_fajr", on: yesterday)

        HasanatTracker.markAwarded(keyToday)

        XCTAssertTrue(HasanatTracker.hasAwarded(keyToday))
        XCTAssertFalse(HasanatTracker.hasAwarded(keyYesterday))
    }

    // MARK: - Daily Key Format

    func test_dailyKey_containsDateSuffix() {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let key = HasanatTracker.dailyKey("prayer_fajr", on: date)
        XCTAssertTrue(key.hasSuffix(dateString), "Key should end with date: \(key)")
    }

    // MARK: - Permanent Key

    func test_permanentKey_doesNotContainDate() {
        let key = HasanatTracker.permanentKey("lesson_abc123")
        XCTAssertEqual(key, "com.safa.hasanat.awarded.lesson_abc123")
    }

    // MARK: - Pruning

    func test_pruneOldEntries_removesOldDailyKeys() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        let oldKey = HasanatTracker.dailyKey("prayer_fajr", on: oldDate)
        HasanatTracker.markAwarded(oldKey)

        XCTAssertTrue(HasanatTracker.hasAwarded(oldKey), "Key should exist before pruning")

        HasanatTracker.pruneOldEntries()

        XCTAssertFalse(HasanatTracker.hasAwarded(oldKey), "Old key should be pruned")
    }

    func test_pruneOldEntries_keepsTodaysKeys() {
        let todayKey = HasanatTracker.dailyKey("prayer_fajr", on: Date())
        HasanatTracker.markAwarded(todayKey)

        HasanatTracker.pruneOldEntries()

        XCTAssertTrue(HasanatTracker.hasAwarded(todayKey), "Today's key should survive pruning")
    }

    func test_pruneOldEntries_keepsPermanentKeys() {
        let permanentKey = HasanatTracker.permanentKey("lesson_abc123")
        HasanatTracker.markAwarded(permanentKey)

        HasanatTracker.pruneOldEntries()

        XCTAssertTrue(HasanatTracker.hasAwarded(permanentKey), "Permanent key should survive pruning")
    }

    func test_pruneOldEntries_keepsRecentDailyKeys() {
        // 3 days ago should survive (within 7-day window)
        let recentDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let recentKey = HasanatTracker.dailyKey("prayer_fajr", on: recentDate)
        HasanatTracker.markAwarded(recentKey)

        HasanatTracker.pruneOldEntries()

        XCTAssertTrue(HasanatTracker.hasAwarded(recentKey), "Recent key should survive pruning")
    }

    // MARK: - HasanatAward Point Values

    func test_allAwardPointValues() {
        // Verify all awards have expected point values
        XCTAssertEqual(HasanatAward.prayerLogged.points, 10)
        XCTAssertEqual(HasanatAward.prayerAllFive.points, 25)
        XCTAssertEqual(HasanatAward.quranPage.points, 5)
        XCTAssertEqual(HasanatAward.quranSurah.points, 15)
        XCTAssertEqual(HasanatAward.quranJuz.points, 50)
        XCTAssertEqual(HasanatAward.lessonComplete.points, 10)
        XCTAssertEqual(HasanatAward.lessonPerfect.points, 5)
        XCTAssertEqual(HasanatAward.pronunciationPass.points, 5)
        XCTAssertEqual(HasanatAward.tajweedModule.points, 20)
        XCTAssertEqual(HasanatAward.morningDhikr.points, 15)
        XCTAssertEqual(HasanatAward.eveningDhikr.points, 15)
        XCTAssertEqual(HasanatAward.tasbeehSession.points, 10)
        XCTAssertEqual(HasanatAward.dailyOpen.points, 5)
        XCTAssertEqual(HasanatAward.dailyVerse.points, 3)
        XCTAssertEqual(HasanatAward.dailyHadith.points, 3)
        XCTAssertEqual(HasanatAward.share.points, 5)
        XCTAssertEqual(HasanatAward.inviteAccepted.points, 25)
        XCTAssertEqual(HasanatAward.familyJoined.points, 15)
        XCTAssertEqual(HasanatAward.fastingDay.points, 20)
        XCTAssertEqual(HasanatAward.taraweeh.points, 25)
    }

    // MARK: - Dedup Simulation (using markAwarded/hasAwarded)

    func test_prayerLogUnlogRelog_onlyAwardsOnce() {
        let key = HasanatTracker.dailyKey("prayer_fajr")

        // First log — should award
        XCTAssertFalse(HasanatTracker.hasAwarded(key))
        HasanatTracker.markAwarded(key)
        XCTAssertTrue(HasanatTracker.hasAwarded(key))

        // Simulate unlog (tracker state is unchanged — "lock-in" model)
        // Re-log — should NOT award again
        XCTAssertTrue(HasanatTracker.hasAwarded(key), "Second check should still be true (locked in)")
    }

    func test_allFivePrayers_awardedOncePerDay() {
        let key = HasanatTracker.dailyKey("prayerAllFive")

        // Log all five prayers, check bonus awards once
        HasanatTracker.markAwarded(key)
        XCTAssertTrue(HasanatTracker.hasAwarded(key))

        // Trying to award again on same day — already marked
        XCTAssertTrue(HasanatTracker.hasAwarded(key))
    }

    func test_prayerAwardFromMultipleScreens_usesSharedTracker() {
        // HomeView and PrayerView both use the same key format
        let keyFromHome = HasanatTracker.dailyKey("prayer_fajr")
        let keyFromPrayer = HasanatTracker.dailyKey("prayer_fajr")

        XCTAssertEqual(keyFromHome, keyFromPrayer, "Keys from different screens should match")

        HasanatTracker.markAwarded(keyFromHome)
        XCTAssertTrue(HasanatTracker.hasAwarded(keyFromPrayer), "Award from HomeView should block PrayerView")
    }

    func test_lessonCompletion_awardedOnceEver() {
        let key = HasanatTracker.permanentKey("lesson_intro-1")

        XCTAssertFalse(HasanatTracker.hasAwarded(key))
        HasanatTracker.markAwarded(key)
        XCTAssertTrue(HasanatTracker.hasAwarded(key))

        // Completing same lesson again — already awarded
        XCTAssertTrue(HasanatTracker.hasAwarded(key))
    }

    func test_fastingDay_independentPerDay() {
        let key1 = HasanatTracker.dailyKey("fastingDay_1")
        let key2 = HasanatTracker.dailyKey("fastingDay_2")

        HasanatTracker.markAwarded(key1)

        XCTAssertTrue(HasanatTracker.hasAwarded(key1))
        XCTAssertFalse(HasanatTracker.hasAwarded(key2), "Different fasting days should be independent")
    }

    func test_taraweeh_awardedOncePerDay() {
        let key = HasanatTracker.dailyKey("taraweeh")

        XCTAssertFalse(HasanatTracker.hasAwarded(key))
        HasanatTracker.markAwarded(key)
        XCTAssertTrue(HasanatTracker.hasAwarded(key))
    }

    func test_dailyVerse_awardedOncePerDay() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let keyToday = HasanatTracker.dailyKey("dailyVerse", on: today)
        let keyTomorrow = HasanatTracker.dailyKey("dailyVerse", on: tomorrow)

        HasanatTracker.markAwarded(keyToday)

        XCTAssertTrue(HasanatTracker.hasAwarded(keyToday))
        XCTAssertFalse(HasanatTracker.hasAwarded(keyTomorrow), "Tomorrow should get its own award")
    }

    func test_dailyHadith_awardedOncePerDay() {
        let key = HasanatTracker.dailyKey("dailyHadith")

        XCTAssertFalse(HasanatTracker.hasAwarded(key))
        HasanatTracker.markAwarded(key)
        XCTAssertTrue(HasanatTracker.hasAwarded(key))
    }

    func test_inviteAccepted_permanentDedup() {
        let key = HasanatTracker.permanentKey("inviteAccepted")

        XCTAssertFalse(HasanatTracker.hasAwarded(key))
        HasanatTracker.markAwarded(key)
        XCTAssertTrue(HasanatTracker.hasAwarded(key))
    }

    func test_shareAward_scopedToContentType() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())

        let keyVerse = HasanatTracker.dailyKey("share_verse_\(dateString)")
        let keyAchievement = HasanatTracker.dailyKey("share_achievement_\(dateString)")

        HasanatTracker.markAwarded(keyVerse)

        XCTAssertTrue(HasanatTracker.hasAwarded(keyVerse))
        XCTAssertFalse(HasanatTracker.hasAwarded(keyAchievement), "Different share types should be independent")
    }

    // MARK: - Daily Open Dedup

    func test_dailyOpen_awardedOncePerDay() {
        let key = HasanatTracker.dailyKey("dailyOpen")

        XCTAssertFalse(HasanatTracker.hasAwarded(key))
        HasanatTracker.markAwarded(key)
        XCTAssertTrue(HasanatTracker.hasAwarded(key))

        // Second call same day — already awarded
        XCTAssertTrue(HasanatTracker.hasAwarded(key), "dailyOpen should only award once per day")
    }

    func test_dailyOpen_resetsNextDay() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let keyToday = HasanatTracker.dailyKey("dailyOpen", on: today)
        let keyTomorrow = HasanatTracker.dailyKey("dailyOpen", on: tomorrow)

        HasanatTracker.markAwarded(keyToday)

        XCTAssertTrue(HasanatTracker.hasAwarded(keyToday))
        XCTAssertFalse(HasanatTracker.hasAwarded(keyTomorrow), "dailyOpen should reset for a new day")
    }

    // MARK: - Total Prayers Logged Counter

    func test_totalPrayersLogged_defaultsToZero() {
        let stats = UserStats()
        XCTAssertEqual(stats.totalPrayersLogged, 0)
    }

    func test_totalPrayersLogged_increments() {
        var stats = UserStats()
        stats.totalPrayersLogged += 1
        XCTAssertEqual(stats.totalPrayersLogged, 1)
        stats.totalPrayersLogged += 1
        XCTAssertEqual(stats.totalPrayersLogged, 2)
    }
}

// MARK: - Integration Tests (UserStateManager + HasanatTracker)

@MainActor
final class HasanatIntegrationTests: XCTestCase {

    private var mockRepo: TrackingMockUserRepository!
    private var userState: UserStateManager!

    override func setUp() {
        super.setUp()
        clearTrackerKeys()
        mockRepo = TrackingMockUserRepository()
        userState = UserStateManager(userRepository: mockRepo)
    }

    override func tearDown() {
        clearTrackerKeys()
        mockRepo = nil
        userState = nil
        super.tearDown()
    }

    private func clearTrackerKeys() {
        let prefix = "com.safa.hasanat.awarded."
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix(prefix) {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - awardOnce Integration

    func test_awardOnce_firstCall_awardsHasanat() async {
        let awarded = await HasanatTracker.awardOnce(.prayerLogged, key: "prayer_fajr", via: userState)

        XCTAssertTrue(awarded)
        XCTAssertEqual(mockRepo.addHasanatCalls.count, 1)
        XCTAssertEqual(mockRepo.addHasanatCalls.first, HasanatAward.prayerLogged.points)
    }

    func test_awardOnce_secondCall_doesNotAwardAgain() async {
        _ = await HasanatTracker.awardOnce(.prayerLogged, key: "prayer_fajr", via: userState)
        let secondAwarded = await HasanatTracker.awardOnce(.prayerLogged, key: "prayer_fajr", via: userState)

        XCTAssertFalse(secondAwarded)
        XCTAssertEqual(mockRepo.addHasanatCalls.count, 1, "Should only call addHasanat once")
    }

    func test_awardOnce_differentKeys_bothAward() async {
        let a = await HasanatTracker.awardOnce(.prayerLogged, key: "prayer_fajr", via: userState)
        let b = await HasanatTracker.awardOnce(.prayerLogged, key: "prayer_dhuhr", via: userState)

        XCTAssertTrue(a)
        XCTAssertTrue(b)
        XCTAssertEqual(mockRepo.addHasanatCalls.count, 2)
    }

    // MARK: - awardOnceEver Integration

    func test_awardOnceEver_firstCall_awards() async {
        let awarded = await HasanatTracker.awardOnceEver(.lessonComplete, key: "lesson_1", via: userState)

        XCTAssertTrue(awarded)
        XCTAssertEqual(mockRepo.addHasanatCalls.count, 1)
        XCTAssertEqual(mockRepo.addHasanatCalls.first, HasanatAward.lessonComplete.points)
    }

    func test_awardOnceEver_secondCall_blocked() async {
        _ = await HasanatTracker.awardOnceEver(.lessonComplete, key: "lesson_1", via: userState)
        let second = await HasanatTracker.awardOnceEver(.lessonComplete, key: "lesson_1", via: userState)

        XCTAssertFalse(second)
        XCTAssertEqual(mockRepo.addHasanatCalls.count, 1)
    }

    // MARK: - recordActivity(.daily) + dailyOpen Dedup

    func test_recordActivityDaily_awardsDailyOpen() async {
        await userState.recordActivity(type: .daily)

        XCTAssertEqual(mockRepo.recordStreakCalls, [.daily])
        // dailyOpen uses HasanatTracker.awardOnce, which calls addHasanat
        XCTAssertEqual(mockRepo.addHasanatCalls.count, 1)
        XCTAssertEqual(mockRepo.addHasanatCalls.first, HasanatAward.dailyOpen.points)
    }

    func test_recordActivityDaily_twice_awardsDailyOpenOnce() async {
        await userState.recordActivity(type: .daily)
        await userState.recordActivity(type: .daily)

        // HasanatTracker dedup should block the second dailyOpen award
        XCTAssertEqual(mockRepo.addHasanatCalls.count, 1, "dailyOpen should only award once per day")
    }

    func test_recordActivityPrayer_doesNotAwardDailyOpen() async {
        await userState.recordActivity(type: .prayer)

        // .prayer type should not trigger .dailyOpen
        XCTAssertTrue(mockRepo.addHasanatCalls.isEmpty, "Prayer activity should not award dailyOpen")
    }

    // MARK: - incrementPrayersLogged Integration

    func test_incrementPrayersLogged_updatesStats() async {
        XCTAssertEqual(userState.userStats.totalPrayersLogged, 0)

        await userState.incrementPrayersLogged()

        XCTAssertEqual(userState.userStats.totalPrayersLogged, 1)
        XCTAssertEqual(mockRepo.updateStatsCalls.count, 1)
        XCTAssertEqual(mockRepo.updateStatsCalls.first?.totalPrayersLogged, 1)
    }

    func test_incrementPrayersLogged_calledMultipleTimes() async {
        await userState.incrementPrayersLogged()
        await userState.incrementPrayersLogged()
        await userState.incrementPrayersLogged()

        XCTAssertEqual(userState.userStats.totalPrayersLogged, 3)
        XCTAssertEqual(mockRepo.updateStatsCalls.count, 3)
    }

    // MARK: - End-to-End Prayer Flow Simulation

    func test_prayerFlow_awardsHasanat_andIncrementsPrayerCount() async {
        // Simulate what PrayerViewModel.logPrayer does:
        // 1. HasanatTracker.awardOnce for prayer
        let awarded = await HasanatTracker.awardOnce(.prayerLogged, key: "prayer_fajr", via: userState)
        // 2. incrementPrayersLogged
        let wasFirsTPrayer = userState.userStats.totalPrayersLogged == 0
        await userState.incrementPrayersLogged()
        // 3. recordActivity for streak
        await userState.recordActivity(type: .prayer)

        XCTAssertTrue(awarded)
        XCTAssertTrue(wasFirsTPrayer)
        XCTAssertEqual(userState.userStats.totalPrayersLogged, 1)
        XCTAssertEqual(mockRepo.addHasanatCalls, [HasanatAward.prayerLogged.points])
        XCTAssertEqual(mockRepo.recordStreakCalls, [.prayer])
    }

    func test_prayerFlow_logUnlogRelog_onlyAwardsOnce() async {
        // First log
        _ = await HasanatTracker.awardOnce(.prayerLogged, key: "prayer_fajr", via: userState)
        await userState.incrementPrayersLogged()

        // Unlog (no tracker interaction — lock-in model)

        // Re-log
        let secondAwarded = await HasanatTracker.awardOnce(.prayerLogged, key: "prayer_fajr", via: userState)
        await userState.incrementPrayersLogged()

        XCTAssertFalse(secondAwarded, "Re-log should not award hasanat again")
        XCTAssertEqual(mockRepo.addHasanatCalls.count, 1, "Only one hasanat call")
        XCTAssertEqual(userState.userStats.totalPrayersLogged, 2, "Counter still increments (lifetime total)")
    }
}

// MARK: - Tracking Mock User Repository

@MainActor
private final class TrackingMockUserRepository: UserRepositoryProtocol {
    var addHasanatCalls: [Int] = []
    var recordStreakCalls: [StreakType] = []
    var updateStatsCalls: [UserStats] = []
    private var storedStats = UserStats()

    nonisolated func getUserStats() async throws -> UserStats {
        await storedStats
    }

    nonisolated func updateUserStats(_ stats: UserStats) async throws {
        await MainActor.run {
            storedStats = stats
            updateStatsCalls.append(stats)
        }
    }

    nonisolated func addHasanat(_ amount: Int) async throws -> Int {
        await MainActor.run {
            addHasanatCalls.append(amount)
            storedStats.totalHasanat += amount
            return storedStats.totalHasanat
        }
    }

    nonisolated func getStreaks() async throws -> [Streak] {
        StreakType.allCases.map { Streak(type: $0) }
    }

    nonisolated func getStreak(type: StreakType) async throws -> Streak? {
        Streak(type: type)
    }

    nonisolated func updateStreak(_ streak: Streak) async throws {}

    nonisolated func recordStreakActivity(type: StreakType) async throws {
        await MainActor.run { recordStreakCalls.append(type) }
    }

    nonisolated func getAchievements() async throws -> [Achievement] { [] }
    nonisolated func unlockAchievement(_ achievementId: String) async throws {}
    nonisolated func isAchievementUnlocked(_ achievementId: String) async throws -> Bool { false }
    nonisolated func getPreference<T: Codable>(key: String) async throws -> T? { nil }
    nonisolated func setPreference<T: Codable>(key: String, value: T) async throws {}
    nonisolated func getPreferences() async -> UserPreferences { UserPreferences() }
    nonisolated func updatePreferences(_ preferences: UserPreferences) async throws {}
    nonisolated func getStreakFreezes() async throws -> Int { 0 }
    nonisolated func useStreakFreeze() async throws {}
    nonisolated func awardStreakFreeze() async throws {}
}
