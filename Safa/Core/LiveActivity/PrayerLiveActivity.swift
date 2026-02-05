// MARK: - PrayerLiveActivity.swift
// PURPOSE: Live Activity for prayer time countdown on lock screen
// DEPENDENCIES: ActivityKit, WidgetKit, SwiftUI

import ActivityKit
import WidgetKit
import SwiftUI
import Combine

// MARK: - Prayer Activity Attributes

struct PrayerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var nextPrayerName: String
        var nextPrayerTime: Date
        var hijriDate: String
        var locationName: String
    }

    var prayerType: String
}

// MARK: - Prayer Live Activity View

struct PrayerLiveActivityView: View {
    let context: ActivityViewContext<PrayerActivityAttributes>

    var body: some View {
        HStack {
            // Prayer info
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Prayer")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(context.state.nextPrayerName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(context.state.locationName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Countdown
            VStack(alignment: .trailing, spacing: 4) {
                Text(context.state.nextPrayerTime, style: .time)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(context.state.nextPrayerTime, style: .relative)
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
    }
}

// MARK: - Compact Live Activity Views

struct PrayerLiveActivityCompactLeadingView: View {
    let context: ActivityViewContext<PrayerActivityAttributes>

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "moon.stars")
            Text(context.state.nextPrayerName)
                .font(.caption)
        }
    }
}

struct PrayerLiveActivityCompactTrailingView: View {
    let context: ActivityViewContext<PrayerActivityAttributes>

    var body: some View {
        Text(context.state.nextPrayerTime, style: .time)
            .font(.caption)
            .monospacedDigit()
    }
}

// MARK: - Minimal Live Activity View

struct PrayerLiveActivityMinimalView: View {
    let context: ActivityViewContext<PrayerActivityAttributes>

    var body: some View {
        Image(systemName: "moon.stars")
    }
}

// MARK: - Live Activity Manager

@MainActor
final class PrayerLiveActivityManager: ObservableObject {
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
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

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
            print("Started Live Activity for \(prayerName)")
        } catch {
            print("Failed to start Live Activity: \(error)")
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

// MARK: - Live Activity Widget Bundle Extension

// Note: This would be in the Widget extension target
/*
@main
struct SafaWidgetBundle: WidgetBundle {
    var body: some Widget {
        SafaWidget()

        if #available(iOS 16.1, *) {
            PrayerLiveActivityWidget()
        }
    }
}

@available(iOS 16.1, *)
struct PrayerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            PrayerLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("Next Prayer")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.nextPrayerName)
                            .font(.headline)
                    }
                    .padding(.leading)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(context.state.nextPrayerTime, style: .time)
                            .font(.headline)
                        Text(context.state.nextPrayerTime, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.trailing)
                }
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(context.state.locationName)
                            .font(.caption2)
                        Spacer()
                        Text(context.state.hijriDate)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                }
            } compactLeading: {
                PrayerLiveActivityCompactLeadingView(context: context)
            } compactTrailing: {
                PrayerLiveActivityCompactTrailingView(context: context)
            } minimal: {
                PrayerLiveActivityMinimalView(context: context)
            }
        }
    }
}
*/
