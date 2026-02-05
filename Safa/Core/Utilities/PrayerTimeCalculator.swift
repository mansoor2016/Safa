// MARK: - PrayerTimeCalculator.swift
// PURPOSE: Calculate Islamic prayer times based on location and calculation method
// DEPENDENCIES: Foundation

import Foundation

final class PrayerTimeCalculator {
    // MARK: - Constants
    private let kaabahLatitude = 21.4225
    private let kaabahLongitude = 39.8262

    // MARK: - Calculate Prayer Times

    func calculatePrayerTimes(
        for date: Date,
        location: Coordinates,
        method: CalculationMethod
    ) -> [PrayerTime] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return []
        }

        // Calculate Julian date
        let jd = julianDate(year: year, month: month, day: day)

        // Get sun position
        let sunDec = sunDeclination(jd: jd)
        let eqTime = equationOfTime(jd: jd)

        // Calculate prayer times
        let fajr = calculateFajr(
            latitude: location.latitude,
            longitude: location.longitude,
            sunDeclination: sunDec,
            equationOfTime: eqTime,
            fajrAngle: method.fajrAngle
        )

        let sunrise = calculateSunrise(
            latitude: location.latitude,
            longitude: location.longitude,
            sunDeclination: sunDec,
            equationOfTime: eqTime
        )

        let dhuhr = calculateDhuhr(
            longitude: location.longitude,
            equationOfTime: eqTime
        )

        let asr = calculateAsr(
            latitude: location.latitude,
            sunDeclination: sunDec,
            dhuhr: dhuhr,
            shadow: method.asrShadowRatio
        )

        let maghrib = calculateMaghrib(
            latitude: location.latitude,
            longitude: location.longitude,
            sunDeclination: sunDec,
            equationOfTime: eqTime
        )

        let isha = calculateIsha(
            latitude: location.latitude,
            longitude: location.longitude,
            sunDeclination: sunDec,
            equationOfTime: eqTime,
            ishaAngle: method.ishaAngle,
            maghribTime: maghrib
        )

        // Convert to Date objects
        let prayerTimes = [
            PrayerTime(type: .fajr, time: timeToDate(hours: fajr, date: date)),
            PrayerTime(type: .sunrise, time: timeToDate(hours: sunrise, date: date)),
            PrayerTime(type: .dhuhr, time: timeToDate(hours: dhuhr, date: date)),
            PrayerTime(type: .asr, time: timeToDate(hours: asr, date: date)),
            PrayerTime(type: .maghrib, time: timeToDate(hours: maghrib, date: date)),
            PrayerTime(type: .isha, time: timeToDate(hours: isha, date: date)),
        ]

        return prayerTimes
    }

    // MARK: - Qibla Direction

    func calculateQiblaDirection(from location: Coordinates) -> Double {
        let lat1 = location.latitude.toRadians
        let lon1 = location.longitude.toRadians
        let lat2 = kaabahLatitude.toRadians
        let lon2 = kaabahLongitude.toRadians

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        var bearing = atan2(y, x).toDegrees
        bearing = (bearing + 360).truncatingRemainder(dividingBy: 360)

        return bearing
    }

    // MARK: - Private Calculation Methods

    private func calculateFajr(
        latitude: Double,
        longitude: Double,
        sunDeclination: Double,
        equationOfTime: Double,
        fajrAngle: Double
    ) -> Double {
        let t = calculateTimeForAngle(
            angle: fajrAngle,
            latitude: latitude,
            sunDeclination: sunDeclination,
            rising: true
        )
        let transit = 12 + (-longitude / 15) - (equationOfTime / 60)
        return transit - (t / 15)
    }

    private func calculateSunrise(
        latitude: Double,
        longitude: Double,
        sunDeclination: Double,
        equationOfTime: Double
    ) -> Double {
        let t = calculateTimeForAngle(
            angle: 0.833, // Standard refraction
            latitude: latitude,
            sunDeclination: sunDeclination,
            rising: true
        )
        let transit = 12 + (-longitude / 15) - (equationOfTime / 60)
        return transit - (t / 15)
    }

    private func calculateDhuhr(
        longitude: Double,
        equationOfTime: Double
    ) -> Double {
        return 12 + (-longitude / 15) - (equationOfTime / 60)
    }

    private func calculateAsr(
        latitude: Double,
        sunDeclination: Double,
        dhuhr: Double,
        shadow: Double
    ) -> Double {
        let latRad = latitude.toRadians
        let decRad = sunDeclination.toRadians

        let angle = atan(1 / (shadow + tan(abs(latRad - decRad))))
        let asrAngle = acos(
            (sin(angle) - sin(latRad) * sin(decRad)) /
            (cos(latRad) * cos(decRad))
        ).toDegrees

        return dhuhr + (asrAngle / 15)
    }

    private func calculateMaghrib(
        latitude: Double,
        longitude: Double,
        sunDeclination: Double,
        equationOfTime: Double
    ) -> Double {
        let t = calculateTimeForAngle(
            angle: 0.833,
            latitude: latitude,
            sunDeclination: sunDeclination,
            rising: false
        )
        let transit = 12 + (-longitude / 15) - (equationOfTime / 60)
        return transit + (t / 15)
    }

    private func calculateIsha(
        latitude: Double,
        longitude: Double,
        sunDeclination: Double,
        equationOfTime: Double,
        ishaAngle: Double,
        maghribTime: Double
    ) -> Double {
        let t = calculateTimeForAngle(
            angle: ishaAngle,
            latitude: latitude,
            sunDeclination: sunDeclination,
            rising: false
        )
        let transit = 12 + (-longitude / 15) - (equationOfTime / 60)
        return transit + (t / 15)
    }

    private func calculateTimeForAngle(
        angle: Double,
        latitude: Double,
        sunDeclination: Double,
        rising: Bool
    ) -> Double {
        let latRad = latitude.toRadians
        let decRad = sunDeclination.toRadians
        let angleRad = angle.toRadians

        let cosH = (cos(angleRad + .pi / 2) - sin(latRad) * sin(decRad)) /
                   (cos(latRad) * cos(decRad))

        // Handle high latitudes
        if cosH > 1 || cosH < -1 {
            return 0
        }

        let h = acos(cosH).toDegrees
        return h
    }

    // MARK: - Astronomical Calculations

    private func julianDate(year: Int, month: Int, day: Int) -> Double {
        var y = Double(year)
        var m = Double(month)

        if m <= 2 {
            y -= 1
            m += 12
        }

        let a = floor(y / 100)
        let b = 2 - a + floor(a / 4)

        return floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + Double(day) + b - 1524.5
    }

    private func sunDeclination(jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t
        let m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t
        let e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t

        let c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(m.toRadians) +
                (0.019993 - 0.000101 * t) * sin(2 * m.toRadians) +
                0.000289 * sin(3 * m.toRadians)

        let sunLon = l0 + c
        let omega = 125.04 - 1934.136 * t
        let lambda = sunLon - 0.00569 - 0.00478 * sin(omega.toRadians)

        let epsilon0 = 23.439291 - 0.013004167 * t - 0.0000001639 * t * t + 0.0000005036 * t * t * t
        let epsilon = epsilon0 + 0.00256 * cos(omega.toRadians)

        return asin(sin(epsilon.toRadians) * sin(lambda.toRadians)).toDegrees
    }

    private func equationOfTime(jd: Double) -> Double {
        let t = (jd - 2451545.0) / 36525.0
        let l0 = (280.46646 + 36000.76983 * t).truncatingRemainder(dividingBy: 360)
        let m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t
        let e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t

        let y = tan((23.439291 - 0.013004167 * t).toRadians / 2)
        let ySquared = y * y

        let sinM = sin(m.toRadians)
        let sin2L0 = sin(2 * l0.toRadians)
        let cos2L0 = cos(2 * l0.toRadians)
        let sin4L0 = sin(4 * l0.toRadians)
        let sin2M = sin(2 * m.toRadians)

        let eot = ySquared * sin2L0 - 2 * e * sinM + 4 * e * ySquared * sinM * cos2L0 -
                  0.5 * ySquared * ySquared * sin4L0 - 1.25 * e * e * sin2M

        return 4 * eot.toDegrees
    }

    // MARK: - Helpers

    private func timeToDate(hours: Double, date: Date) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Get timezone offset
        let timezone = TimeZone.current
        let gmtOffset = Double(timezone.secondsFromGMT(for: date)) / 3600

        let adjustedHours = hours + gmtOffset
        let totalSeconds = adjustedHours * 3600

        return startOfDay.addingTimeInterval(totalSeconds)
    }
}

// MARK: - Extensions

private extension Double {
    var toRadians: Double {
        self * .pi / 180
    }

    var toDegrees: Double {
        self * 180 / .pi
    }
}
