// MARK: - PrayerViewModel.swift
// PURPOSE: ViewModel for prayer times feature
// DEPENDENCIES: Foundation, PrayerRepository, LocationService

import Foundation
import CoreLocation
import UserNotifications

@Observable
final class PrayerViewModel {
    // MARK: - Published State
    var todayPrayers: [PrayerTime] = []
    var loggedPrayers: Set<PrayerType> = []
    var notificationEnabledPrayers: Set<PrayerType> = []
    var currentDate = Date()
    var calculationMethod: CalculationMethod = .isna
    var isLoading = false
    var error: Error?
    var notificationSchedulingFailed = false

    // MARK: - Dependencies
    private let prayerRepository: PrayerRepositoryProtocol
    private let locationService: LocationServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let userState: UserStateManager

    // MARK: - Private State
    private var currentLocation: Coordinates?

    // MARK: - Init
    init(
        prayerRepository: PrayerRepositoryProtocol,
        locationService: LocationServiceProtocol,
        notificationService: NotificationServiceProtocol,
        userState: UserStateManager
    ) {
        self.prayerRepository = prayerRepository
        self.locationService = locationService
        self.notificationService = notificationService
        self.userState = userState

        // Load saved calculation method
        if let savedMethod = UserDefaults.standard.string(forKey: "calculationMethod"),
           let method = CalculationMethod(rawValue: savedMethod) {
            self.calculationMethod = method
        }

        // Default notification state (will be overwritten by async load in loadPrayerTimes)
        notificationEnabledPrayers = Set(PrayerType.obligatoryPrayers)
    }

    // MARK: - Computed Properties

    var nextPrayer: PrayerTime? {
        let now = Date()
        return todayPrayers.first { $0.time > now && $0.type.isObligatory }
    }

    var prayersCompletedToday: Int {
        loggedPrayers.count
    }

    var allPrayersCompleted: Bool {
        PrayerType.obligatoryPrayers.allSatisfy { loggedPrayers.contains($0) }
    }

    // MARK: - Public Methods

    func loadPrayerTimes() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Get location
            let location = try await getCurrentLocation()
            currentLocation = location

            // Calculate prayer times
            let prayers = try await prayerRepository.getPrayers(
                for: currentDate,
                location: location,
                method: calculationMethod
            )
            todayPrayers = prayers

            // Load logged prayers
            let logs = try await prayerRepository.getPrayerLogs(for: currentDate)
            loggedPrayers = Set(logs.map { $0.prayerType })

            // Update next prayer indicator
            updateNextPrayerIndicator()

            // Load notification preferences from PreferencesManager
            await loadNotificationSettings()

