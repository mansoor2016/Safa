// MARK: - RamadanService.swift
// PURPOSE: Ramadan mode management, auto-activation, and notifications
// DEPENDENCIES: Foundation, UserNotifications

import Foundation
import UserNotifications

// MARK: - Ramadan Service

@Observable
final class RamadanService {

    // MARK: - Properties

    var isRamadanMode: Bool = false
    var currentRamadanDay: Int = 0
    var totalRamadanDays: Int = 30
    var isRamadanMonth: Bool = false
    var daysUntilRamadan: Int?

    var suhoorReminderEnabled: Bool = true
    var iftarReminderEnabled: Bool = true
    var taraweehReminderEnabled: Bool = true

    var suhoorReminderMinutesBefore: Int = 30
    var iftarReminderMinutesBefore: Int = 15

    // MARK: - Storage Keys

    private let ramadanModeKey = AppConstants.StorageKeys.ramadanEnabled
    private let suhoorReminderKey = AppConstants.StorageKeys.ramadanSuhoorReminder
    private let iftarReminderKey = AppConstants.StorageKeys.ramadanIftarReminder
    private let taraweehReminderKey = AppConstants.StorageKeys.ramadanTaraweehReminder
    private let suhoorMinutesKey = AppConstants.StorageKeys.ramadanSuhoorMinutes
    private let iftarMinutesKey = AppConstants.StorageKeys.ramadanIftarMinutes
    private let fastingDaysKey = AppConstants.StorageKeys.ramadanFastingDays
    private let taraweehDaysKey = AppConstants.StorageKeys.ramadanTaraweehDays

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Initialization

    init() {
        loadSettings()
        checkRamadanStatus()
    }

    // MARK: - Settings

    func loadSettings() {
        isRamadanMode = UserDefaults.standard.bool(forKey: ramadanModeKey)
        suhoorReminderEnabled = UserDefaults.standard.object(forKey: suhoorReminderKey) as? Bool ?? true
        iftarReminderEnabled = UserDefaults.standard.object(forKey: iftarReminderKey) as? Bool ?? true
        taraweehReminderEnabled = UserDefaults.standard.object(forKey: taraweehReminderKey) as? Bool ?? true
        suhoorReminderMinutesBefore = UserDefaults.standard.integer(forKey: suhoorMinutesKey)
        iftarReminderMinutesBefore = UserDefaults.standard.integer(forKey: iftarMinutesKey)

        if suhoorReminderMinutesBefore == 0 { suhoorReminderMinutesBefore = 30 }
        if iftarReminderMinutesBefore == 0 { iftarReminderMinutesBefore = 15 }
    }

    func saveSettings() {
        UserDefaults.standard.set(isRamadanMode, forKey: ramadanModeKey)
        UserDefaults.standard.set(suhoorReminderEnabled, forKey: suhoorReminderKey)
        UserDefaults.standard.set(iftarReminderEnabled, forKey: iftarReminderKey)
        UserDefaults.standard.set(taraweehReminderEnabled, forKey: taraweehReminderKey)
        UserDefaults.standard.set(suhoorReminderMinutesBefore, forKey: suhoorMinutesKey)
        UserDefaults.standard.set(iftarReminderMinutesBefore, forKey: iftarMinutesKey)
    }

    // MARK: - Ramadan Status

    func checkRamadanStatus() {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        let now = Date()

        let hijriMonth = hijriCalendar.component(.month, from: now)
        let hijriDay = hijriCalendar.component(.day, from: now)

        // Ramadan is month 9 in Hijri calendar
        isRamadanMonth = hijriMonth == 9

        if isRamadanMonth {
            currentRamadanDay = hijriDay

            // Get total days in Ramadan this year
            if let range = hijriCalendar.range(of: .day, in: .month, for: now) {
                totalRamadanDays = range.count
            }

            // Auto-activate Ramadan mode if it's Ramadan
            if !isRamadanMode {
                activateRamadanMode()
            }

            daysUntilRamadan = nil
        } else {
            currentRamadanDay = 0

            // Calculate days until next Ramadan
            daysUntilRamadan = calculateDaysUntilRamadan()

            // Auto-deactivate if Ramadan ended
            if isRamadanMode && hijriMonth == 10 && hijriDay == 1 {
                deactivateRamadanMode()
            }
        }
    }

