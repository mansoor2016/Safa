// MARK: - PrayerTimeCalculator.swift
// PURPOSE: Calculate Islamic prayer times using adhan-swift (Meeus astronomical algorithms)
// DEPENDENCIES: Adhan

import Adhan
import Foundation

struct PrayerTimeCalculator {
    // MARK: - Calculate Prayer Times

    func calculatePrayerTimes(
        for date: Date,
        location: Coordinates,
        method: CalculationMethod,
        madhab: Madhab? = nil
    ) -> [PrayerTime] {
        let coords = Adhan.Coordinates(
            latitude: location.latitude,
            longitude: location.longitude
        )
        let components = Calendar.current.dateComponents(
            [.year, .month, .day], from: date
        )

        var params = adhanParameters(for: method)
        if let madhab = madhab {
            params.madhab = madhab == .hanafi ? Adhan.Madhab.hanafi : Adhan.Madhab.shafi
        }

        guard let times = Adhan.PrayerTimes(
            coordinates: coords,
            date: components,
            calculationParameters: params
        ) else {
            return []
        }

        return [
            PrayerTime(type: .fajr, time: times.fajr),
            PrayerTime(type: .sunrise, time: times.sunrise),
            PrayerTime(type: .dhuhr, time: times.dhuhr),
            PrayerTime(type: .asr, time: times.asr),
            PrayerTime(type: .maghrib, time: times.maghrib),
            PrayerTime(type: .isha, time: times.isha),
        ]
    }

    // MARK: - Qibla Direction

    func calculateQiblaDirection(from location: Coordinates) -> Double {
        let coords = Adhan.Coordinates(
            latitude: location.latitude,
            longitude: location.longitude
        )
        return Adhan.Qibla(coordinates: coords).direction
    }

    // MARK: - Private Helpers

    private func adhanParameters(for method: CalculationMethod) -> Adhan.CalculationParameters {
        switch method {
        case .muslimWorldLeague:
            return Adhan.CalculationMethod.muslimWorldLeague.params
        case .isna:
            return Adhan.CalculationMethod.northAmerica.params
        case .egypt:
            return Adhan.CalculationMethod.egyptian.params
        case .makkah:
            return Adhan.CalculationMethod.ummAlQura.params
        case .karachi:
            return Adhan.CalculationMethod.karachi.params
        case .tehran:
            return Adhan.CalculationMethod.tehran.params
        case .jafari:
            // Jafari method: Fajr 16°, Isha 14°, Hanafi madhab
            var params = Adhan.CalculationMethod.other.params
            params.fajrAngle = 16.0
            params.ishaAngle = 14.0
            params.madhab = Adhan.Madhab.hanafi
            return params
        }
    }
}
