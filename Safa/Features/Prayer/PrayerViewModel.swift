// MARK: - PrayerViewModel.swift
// PURPOSE: ViewModel for prayer times feature
// DEPENDENCIES: Foundation, PrayerRepository, LocationService

import Foundation
import CoreLocation
import SafaShared

@MainActor
@Observable
final class PrayerViewModel {
    // MARK: - Published State
    var todayPrayers: [PrayerTime] = []
    var sunnahTimes: [SunnahTime] = []
    var loggedPrayers: Set<PrayerType> = []
    var notificationEnabledPrayers: Set<PrayerType> = []
    var currentDate = Date()
    var calculationMethod: CalculationMethod = .isna
    var madhab: Madhab = AppDefaults.madhab
    var isLoading = false
    var error: Error?
    var showSunnahTimes = false
    var showRakatInfo = false
    var notificationSchedulingFailed = false

    // MARK: - Dependencies
    private let prayerRepository: PrayerRepositoryProtocol
    private let locationService: LocationServiceProtocol
    private let userState: UserStateManager
    private let widgetDataService: WidgetDataService

    // MARK: - Private State
    private var currentLocation: Coordinates?
    private var isLoadingPrayers = false
    private var needsReload = false
    private(set) var lastForegroundRefresh: Date = .distantPast
    private var errorRetryUsed = false

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

        // Load saved settings from canonical preferences
        let prefs = PreferencesManager.loadPreferencesSync()
        self.calculationMethod = prefs.calculationMethod
        self.madhab = prefs.madhab
        self.showSunnahTimes = prefs.showSunnahTimes
        self.showRakatInfo = prefs.showRakatInfo

