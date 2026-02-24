// MARK: - PrayerLiveActivity.swift
// PURPOSE: Live Activity manager for prayer time countdown
// DEPENDENCIES: ActivityKit, SafaShared

import Foundation
import ActivityKit
import SafaShared

// MARK: - Live Activity Manager

@MainActor
final class PrayerLiveActivityManager {
    static let shared = PrayerLiveActivityManager()

    private var currentActivity: Activity<PrayerActivityAttributes>?
    private var boundaryTask: Task<Void, Never>?
    private let calculator = NextPrayerCalculator()

    // MARK: - Dependencies (configured once at app launch)

    private var prayerRepository: PrayerRepositoryProtocol?
    private var locationService: LocationServiceProtocol?

    private init() {}

    /// Configure with dependencies (call from Dependencies.init)
    func configure(
        prayerRepository: PrayerRepositoryProtocol,
        locationService: LocationServiceProtocol
    ) {
        self.prayerRepository = prayerRepository
        self.locationService = locationService
    }

    // MARK: - Ensure Activity (recover/start if needed)

    /// Ensure a Live Activity is running if the user wants one.
    /// Safe to call on every foreground resume — it's a no-op when already current.
    func ensureActivityIfNeeded() async {
        let prefs = PreferencesManager.loadPreferencesSync()

        // Not onboarded yet → don't show activity with default/London data
        guard prefs.hasCompletedOnboarding else { return }

        // Preference off → tear down any running activity
        guard prefs.liveActivityEnabled else {
            await endAllActivities()
            return
        }

        // System-level permission
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // Reattach to existing system activity after cold launch (prevents duplicates)
        if currentActivity == nil {
            currentActivity = Activity<PrayerActivityAttributes>.activities.first {
                $0.activityState == .active || $0.activityState == .stale
            }
        }

        // Detect stale/ended tracked activity
        if let activity = currentActivity {
            let state = activity.activityState
            if state == .ended || state == .dismissed {
                currentActivity = nil
            }
        }

        // Fetch today's prayers
        guard let repo = prayerRepository else { return }
        let coordinates = resolveCoordinates(prefs: prefs)
        guard let prayers = try? await repo.getPrayers(
            for: Date(),
            location: coordinates,
            method: prefs.calculationMethod,
            madhab: prefs.madhab
        ) else { return }

        // Find next obligatory prayer (including those in grace window)
        let now = Date()
        let obligatory = prayers.filter { $0.type.isObligatory }

        // Check for a prayer in its grace window first
        let gracePrayer = obligatory.last { isPrayerTimeNow($0.time, at: now) }
        let futurePrayer = obligatory.first { $0.time > now }

        guard let activePrayer = gracePrayer ?? futurePrayer else {
            // All prayers passed (including grace) — end all activities
            await endAllActivities()
            return
        }

        let isGrace = gracePrayer != nil
        let hijri = HijriDateConverter.shared.hijriDateString(from: now, style: .dayMonth)
        let location = prefs.savedLocationName ?? AppDefaults.defaultLocationName
        let prayerInfos = obligatory
            .map { PrayerInfo(name: $0.type.localizedDisplayName, time: $0.time) }

        await updateActivity(
            prayerName: activePrayer.type.localizedDisplayName,
            prayerTime: activePrayer.time,
            hijriDate: hijri,
            locationName: location,
            isGrace: isGrace
        )
        scheduleBoundaryUpdates(
            prayers: prayerInfos,
            hijriDate: hijri,
            locationName: location
        )
    }

    // MARK: - Start Activity

