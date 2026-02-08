// MARK: - NotificationService.swift
// PURPOSE: Push notification scheduling for prayer times and reminders
// DEPENDENCIES: UserNotifications

import Foundation
import UserNotifications
import Combine

final class NotificationService: ObservableObject, NotificationServiceProtocol {
    // MARK: - Published State
    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Settings
    @Published var mosqueModeEnabled: Bool {
        didSet { UserDefaults.standard.set(mosqueModeEnabled, forKey: mosqueModeKey) }
    }
    @Published var vibrationOnly: Bool {
        didSet { UserDefaults.standard.set(vibrationOnly, forKey: vibrationOnlyKey) }
    }
    @Published var travelTimeMinutes: Int {
        didSet { UserDefaults.standard.set(travelTimeMinutes, forKey: travelTimeKey) }
    }

    // Storage Keys
    private let mosqueModeKey = AppConstants.StorageKeys.notificationMosqueMode
    private let vibrationOnlyKey = AppConstants.StorageKeys.notificationVibrationOnly
    private let travelTimeKey = AppConstants.StorageKeys.notificationTravelTime

    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Init
    init() {
        // Load saved settings
        self.mosqueModeEnabled = UserDefaults.standard.bool(forKey: mosqueModeKey)
        self.vibrationOnly = UserDefaults.standard.object(forKey: vibrationOnlyKey) as? Bool ?? true // Default: vibration only
        self.travelTimeMinutes = UserDefaults.standard.object(forKey: travelTimeKey) as? Int ?? 15 // Default: 15 minutes

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
        content.title = String(localized: "Prayer Time")

        // Calculate effective offset including mosque mode travel time
        let effectiveOffset = mosqueModeEnabled ? offsetMinutes + travelTimeMinutes : offsetMinutes

        if effectiveOffset > 0 {
            if mosqueModeEnabled {
                content.body = String(localized: "\(prayer.displayName) in \(effectiveOffset) minutes. Time to head to the mosque!")
            } else {
                content.body = String(localized: "\(prayer.displayName) in \(effectiveOffset) minutes")
            }
        } else {
            content.body = String(localized: "It's time for \(prayer.displayName)")
        }

        // Use vibration only (no sound) by default
        if vibrationOnly {
            content.sound = nil
            // On iOS, setting sound to nil still allows the system default behavior
            // To ensure vibration, we use a silent sound or the default critical alert
        } else {
            content.sound = .default
        }

        content.categoryIdentifier = "PRAYER_REMINDER"

        // Add prayer type to userInfo for action handling
        content.userInfo = [
            "prayerType": prayer.rawValue,
            "prayerTime": time.timeIntervalSince1970
        ]

        let triggerDate = Calendar.current.date(
            byAdding: .minute,
            value: -effectiveOffset,
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
        content.title = String(localized: "Achievement Unlocked! 🏆")
        content.body = String(localized: "\(achievement.title): \(achievement.description)")
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

    // MARK: - Islamic Event Notifications

    /// Schedule notifications for Islamic events (Eid, Ramadan, etc.)
    func scheduleIslamicEventNotification(
        eventType: IslamicCalendarEvent.IslamicEventType,
        eventDate: Date,
        daysBefore: Int = 1
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = eventType.notificationTitle
        content.body = eventType.notificationBody(daysBefore: daysBefore)
        content.sound = vibrationOnly ? nil : .default
        content.categoryIdentifier = "ISLAMIC_EVENT"
        content.userInfo = ["eventType": eventType.rawValue]

        // Schedule for day before the event (or on the day)
        let triggerDate = Calendar.current.date(
            byAdding: .day,
            value: -daysBefore,
            to: eventDate
        ) ?? eventDate

        // Set notification for 9 AM on that day
        var components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: triggerDate
        )
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let identifier = "event_\(eventType.rawValue)_\(eventDate.timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    /// Schedule notifications for all upcoming Islamic events
    func scheduleAllIslamicEventNotifications(events: [IslamicCalendarEvent]) async throws {
        // Remove existing event notifications
        let requests = await notificationCenter.pendingNotificationRequests()
        let eventIdentifiers = requests
            .filter { $0.identifier.hasPrefix("event_") }
            .map { $0.identifier }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: eventIdentifiers)

        // Schedule new ones
        for event in events {
            // Notify 1 day before
            try await scheduleIslamicEventNotification(
                eventType: event.eventType,
                eventDate: event.startDate,
                daysBefore: 1
            )

            // Also notify on the day for major events
            if event.eventType == .eidAlFitr || event.eventType == .eidAlAdha || event.eventType == .ramadan {
                try await scheduleIslamicEventNotification(
                    eventType: event.eventType,
                    eventDate: event.startDate,
                    daysBefore: 0
                )
            }
        }
    }

    // MARK: - Notification Categories

    func registerNotificationCategories() {
        let prayerCategory = UNNotificationCategory(
            identifier: "PRAYER_REMINDER",
            actions: [
                UNNotificationAction(
                    identifier: "DONE_PRAYER",
                    title: String(localized: "Done \u{2713}"),
                    options: [] // Does not open app - logs prayer silently
                ),
                UNNotificationAction(
                    identifier: "SNOOZE",
                    title: String(localized: "Remind in 10 min"),
                    options: []
                ),
                UNNotificationAction(
                    identifier: "VIEW_TIMES",
                    title: String(localized: "View Times"),
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let achievementCategory = UNNotificationCategory(
            identifier: "ACHIEVEMENT_UNLOCKED",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_ACHIEVEMENT",
                    title: String(localized: "View"),
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
                    title: String(localized: "Log Fast"),
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        let islamicEventCategory = UNNotificationCategory(
            identifier: "ISLAMIC_EVENT",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_CALENDAR",
                    title: String(localized: "View Calendar"),
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "DISMISS",
                    title: String(localized: "Dismiss"),
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([
            prayerCategory,
            achievementCategory,
            ramadanCategory,
            islamicEventCategory
        ])
    }

    // MARK: - Notification Action Handling

    /// Handle notification action (called from AppDelegate/SceneDelegate)
    func handleNotificationAction(
        identifier: String,
        userInfo: [AnyHashable: Any],
        completion: @escaping () -> Void
    ) {
        switch identifier {
        case "DONE_PRAYER":
            // Log the prayer from the notification
            if let prayerTypeRaw = userInfo["prayerType"] as? String,
               let prayerType = PrayerType(rawValue: prayerTypeRaw) {
                // Post notification for the app to handle logging
                NotificationCenter.default.post(
                    name: .prayerLoggedFromNotification,
                    object: nil,
                    userInfo: ["prayerType": prayerType]
                )
            }

        case "SNOOZE":
            // Reschedule notification for 10 minutes later
            if let prayerTypeRaw = userInfo["prayerType"] as? String,
               let prayerType = PrayerType(rawValue: prayerTypeRaw) {
                Task {
                    try? await schedulePrayerNotification(
                        prayer: prayerType,
                        time: Date().addingTimeInterval(10 * 60),
                        offsetMinutes: 0
                    )
                }
            }

        case "LOG_FAST":
            // Post notification for Ramadan fasting log
            NotificationCenter.default.post(
                name: .fastLoggedFromNotification,
                object: nil
            )

        default:
            break
        }

        completion()
    }
}

// MARK: - Islamic Event Type Extension

extension IslamicCalendarEvent.IslamicEventType {
    var notificationTitle: String {
        switch self {
        case .eidAlFitr: return String(localized: "Eid al-Fitr")
        case .eidAlAdha: return String(localized: "Eid al-Adha")
        case .ramadan: return String(localized: "Ramadan")
        case .islamicNewYear: return String(localized: "Islamic New Year")
        case .ashura: return String(localized: "Day of Ashura")
        case .mawlidAlNabi: return String(localized: "Mawlid al-Nabi")
        case .isra: return String(localized: "Isra and Mi'raj")
        case .shaban: return String(localized: "Mid-Sha'ban")
        case .prayerTime: return String(localized: "Prayer Time")
        }
    }

    func notificationBody(daysBefore: Int) -> String {
        if daysBefore == 0 {
            switch self {
            case .eidAlFitr: return String(localized: "Eid Mubarak! May Allah accept your worship.")
            case .eidAlAdha: return String(localized: "Eid Mubarak! May Allah accept your sacrifice.")
            case .ramadan: return String(localized: "Ramadan Mubarak! The blessed month begins today.")
            case .islamicNewYear: return String(localized: "Happy Islamic New Year! May this year bring blessings.")
            case .ashura: return String(localized: "Today is the Day of Ashura. Fasting is recommended.")
            case .mawlidAlNabi: return String(localized: "Today we celebrate the birth of Prophet Muhammad (PBUH).")
            case .isra: return String(localized: "Tonight is the Night Journey and Ascension.")
            case .shaban: return String(localized: "Tonight is the Night of Mid-Sha'ban.")
            case .prayerTime: return String(localized: "It's prayer time.")
            }
        } else {
            switch self {
            case .eidAlFitr: return String(localized: "Eid al-Fitr is tomorrow! Prepare your Eid prayers.")
            case .eidAlAdha: return String(localized: "Eid al-Adha is tomorrow! Prepare for the celebration.")
            case .ramadan: return String(localized: "Ramadan begins tomorrow! Prepare for the blessed month.")
            case .islamicNewYear: return String(localized: "Islamic New Year is tomorrow.")
            case .ashura: return String(localized: "The Day of Ashura is tomorrow. Consider fasting.")
            case .mawlidAlNabi: return String(localized: "Mawlid al-Nabi is tomorrow.")
            case .isra: return String(localized: "Isra and Mi'raj is tomorrow night.")
            case .shaban: return String(localized: "Mid-Sha'ban is tomorrow night.")
            case .prayerTime: return String(localized: "Prayer reminder.")
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let prayerLoggedFromNotification = Notification.Name("com.safa.prayerLoggedFromNotification")
    static let fastLoggedFromNotification = Notification.Name("com.safa.fastLoggedFromNotification")
}