            // Schedule notifications for enabled prayers
            await scheduleEnabledNotifications()

        } catch {
            self.error = error
        }
    }

    func refreshPrayerTimes() async {
        await loadPrayerTimes()
    }

    func togglePrayer(_ prayerType: PrayerType) async {
        if loggedPrayers.contains(prayerType) {
            await unlogPrayer(prayerType)
        } else {
            await logPrayer(prayerType)
        }
    }

    func logPrayer(_ prayerType: PrayerType) async {
        guard !loggedPrayers.contains(prayerType) else { return }

        do {
            // Find the prayer time
            guard let prayer = todayPrayers.first(where: { $0.type == prayerType }) else { return }

            // Check if on time (within 30 minutes of prayer time)
            let isOnTime = abs(Date().timeIntervalSince(prayer.time)) < 30 * 60

            // Log the prayer
            try await prayerRepository.logPrayer(
                prayerType,
                for: currentDate,
                at: Date(),
                isOnTime: isOnTime
            )

            // Update local state
            loggedPrayers.insert(prayerType)

            // Award Hasanat
            await userState.awardHasanat(.prayerLogged)

            // Check if all prayers completed
            if allPrayersCompleted {
                await userState.awardHasanat(.prayerAllFive)
                await userState.checkAndUnlockAchievement("prayer_perfect_day")
            }

            // Update prayer streak
            await userState.recordActivity(type: .prayer)

            // Check first prayer achievement
            if userState.userStats.totalPrayersLogged == 0 {
                await userState.checkAndUnlockAchievement("prayer_first")
            }

        } catch {
            self.error = error
        }
    }

    private func unlogPrayer(_ prayerType: PrayerType) async {
        do {
            let logs = try await prayerRepository.getPrayerLogs(for: currentDate)
            if let log = logs.first(where: { $0.prayerType == prayerType }) {
                try await prayerRepository.deletePrayerLog(log)
                loggedPrayers.remove(prayerType)
            }
        } catch {
            self.error = error
        }
    }

    func reloadLoggedPrayers() async {
        do {
            let logs = try await prayerRepository.getPrayerLogs(for: currentDate)
            loggedPrayers = Set(logs.map { $0.prayerType })
        } catch {
            // Ignore - keep existing state
        }
    }

    func toggleNotification(for prayerType: PrayerType) async {
        if notificationEnabledPrayers.contains(prayerType) {
            // Disable: remove from set and cancel notification
            notificationEnabledPrayers.remove(prayerType)
            await saveNotificationSettings()
            cancelNotification(for: prayerType)
        } else {
            // Enable: request permission if needed, then schedule
            if !notificationService.isAuthorized {
                let granted = try? await notificationService.requestAuthorization()
                guard granted == true else { return }
            }
            notificationEnabledPrayers.insert(prayerType)
            await saveNotificationSettings()
            await scheduleNotification(for: prayerType)
        }
    }

    private func scheduleNotification(for prayerType: PrayerType) async {
        guard let prayer = todayPrayers.first(where: { $0.type == prayerType }),
              prayer.time > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(prayerType.displayName) Time"
        content.body = "It's time for \(prayerType.displayName) prayer"
        content.interruptionLevel = .timeSensitive

        // Use adhan sound if enabled
        let prefs = await PreferencesManager.shared.getPreferences()
        if prefs.adhanEnabled {
            let fileName = prayerType == .fajr ? prefs.selectedFajrAdhan : prefs.selectedAdhan
            content.sound = UNNotificationSound(named: UNNotificationSoundName("\(fileName)_notification.caf"))
        } else {
            content.sound = .default
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: prayer.time
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "prayer_\(prayerType.rawValue)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            notificationSchedulingFailed = false
        } catch {
            notificationSchedulingFailed = true
        }
    }

    private func cancelNotification(for prayerType: PrayerType) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["prayer_\(prayerType.rawValue)"]
        )
    }

    private func scheduleEnabledNotifications() async {
        for prayerType in PrayerType.obligatoryPrayers {
            if notificationEnabledPrayers.contains(prayerType) {
                await scheduleNotification(for: prayerType)
            } else {
                cancelNotification(for: prayerType)
            }
        }
    }

    private func loadNotificationSettings() async {
        let prefs = await PreferencesManager.shared.getPreferences()
        notificationEnabledPrayers = Set(prefs.notificationEnabledPrayers.compactMap { PrayerType(rawValue: $0) })
    }

    private func saveNotificationSettings() async {
        let values = notificationEnabledPrayers.map { $0.rawValue }
        await PreferencesManager.shared.update(\.notificationEnabledPrayers, to: values)
    }

    func setCalculationMethod(_ method: CalculationMethod) async {
        calculationMethod = method
        UserDefaults.standard.set(method.rawValue, forKey: "calculationMethod")
        await loadPrayerTimes()
    }

    func requestNotificationPermission() async {
        do {
            let granted = try await notificationService.requestAuthorization()
            if granted {
                await scheduleNotifications()
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Private Methods

    private func getCurrentLocation() async throws -> Coordinates {
        // Return cached if available
        if let cached = currentLocation {
            return cached
        }

        // Try saved/cached coordinates first (works without live GPS)
        if let saved = locationService.coordinates {
            return saved
        }

        // Check if we have permission
        if locationService.authorizationStatus == .notDetermined {
            locationService.requestPermission()
        }

        // Fall back to live GPS with retry
        let location = try await withRetry(maxAttempts: 2, initialDelay: 1.0) {
            try await locationService.getCurrentLocation()
        }
        return Coordinates(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }

    private func updateNextPrayerIndicator() {
        let now = Date()
        for i in 0..<todayPrayers.count {
            todayPrayers[i].isNext = todayPrayers[i].time > now &&
                                     todayPrayers[i].type.isObligatory &&
                                     (i == 0 || todayPrayers[i - 1].time <= now)
        }
    }

    private func scheduleNotifications() async {
        guard notificationService.isAuthorized else { return }

        do {
            try await notificationService.scheduleDailyPrayerNotifications(
                prayers: todayPrayers.filter { $0.type.isObligatory },
                offsetMinutes: 5
            )
        } catch {
            self.error = error
        }
    }
}

