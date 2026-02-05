// MARK: - LocationInferenceService.swift
// PURPOSE: Infer user preferences based on geographic location
// DEPENDENCIES: CoreLocation, Foundation

import Foundation
import CoreLocation

// MARK: - Location Context

/// Holds inferred and resolved location data
struct LocationContext: Codable, Hashable {
    let coordinates: Coordinates
    let city: String?
    let country: String?
    let countryCode: String?
    let timezone: TimeZone?
    let recommendedMethod: CalculationMethod
    let recommendedMadhab: Madhab
    let recommendedLanguage: String
    let regionName: String // Human-readable location name

    /// Fallback context when location is unavailable
    static let fallback = LocationContext(
        coordinates: Coordinates(latitude: 21.4225, longitude: 39.8262), // Mecca
        city: nil,
        country: nil,
        countryCode: nil,
        timezone: nil,
        recommendedMethod: AppDefaults.calculationMethod,
        recommendedMadhab: AppDefaults.madhab,
        recommendedLanguage: AppDefaults.translationLanguage,
        regionName: "Unknown Location"
    )
}

// MARK: - Location Inference Service

final class LocationInferenceService {

    // MARK: - Singleton
    static let shared = LocationInferenceService()

    private let geocoder = CLGeocoder()

    private init() {}

    // MARK: - Public Methods

