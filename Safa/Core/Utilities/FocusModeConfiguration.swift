// MARK: - FocusModeConfiguration.swift
// PURPOSE: Guide and utilities for Focus Mode integration
// DEPENDENCIES: Foundation, UserNotifications

import Foundation
import UserNotifications

// MARK: - Focus Mode Configuration Guide

/// # Focus Mode Integration Guide for Safa
///
/// iOS Focus Mode allows users to filter notifications and customize their device
/// behavior during specific activities. Safa can integrate with Focus Mode to:
///
/// 1. **Prayer Focus**: Silence non-prayer notifications during prayer times
/// 2. **Quran Focus**: Create distraction-free reading environment
/// 3. **Sleep Focus**: Wind-down mode that integrates with iOS Sleep
///
/// ## Setup Requirements
///
/// ### 1. Notification Categories
/// Register notification categories that can be filtered by Focus Mode:
/// ```swift
/// let prayerCategory = UNNotificationCategory(
///     identifier: "PRAYER_REMINDER",
///     actions: [...],
///     intentIdentifiers: [],
///     options: [.allowInCarPlay]
/// )
/// ```
///
/// ### 2. App Intent Integration
/// Declare Focus Filter intents in your app's Info.plist:
/// ```xml
/// <key>NSUserActivityTypes</key>
/// <array>
///     <string>com.safa.app.prayerFocus</string>
///     <string>com.safa.app.quranFocus</string>
/// </array>
/// ```
///
/// ### 3. Handling Focus Status
/// Check current Focus status to adapt app behavior:
/// ```swift
/// let center = UNUserNotificationCenter.current()
/// let settings = await center.notificationSettings()
/// let isFocusActive = settings.authorizationStatus == .authorized
/// ```

// MARK: - Focus Mode Service

@Observable
final class FocusModeService {

    // MARK: - Properties

    private let notificationCenter = UNUserNotificationCenter.current()

    var isPrayerFocusActive: Bool = false
    var isQuranFocusActive: Bool = false
    var isSleepFocusActive: Bool = false

    // MARK: - Notification Categories

    /// Categories for different notification types
    enum NotificationCategory: String, CaseIterable {
        case prayerReminder = "PRAYER_REMINDER"
        case prayerTime = "PRAYER_TIME"
        case quranReminder = "QURAN_REMINDER"
        case streakReminder = "STREAK_REMINDER"
        case achievementUnlocked = "ACHIEVEMENT_UNLOCKED"
        case generalReminder = "GENERAL_REMINDER"

        /// Whether this category should be allowed during Prayer Focus
        var allowedDuringPrayerFocus: Bool {
            switch self {
            case .prayerReminder, .prayerTime:
                return true
            default:
                return false
            }
        }

        /// Whether this category should be allowed during Quran Focus
        var allowedDuringQuranFocus: Bool {
            switch self {
            case .prayerTime:
                return true
            default:
                return false
            }
        }

        /// Whether this category should be allowed during Sleep Focus
        var allowedDuringSleepFocus: Bool {
            return false // All silenced during sleep except alarms
        }

        /// Interruption level for this category
        var interruptionLevel: UNNotificationInterruptionLevel {
            switch self {
            case .prayerTime:
                return .timeSensitive
            case .prayerReminder:
                return .active
            case .achievementUnlocked:
                return .passive
            default:
                return .active
            }
        }
    }

    // MARK: - Initialization

    init() {
        Task {
            await registerNotificationCategories()
        }
    }

    // MARK: - Category Registration

