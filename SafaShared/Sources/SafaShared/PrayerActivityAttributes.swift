// MARK: - PrayerActivityAttributes.swift
// PURPOSE: Shared ActivityKit attributes for prayer Live Activity
// DEPENDENCIES: ActivityKit

import Foundation
import ActivityKit

public struct PrayerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var nextPrayerName: String
        public var nextPrayerTime: Date
        public var hijriDate: String
        public var locationName: String

        public init(
            nextPrayerName: String,
            nextPrayerTime: Date,
            hijriDate: String,
            locationName: String
        ) {
            self.nextPrayerName = nextPrayerName
            self.nextPrayerTime = nextPrayerTime
            self.hijriDate = hijriDate
            self.locationName = locationName
        }
    }

    public var prayerType: String

    public init(prayerType: String) {
        self.prayerType = prayerType
    }
}
