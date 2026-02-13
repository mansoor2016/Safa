// MARK: - SleepFocusService.swift
// PURPOSE: Integration with iOS Sleep Focus mode
// DEPENDENCIES: Foundation, UserNotifications, ActivityKit

import Foundation
import UserNotifications
import ActivityKit

// MARK: - Sleep Focus Service

@Observable
final class SleepFocusService {

    // MARK: - Properties

    var isSleepFocusEnabled: Bool = false
    var scheduledBedtime: Date?
    var scheduledWakeTime: Date?
    var fajrAlarmEnabled: Bool = false
    var windDownReminderEnabled: Bool = true
    var windDownMinutesBefore: Int = 30

    // MARK: - Storage Keys

    private let bedtimeKey = AppConstants.StorageKeys.windDownBedtime
    private let wakeTimeKey = AppConstants.StorageKeys.windDownWakeTime
    private let fajrAlarmKey = AppConstants.StorageKeys.windDownFajrAlarm
    private let windDownReminderKey = AppConstants.StorageKeys.windDownReminder
    private let windDownMinutesKey = AppConstants.StorageKeys.windDownMinutes

    // MARK: - Initialization

    init() {
        loadSettings()
    }

    // MARK: - Settings Management

    func loadSettings() {
        if let bedtimeData = UserDefaults.standard.object(forKey: bedtimeKey) as? Date {
            scheduledBedtime = bedtimeData
        }
        if let wakeTimeData = UserDefaults.standard.object(forKey: wakeTimeKey) as? Date {
            scheduledWakeTime = wakeTimeData
        }
        fajrAlarmEnabled = UserDefaults.standard.bool(forKey: fajrAlarmKey)
        windDownReminderEnabled = UserDefaults.standard.bool(forKey: windDownReminderKey)
        windDownMinutesBefore = UserDefaults.standard.integer(forKey: windDownMinutesKey)
        if windDownMinutesBefore == 0 { windDownMinutesBefore = 30 }
    }

    func saveSettings() {
        UserDefaults.standard.set(scheduledBedtime, forKey: bedtimeKey)
        UserDefaults.standard.set(scheduledWakeTime, forKey: wakeTimeKey)
        UserDefaults.standard.set(fajrAlarmEnabled, forKey: fajrAlarmKey)
        UserDefaults.standard.set(windDownReminderEnabled, forKey: windDownReminderKey)
        UserDefaults.standard.set(windDownMinutesBefore, forKey: windDownMinutesKey)
    }

    // MARK: - Bedtime Configuration

    func setBedtime(_ time: Date) {
        scheduledBedtime = time
        saveSettings()

        if windDownReminderEnabled {
            scheduleWindDownReminder()
        }
    }

    func setWakeTime(_ time: Date) {
        scheduledWakeTime = time
        saveSettings()
    }

    func setFajrAsWakeTime(fajrTime: Date) {
        // Set wake time slightly before Fajr to allow time for wudu
        let wakeTime = Calendar.current.date(byAdding: .minute, value: -15, to: fajrTime)
        scheduledWakeTime = wakeTime
        fajrAlarmEnabled = true
        saveSettings()
        scheduleFajrAlarm(fajrTime: fajrTime)
    }

    // MARK: - Wind Down Reminder

    func scheduleWindDownReminder() {
        guard let bedtime = scheduledBedtime else { return }

        let windDownTime = Calendar.current.date(
            byAdding: .minute,
            value: -windDownMinutesBefore,
            to: bedtime
        )

        guard let windDownTime = windDownTime, windDownTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Time to Wind Down")
        content.body = String(localized: "Start your evening dhikr and prepare for a restful night.")
        content.categoryIdentifier = "WIND_DOWN"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("soft_chime.wav"))
        content.interruptionLevel = .timeSensitive

