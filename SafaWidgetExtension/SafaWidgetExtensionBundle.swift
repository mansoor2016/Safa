// MARK: - SafaWidgetExtensionBundle.swift
// PURPOSE: Widget bundle registering all Safa widgets

import WidgetKit
import SwiftUI

@main
struct SafaWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimesWidget()
        InteractivePrayerWidget()
        TasbeehWidget()
        StandByPrayerWidget()
    }
}
