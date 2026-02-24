// MARK: - PrayerLiveActivityWidget.swift
// PURPOSE: Live Activity widget for prayer time countdown on lock screen and Dynamic Island
// DEPENDENCIES: WidgetKit, SwiftUI, ActivityKit, SafaShared

import WidgetKit
import SwiftUI
import ActivityKit
import SafaShared

// MARK: - Lock Screen View

struct PrayerLiveActivityView: View {
    let context: ActivityViewContext<PrayerActivityAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.isGrace ? "Time to pray" : "Next Prayer")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(context.state.nextPrayerName)
                    .font(.title2)
                    .fontWeight(.bold)

                if context.isStale {
                    Text("Open app to refresh")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if context.state.isGrace {
                    Text("Prayer time")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                } else {
                    Text(context.state.nextPrayerTime, style: .relative)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }

                Text(context.state.locationName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if context.isStale {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .foregroundColor(.secondary)
            } else {
                Text(context.state.nextPrayerTime, style: .time)
                    .font(.title)
                    .fontWeight(.semibold)
            }
        }
        .padding()
    }
}

// MARK: - Dynamic Island Compact Views

struct PrayerCompactLeadingView: View {
    let context: ActivityViewContext<PrayerActivityAttributes>

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "moon.stars")
            Text(context.state.nextPrayerName)
                .font(.caption)
        }
    }
}

struct PrayerCompactTrailingView: View {
    let context: ActivityViewContext<PrayerActivityAttributes>

    var body: some View {
        if context.isStale {
            Image(systemName: "arrow.clockwise")
                .font(.caption)
        } else {
            Text(context.state.nextPrayerTime, style: .time)
                .font(.caption)
                .monospacedDigit()
        }
    }
}

// MARK: - Dynamic Island Minimal View

struct PrayerMinimalView: View {
    let context: ActivityViewContext<PrayerActivityAttributes>

    var body: some View {
        Image(systemName: "moon.stars")
    }
}

// MARK: - Widget Configuration

struct PrayerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            PrayerLiveActivityView(context: context)
                .widgetURL(URL(string: "safa://prayer"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text(context.state.isGrace ? "Time to pray" : "Next Prayer")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.nextPrayerName)
                            .font(.headline)
                    }
                    .padding(.leading)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        if context.isStale {
                            Text("Tap to refresh")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else if context.state.isGrace {
                            Text(context.state.nextPrayerTime, style: .time)
                                .font(.headline)
                            Text("Prayer time")
                                .font(.caption2)
                                .foregroundColor(.accentColor)
                        } else {
                            Text(context.state.nextPrayerTime, style: .time)
                                .font(.headline)
                            Text(context.state.nextPrayerTime, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.accentColor)
                        }
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
                PrayerCompactLeadingView(context: context)
            } compactTrailing: {
                PrayerCompactTrailingView(context: context)
            } minimal: {
                PrayerMinimalView(context: context)
            }
            .widgetURL(URL(string: "safa://prayer"))
        }
    }
}
