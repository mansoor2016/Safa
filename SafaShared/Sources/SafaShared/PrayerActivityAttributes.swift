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
        public var isGrace: Bool

        public init(
            nextPrayerName: String,
            nextPrayerTime: Date,
            hijriDate: String,
            locationName: String,
            isGrace: Bool = false
        ) {
            self.nextPrayerName = nextPrayerName
            self.nextPrayerTime = nextPrayerTime
            self.hijriDate = hijriDate
            self.locationName = locationName
            self.isGrace = isGrace
        }

        // Custom decoder: isGrace defaults to false for payloads from pre-update activities
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            nextPrayerName = try container.decode(String.self, forKey: .nextPrayerName)
            nextPrayerTime = try container.decode(Date.self, forKey: .nextPrayerTime)
            hijriDate = try container.decode(String.self, forKey: .hijriDate)
            locationName = try container.decode(String.self, forKey: .locationName)
            isGrace = try container.decodeIfPresent(Bool.self, forKey: .isGrace) ?? false
        }
    }

    public var prayerType: String

    public init(prayerType: String) {
        self.prayerType = prayerType
    }
}
