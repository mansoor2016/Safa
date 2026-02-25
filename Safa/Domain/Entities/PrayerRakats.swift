// MARK: - PrayerRakats.swift
// PURPOSE: Madhab-aware rakat breakdown for each prayer with before/after Fard split
// DEPENDENCIES: Foundation, PrayerType, Madhab

import Foundation

// MARK: - PrayerRakatInfo

struct PrayerRakatInfo {
    let sunnahBefore: Int     // Sunnah Mu'akkadah before Fard
    let naflBefore: Int       // Nafl (Ghair Mu'akkadah) before Fard
    let fard: Int
    let sunnahAfter: Int      // Sunnah Mu'akkadah after Fard
    let naflAfter: Int        // Nafl (Ghair Mu'akkadah) after Fard
    let witr: Int
    let witrIsRange: Bool

    /// Compact notation in prayer order: "4S · 4F · 2S · 2N"
    var compactSummary: String {
        var segments: [String] = []
        if sunnahBefore > 0 { segments.append("\(sunnahBefore)S") }
        if naflBefore > 0 { segments.append("\(naflBefore)N") }
        segments.append("\(fard)F")
        if sunnahAfter > 0 { segments.append("\(sunnahAfter)S") }
        if naflAfter > 0 { segments.append("\(naflAfter)N") }
        if witr > 0 {
            segments.append(witrIsRange ? "\(witr)+W" : "\(witr)W")
        }
        return segments.joined(separator: " · ")
    }

    /// Detailed summary in prayer order: "4 Sunnah · 4 Fard · 2 Sunnah · 2 Nafl"
    var detailedSummary: String {
        var segments: [String] = []
        if sunnahBefore > 0 { segments.append(String(localized: "\(sunnahBefore) Sunnah")) }
        if naflBefore > 0 { segments.append(String(localized: "\(naflBefore) Nafl")) }
        segments.append(String(localized: "\(fard) Fard"))
        if sunnahAfter > 0 { segments.append(String(localized: "\(sunnahAfter) Sunnah")) }
        if naflAfter > 0 { segments.append(String(localized: "\(naflAfter) Nafl")) }
        if witr > 0 {
            if witrIsRange {
                segments.append(String(localized: "\(witr)+ Witr"))
            } else {
                segments.append(String(localized: "\(witr) Witr"))
            }
        }
        return segments.joined(separator: " · ")
    }
}

// MARK: - PrayerRakats

enum PrayerRakats {
    /// Returns rakat breakdown for a prayer type and madhab. Returns nil for sunrise.
    static func info(for prayer: PrayerType, madhab: Madhab) -> PrayerRakatInfo? {
        switch (prayer, madhab) {
        // MARK: Fajr (same for both)
        case (.fajr, _):
            return PrayerRakatInfo(sunnahBefore: 2, naflBefore: 0, fard: 2, sunnahAfter: 0, naflAfter: 0, witr: 0, witrIsRange: false)

        // MARK: Sunrise (not a prayer)
        case (.sunrise, _):
            return nil

        // MARK: Dhuhr
        case (.dhuhr, .hanafi):
            // 4 Sunnah Mu. before, 4 Fard, 2 Sunnah Mu. after, 2 Nafl after
            return PrayerRakatInfo(sunnahBefore: 4, naflBefore: 0, fard: 4, sunnahAfter: 2, naflAfter: 2, witr: 0, witrIsRange: false)
        case (.dhuhr, .shafi):
            // 2 Sunnah Mu. before, 2 Nafl before, 4 Fard, 2 Sunnah Mu. after, 2 Nafl after
            return PrayerRakatInfo(sunnahBefore: 2, naflBefore: 2, fard: 4, sunnahAfter: 2, naflAfter: 2, witr: 0, witrIsRange: false)

        // MARK: Asr (same for both)
        case (.asr, _):
            // 4 Nafl before
            return PrayerRakatInfo(sunnahBefore: 0, naflBefore: 4, fard: 4, sunnahAfter: 0, naflAfter: 0, witr: 0, witrIsRange: false)

        // MARK: Maghrib (same for both)
        case (.maghrib, _):
            // 3 Fard, 2 Sunnah Mu. after, 2 Nafl after
            return PrayerRakatInfo(sunnahBefore: 0, naflBefore: 0, fard: 3, sunnahAfter: 2, naflAfter: 2, witr: 0, witrIsRange: false)

        // MARK: Isha
        case (.isha, .hanafi):
            // 4 Nafl before, 4 Fard, 2 Sunnah Mu. after, 2 Nafl after, 3 Witr (Wajib, fixed)
            return PrayerRakatInfo(sunnahBefore: 0, naflBefore: 4, fard: 4, sunnahAfter: 2, naflAfter: 2, witr: 3, witrIsRange: false)
        case (.isha, .shafi):
            // 2 Nafl before, 4 Fard, 2 Sunnah Mu. after, 2 Nafl after, 1+ Witr (Sunnah Mu., range)
            return PrayerRakatInfo(sunnahBefore: 0, naflBefore: 2, fard: 4, sunnahAfter: 2, naflAfter: 2, witr: 1, witrIsRange: true)
        }
    }
}
