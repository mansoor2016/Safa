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

    /// Localized display name for user-facing surfaces (widgets, live activity, notifications)
    var localizedDisplayName: String {
        String(localized: String.LocalizationValue(displayName))
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

    /// All adhan sounds for the regular (non-Fajr) picker — excludes Fajr-specific and system default
    static var regularOptions: [AdhanSound] {
        allCases.filter { !$0.isFajrSpecific && $0 != .defaultSound }
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
    case dubai = "dubai"
    case kuwait = "kuwait"
    case qatar = "qatar"
    case singapore = "singapore"
    case turkey = "turkey"

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
        case .dubai: return "Dubai (GIAE)"
        case .kuwait: return "Kuwait"
        case .qatar: return "Qatar"
        case .singapore: return "MUIS, Singapore"
        case .turkey: return "Diyanet, Turkey"
        }
    }

    var localizedDisplayName: String {
        String(localized: String.LocalizationValue(displayName))
    }

    var shortDisplayName: String {
        switch self {
        case .muslimWorldLeague: return "MWL"
        case .isna: return "ISNA"
        case .egypt: return "Egyptian"
        case .makkah: return "Makkah"
        case .karachi: return "Karachi"
        case .tehran: return "Tehran"
        case .jafari: return "Jafari"
        case .dubai: return "Dubai"
        case .kuwait: return "Kuwait"
        case .qatar: return "Qatar"
        case .singapore: return "Singapore"
        case .turkey: return "Turkey"
        }
    }

    var methodDescription: String {
        switch self {
        case .muslimWorldLeague:
            return "Used across Europe, Africa, and parts of Asia. Fajr 18°, Isha 17°."
        case .isna:
            return "Standard for the United States and Canada. Fajr 15°, Isha 15°."
        case .egypt:
            return "Used in Egypt, Libya, and Sudan. Fajr 19.5°, Isha 17.5°."
        case .makkah:
            return "Umm al-Qura method for Saudi Arabia and nearby Gulf states. Fajr 18.5°, Isha 90 min after Maghrib."
        case .karachi:
            return "Used in Pakistan, Bangladesh, Afghanistan, and India. Fajr 18°, Isha 18°."
        case .tehran:
            return "Used in Iran. Fajr 17.7°, Isha 14°, with Maghrib at 4.5°."
        case .jafari:
            return "Shia Ithna-Ashari method. Fajr 16°, Isha 14°."
        case .dubai:
            return "GIAE method for the United Arab Emirates. Fajr 18.2°, Isha 18.2°."
        case .kuwait:
            return "Standard for Kuwait. Fajr 18°, Isha 17.5°."
        case .qatar:
            return "Modified Umm al-Qura for Qatar. Fajr 18°, Isha 90 min after Maghrib."
        case .singapore:
            return "MUIS method for Singapore, Malaysia, and Brunei. Fajr 20°, Isha 18°."
        case .turkey:
            return "Diyanet method for Turkey and Central Asia. Fajr 18°, Isha 17°."
        }
    }
}

// MARK: - Sunnah Time Type

enum SunnahTimeType: String, Codable, CaseIterable, Identifiable {
    case middleOfTheNight
    case lastThirdOfTheNight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .middleOfTheNight: return "Middle of the Night"
        case .lastThirdOfTheNight: return "Last Third of the Night"
        }
    }

    var localizedDisplayName: String {
        String(localized: String.LocalizationValue(displayName))
    }

    var arabicName: String {
        switch self {
        case .middleOfTheNight: return "نصف الليل"
        case .lastThirdOfTheNight: return "الثلث الأخير"
        }
    }

    var iconName: String {
        switch self {
        case .middleOfTheNight: return "moon.fill"
        case .lastThirdOfTheNight: return "moon.haze.fill"
        }
    }
}

// MARK: - Sunnah Time

struct SunnahTime: Identifiable, Hashable {
    let id: UUID
    let type: SunnahTimeType
    let time: Date

    init(id: UUID = UUID(), type: SunnahTimeType, time: Date) {
        self.id = id
        self.type = type
        self.time = time
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}
