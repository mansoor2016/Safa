// MARK: - NotificationService.swift
// PURPOSE: Push notification scheduling for prayer times and reminders
// DEPENDENCIES: UserNotifications

import Foundation
import UserNotifications
import Combine

final class NotificationService: ObservableObject {
    // MARK: - Published State
    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Init
    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await notificationCenter.requestAuthorization(options: options)
        await MainActor.run {
            self.isAuthorized = granted
        }
        return granted
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Prayer Notifications

    func schedulePrayerNotification(
        prayer: PrayerType,
        time: Date,
        offsetMinutes: Int = 0
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Prayer Time"
        content.body = offsetMinutes > 0
            ? "\(prayer.displayName) in \(offsetMinutes) minutes"
            : "It's time for \(prayer.displayName)"
        content.sound = .default
        content.categoryIdentifier = "PRAYER_REMINDER"

        let triggerDate = Calendar.current.date(
            byAdding: .minute,
            value: -offsetMinutes,
            to: time
        ) ?? time

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let identifier = "prayer_\(prayer.rawValue)_\(time.timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    func scheduleDailyPrayerNotifications(
        prayers: [PrayerTime],
        offsetMinutes: Int = 0
    ) async throws {
        // Remove existing prayer notifications
        await removeAllPrayerNotifications()

        // Schedule new ones
        for prayer in prayers {
            try await schedulePrayerNotification(
                prayer: prayer.type,
                time: prayer.time,
                offsetMinutes: offsetMinutes
            )
        }
    }

    // MARK: - General Notifications

    func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        at date: Date,
        repeats: Bool = false
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            repeats ? [.hour, .minute] : [.year, .month, .day, .hour, .minute],
            from: date
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: repeats
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    // MARK: - Remove Notifications

    func removeAllPrayerNotifications() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let prayerIdentifiers = requests
            .filter { $0.identifier.hasPrefix("prayer_") }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: prayerIdentifiers)
    }

    func removeNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func removeAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Achievement Notifications

    func showAchievementNotification(achievement: Achievement) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked! 🏆"
        content.body = "\(achievement.title): \(achievement.description)"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "ACHIEVEMENT_UNLOCKED"

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        let identifier = "achievement_\(achievement.id)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    func showLocalNotification(
        title: String,
        body: String,
        categoryIdentifier: String = "GENERAL"
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        let identifier = "local_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    // MARK: - Notification Categories

    func registerNotificationCategories() {
        let prayerCategory = UNNotificationCategory(
            identifier: "PRAYER_REMINDER",
            actions: [
                UNNotificationAction(
                    identifier: "LOG_PRAYER",
                    title: "Log Prayer",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "SNOOZE",
                    title: "Remind in 10 min",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        let achievementCategory = UNNotificationCategory(
            identifier: "ACHIEVEMENT_UNLOCKED",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_ACHIEVEMENT",
                    title: "View",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        let ramadanCategory = UNNotificationCategory(
            identifier: "RAMADAN_REMINDER",
            actions: [
                UNNotificationAction(
                    identifier: "LOG_FAST",
                    title: "Log Fast",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([
            prayerCategory,
            achievementCategory,
            ramadanCategory
        ])
    }
}