    /// Register all notification categories with the system
    func registerNotificationCategories() async {
        var categories: Set<UNNotificationCategory> = []

        // Prayer Time Category - time sensitive
        let prayerTimeActions = [
            UNNotificationAction(
                identifier: "LOG_PRAYER",
                title: String(localized: "Mark as Prayed"),
                options: [.foreground]
            ),
            UNNotificationAction(
                identifier: "OPEN_QIBLA",
                title: String(localized: "Open Qibla"),
                options: [.foreground]
            )
        ]

        let prayerTimeCategory = UNNotificationCategory(
            identifier: NotificationCategory.prayerTime.rawValue,
            actions: prayerTimeActions,
            intentIdentifiers: [],
            options: [.allowInCarPlay, .customDismissAction]
        )
        categories.insert(prayerTimeCategory)

        // Prayer Reminder Category
        let prayerReminderCategory = UNNotificationCategory(
            identifier: NotificationCategory.prayerReminder.rawValue,
            actions: prayerTimeActions,
            intentIdentifiers: [],
            options: []
        )
        categories.insert(prayerReminderCategory)

        // Quran Reminder Category
        let quranActions = [
            UNNotificationAction(
                identifier: "OPEN_QURAN",
                title: String(localized: "Continue Reading"),
                options: [.foreground]
            )
        ]

        let quranCategory = UNNotificationCategory(
            identifier: NotificationCategory.quranReminder.rawValue,
            actions: quranActions,
            intentIdentifiers: [],
            options: []
        )
        categories.insert(quranCategory)

        // Streak Reminder Category
        let streakActions = [
            UNNotificationAction(
                identifier: "OPEN_APP",
                title: String(localized: "Open Safa"),
                options: [.foreground]
            )
        ]

        let streakCategory = UNNotificationCategory(
            identifier: NotificationCategory.streakReminder.rawValue,
            actions: streakActions,
            intentIdentifiers: [],
            options: []
        )
        categories.insert(streakCategory)

        // Achievement Category - passive notifications
        let achievementCategory = UNNotificationCategory(
            identifier: NotificationCategory.achievementUnlocked.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        categories.insert(achievementCategory)

        // General Reminder Category
        let generalCategory = UNNotificationCategory(
            identifier: NotificationCategory.generalReminder.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        categories.insert(generalCategory)

        // Register all categories
        notificationCenter.setNotificationCategories(categories)
    }

    // MARK: - Focus Status Checking

    /// Check current notification settings
    func checkFocusStatus() async {
        let settings = await notificationCenter.notificationSettings()

        // Note: iOS doesn't expose which Focus is active directly
        // We can only check general authorization and notification settings
        let isAuthorized = settings.authorizationStatus == .authorized

        // Log for debugging
        print("Notification Authorization: \(isAuthorized)")
        print("Alert Setting: \(settings.alertSetting.rawValue)")
        print("Sound Setting: \(settings.soundSetting.rawValue)")
    }

    // MARK: - Scheduling with Focus Support

    /// Schedule a notification with appropriate Focus Mode handling
    func scheduleNotification(
        title: String,
        body: String,
        category: NotificationCategory,
        triggerDate: Date,
        identifier: String
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = category.rawValue
        content.interruptionLevel = category.interruptionLevel

        // Set relevance score based on category
        switch category {
        case .prayerTime:
            content.relevanceScore = 1.0 // Highest
        case .prayerReminder:
            content.relevanceScore = 0.9
        case .streakReminder:
            content.relevanceScore = 0.7
        default:
            content.relevanceScore = 0.5
        }

        // Add sound for important notifications
        if category == .prayerTime {
            content.sound = .default
        }

        // Create trigger
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        // Create request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    /// Cancel a scheduled notification
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel all notifications of a specific category
    func cancelNotifications(category: NotificationCategory) {
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiers = requests
                .filter { $0.content.categoryIdentifier == category.rawValue }
                .map { $0.identifier }

            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
}

// MARK: - Focus Mode Filter Intent (Guide)

/// # Implementing Focus Filter Intents
///
/// To create custom Focus Filters that appear in Settings > Focus,
/// you need to implement an App Intent:
///
/// ```swift
/// import AppIntents
///
/// @available(iOS 16.0, *)
/// struct PrayerFocusFilter: SetFocusFilterIntent {
///     static var title: LocalizedStringResource = "Prayer Time Focus"
///     static var description: IntentDescription = "Customize Safa during prayer times"
///
///     @Parameter(title: "Show Only Prayer Notifications")
///     var prayerNotificationsOnly: Bool
///
///     @Parameter(title: "Enable Qibla Compass")
///     var enableQibla: Bool
///
///     func perform() async throws -> some IntentResult {
///         // Apply the focus filter settings
///         return .result()
///     }
/// }
/// ```
///
/// This requires:
/// 1. iOS 16.0+
/// 2. App Intents framework
/// 3. Focus Filter capability in Signing & Capabilities

// MARK: - Focus Mode UI Helpers

extension FocusModeService {

    /// Get user-facing text for Focus Mode setup
    var setupInstructions: [String] {
        [
            String(localized: "1. Open Settings on your iPhone"),
            String(localized: "2. Tap Focus"),
            String(localized: "3. Create a new Focus or edit an existing one"),
            String(localized: "4. Under 'Allowed Notifications', add Safa"),
            String(localized: "5. Choose which Safa notification types to allow"),
            String(localized: "6. Optional: Schedule the Focus for prayer times")
        ]
    }

    /// Generate a Focus Mode configuration summary
    func getConfigurationSummary() -> String {
        String(localized: """
        Safa Focus Mode Configuration:

        Prayer Notifications: Time Sensitive
        - Will break through most Focus modes
        - Includes prayer time alerts

        Streak Reminders: Active
        - Regular notification priority
        - Can be filtered by Focus

        Achievement Notifications: Passive
        - Low priority, silent
        - Shown in Notification Center only

        To customize, go to:
        Settings > Focus > [Your Focus] > Apps > Safa
        """)
    }
}
