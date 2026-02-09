// MARK: - NotificationScheduler.swift
// PURPOSE: Schedule and manage notifications for prayer times, reminders, etc.
// DEPENDENCIES: UserNotifications, Foundation

import Foundation
import UserNotifications

// MARK: - Notification Scheduler

@Observable
final class NotificationScheduler {

    // MARK: - Shared Instance
    static let shared = NotificationScheduler()

    // MARK: - Properties

    private let center = UNUserNotificationCenter.current()
    private let focusService = FocusModeService()

    var isAuthorized: Bool = false
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Storage Keys
    private let lastScheduledDateKey = AppConstants.StorageKeys.notificationLastScheduled

    // MARK: - Initialization

    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Daily Re-Scheduling (App Launch)

    /// Call from SafaApp.task{} to ensure notifications are scheduled for today.
    /// Skips if already scheduled today.
    func scheduleIfNeeded() async {
        await checkAuthorizationStatus()
        guard isAuthorized else { return }

        // Check if we already scheduled today
        if let lastDate = UserDefaults.standard.object(forKey: lastScheduledDateKey) as? Date,
           Calendar.current.isDateInToday(lastDate) {
            return
        }

        await scheduleTodaysPrayerNotifications()
    }

    /// Force re-schedule (e.g. when calculation method changes)
    func forceReschedule() async {
        await checkAuthorizationStatus()
        guard isAuthorized else { return }
        await scheduleTodaysPrayerNotifications()
    }

