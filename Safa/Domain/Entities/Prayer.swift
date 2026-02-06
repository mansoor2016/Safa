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

    var shortName: String {
        switch self {
        case .fajr: return "Faj"
        case .sunrise: return "Sun"
        case .dhuhr: return "Dhu"
        case .asr: return "Asr"
        case .maghrib: return "Mag"
        case .isha: return "Ish"
        }
    }
}

// MARK: - Adhan Sound

enum AdhanSound: String, Codable, CaseIterable, Identifiable {
    case defaultSound = "default"
    case misharyAlafasy = "mishary_alafasy"
    case misharyAlafasyFajr = "mishary_alafasy_fajr"
    case abdulbasitAbdusamad = "abdulbasit_abdusamad"
    case adhamAlSharqawe = "adham_al_sharqawe"
    case ahmadAlTrablsi = "ahmad_al_trablsi"
    case ahmedElKourdi = "ahmed_el_kourdi"
    case hamzaAlMajale = "hamza_al_majale"
    case ismailAlSheikh = "ismail_al_sheikh"
    case muhammadAlDamradash = "muhammad_al_damradash"
    case muhammadRamadanSaadMakkah = "muhammad_ramadan_saad_makkah"
    case rabehIbnDarah = "rabeh_ibn_darah"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .defaultSound: return "System Default"
        case .misharyAlafasy: return "Mishary Rashid Alafasy"
        case .misharyAlafasyFajr: return "Mishary Alafasy (Fajr)"
        case .abdulbasitAbdusamad: return "Abdul Basit Abdul Samad"
        case .adhamAlSharqawe: return "Adham Al Sharqawe"
        case .ahmadAlTrablsi: return "Ahmad Al Trablsi"
        case .ahmedElKourdi: return "Ahmed El Kourdi"
        case .hamzaAlMajale: return "Hamza Al Majale"
        case .ismailAlSheikh: return "Ismail Al Sheikh"
        case .muhammadAlDamradash: return "Muhammad Al Damradash"
        case .muhammadRamadanSaadMakkah: return "Muhammad Ramadan Saad"
        case .rabehIbnDarah: return "Rabeh Ibn Darah"
        }
    }

    var subtitle: String {
        switch self {
        case .defaultSound: return "Standard iOS notification sound"
        case .misharyAlafasy: return "Kuwaiti style, polished melody"
        case .misharyAlafasyFajr: return "Fajr-specific with pre-dawn call"
        case .abdulbasitAbdusamad: return "Egyptian, deep Maqam Bayati"
        case .adhamAlSharqawe: return "Egyptian, ornate vocal style"
        case .ahmadAlTrablsi: return "Levantine, warm Shami melody"
        case .ahmedElKourdi: return "Contemplative Maqam Hijaz"
        case .hamzaAlMajale: return "Jordanian, bright and uplifting"
        case .ismailAlSheikh: return "Soft, meditative delivery"
        case .muhammadAlDamradash: return "Cairo-style Maqam Rast"
        case .muhammadRamadanSaadMakkah: return "Makkah Haram-style, majestic"
        case .rabehIbnDarah: return "Algerian, Andalusian-influenced"
        }
    }

    var isFajrSpecific: Bool { self == .misharyAlafasyFajr }

    /// All adhan sounds suitable for regular (non-Fajr) prayers
    static var regularOptions: [AdhanSound] {
        allCases.filter { !$0.isFajrSpecific }
    }

    /// All adhan sounds (for Fajr picker, which can use any)
    static var fajrOptions: [AdhanSound] {
        allCases.filter { $0 != .defaultSound }
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

    // MARK: - Sample Data for Previews

    static var samplePrayers: [PrayerTime] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return [
            PrayerTime(type: .fajr, time: calendar.date(bySettingHour: 5, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .sunrise, time: calendar.date(bySettingHour: 6, minute: 45, second: 0, of: today)!),
            PrayerTime(type: .dhuhr, time: calendar.date(bySettingHour: 12, minute: 15, second: 0, of: today)!),
            PrayerTime(type: .asr, time: calendar.date(bySettingHour: 15, minute: 45, second: 0, of: today)!),
            PrayerTime(type: .maghrib, time: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: today)!),
            PrayerTime(type: .isha, time: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!)
        ]
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