    private func calculateDaysUntilRamadan() -> Int {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        let gregorianCalendar = Calendar(identifier: .gregorian)
        let now = Date()

        let hijriYear = hijriCalendar.component(.year, from: now)
        let hijriMonth = hijriCalendar.component(.month, from: now)

        // Determine next Ramadan year
        let nextRamadanYear = hijriMonth < 9 ? hijriYear : hijriYear + 1

        // Create date components for 1st of Ramadan
        var components = DateComponents()
        components.year = nextRamadanYear
        components.month = 9
        components.day = 1

        guard let ramadanStart = hijriCalendar.date(from: components) else {
            return 0
        }

        let daysBetween = gregorianCalendar.dateComponents([.day], from: now, to: ramadanStart).day
        return max(0, daysBetween ?? 0)
    }

    // MARK: - Mode Activation

    func activateRamadanMode() {
        isRamadanMode = true
        saveSettings()

        // Send activation notification
        sendRamadanActivationNotification()
    }

    func deactivateRamadanMode() {
        isRamadanMode = false
        saveSettings()

        // Cancel all Ramadan notifications
        cancelAllRamadanNotifications()

        // Send Eid notification
        sendEidNotification()
    }

    func toggleRamadanMode() {
        if isRamadanMode {
            deactivateRamadanMode()
        } else {
            activateRamadanMode()
        }
    }

    // MARK: - Suhoor Notifications

    func scheduleSuhoorReminder(fajrTime: Date) async {
        guard suhoorReminderEnabled else { return }

        // Calculate reminder time
        guard let reminderTime = Calendar.current.date(
            byAdding: .minute,
            value: -suhoorReminderMinutesBefore,
            to: fajrTime
        ) else { return }

        guard reminderTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Suhoor Time")
        content.body = String(localized: "Time for pre-dawn meal. Fajr is in \(suhoorReminderMinutesBefore) minutes. May your fast be accepted.")
        content.categoryIdentifier = "SUHOOR"
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive

        // Add user info for deep linking
        content.userInfo = [
            "type": "suhoor",
            "fajrTime": fajrTime.timeIntervalSince1970
        ]

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderTime
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "suhoor_reminder_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    func scheduleSuhoorDua(fajrTime: Date) async {
        // Schedule dua notification at Suhoor ending (just before Fajr)
        guard let duaTime = Calendar.current.date(
            byAdding: .minute,
            value: -5,
            to: fajrTime
        ) else { return }

        guard duaTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Suhoor Dua")
        content.body = "وَبِصَوْمِ غَدٍ نَّوَيْتُ مِنْ شَهْرِ رَمَضَانَ\n" + String(localized: "\"I intend to fast tomorrow for the month of Ramadan\"")
        content.categoryIdentifier = "SUHOOR_DUA"
        content.sound = nil
        content.interruptionLevel = .passive

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: duaTime
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "suhoor_dua_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    // MARK: - Iftar Notifications

    func scheduleIftarReminder(maghribTime: Date) async {
        guard iftarReminderEnabled else { return }

        // Schedule reminder before Iftar
        guard let reminderTime = Calendar.current.date(
            byAdding: .minute,
            value: -iftarReminderMinutesBefore,
            to: maghribTime
        ) else { return }

        guard reminderTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Iftar in \(iftarReminderMinutesBefore) minutes")
        content.body = String(localized: "Prepare to break your fast. May Allah accept your worship.")
        content.categoryIdentifier = "IFTAR"
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive

        content.userInfo = [
            "type": "iftar",
            "maghribTime": maghribTime.timeIntervalSince1970
        ]

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderTime
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "iftar_reminder_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    func scheduleIftarTime(maghribTime: Date) async {
        // Schedule notification at exact Iftar time
        guard maghribTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Iftar Time!")
        content.body = "اللَّهُمَّ إِنِّي لَكَ صُمْتُ وَبِكَ آمَنْتُ وَعَلَى رِزْقِكَ أَفْطَرْتُ\n" + String(localized: "Bismillah! Time to break your fast.")
        content.categoryIdentifier = "IFTAR_TIME"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("iftar_athan.wav"))
        content.interruptionLevel = .timeSensitive

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: maghribTime
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "iftar_time_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    // MARK: - Taraweeh Notifications

    func scheduleTaraweehReminder(ishaTime: Date) async {
        guard taraweehReminderEnabled else { return }

        // Schedule 30 minutes after Isha
        guard let reminderTime = Calendar.current.date(
            byAdding: .minute,
            value: 30,
            to: ishaTime
        ) else { return }

        guard reminderTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Taraweeh Time")
        content.body = String(localized: "Don't forget your Taraweeh prayers tonight. May your worship be accepted.")
        content.categoryIdentifier = "TARAWEEH"
        content.sound = .default
        content.interruptionLevel = .active

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderTime
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "taraweeh_reminder_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    // MARK: - Special Notifications

    private func sendRamadanActivationNotification() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Ramadan Mubarak! 🌙")
        content.body = String(localized: "Ramadan mode is now active. May this month bring you peace, mercy, and forgiveness.")
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "ramadan_activated",
            content: content,
            trigger: nil // Immediate
        )

        notificationCenter.add(request)
    }

