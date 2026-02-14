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

    private init() {}

    // MARK: - Start Activity

    func startActivity(
        prayerName: String,
        prayerTime: Date,
        hijriDate: String,
        locationName: String
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = PrayerActivityAttributes(prayerType: prayerName)
        let state = PrayerActivityAttributes.ContentState(
            nextPrayerName: prayerName,
            nextPrayerTime: prayerTime,
            hijriDate: hijriDate,
            locationName: locationName
        )

        let content = ActivityContent(state: state, staleDate: prayerTime)

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
        locationName: String
    ) async {
        guard let activity = currentActivity else {
            startActivity(
                prayerName: prayerName,
                prayerTime: prayerTime,
                hijriDate: hijriDate,
                locationName: locationName
            )
            return
        }

        let state = PrayerActivityAttributes.ContentState(
            nextPrayerName: prayerName,
            nextPrayerTime: prayerTime,
            hijriDate: hijriDate,
            locationName: locationName
        )

        let content = ActivityContent(state: state, staleDate: prayerTime)

        await activity.update(content)
    }

    // MARK: - Schedule Boundary Updates

    /// Schedule Live Activity updates at each prayer boundary so the displayed prayer
    /// name switches at the correct time. Uses Task.sleep to wake at each boundary.
    /// Only effective while the app process is alive (foreground or recently backgrounded).
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
                let next = self.calculator.nextPrayer(from: prayers, at: now)
                if let next {
                    await self.updateActivity(
                        prayerName: next.name,
                        prayerTime: next.time,
                        hijriDate: hijriDate,
                        locationName: locationName
                    )
                } else {
                    await self.endActivity()
                    return
                }
            }
        }
    }

    // MARK: - End Activity

    func endActivity() async {
        guard let activity = currentActivity else { return }

        let state = activity.content.state
        let content = ActivityContent(state: state, staleDate: Date())

        await activity.end(content, dismissalPolicy: .immediate)
        currentActivity = nil
    }

    // MARK: - End All Activities

    func endAllActivities() async {
        for activity in Activity<PrayerActivityAttributes>.activities {
            let state = activity.content.state
            let content = ActivityContent(state: state, staleDate: Date())
            await activity.end(content, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
}