    func startActivity(
        prayerName: String,
        prayerTime: Date,
        hijriDate: String,
        locationName: String,
        isGrace: Bool = false
    ) {
        guard PreferencesManager.loadPreferencesSync().liveActivityEnabled else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = PrayerActivityAttributes(prayerType: prayerName)
        let state = PrayerActivityAttributes.ContentState(
            nextPrayerName: prayerName,
            nextPrayerTime: prayerTime,
            hijriDate: hijriDate,
            locationName: locationName,
            isGrace: isGrace
        )

        let content = ActivityContent(state: state, staleDate: LiveActivityStaleness.staleDate(for: prayerTime, isGrace: isGrace))

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            // Activity request failed — user may have disabled Live Activities
        }
    }

    // MARK: - Update Activity

    func updateActivity(
        prayerName: String,
        prayerTime: Date,
        hijriDate: String,
        locationName: String,
        isGrace: Bool = false
    ) async {
        // Reattach to existing system activity if handle was lost (cold launch)
        if currentActivity == nil {
            currentActivity = Activity<PrayerActivityAttributes>.activities.first {
                $0.activityState == .active || $0.activityState == .stale
            }
        }

        // Detect stale/ended tracked activity
        if let activity = currentActivity {
            let actState = activity.activityState
            if actState == .ended || actState == .dismissed {
                currentActivity = nil
            }
        }

        guard let activity = currentActivity else {
            startActivity(
                prayerName: prayerName,
                prayerTime: prayerTime,
                hijriDate: hijriDate,
                locationName: locationName,
                isGrace: isGrace
            )
            return
        }

        let state = PrayerActivityAttributes.ContentState(
            nextPrayerName: prayerName,
            nextPrayerTime: prayerTime,
            hijriDate: hijriDate,
            locationName: locationName,
            isGrace: isGrace
        )

        let content = ActivityContent(state: state, staleDate: LiveActivityStaleness.staleDate(for: prayerTime, isGrace: isGrace))

        await activity.update(content)
    }

    // MARK: - Schedule Boundary Updates

    /// Schedule Live Activity updates at each prayer boundary so the displayed prayer
    /// name switches at the correct time. Uses Task.sleep to wake at each boundary.
    /// Only effective while the app process is alive (foreground or recently backgrounded).
    /// Schedule Live Activity updates at each prayer boundary so the displayed prayer
    /// name switches at the correct time. Also handles grace windows (15 min after prayer time).
    ///
    /// **Limitation:** When app is suspended (>30s background), Task.sleep is frozen.
    /// The Live Activity may show stale content until the app is foregrounded or a push
    /// notification updates it. This is an ActivityKit limitation.
    func scheduleBoundaryUpdates(
        prayers: [PrayerInfo],
        hijriDate: String,
        locationName: String
    ) {
        boundaryTask?.cancel()
        boundaryTask = Task { [weak self] in
            guard let self else { return }
            var now = Date()

            while !Task.isCancelled {
                guard let nextDate = self.calculator.nextBoundaryDate(from: prayers, after: now) else {
                    // No more prayer boundaries today — end the activity
                    await self.endActivity()
                    return
                }

                let delay = nextDate.timeIntervalSince(now)
                guard delay > 0 else { break }

                do {
                    try await Task.sleep(for: .seconds(delay))
                } catch {
                    return // Cancelled
                }

                guard !Task.isCancelled else { return }

                now = Date()

                // Check if a prayer just arrived (entering grace window)
                if let gracePrayer = prayers.last(where: { isPrayerTimeNow($0.time, at: now) }) {
                    // Show grace state
                    await self.updateActivity(
                        prayerName: gracePrayer.name,
                        prayerTime: gracePrayer.time,
                        hijriDate: hijriDate,
                        locationName: locationName,
                        isGrace: true
                    )
                } else {
                    // Grace ended or normal transition — show next prayer
                    let next = self.calculator.nextPrayer(from: prayers, at: now)
                    if let next {
                        await self.updateActivity(
                            prayerName: next.name,
                            prayerTime: next.time,
                            hijriDate: hijriDate,
                            locationName: locationName,
                            isGrace: false
                        )
                    } else {
                        await self.endActivity()
                        return
                    }
                }
            }
        }
    }

    // MARK: - End Activity

    func endActivity() async {
        boundaryTask?.cancel()
        boundaryTask = nil

        guard let activity = currentActivity else { return }

        let state = activity.content.state
        let content = ActivityContent(state: state, staleDate: Date())

        await activity.end(content, dismissalPolicy: .immediate)
        currentActivity = nil
    }

    // MARK: - End All Activities

    func endAllActivities() async {
        boundaryTask?.cancel()
        boundaryTask = nil

        for activity in Activity<PrayerActivityAttributes>.activities {
            let state = activity.content.state
            let content = ActivityContent(state: state, staleDate: Date())
            await activity.end(content, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }

    // MARK: - Private Helpers

    /// Resolve coordinates: saved prefs → LocationService cache → AppDefaults
    private func resolveCoordinates(prefs: UserPreferences) -> Coordinates {
        if let saved = prefs.savedCoordinates {
            return saved
        }
        if let cached = locationService?.coordinates {
            return cached
        }
        return AppDefaults.defaultCoordinates
    }
}
