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
        static let website = URL(string: "https://mansoor2016.github.io/safa-legal")!
        static let privacyPolicy = URL(string: "https://mansoor2016.github.io/safa-legal/privacy")!
        static let termsOfService = URL(string: "https://mansoor2016.github.io/safa-legal/terms")!
        static let support = URL(string: "mailto:helpmesafa@gmail.com")!
        static let feedback = URL(string: "mailto:helpmesafa@gmail.com")!

        // App Store URLs — update appStoreId after App Store approval
        static let appStoreId = "" // TODO: Replace with real App Store ID (e.g. "id6741076498")
        static let appStore = URL(string: "https://apps.apple.com/app/safa/\(appStoreId)")!
        static let testFlight = URL(string: "https://testflight.apple.com/join/QhcJrVg6")!

        /// The best available download link: App Store if published, otherwise TestFlight.
        static var downloadURL: URL {
            appStoreId.isEmpty ? testFlight : appStore
        }
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
        static let settings = "settings"
    }

    // MARK: - Storage Keys (UserDefaults)
    // All UserDefaults keys centralized here to prevent typos and aid discovery.
    enum StorageKeys {
        // App State
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastAppVersion = "lastAppVersion"
        static let featureFlags = "com.safa.featureFlags"

        // Prayer
        static let calculationMethod = "calculationMethod"
        static let prayerLogs = "com.safa.prayerLogs"
        static let prayerLogsMigrated = "com.safa.prayerLogsMigratedToAppGroup"

        // Notifications
        static let adhanSilentModeTipShown = "com.safa.notifications.adhanSilentModeTipShown"
        static let notificationOffset = "notificationOffset"
        static let notificationMosqueMode = "com.safa.notifications.mosqueMode"
        static let notificationVibrationOnly = "com.safa.notifications.vibrationOnly"
        static let notificationTravelTime = "com.safa.notifications.travelTime"
        static let notificationLastScheduled = "com.safa.notifications.lastScheduledDate"

        // Theme & Appearance
        static let themeColorScheme = "com.safa.theme.colorScheme"
        static let themeAccentColor = "com.safa.theme.accentColor"
        static let hapticsEnabled = "com.safa.haptics.enabled"

        // Quran
        static let quranBookmarks = "com.safa.quran.bookmarks"
        static let quranProgress = "com.safa.quran.progress"
        static let lastQuranPosition = "lastQuranPosition"
        static let selectedReciter = "selectedReciter"

        // Hadith
        static let hadithBookmarks = "com.safa.hadith.bookmarks"

        // Dua & Dhikr
        static let duaFavorites = "com.safa.dua.favorites"
        static let dhikrCompletion = "com.safa.dhikr.completion"
        static let dhikrDate = "com.safa.dhikr.date"

        // Chat
        static let chatConversations = "com.safa.chat.conversations"
        static let chatMessagesPrefix = "com.safa.chat.messages."
        static let chatActiveConversation = "com.safa.chat.active"

        // Learning
        static let learningProgress = "com.safa.learning.progress"
        static let learningCompleted = "com.safa.learning.completed"
        static let learningPronunciation = "com.safa.learning.pronunciation"

        // User State
        static let userStats = "com.safa.user.stats"
        static let userStreaks = "com.safa.user.streaks"
        static let userAchievements = "com.safa.user.achievements"
        static let userPreferences = "com.safa.user.preferences"

        // Ramadan
        static let ramadanEnabled = "com.safa.ramadan.enabled"
        static let ramadanSuhoorReminder = "com.safa.ramadan.suhoorReminder"
        static let ramadanIftarReminder = "com.safa.ramadan.iftarReminder"
        static let ramadanTaraweehReminder = "com.safa.ramadan.taraweehReminder"
        static let ramadanSuhoorMinutes = "com.safa.ramadan.suhoorMinutes"
        static let ramadanIftarMinutes = "com.safa.ramadan.iftarMinutes"
        static let ramadanFastingDays = "com.safa.ramadan.fastingDays"
        static let ramadanTaraweehDays = "com.safa.ramadan.taraweehDays"

        // Wind Down / Sleep
        static let windDownBedtime = "com.safa.windDown.bedtime"
        static let windDownWakeTime = "com.safa.windDown.wakeTime"
        static let windDownFajrAlarm = "com.safa.windDown.fajrAlarm"
        static let windDownReminder = "com.safa.windDown.reminder"
        static let windDownMinutes = "com.safa.windDown.minutes"

        // Islamic Events
        static let islamicEventsEnabled = "com.safa.islamicEvents.enabled"
        static let islamicEventsReminderDays = "com.safa.islamicEvents.reminderDays"

        // Calendar
        static let calendarIdentifier = "com.safa.calendarIdentifier"

        // Core Data
        static let coreDataModelVersion = "com.safa.coredata.modelVersion"

        // Share Banner
        static let shareBannerDismissed = "share_banner_dismissed"

        // Tasbeeh Widget
        static let tasbeehWidgetCount = "com.safa.tasbeeh.widgetCount"
        static let tasbeehDhikrType = "com.safa.tasbeeh.dhikrType"

        // Predictive Download
        static let predictiveReadingHistory = "com.safa.predictive.readingHistory"
        static let predictiveDownloadQueue = "com.safa.predictive.downloadQueue"
        static let predictiveEnabled = "com.safa.predictive.enabled"
        static let predictiveWifiOnly = "com.safa.predictive.wifiOnly"

        // HealthKit
        static let healthKitSyncEnabled = "com.safa.healthkit.syncEnabled"
        static let healthKitHasPrompted = "com.safa.healthkit.hasPrompted"
        static let healthKitFastingLogs = "com.safa.healthkit.fastingLogs"

        // Fasting
        static let fastingSource = "com.safa.fasting.source"
        static let fastingType = "com.safa.fasting.type"

        // Invites
        static let inviteCount = "com.safa.invite.count"
        static let inviteHasanatAwarded = "com.safa.invite.hasanatAwarded"
        static let inviteWasInvited = "com.safa.invite.wasInvited"

        // Spotlight
        static let spotlightIndexed = "com.safa.spotlight.indexed"
        static let spotlightIndexDate = "com.safa.spotlight.indexDate"
        static let spotlightIndexCount = "com.safa.spotlight.indexCount"
        static let spotlightIndexVersion = "com.safa.spotlight.indexVersion"

        // Eid
        static let eidBannerDismissedPrefix = "eid_banner_dismissed_"

        // Qada (missed fast) Reminder
        static let qadaReminderShownHijriYear = "com.safa.ramadan.qadaReminderShownHijriYear"

        // App Review
        static let reviewFirstLaunchDate = "com.safa.review.firstLaunchDate"
        static let reviewPromptCount = "com.safa.review.promptCount"
        static let reviewOptedOut = "com.safa.review.optedOut"
        static let reviewLastPromptDate = "com.safa.review.lastPromptDate"

        // Storage Cleanup
        static let storageAudioMetadata = "com.safa.storage.audioMetadata"
        static let storageAutoCleanup = "com.safa.storage.autoCleanup"
        static let storageLastCleanup = "com.safa.storage.lastCleanup"
        static let storageRetentionPeriod = "com.safa.storage.retentionPeriod"
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