        // Default notification state (will be overwritten by async load in loadPrayerTimes)
        notificationEnabledPrayers = Set(PrayerType.obligatoryPrayers)
    }

    // MARK: - Computed Properties

    var nextPrayer: PrayerTime? {
        let now = Date()
        return todayPrayers.first {
            $0.type.isObligatory && ($0.time > now || isPrayerTimeNow($0.time, at: now))
        }
    }

    var prayersCompletedToday: Int {
        loggedPrayers.count
    }

    var allPrayersCompleted: Bool {
        PrayerType.obligatoryPrayers.allSatisfy { loggedPrayers.contains($0) }
    }

    // MARK: - Public Methods

    func loadPrayerTimes() async {
        guard !isLoadingPrayers else {
            needsReload = true
            return
        }
        isLoadingPrayers = true
        isLoading = true
        defer {
            isLoading = false
            isLoadingPrayers = false
        }

        repeat {
            needsReload = false

            do {
                // Clear previous error on new attempt
                error = nil

                // Advance date so reloads always fetch for today (fixes midnight rollover)
                currentDate = Date()

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

                // Load sunnah times
                sunnahTimes = prayerRepository.getSunnahTimes(
                    for: currentDate,
                    location: location,
                    method: calculationMethod,
                    madhab: prefs.madhab
                )

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

                // Update Live Activity with next prayer context
                updateLiveActivity()

            } catch {
                self.error = error
            }
        } while needsReload
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
        guard todayPrayers.contains(where: { $0.type == prayerType }) else { return }

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
            let isOnTime = isPrayerOnTime(prayerType, at: Date())
            try await prayerRepository.logPrayer(
                prayerType,
                for: currentDate,
                at: Date(),
                isOnTime: isOnTime
            )

            // Side effects (after persist succeeds)
            await HasanatTracker.awardOnce(.prayerLogged, key: "prayer_\(prayerType.rawValue)", via: userState)
            await userState.incrementPrayersLogged()

            if allPrayersCompleted {
                await HasanatTracker.awardOnce(.prayerAllFive, key: "prayerAllFive", via: userState)
            }

            // Prayer streak requires at least 3/5 obligatory prayers logged today
            let obligatoryLoggedCount = PrayerType.obligatoryPrayers.filter { loggedPrayers.contains($0) }.count
            if obligatoryLoggedCount >= 3 {
                await userState.recordActivity(type: .prayer)
            }

            // Update Live Activity (next prayer context may have changed)
            updateLiveActivity()
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
                guard todayPrayers.contains(where: { $0.type == prayerType }) else { return }
                let isOnTime = isPrayerOnTime(prayerType, at: Date())
                try await prayerRepository.logPrayer(prayerType, for: currentDate, at: Date(), isOnTime: isOnTime)
            } catch {
                // Silent — best-effort undo
            }
        }
    }

    /// Determines if a prayer is on time based on Islamic prayer windows.
    /// A prayer is on-time if logged between its start and the next prayer's start:
    ///   Fajr → until Sunrise, Dhuhr → until Asr, Asr → until Maghrib,
    ///   Maghrib → until Isha, Isha → until next Fajr (approximated as end of day).
    func isPrayerOnTime(_ prayerType: PrayerType, at time: Date) -> Bool {
        Self.isPrayerOnTime(prayerType, at: time, schedule: todayPrayers)
    }

    /// Testable overload that accepts an explicit schedule.
    static func isPrayerOnTime(_ prayerType: PrayerType, at time: Date, schedule: [PrayerTime]) -> Bool {
        guard prayerType != .sunrise else { return false }

        guard let prayerStart = schedule.first(where: { $0.type == prayerType })?.time else {
            return false
        }

        // Must be at or after the prayer's start time
        guard time >= prayerStart else { return false }

        if let endTime = PrayerWindowHelper.windowEndTime(for: prayerType, schedule: schedule) {
            return time < endTime
        }
        // Isha: on-time for the rest of the day
        return true
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
        await NotificationScheduler.shared.forceReschedule()
    }

    func setMadhab(_ madhab: Madhab) async {
        self.madhab = madhab
        await PreferencesManager.shared.saveMadhab(madhab)
        await loadPrayerTimes()
        await NotificationScheduler.shared.forceReschedule()
    }

    func toggleRakatInfo() {
        showRakatInfo.toggle()
        Task { await PreferencesManager.shared.update(\.showRakatInfo, to: showRakatInfo) }
    }

    /// Reload settings from prefs (for sync after Settings page changes)
    func reloadSettings() {
        let prefs = PreferencesManager.loadPreferencesSync()
        calculationMethod = prefs.calculationMethod
        madhab = prefs.madhab
        showSunnahTimes = prefs.showSunnahTimes
        showRakatInfo = prefs.showRakatInfo
    }

    func requestNotificationPermission() async {
        let granted = await NotificationScheduler.shared.requestAuthorization()
        if granted {
            await NotificationScheduler.shared.forceReschedule()
        }
    }

    // MARK: - Private Methods

    private func getCurrentLocation(forceFresh: Bool = false) async throws -> Coordinates {
        // Return cached if available (skip when forcing fresh)
        if !forceFresh, let cached = currentLocation {
            return cached
        }

        // Try saved/cached coordinates first (skip when forcing fresh)
        if !forceFresh, let saved = locationService.coordinates {
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

    /// Pure decision helper — testable with any dates, no wall-clock dependency.
    static func shouldRefresh(
        now: Date,
        lastRefresh: Date,
        hasError: Bool,
        errorRetryUsed: Bool,
        throttleInterval: TimeInterval = 60
    ) -> Bool {
        // Day changed since last refresh — always refresh (midnight rollover)
        if !Calendar.current.isDate(now, inSameDayAs: lastRefresh) { return true }
        // Within throttle window
        if now.timeIntervalSince(lastRefresh) < throttleInterval {
            // Allow one error retry, then throttle again
            return hasError && !errorRetryUsed
        }
        return true
    }

    /// Refresh prayer data for foreground resume — advances date, clears location cache,
    /// and forces fresh GPS coordinates to avoid stale data after returning from background.
    /// Throttled to avoid wasteful GPS hits on quick tab switches and Control Center.
    func refreshForForeground() async {
        let now = Date()
        guard Self.shouldRefresh(
            now: now,
            lastRefresh: lastForegroundRefresh,
            hasError: error != nil,
            errorRetryUsed: errorRetryUsed
        ) else { return }

        lastForegroundRefresh = now
        if error != nil { errorRetryUsed = true } else { errorRetryUsed = false }

        currentDate = now
        currentLocation = nil

        // Force fresh GPS — skips locationService.coordinates cache too
        if let freshLocation = try? await getCurrentLocation(forceFresh: true) {
            currentLocation = freshLocation
        }

        await loadPrayerTimes()

        // Reset error retry on success
        if error == nil { errorRetryUsed = false }
    }

    func updateNextPrayerIndicator() {
        // Find which prayer the computed `nextPrayer` resolves to (accounts for grace)
        let nextId = nextPrayer?.id
        for i in 0..<todayPrayers.count {
            todayPrayers[i].isNext = todayPrayers[i].id == nextId
        }
    }

    private func updateLiveActivity() {
        let prefs = PreferencesManager.loadPreferencesSync()
        guard prefs.liveActivityEnabled else { return }
        guard let next = nextPrayer else {
            Task { await PrayerLiveActivityManager.shared.endActivity() }
            return
        }
        let isGrace = isPrayerTimeNow(next.time)
        let maghrib = todayPrayers.first(where: { $0.type == .maghrib })?.time
        let hijri = HijriDateConverter.shared.hijriDateString(from: Date(), style: .dayMonth, maghribTime: maghrib)
        let location = prefs.savedLocationName ?? AppDefaults.defaultLocationName

        // Convert PrayerTime → PrayerInfo for boundary scheduling
        let prayerInfos = todayPrayers
            .filter { $0.type.isObligatory }
            .map { PrayerInfo(name: $0.type.displayName, time: $0.time) }

        Task {
            await PrayerLiveActivityManager.shared.updateActivity(
                prayerName: next.type.displayName,
                prayerTime: next.time,
                hijriDate: hijri,
                locationName: location,
                isGrace: isGrace
            )
            // Schedule updates at each prayer boundary so the name switches on time
            PrayerLiveActivityManager.shared.scheduleBoundaryUpdates(
                prayers: prayerInfos,
                maghribTime: maghrib,
                locationName: location
            )
        }
    }

}

