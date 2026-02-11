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