    /// Infer location context from coordinates with reverse geocoding
    func inferContext(from location: CLLocation) async -> LocationContext {
        // Try reverse geocoding first
        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        let placemark = placemarks?.first

        let countryCode = placemark?.isoCountryCode?.uppercased()
        let country = placemark?.country
        let city = placemark?.locality ?? placemark?.administrativeArea

        let coordinates = Coordinates(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        // Infer recommendations based on country
        let method = inferCalculationMethod(countryCode: countryCode, coordinates: coordinates)
        let madhab = inferMadhab(countryCode: countryCode)
        let language = inferLanguage(countryCode: countryCode)

        // Build region name
        let regionName = buildRegionName(city: city, country: country)

        return LocationContext(
            coordinates: coordinates,
            city: city,
            country: country,
            countryCode: countryCode,
            timezone: placemark?.timeZone,
            recommendedMethod: method,
            recommendedMadhab: madhab,
            recommendedLanguage: language,
            regionName: regionName
        )
    }

    /// Quick inference without geocoding (uses coordinate-based heuristics)
    func inferContextFast(from coordinates: Coordinates) -> LocationContext {
        let countryCode = inferCountryFromCoordinates(coordinates)

        let method = inferCalculationMethod(countryCode: countryCode, coordinates: coordinates)
        let madhab = inferMadhab(countryCode: countryCode)
        let language = inferLanguage(countryCode: countryCode)

        return LocationContext(
            coordinates: coordinates,
            city: nil,
            country: nil,
            countryCode: countryCode,
            timezone: nil,
            recommendedMethod: method,
            recommendedMadhab: madhab,
            recommendedLanguage: language,
            regionName: "Your Location"
        )
    }

    // MARK: - Calculation Method Inference

    private func inferCalculationMethod(countryCode: String?, coordinates: Coordinates) -> CalculationMethod {
        guard let code = countryCode else {
            return inferMethodFromCoordinates(coordinates)
        }

        // Middle East & North Africa
        let mwlCountries: Set<String> = ["GB", "IE", "FR", "DE", "IT", "ES", "PT", "NL", "BE", "CH", "AT",
                                          "SE", "NO", "DK", "FI", "PL", "CZ", "HU", "RO", "BG", "GR",
                                          "AU", "NZ", "ZA", "BR", "AR", "MX", "CL", "CO", "PE"]

        let isnaCountries: Set<String> = ["US", "CA"]

        let egyptCountries: Set<String> = ["EG", "LY", "SD"]

        let makkahCountries: Set<String> = ["SA", "QA", "BH", "KW", "AE", "OM", "YE"]

        let karachiCountries: Set<String> = ["PK", "BD", "AF", "IN", "NP", "LK"]

        let tehranCountries: Set<String> = ["IR"]

        // Southeast Asia - typically uses MWL or Shafi'i-based
        let seAsiaCountries: Set<String> = ["MY", "ID", "SG", "BN", "TH", "PH"]

        // Turkey uses Diyanet (similar to MWL with adjustments)
        let turkeyCountries: Set<String> = ["TR", "AZ", "TM", "UZ", "KZ", "KG", "TJ"]

        // North/West Africa
        let nwAfricaCountries: Set<String> = ["MA", "DZ", "TN", "MR", "SN", "ML", "NE", "NG"]

        // Iraq, Syria, Jordan, Lebanon, Palestine
        let levantCountries: Set<String> = ["IQ", "SY", "JO", "LB", "PS", "IL"]

        switch code {
        case _ where isnaCountries.contains(code):
            return .isna
        case _ where makkahCountries.contains(code):
            return .makkah
        case _ where egyptCountries.contains(code):
            return .egypt
        case _ where karachiCountries.contains(code):
            return .karachi
        case _ where tehranCountries.contains(code):
            return .tehran
        case _ where turkeyCountries.contains(code):
            return .muslimWorldLeague // Turkey/Central Asia - MWL is closest
        case _ where seAsiaCountries.contains(code):
            return .muslimWorldLeague // Southeast Asia typically uses MWL
        case _ where nwAfricaCountries.contains(code):
            return .muslimWorldLeague // North/West Africa - MWL
        case _ where levantCountries.contains(code):
            return .muslimWorldLeague // Levant region
        case _ where mwlCountries.contains(code):
            return .muslimWorldLeague
        default:
            return inferMethodFromCoordinates(coordinates)
        }
    }

    private func inferMethodFromCoordinates(_ coordinates: Coordinates) -> CalculationMethod {
        let lat = coordinates.latitude
        let lng = coordinates.longitude

        // Rough geographic inference when country code unavailable

        // North America
        if lat > 25 && lat < 72 && lng > -170 && lng < -50 {
            return .isna
        }

        // Europe
        if lat > 35 && lat < 72 && lng > -10 && lng < 40 {
            return .muslimWorldLeague
        }

        // Middle East (Arabian Peninsula)
        if lat > 12 && lat < 32 && lng > 35 && lng < 60 {
            return .makkah
        }

        // South Asia
        if lat > 5 && lat < 40 && lng > 60 && lng < 100 {
            return .karachi
        }

        // Southeast Asia & Australia
        if lat > -50 && lat < 25 && lng > 90 && lng < 180 {
            return .muslimWorldLeague
        }

        // Africa
        if lat > -35 && lat < 35 && lng > -20 && lng < 55 {
            return .egypt
        }

        // Default fallback
        return .muslimWorldLeague
    }

    // MARK: - Madhab Inference

    private func inferMadhab(countryCode: String?) -> Madhab {
        guard let code = countryCode else {
            return .hanafi // Default to Hanafi (most followed globally ~30%)
        }

        // Shafi'i-majority countries
        let shafiCountries: Set<String> = [
            // Southeast Asia
            "ID", "MY", "SG", "BN", "PH", "TH",
            // East Africa
            "SO", "DJ", "KM", "TZ", "KE",
            // Yemen
            "YE",
            // Parts of Egypt (mixed, but Shafi'i significant)
            // Kurdish regions often Shafi'i
        ]

        // Maliki-majority (we map to Shafi'i for Asr since similar)
        let malikiCountries: Set<String> = [
            // North & West Africa
            "MA", "DZ", "TN", "LY", "MR", "SN", "ML", "NE", "NG", "TD", "SD"
        ]

        // Shafi'i or Maliki regions use later Asr time (similar to Shafi'i)
        if shafiCountries.contains(code) || malikiCountries.contains(code) {
            return .shafi
        }

        // Default to Hanafi (covers: South Asia, Turkey, Central Asia, Levant, Iraq, Balkans, most of the world)
        return .hanafi
    }

    // MARK: - Language Inference

    private func inferLanguage(countryCode: String?) -> String {
        guard let code = countryCode else {
            return "English" // Universal fallback
        }

        // Arabic-speaking countries
        let arabicCountries: Set<String> = [
            "SA", "AE", "QA", "KW", "BH", "OM", "YE", "IQ", "SY", "JO",
            "LB", "PS", "EG", "LY", "SD", "TN", "DZ", "MA", "MR"
        ]

        // Urdu
        let urduCountries: Set<String> = ["PK"]

        // Turkish
        let turkishCountries: Set<String> = ["TR", "AZ"]

        // French (for North/West Africa)
        let frenchCountries: Set<String> = ["FR", "SN", "ML", "NE", "CI", "BF", "GN", "BE", "CH", "CA"]

        // Indonesian/Malay
        let indonesianCountries: Set<String> = ["ID", "MY", "BN", "SG"]

        // Bengali
        let bengaliCountries: Set<String> = ["BD"]

        switch code {
        case _ where arabicCountries.contains(code):
            return "Arabic"
        case _ where urduCountries.contains(code):
            return "Urdu"
        case _ where turkishCountries.contains(code):
            return "Turkish"
        case _ where frenchCountries.contains(code):
            return "French"
        case _ where indonesianCountries.contains(code):
            return "Indonesian"
        case _ where bengaliCountries.contains(code):
            return "Bengali"
        default:
            return "English"
        }
    }

    // MARK: - Country Inference from Coordinates

    private func inferCountryFromCoordinates(_ coordinates: Coordinates) -> String? {
        let lat = coordinates.latitude
        let lng = coordinates.longitude

        // Very rough bounding boxes for major Muslim-majority countries
        // This is a fallback when geocoding fails

        // Saudi Arabia
        if lat > 16 && lat < 33 && lng > 34 && lng < 56 {
            return "SA"
        }

        // Egypt
        if lat > 22 && lat < 32 && lng > 24 && lng < 37 {
            return "EG"
        }

        // Pakistan
        if lat > 23 && lat < 37 && lng > 60 && lng < 78 {
            return "PK"
        }

        // Turkey
        if lat > 36 && lat < 42 && lng > 26 && lng < 45 {
            return "TR"
        }

        // Indonesia
        if lat > -11 && lat < 6 && lng > 95 && lng < 141 {
            return "ID"
        }

        // Malaysia
        if lat > 0 && lat < 8 && lng > 99 && lng < 120 {
            return "MY"
        }

        // Iran
        if lat > 25 && lat < 40 && lng > 44 && lng < 64 {
            return "IR"
        }

        // USA
        if lat > 24 && lat < 50 && lng > -125 && lng < -66 {
            return "US"
        }

        // UK
        if lat > 49 && lat < 61 && lng > -11 && lng < 2 {
            return "GB"
        }

        // Canada
        if lat > 41 && lat < 84 && lng > -141 && lng < -52 {
            return "CA"
        }

        return nil
    }

    // MARK: - Helpers

    private func buildRegionName(city: String?, country: String?) -> String {
        switch (city, country) {
        case let (c?, co?):
            return "\(c), \(co)"
        case let (nil, co?):
            return co
        case let (c?, nil):
            return c
        default:
            return "Your Location"
        }
    }

    // MARK: - High Latitude Detection

    /// Check if location is in extreme latitude zone (>48° or <-48°)
    func isHighLatitude(_ coordinates: Coordinates) -> Bool {
        abs(coordinates.latitude) > 48
    }

    /// Check if location is in polar zone (>65° or <-65°)
    func isPolarLatitude(_ coordinates: Coordinates) -> Bool {
        abs(coordinates.latitude) > 65
    }

    /// Get high latitude warning message if applicable
    func highLatitudeWarning(for coordinates: Coordinates) -> String? {
        if isPolarLatitude(coordinates) {
            return "You're in a polar region where prayer times may be unusual. Some prayers may need to be estimated during midnight sun or polar night periods."
        } else if isHighLatitude(coordinates) {
            return "You're in a high latitude region. Prayer times may vary significantly by season. Consider using the angle-based calculation for Isha and Fajr."
        }
        return nil
    }
}

// MARK: - Coordinates Extension

extension Coordinates {
    init(location: CLLocation) {
        self.init(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }
}