    private func sendEidNotification() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Eid Mubarak! 🎉")
        content.body = String(localized: "Taqabbal Allahu minna wa minkum. May Allah accept from us and from you.")
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "eid_notification",
            content: content,
            trigger: nil // Immediate
        )

        notificationCenter.add(request)
    }

    func scheduleLaylatAlQadrReminders() async {
        // Schedule reminders for odd nights in the last 10 days
        let oddNights = [21, 23, 25, 27, 29]

        for night in oddNights {
            await scheduleLaylatAlQadrReminder(night: night)
        }
    }

    private func scheduleLaylatAlQadrReminder(night: Int) async {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        let now = Date()

        let hijriYear = hijriCalendar.component(.year, from: now)

        // Create date for the night
        var components = DateComponents()
        components.year = hijriYear
        components.month = 9 // Ramadan
        components.day = night

        guard let nightDate = hijriCalendar.date(from: components),
              nightDate > now else { return }

        // Schedule at Maghrib time (would need prayer times)
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Laylat al-Qadr - Night \(night)")
        content.body = String(localized: "This could be the Night of Power. Increase your worship and make dua: اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي")
        content.categoryIdentifier = "LAYLAT_AL_QADR"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        var triggerComponents = Calendar.current.dateComponents([.year, .month, .day], from: nightDate)
        triggerComponents.hour = 20 // 8 PM
        triggerComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "laylat_al_qadr_\(night)",
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    // MARK: - Cancel Notifications

    func cancelAllRamadanNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            "ramadan_activated",
            "eid_notification"
        ])

        // Remove all suhoor, iftar, taraweeh notifications by prefix pattern
        notificationCenter.getPendingNotificationRequests { requests in
            let idsToRemove = requests
                .filter { request in
                    request.identifier.hasPrefix("suhoor_") ||
                    request.identifier.hasPrefix("iftar_") ||
                    request.identifier.hasPrefix("taraweeh_") ||
                    request.identifier.hasPrefix("laylat_al_qadr_")
                }
                .map { $0.identifier }

            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
    }

    // MARK: - Fasting Tracking

    func getFastingDays() -> Set<Int> {
        guard let data = UserDefaults.standard.data(forKey: fastingDaysKey),
              let days = try? JSONDecoder().decode(Set<Int>.self, from: data) else {
            return []
        }
        return days
    }

    func saveFastingDays(_ days: Set<Int>) {
        if let data = try? JSONEncoder().encode(days) {
            UserDefaults.standard.set(data, forKey: fastingDaysKey)
        }
    }

    func markDayFasted(_ day: Int) {
        var days = getFastingDays()
        days.insert(day)
        saveFastingDays(days)
    }

    func unmarkDayFasted(_ day: Int) {
        var days = getFastingDays()
        days.remove(day)
        saveFastingDays(days)
    }

    // MARK: - Taraweeh Tracking

    func getTaraweehDays() -> [Int: Int] { // day -> rakaahs
        guard let data = UserDefaults.standard.data(forKey: taraweehDaysKey),
              let days = try? JSONDecoder().decode([Int: Int].self, from: data) else {
            return [:]
        }
        return days
    }

    func saveTaraweeh(day: Int, rakaahs: Int) {
        var days = getTaraweehDays()
        days[day] = rakaahs
        if let data = try? JSONEncoder().encode(days) {
            UserDefaults.standard.set(data, forKey: taraweehDaysKey)
        }
    }

    // MARK: - Statistics

    var fastingProgress: Double {
        let fastingDays = getFastingDays()
        guard totalRamadanDays > 0 else { return 0 }
        return Double(fastingDays.count) / Double(totalRamadanDays)
    }

    var taraweehProgress: Double {
        let taraweehDays = getTaraweehDays()
        guard totalRamadanDays > 0 else { return 0 }
        return Double(taraweehDays.count) / Double(totalRamadanDays)
    }

    var totalTaraweehRakaahs: Int {
        getTaraweehDays().values.reduce(0, +)
    }
}