        let dateComponents = Calendar.current.dateComponents(
            [.hour, .minute],
            from: windDownTime
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "wind_down_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelWindDownReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["wind_down_reminder"]
        )
    }

    // MARK: - Fajr Alarm

    func scheduleFajrAlarm(fajrTime: Date) {
        guard fajrAlarmEnabled else { return }

        // Calculate wake time (15 minutes before Fajr)
        guard let wakeTime = Calendar.current.date(byAdding: .minute, value: -15, to: fajrTime) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Fajr Prayer Soon")
        content.body = String(localized: "Wake up for Fajr prayer. May Allah accept your worship.")
        content.categoryIdentifier = "FAJR_ALARM"
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive

        // Add action buttons
        let openQiblaAction = UNNotificationAction(
            identifier: "OPEN_QIBLA",
            title: String(localized: "Open Qibla"),
            options: .foreground
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: String(localized: "Snooze 5 min"),
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "FAJR_ALARM",
            actions: [openQiblaAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])

        let dateComponents = Calendar.current.dateComponents(
            [.hour, .minute],
            from: wakeTime
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "fajr_alarm",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelFajrAlarm() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["fajr_alarm"]
        )
    }

    // MARK: - Sleep Schedule Notification Actions

    func registerNotificationActions() {
        // Wind Down actions
        let startWindDownAction = UNNotificationAction(
            identifier: "START_WIND_DOWN",
            title: String(localized: "Start Wind Down"),
            options: .foreground
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: String(localized: "Dismiss"),
            options: .destructive
        )

        let windDownCategory = UNNotificationCategory(
            identifier: "WIND_DOWN",
            actions: [startWindDownAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        // Fajr alarm actions
        let openPrayerAction = UNNotificationAction(
            identifier: "OPEN_PRAYER",
            title: String(localized: "Open Prayer"),
            options: .foreground
        )
        let openQiblaAction = UNNotificationAction(
            identifier: "OPEN_QIBLA",
            title: String(localized: "Open Qibla"),
            options: .foreground
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: String(localized: "Snooze 5 min"),
            options: []
        )

        let fajrCategory = UNNotificationCategory(
            identifier: "FAJR_ALARM",
            actions: [openPrayerAction, openQiblaAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([windDownCategory, fajrCategory])
    }

    // MARK: - Sleep Focus Detection

    func checkSleepFocusStatus() async {
        // Note: iOS does not provide a direct API to check if Sleep Focus is active
        // We can infer it based on the scheduled sleep time
        guard let bedtime = scheduledBedtime, let wakeTime = scheduledWakeTime else {
            isSleepFocusEnabled = false
            return
        }

        let now = Date()
        let calendar = Calendar.current

        // Create today's bedtime and wake time
        var bedtimeComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        bedtimeComponents.year = calendar.component(.year, from: now)
        bedtimeComponents.month = calendar.component(.month, from: now)
        bedtimeComponents.day = calendar.component(.day, from: now)

        var wakeTimeComponents = calendar.dateComponents([.hour, .minute], from: wakeTime)
        wakeTimeComponents.year = calendar.component(.year, from: now)
        wakeTimeComponents.month = calendar.component(.month, from: now)
        wakeTimeComponents.day = calendar.component(.day, from: now)

        guard let todayBedtime = calendar.date(from: bedtimeComponents),
              var todayWakeTime = calendar.date(from: wakeTimeComponents) else {
            isSleepFocusEnabled = false
            return
        }

        // If wake time is before bedtime, it's the next day
        if todayWakeTime < todayBedtime {
            todayWakeTime = calendar.date(byAdding: .day, value: 1, to: todayWakeTime) ?? todayWakeTime
        }

        // Check if current time is within sleep window
        isSleepFocusEnabled = now >= todayBedtime && now <= todayWakeTime
    }

    // MARK: - Sleep Statistics

    func getSleepDuration() -> TimeInterval? {
        guard let bedtime = scheduledBedtime, let wakeTime = scheduledWakeTime else {
            return nil
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: wakeTime)

        // If wake time hour is less than bedtime hour, it's next day
        let bedtimeHour = calendar.component(.hour, from: bedtime)
        let wakeTimeHour = components.hour ?? 0

        var duration: TimeInterval = 0
        if wakeTimeHour < bedtimeHour {
            // Sleep spans midnight
            let bedtimeMinutes = bedtimeHour * 60 + (calendar.component(.minute, from: bedtime))
            let midnightMinutes = 24 * 60
            let wakeMinutes = wakeTimeHour * 60 + (components.minute ?? 0)
            duration = TimeInterval((midnightMinutes - bedtimeMinutes + wakeMinutes) * 60)
        } else {
            // Same day
            duration = wakeTime.timeIntervalSince(bedtime)
        }

        return duration
    }

    func getFormattedSleepDuration() -> String {
        guard let duration = getSleepDuration() else {
            return String(localized: "Not set")
        }

        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if minutes == 0 {
            return String(localized: "\(hours) hours")
        }
        return String(localized: "\(hours)h \(minutes)m")
    }
}

// MARK: - Sleep Settings View Model

@Observable
final class SleepSettingsViewModel {
    let sleepService: SleepFocusService

    var bedtime: Date {
        get { sleepService.scheduledBedtime ?? defaultBedtime }
        set { sleepService.setBedtime(newValue) }
    }

    var wakeTime: Date {
        get { sleepService.scheduledWakeTime ?? defaultWakeTime }
        set { sleepService.setWakeTime(newValue) }
    }

    var fajrAlarmEnabled: Bool {
        get { sleepService.fajrAlarmEnabled }
        set {
            sleepService.fajrAlarmEnabled = newValue
            sleepService.saveSettings()
        }
    }

    var windDownReminderEnabled: Bool {
        get { sleepService.windDownReminderEnabled }
        set {
            sleepService.windDownReminderEnabled = newValue
            sleepService.saveSettings()
            if newValue {
                sleepService.scheduleWindDownReminder()
            } else {
                sleepService.cancelWindDownReminder()
            }
        }
    }

    var windDownMinutes: Int {
        get { sleepService.windDownMinutesBefore }
        set {
            sleepService.windDownMinutesBefore = newValue
            sleepService.saveSettings()
            sleepService.scheduleWindDownReminder()
        }
    }

    var sleepDuration: String {
        sleepService.getFormattedSleepDuration()
    }

    private var defaultBedtime: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 22
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private var defaultWakeTime: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 5
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }

    init(sleepService: SleepFocusService = SleepFocusService()) {
        self.sleepService = sleepService
    }
}