    private func scheduleTodaysPrayerNotifications() async {
        let prefs = await PreferencesManager.shared.getPreferences()
        let enabledPrayers = Set(prefs.notificationEnabledPrayers.compactMap { PrayerType(rawValue: $0) })
        guard !enabledPrayers.isEmpty else { return }

        guard let coords = Dependencies.shared.locationService.coordinates else { return }

        let method: CalculationMethod
        if let raw = UserDefaults.standard.string(forKey: "calculationMethod"),
           let saved = CalculationMethod(rawValue: raw) {
            method = saved
        } else {
            method = AppDefaults.calculationMethod
        }

        do {
            let prayers = try await Dependencies.shared.prayerRepository.getPrayers(
                for: Date(),
                location: coords,
                method: method
            )

            await cancelPrayerNotifications()

            let now = Date()
            for prayer in prayers where prayer.type.isObligatory && enabledPrayers.contains(prayer.type) && prayer.time > now {
                let content = UNMutableNotificationContent()
                content.title = String(localized: "\(prayer.type.displayName) Time")
                content.body = String(localized: "It's time for \(prayer.type.displayName) prayer")
                content.sound = .default
                content.interruptionLevel = .timeSensitive
                content.categoryIdentifier = FocusModeService.NotificationCategory.prayerTime.rawValue
                content.userInfo = ["prayerType": prayer.type.rawValue]

                // Adhan sound selection:
                // 1. Global adhan enabled → use selected adhan for all prayers
                // 2. Iftar adhan enabled + Ramadan + Maghrib → use adhan just for iftar
                let isRamadanIftarAdhan = prefs.iftarAdhanEnabled
                    && prayer.type == .maghrib
                    && HijriDateConverter.shared.isRamadan()

                if prefs.adhanEnabled || isRamadanIftarAdhan {
                    let fileName = prayer.type == .fajr ? prefs.selectedFajrAdhan : prefs.selectedAdhan
                    content.sound = UNNotificationSound(named: UNNotificationSoundName("\(fileName)_notification.caf"))
                }

                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: prayer.time
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "prayer_at_\(prayer.type.rawValue)",
                    content: content,
                    trigger: trigger
                )

                try await center.add(request)
            }

            UserDefaults.standard.set(Date(), forKey: lastScheduledDateKey)
        } catch {
            // Silently fail — notifications are best-effort
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge, .criticalAlert, .provisional]
            )
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            authorizationStatus = settings.authorizationStatus
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Prayer Notifications

    /// Schedule notifications for all prayer times
    func schedulePrayerNotifications(
        prayers: DailyPrayerTimes,
        notifyBefore: TimeInterval = 600, // 10 minutes before
        notifyAt: Bool = true
    ) async throws {
        // Remove existing prayer notifications
        await cancelPrayerNotifications()

        let prayerTimes = [
            prayers.fajr,
            prayers.dhuhr,
            prayers.asr,
            prayers.maghrib,
            prayers.isha
        ]

        for prayerTime in prayerTimes {
            // Notification at prayer time
            if notifyAt {
                try await scheduleNotification(
                    identifier: "prayer_at_\(prayerTime.type.rawValue)",
                    title: "\(prayerTime.type.displayName) Time",
                    body: "It's time for \(prayerTime.type.displayName) prayer",
                    date: prayerTime.time,
                    category: .prayerTime,
                    sound: .default
                )
            }

            // Notification before prayer time
            let beforeTime = prayerTime.time.addingTimeInterval(-notifyBefore)
            if beforeTime > Date() {
                try await scheduleNotification(
                    identifier: "prayer_before_\(prayerTime.type.rawValue)",
                    title: "\(prayerTime.type.displayName) in \(Int(notifyBefore / 60)) minutes",
                    body: "Prepare for \(prayerTime.type.displayName) prayer",
                    date: beforeTime,
                    category: .prayerReminder,
                    sound: nil
                )
            }
        }
    }

    /// Cancel all prayer notifications (current + legacy identifier formats)
    func cancelPrayerNotifications() async {
        // Current format: prayer_at_fajr, prayer_before_fajr
        var identifiers = PrayerType.allCases.flatMap { type in
            ["prayer_at_\(type.rawValue)", "prayer_before_\(type.rawValue)"]
        }

        // Legacy format from old PrayerViewModel: prayer_fajr
        identifiers += PrayerType.allCases.map { "prayer_\($0.rawValue)" }

        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        // Legacy timestamp-based format: prayer_fajr_1707234000.123
        // These have unpredictable identifiers, so find and cancel by scanning pending
        let pending = await center.pendingNotificationRequests()
        let timestampIDs = pending
            .map { $0.identifier }
            .filter { id in
                // Match prayer_<type>_<digits> but NOT prayer_at_* or prayer_before_*
                id.starts(with: "prayer_") &&
                !id.starts(with: "prayer_at_") &&
                !id.starts(with: "prayer_before_") &&
                !identifiers.contains(id) // not already handled above
            }
        if !timestampIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: timestampIDs)
        }
    }

    // MARK: - Streak Reminders

    /// Schedule streak reminder notification
    func scheduleStreakReminder(
        streakType: StreakType,
        currentCount: Int,
        at date: Date
    ) async throws {
        let identifier = "streak_reminder_\(streakType.rawValue)"

        let title = "Don't break your streak!"
        let body = "You're on a \(currentCount)-day \(streakType.displayName) streak. Keep it going!"

        try await scheduleNotification(
            identifier: identifier,
            title: title,
            body: body,
            date: date,
            category: .streakReminder,
            sound: nil
        )
    }

    /// Cancel streak reminder
    func cancelStreakReminder(for type: StreakType) {
        center.removePendingNotificationRequests(
            withIdentifiers: ["streak_reminder_\(type.rawValue)"]
        )
    }

    // MARK: - Dhikr Reminders

    /// Schedule morning dhikr reminder
    func scheduleMorningDhikrReminder(at date: Date) async throws {
        try await scheduleNotification(
            identifier: "morning_dhikr_reminder",
            title: "Morning Dhikr",
            body: "Start your day with remembrance of Allah",
            date: date,
            category: .generalReminder,
            sound: nil
        )
    }

    /// Schedule evening dhikr reminder
    func scheduleEveningDhikrReminder(at date: Date) async throws {
        try await scheduleNotification(
            identifier: "evening_dhikr_reminder",
            title: "Evening Dhikr",
            body: "End your day with remembrance of Allah",
            date: date,
            category: .generalReminder,
            sound: nil
        )
    }

    // MARK: - Achievement Notifications

    /// Show achievement unlocked notification
    func showAchievementUnlocked(achievement: Achievement) async throws {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Achievement Unlocked!")
        content.body = achievement.title
        content.categoryIdentifier = FocusModeService.NotificationCategory.achievementUnlocked.rawValue
        content.interruptionLevel = .passive // Silent notification
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: "achievement_\(achievement.id)",
            content: content,
            trigger: nil // Immediate
        )

        try await center.add(request)
    }

    // MARK: - Ramadan Notifications

    /// Schedule Suhoor reminder
    func scheduleSuhoorReminder(at date: Date) async throws {
        try await scheduleNotification(
            identifier: "suhoor_reminder",
            title: "Suhoor Time",
            body: "Time for pre-dawn meal. May your fast be accepted.",
            date: date,
            category: .generalReminder,
            sound: .default
        )
    }

    /// Schedule Iftar reminder
    func scheduleIftarReminder(at date: Date) async throws {
        try await scheduleNotification(
            identifier: "iftar_reminder",
            title: "Iftar Time",
            body: "Time to break your fast. Bismillah!",
            date: date,
            category: .generalReminder,
            sound: .default
        )
    }

    // MARK: - Private Helpers

    private func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        date: Date,
        category: FocusModeService.NotificationCategory,
        sound: UNNotificationSound?
    ) async throws {
        guard date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = category.rawValue
        content.interruptionLevel = category.interruptionLevel

        if let sound = sound {
            content.sound = sound
        }

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - Notification Management

    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }

    /// Cancel specific notification
    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel all notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    /// Get delivered notifications
    func getDeliveredNotifications() async -> [UNNotification] {
        return await center.deliveredNotifications()
    }

    /// Remove delivered notifications
    func removeDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
    }
}

