// MARK: - Prayer.swift
// PURPOSE: Domain entities for prayer times, logging, and tracking

import Foundation
import SwiftUI

// MARK: - Prayer Type
enum PrayerType: String, Codable, CaseIterable, Identifiable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fajr: return "Fajr"
        case .sunrise: return "Sunrise"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }

    var arabicName: String {
        switch self {
        case .fajr: return "الفجر"
        case .sunrise: return "الشروق"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }

    var isObligatory: Bool {
        switch self {
        case .fajr, .dhuhr, .asr, .maghrib, .isha: return true
        case .sunrise: return false
        }
    }

    var iconName: String {
        switch self {
        case .fajr: return "sunrise"
        case .sunrise: return "sun.and.horizon"
        case .dhuhr: return "sun.max"
        case .asr: return "sun.min"
        case .maghrib: return "sunset"
        case .isha: return "moon.stars"
        }
    }

    static var obligatoryPrayers: [PrayerType] {
        [.fajr, .dhuhr, .asr, .maghrib, .isha]
    }
}

// MARK: - Prayer Time
struct PrayerTime: Identifiable, Hashable {
    let id: UUID
    let type: PrayerType
    let time: Date
    var isNext: Bool

    init(id: UUID = UUID(), type: PrayerType, time: Date, isNext: Bool = false) {
        self.id = id
        self.type = type
        self.time = time
        self.isNext = isNext
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}

// MARK: - Daily Prayer Times
struct DailyPrayerTimes {
    let fajr: PrayerTime
    let sunrise: PrayerTime
    let dhuhr: PrayerTime
    let asr: PrayerTime
    let maghrib: PrayerTime
    let isha: PrayerTime

    var all: [PrayerTime] {
        [fajr, sunrise, dhuhr, asr, maghrib, isha]
    }

    var obligatory: [PrayerTime] {
        [fajr, dhuhr, asr, maghrib, isha]
    }
}

// MARK: - Prayer Log
struct PrayerLog: Identifiable, Codable, Hashable {
    let id: UUID
    let prayerType: PrayerType
    let date: Date
    let loggedAt: Date
    let isOnTime: Bool
    let isMakeup: Bool

    init(
        id: UUID = UUID(),
        prayerType: PrayerType,
        date: Date,
        loggedAt: Date = Date(),
        isOnTime: Bool = true,
        isMakeup: Bool = false
    ) {
        self.id = id
        self.prayerType = prayerType
        self.date = date
        self.loggedAt = loggedAt
        self.isOnTime = isOnTime
        self.isMakeup = isMakeup
    }
}

// MARK: - Coordinates
struct Coordinates: Codable, Hashable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Madhab (for Asr calculation)
enum Madhab: String, Codable, CaseIterable, Identifiable {
    case shafi      // Standard - shadow equals object length
    case hanafi     // Hanafi - shadow equals twice the object length

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shafi: return "Shafi'i / Maliki / Hanbali"
        case .hanafi: return "Hanafi"
        }
    }

    var shadowRatio: Double {
        switch self {
        case .shafi: return 1.0
        case .hanafi: return 2.0
        }
    }
}

// MARK: - Calculation Method
enum CalculationMethod: String, Codable, CaseIterable, Identifiable {
    case muslimWorldLeague = "mwl"
    case isna = "isna"
    case egypt = "egypt"
    case makkah = "makkah"
    case karachi = "karachi"
    case tehran = "tehran"
    case jafari = "jafari"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .muslimWorldLeague: return "Muslim World League"
        case .isna: return "Islamic Society of North America (ISNA)"
        case .egypt: return "Egyptian General Authority"
        case .makkah: return "Umm Al-Qura, Makkah"
        case .karachi: return "University of Islamic Sciences, Karachi"
        case .tehran: return "Institute of Geophysics, Tehran"
        case .jafari: return "Shia Ithna-Ashari (Jafari)"
        }
    }

    var fajrAngle: Double {
        switch self {
        case .muslimWorldLeague: return 18.0
        case .isna: return 15.0
        case .egypt: return 19.5
        case .makkah: return 18.5
        case .karachi: return 18.0
        case .tehran: return 17.7
        case .jafari: return 16.0
        }
    }

    var ishaAngle: Double {
        switch self {
        case .muslimWorldLeague: return 17.0
        case .isna: return 15.0
        case .egypt: return 17.5
        case .makkah: return 0 // Uses 90 min after Maghrib
        case .karachi: return 18.0
        case .tehran: return 14.0
        case .jafari: return 14.0
        }
    }

    var asrShadowRatio: Double {
        switch self {
        case .jafari: return 2.0 // Hanafi: shadow equals twice the object
        default: return 1.0 // Standard: shadow equals object length
        }
    }
}
