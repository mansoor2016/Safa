// MARK: - PrayerViewModel.swift
// PURPOSE: ViewModel for prayer times feature
// DEPENDENCIES: Foundation, PrayerRepository, LocationService

import Foundation
import CoreLocation

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
    private let userState: UserStateManager
    private let widgetDataService: WidgetDataService

    // MARK: - Private State
    private var currentLocation: Coordinates?

    // MARK: - Init
    init(
        prayerRepository: PrayerRepositoryProtocol,
        locationService: LocationServiceProtocol,
        userState: UserStateManager,
        widgetDataService: WidgetDataService = .shared
    ) {
        self.prayerRepository = prayerRepository
        self.locationService = locationService
        self.userState = userState
        self.widgetDataService = widgetDataService

        // Load saved calculation method from canonical preferences
        let prefs = PreferencesManager.loadPreferencesSync()
        self.calculationMethod = prefs.calculationMethod

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
            let prefs = PreferencesManager.loadPreferencesSync()
            let prayers = try await prayerRepository.getPrayers(
                for: currentDate,
                location: location,
                method: calculationMethod,
                madhab: prefs.madhab
            )
            todayPrayers = prayers

            // Load logged prayers
            let logs = try await prayerRepository.getPrayerLogs(for: currentDate)
            loggedPrayers = Set(logs.map { $0.prayerType })

            // Update next prayer indicator
            updateNextPrayerIndicator()

            // Sync prayer times and logged state to widgets via App Group
            widgetDataService.writePrayerTimes(prayers)
            widgetDataService.writeLoggedPrayers(loggedPrayers, for: currentDate)

            // Load notification preferences from PreferencesManager
            await loadNotificationSettings()

            // Ensure notifications are scheduled (skips if already done today)
            await NotificationScheduler.shared.scheduleIfNeeded()

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
        guard let prayer = todayPrayers.first(where: { $0.type == prayerType }) else { return }

        // Optimistic: update UI immediately
        loggedPrayers.insert(prayerType)
        widgetDataService.writeLoggedPrayers(loggedPrayers, for: currentDate)

        // Show undo toast
        let displayName = prayerType.displayName
        ToastService.shared.show(Toast.undoAction(message: "\(displayName) logged") { [weak self] in
            self?.revertLog(prayerType)
        })

        // Persist
        do {
            let isOnTime = abs(Date().timeIntervalSince(prayer.time)) < 30 * 60
            try await prayerRepository.logPrayer(
                prayerType,
                for: currentDate,
                at: Date(),
                isOnTime: isOnTime
            )

            // Side effects (after persist succeeds)
            await HasanatTracker.awardOnce(.prayerLogged, key: "prayer_\(prayerType.rawValue)", via: userState)
            let wasFirstPrayer = userState.userStats.totalPrayersLogged == 0
            await userState.incrementPrayersLogged()

            if allPrayersCompleted {
                await HasanatTracker.awardOnce(.prayerAllFive, key: "prayerAllFive", via: userState)
                await userState.checkAndUnlockAchievement("prayer_perfect_day")
            }

            await userState.recordActivity(type: .prayer)

            if wasFirstPrayer {
                await userState.checkAndUnlockAchievement("prayer_first")
            }
        } catch {
            // Revert optimistic state on failure
            loggedPrayers.remove(prayerType)
            widgetDataService.writeLoggedPrayers(loggedPrayers, for: currentDate)
            self.error = error
        }
    }

    private func unlogPrayer(_ prayerType: PrayerType) async {
        guard loggedPrayers.contains(prayerType) else { return }

        // Optimistic: update UI immediately
        loggedPrayers.remove(prayerType)
        widgetDataService.writeLoggedPrayers(loggedPrayers, for: currentDate)

        // Show undo toast
        let displayName = prayerType.displayName
        ToastService.shared.show(Toast.undoAction(message: "\(displayName) unlogged", type: .info) { [weak self] in
            self?.revertUnlog(prayerType)
        })

        // Persist
        do {
            let logs = try await prayerRepository.getPrayerLogs(for: currentDate)
            if let log = logs.first(where: { $0.prayerType == prayerType }) {
                try await prayerRepository.deletePrayerLog(log)
            }
        } catch {
            // Revert optimistic state on failure
            loggedPrayers.insert(prayerType)
            widgetDataService.writeLoggedPrayers(loggedPrayers, for: currentDate)
            self.error = error
        }
    }

    // MARK: - Undo Helpers

    private func revertLog(_ prayerType: PrayerType) {
        loggedPrayers.remove(prayerType)
        widgetDataService.writeLoggedPrayers(loggedPrayers, for: currentDate)
        Task { [weak self] in
            guard let self else { return }
            do {
                let logs = try await prayerRepository.getPrayerLogs(for: currentDate)
                if let log = logs.first(where: { $0.prayerType == prayerType }) {
                    try await prayerRepository.deletePrayerLog(log)
                }
            } catch {
                // Silent — best-effort undo
            }
        }
    }

    private func revertUnlog(_ prayerType: PrayerType) {
        loggedPrayers.insert(prayerType)
        widgetDataService.writeLoggedPrayers(loggedPrayers, for: currentDate)
        Task { [weak self] in
            guard let self else { return }
            do {
                guard let prayer = todayPrayers.first(where: { $0.type == prayerType }) else { return }
                let isOnTime = abs(Date().timeIntervalSince(prayer.time)) < 30 * 60
                try await prayerRepository.logPrayer(prayerType, for: currentDate, at: Date(), isOnTime: isOnTime)
            } catch {
                // Silent — best-effort undo
            }
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
            notificationEnabledPrayers.remove(prayerType)
            await saveNotificationSettings()
        } else {
            if !NotificationScheduler.shared.isAuthorized {
                let granted = await NotificationScheduler.shared.requestAuthorization()
                guard granted else { return }
            }
            notificationEnabledPrayers.insert(prayerType)
            await saveNotificationSettings()
        }
        // Re-schedule all via centralized scheduler (handles add/remove)
        await NotificationScheduler.shared.forceReschedule()
    }

    // Notification scheduling is handled by NotificationScheduler (single system).
    // PrayerViewModel only manages preferences and triggers reschedule.

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
        await PreferencesManager.shared.saveCalculationMethod(method)
        await loadPrayerTimes()

        // Re-schedule notifications with new prayer times
        await NotificationScheduler.shared.forceReschedule()
    }

    func requestNotificationPermission() async {
        let granted = await NotificationScheduler.shared.requestAuthorization()
        if granted {
            await NotificationScheduler.shared.forceReschedule()
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

    func updateNextPrayerIndicator() {
        let now = Date()
        for i in 0..<todayPrayers.count {
            todayPrayers[i].isNext = todayPrayers[i].time > now &&
                                     todayPrayers[i].type.isObligatory &&
                                     (i == 0 || todayPrayers[i - 1].time <= now)
        }
    }

}