// MARK: - Notification Response Handler

final class NotificationResponseHandler: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationResponseHandler()

    private override init() {
        super.init()
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier

        // Handle based on notification type
        if identifier.starts(with: "prayer_") {
            handlePrayerNotificationTap(identifier: identifier, action: actionIdentifier)
        } else if identifier.starts(with: "streak_") {
            handleStreakNotificationTap(identifier: identifier)
        } else if identifier.starts(with: "achievement_") {
            handleAchievementNotificationTap(identifier: identifier)
        }

        completionHandler()
    }

    private func handlePrayerNotificationTap(identifier: String, action: String) {
        switch action {
        case "LOG_PRAYER":
            // Log prayer action
            NotificationCenter.default.post(
                name: .logPrayerFromNotification,
                object: identifier
            )
        case "OPEN_QIBLA":
            // Open Qibla view
            NotificationCenter.default.post(
                name: .openQiblaFromNotification,
                object: nil
            )
        default:
            // Default tap - open app to prayer view
            NotificationCenter.default.post(
                name: .openPrayerFromNotification,
                object: nil
            )
        }
    }

    private func handleStreakNotificationTap(identifier: String) {
        NotificationCenter.default.post(
            name: .openProgressFromNotification,
            object: nil
        )
    }

    private func handleAchievementNotificationTap(identifier: String) {
        NotificationCenter.default.post(
            name: .openAchievementsFromNotification,
            object: nil
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let logPrayerFromNotification = Notification.Name("logPrayerFromNotification")
    static let openQiblaFromNotification = Notification.Name("openQiblaFromNotification")
    static let openPrayerFromNotification = Notification.Name("openPrayerFromNotification")
    static let openProgressFromNotification = Notification.Name("openProgressFromNotification")
    static let openAchievementsFromNotification = Notification.Name("openAchievementsFromNotification")
}
