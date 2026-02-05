// MARK: - AppConstants.swift
// PURPOSE: Application-wide constants
// DEPENDENCIES: Foundation

import Foundation

enum AppConstants {
    // MARK: - App Info
    static let appName = "Safa"
    static let appBundleId = "com.safa.app"
    static let appGroupId = "group.com.safa.app"

    // MARK: - URLs
    enum URLs {
        static let website = URL(string: "https://safaapp.com")!
        static let privacyPolicy = URL(string: "https://safaapp.com/privacy")!
        static let termsOfService = URL(string: "https://safaapp.com/terms")!
        static let support = URL(string: "https://safaapp.com/support")!
        static let appStore = URL(string: "https://apps.apple.com/app/safa")
        static let feedback = URL(string: "mailto:feedback@safaapp.com")!
    }

    // MARK: - Deep Links
    enum DeepLinks {
        static let scheme = "safa"
        static let host = "app"

        // Paths
        static let prayer = "prayer"
        static let quran = "quran"
        static let learn = "learn"
        static let chat = "chat"
        static let family = "family"
        static let settings = "settings"
    }

    // MARK: - Storage Keys
    enum StorageKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastAppVersion = "lastAppVersion"
        static let calculationMethod = "calculationMethod"
        static let notificationOffset = "notificationOffset"
        static let selectedReciter = "selectedReciter"
        static let lastQuranPosition = "lastQuranPosition"
    }

    // MARK: - Notification Categories
    enum NotificationCategories {
        static let prayerReminder = "PRAYER_REMINDER"
        static let dailyReminder = "DAILY_REMINDER"
        static let streakReminder = "STREAK_REMINDER"
    }

    // MARK: - Notification Identifiers
    enum NotificationIdentifiers {
        static let fajr = "notification_fajr"
        static let dhuhr = "notification_dhuhr"
        static let asr = "notification_asr"
        static let maghrib = "notification_maghrib"
        static let isha = "notification_isha"
        static let suhoor = "notification_suhoor"
        static let iftar = "notification_iftar"
    }

    // MARK: - Limits
    enum Limits {
        static let maxChatMessageLength = 2000
        static let maxBookmarks = 100
        static let maxConversations = 50
        static let maxFamilyMembers = 10
    }

    // MARK: - Timing
    enum Timing {
        static let animationDuration: Double = 0.3
        static let debounceDelay: Double = 0.5
        static let locationCacheMinutes: Int = 5
        static let widgetRefreshMinutes: Int = 15
    }

    // MARK: - Defaults
    enum Defaults {
        static let calculationMethod: CalculationMethod = .isna
        static let notificationOffsetMinutes: Int = 5
        static let tasbeehTargetCount: Int = 33
    }
}
