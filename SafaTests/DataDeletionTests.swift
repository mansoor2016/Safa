// MARK: - DataDeletionTests.swift
// PURPOSE: Tests for per-category data deletion and cross-category isolation
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class DataDeletionTests: XCTestCase {

    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "com.safa.tests.dataDeletion")!
        testDefaults.removePersistentDomain(forName: "com.safa.tests.dataDeletion")
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "com.safa.tests.dataDeletion")
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - Prayer History Deletion

    func test_deletePrayerHistory_clearsLogs() {
        // Given
        testDefaults.set(["log1", "log2"], forKey: AppConstants.StorageKeys.prayerLogs)
        XCTAssertNotNil(testDefaults.object(forKey: AppConstants.StorageKeys.prayerLogs))

        // When
        DataDeletionService.deleteCategory(.prayerHistory, from: testDefaults)

        // Then
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.prayerLogs))
    }

    func test_deletePrayerHistory_doesNotAffectBookmarks() {
        // Given
        testDefaults.set(["log1"], forKey: AppConstants.StorageKeys.prayerLogs)
        testDefaults.set(["bookmark1"], forKey: AppConstants.StorageKeys.quranBookmarks)

        // When
        DataDeletionService.deleteCategory(.prayerHistory, from: testDefaults)

        // Then
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.prayerLogs))
        XCTAssertNotNil(testDefaults.object(forKey: AppConstants.StorageKeys.quranBookmarks))
    }

    // MARK: - Quran Progress Deletion

    func test_deleteQuranProgress_clearsBookmarks() {
        // Given
        testDefaults.set(["bm1"], forKey: AppConstants.StorageKeys.quranBookmarks)
        testDefaults.set("2:255", forKey: AppConstants.StorageKeys.quranProgress)
        testDefaults.set("1:5", forKey: AppConstants.StorageKeys.lastQuranPosition)

        // When
        DataDeletionService.deleteCategory(.quranProgress, from: testDefaults)

        // Then
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.quranBookmarks))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.quranProgress))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.lastQuranPosition))
    }

    func test_deleteQuranProgress_doesNotAffectPrayerLogs() {
        // Given
        testDefaults.set(["bm1"], forKey: AppConstants.StorageKeys.quranBookmarks)
        testDefaults.set(["log1"], forKey: AppConstants.StorageKeys.prayerLogs)

        // When
        DataDeletionService.deleteCategory(.quranProgress, from: testDefaults)

        // Then
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.quranBookmarks))
        XCTAssertNotNil(testDefaults.object(forKey: AppConstants.StorageKeys.prayerLogs))
    }

    // MARK: - Hadith Bookmarks Deletion

    func test_deleteHadithBookmarks_clearsOnlyHadith() {
        // Given
        testDefaults.set(["h1", "h2"], forKey: AppConstants.StorageKeys.hadithBookmarks)
        testDefaults.set(["q1"], forKey: AppConstants.StorageKeys.quranBookmarks)

        // When
        DataDeletionService.deleteCategory(.hadithBookmarks, from: testDefaults)

        // Then
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.hadithBookmarks))
        XCTAssertNotNil(testDefaults.object(forKey: AppConstants.StorageKeys.quranBookmarks))
    }

    // MARK: - Chat History Deletion

    func test_deleteChatHistory_clearsConversations() {
        // Given
        testDefaults.set(["conv1"], forKey: AppConstants.StorageKeys.chatConversations)
        testDefaults.set("conv1", forKey: AppConstants.StorageKeys.chatActiveConversation)
        testDefaults.set(["msg1"], forKey: "\(AppConstants.StorageKeys.chatMessagesPrefix)conv1")

        // When
        DataDeletionService.deleteCategory(.chatHistory, from: testDefaults)

        // Then
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.chatConversations))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.chatActiveConversation))
        XCTAssertNil(testDefaults.object(forKey: "\(AppConstants.StorageKeys.chatMessagesPrefix)conv1"))
    }

    // MARK: - Streaks & Progress Deletion

    func test_deleteStreaks_resetsAll() {
        // Given
        testDefaults.set("stats", forKey: AppConstants.StorageKeys.userStats)
        testDefaults.set("streaks", forKey: AppConstants.StorageKeys.userStreaks)
        testDefaults.set("legacy", forKey: AppConstants.StorageKeys.userAchievements)
        testDefaults.set(true, forKey: "com.safa.hasanat.awarded.prayer_2026-02-17")
        testDefaults.set(50, forKey: "com.safa.hasanat.daily.2026-02-17")

        // When
        DataDeletionService.deleteCategory(.streaksAndProgress, from: testDefaults)

        // Then
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.userStats))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.userStreaks))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.userAchievements))
        XCTAssertNil(testDefaults.object(forKey: "com.safa.hasanat.awarded.prayer_2026-02-17"),
                     "Hasanat dedup keys must be cleared so re-awards work after deletion")
        XCTAssertNil(testDefaults.object(forKey: "com.safa.hasanat.daily.2026-02-17"),
                     "Daily hasanat keys must be cleared so weekly chart resets")
    }

    // MARK: - Ramadan Data Deletion

    func test_deleteRamadanData_clearsFastingDays() {
        // Given
        testDefaults.set(["day1", "day2"], forKey: AppConstants.StorageKeys.ramadanFastingDays)
        testDefaults.set(["day1"], forKey: AppConstants.StorageKeys.ramadanTaraweehDays)
        testDefaults.set("goals", forKey: "dailyGoals_2026-03-01")
        testDefaults.set("goals", forKey: "dailyGoals_2026-03-02")

        // When
        DataDeletionService.deleteCategory(.ramadanData, from: testDefaults)

        // Then
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.ramadanFastingDays))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.ramadanTaraweehDays))
        XCTAssertNil(testDefaults.object(forKey: "dailyGoals_2026-03-01"))
        XCTAssertNil(testDefaults.object(forKey: "dailyGoals_2026-03-02"))
    }

    // MARK: - Delete All Data

    func test_deleteAllData_clearsEverything() {
        // Given - populate all categories
        testDefaults.set(["log"], forKey: AppConstants.StorageKeys.prayerLogs)
        testDefaults.set(["bm"], forKey: AppConstants.StorageKeys.quranBookmarks)
        testDefaults.set("pos", forKey: AppConstants.StorageKeys.quranProgress)
        testDefaults.set("pos", forKey: AppConstants.StorageKeys.lastQuranPosition)
        testDefaults.set(["h"], forKey: AppConstants.StorageKeys.hadithBookmarks)
        testDefaults.set(["c"], forKey: AppConstants.StorageKeys.chatConversations)
        testDefaults.set("a", forKey: AppConstants.StorageKeys.chatActiveConversation)
        testDefaults.set(["m"], forKey: "\(AppConstants.StorageKeys.chatMessagesPrefix)c1")
        testDefaults.set("s", forKey: AppConstants.StorageKeys.userStats)
        testDefaults.set("st", forKey: AppConstants.StorageKeys.userStreaks)
        testDefaults.set(true, forKey: "com.safa.hasanat.awarded.prayer_2026-01-01")
        testDefaults.set(25, forKey: "com.safa.hasanat.daily.2026-01-01")
        testDefaults.set(["f"], forKey: AppConstants.StorageKeys.ramadanFastingDays)
        testDefaults.set(["t"], forKey: AppConstants.StorageKeys.ramadanTaraweehDays)
        testDefaults.set("g", forKey: "dailyGoals_2026-01-01")

        // When
        DataDeletionService.deleteAllCategories(from: testDefaults)

        // Then - all cleared
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.prayerLogs))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.quranBookmarks))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.quranProgress))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.lastQuranPosition))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.hadithBookmarks))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.chatConversations))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.chatActiveConversation))
        XCTAssertNil(testDefaults.object(forKey: "\(AppConstants.StorageKeys.chatMessagesPrefix)c1"))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.userStats))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.userStreaks))
        XCTAssertNil(testDefaults.object(forKey: "com.safa.hasanat.awarded.prayer_2026-01-01"))
        XCTAssertNil(testDefaults.object(forKey: "com.safa.hasanat.daily.2026-01-01"))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.ramadanFastingDays))
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.ramadanTaraweehDays))
        XCTAssertNil(testDefaults.object(forKey: "dailyGoals_2026-01-01"))
    }

    // MARK: - Edge Cases

    func test_deleteOnEmptyData_doesNotCrash() {
        // Given - no data stored

        // When/Then - should not crash
        DataDeletionService.deleteCategory(.prayerHistory, from: testDefaults)
        DataDeletionService.deleteCategory(.quranProgress, from: testDefaults)
        DataDeletionService.deleteCategory(.hadithBookmarks, from: testDefaults)
        DataDeletionService.deleteCategory(.chatHistory, from: testDefaults)
        DataDeletionService.deleteCategory(.streaksAndProgress, from: testDefaults)
        DataDeletionService.deleteCategory(.ramadanData, from: testDefaults)
    }

    func test_deleteIsIdempotent() {
        // Given
        testDefaults.set(["log1"], forKey: AppConstants.StorageKeys.prayerLogs)

        // When - delete twice
        DataDeletionService.deleteCategory(.prayerHistory, from: testDefaults)
        DataDeletionService.deleteCategory(.prayerHistory, from: testDefaults)

        // Then - no crash, still nil
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.prayerLogs))
    }

    func test_deleteDoesNotAffectAppSettings() {
        // Given - populate user preferences (app settings) and some data
        testDefaults.set("mwl", forKey: AppConstants.StorageKeys.calculationMethod)
        testDefaults.set("teal", forKey: AppConstants.StorageKeys.themeAccentColor)
        testDefaults.set(true, forKey: AppConstants.StorageKeys.hapticsEnabled)
        testDefaults.set(["log1"], forKey: AppConstants.StorageKeys.prayerLogs)

        // When - delete all user data
        DataDeletionService.deleteAllCategories(from: testDefaults)

        // Then - settings preserved
        XCTAssertEqual(testDefaults.string(forKey: AppConstants.StorageKeys.calculationMethod), "mwl")
        XCTAssertEqual(testDefaults.string(forKey: AppConstants.StorageKeys.themeAccentColor), "teal")
        XCTAssertTrue(testDefaults.bool(forKey: AppConstants.StorageKeys.hapticsEnabled))
        // Data cleared
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.prayerLogs))
    }

    func test_deleteAllData_alsoWorksWithAppGroupDefaults() {
        // Given - data in both standard and app group defaults
        let appGroupDefaults = UserDefaults(suiteName: "com.safa.tests.appGroup")!
        appGroupDefaults.removePersistentDomain(forName: "com.safa.tests.appGroup")

        testDefaults.set(["log1"], forKey: AppConstants.StorageKeys.prayerLogs)
        appGroupDefaults.set(["log2"], forKey: AppConstants.StorageKeys.prayerLogs)

        // When
        DataDeletionService.deleteCategory(.prayerHistory, from: testDefaults, appGroupDefaults: appGroupDefaults)

        // Then - both stores cleared
        XCTAssertNil(testDefaults.object(forKey: AppConstants.StorageKeys.prayerLogs))
        XCTAssertNil(appGroupDefaults.object(forKey: AppConstants.StorageKeys.prayerLogs))

        // Cleanup
        appGroupDefaults.removePersistentDomain(forName: "com.safa.tests.appGroup")
    }

    // MARK: - Category Isolation Matrix

    func test_deletingOneCategory_doesNotAffectOthers() {
        // Given - populate one key per category
        let categoryKeys: [(DataCategory, String)] = [
            (.prayerHistory, AppConstants.StorageKeys.prayerLogs),
            (.quranProgress, AppConstants.StorageKeys.quranBookmarks),
            (.hadithBookmarks, AppConstants.StorageKeys.hadithBookmarks),
            (.chatHistory, AppConstants.StorageKeys.chatConversations),
            (.streaksAndProgress, AppConstants.StorageKeys.userStats),
            (.ramadanData, AppConstants.StorageKeys.ramadanFastingDays),
        ]

        for (_, key) in categoryKeys {
            testDefaults.set("data", forKey: key)
        }

        // When - delete each category one at a time
        for (category, _) in categoryKeys {
            // Reset all data
            for (_, key) in categoryKeys {
                testDefaults.set("data", forKey: key)
            }

            DataDeletionService.deleteCategory(category, from: testDefaults)

            // Then - only this category's key is nil, others are preserved
            for (otherCategory, otherKey) in categoryKeys {
                if otherCategory == category {
                    XCTAssertNil(
                        testDefaults.object(forKey: otherKey),
                        "Key \(otherKey) should be nil after deleting \(category.displayName)"
                    )
                } else {
                    XCTAssertNotNil(
                        testDefaults.object(forKey: otherKey),
                        "Key \(otherKey) should be preserved after deleting \(category.displayName)"
                    )
                }
            }
        }
    }

    // MARK: - DataCategory Coverage

    func test_allCategories_haveStorageKeys() {
        for category in DataCategory.allCases {
            XCTAssertFalse(
                category.storageKeys.isEmpty,
                "\(category.displayName) should have at least one storage key"
            )
        }
    }

    func test_allCategories_haveDisplayProperties() {
        for category in DataCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
            XCTAssertFalse(category.iconName.isEmpty)
            XCTAssertFalse(category.description.isEmpty)
        }
    }
}
