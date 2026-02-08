// MARK: - PrayerTimeMonotonicTests.swift
// PURPOSE: Prove prayer times monotonically increase for all methods and locations
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class PrayerTimeMonotonicTests: XCTestCase {

    private var calculator: PrayerTimeCalculator!

    override func setUp() {
        super.setUp()
        calculator = PrayerTimeCalculator()
    }

    override func tearDown() {
        calculator = nil
        super.tearDown()
    }

    // MARK: - Monotonic Ordering Tests

    /// Prayer times must always be in order: Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha
    private func assertMonotonicOrdering(_ prayers: [PrayerTime], method: CalculationMethod, location: String, file: StaticString = #file, line: UInt = #line) {
        guard prayers.count == 6 else {
            XCTFail("Expected 6 prayer times, got \(prayers.count) for \(method.rawValue) at \(location)", file: file, line: line)
            return
        }

        let expectedOrder: [PrayerType] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]
        for (i, prayer) in prayers.enumerated() {
            XCTAssertEqual(prayer.type, expectedOrder[i], "Prayer \(i) should be \(expectedOrder[i]) for \(method.rawValue) at \(location)", file: file, line: line)
        }

        for i in 1..<prayers.count {
            XCTAssertGreaterThan(
                prayers[i].time, prayers[i - 1].time,
                "\(prayers[i].type.displayName) (\(prayers[i].timeString)) must be after \(prayers[i - 1].type.displayName) (\(prayers[i - 1].timeString)) for \(method.rawValue) at \(location)",
                file: file, line: line
            )
        }
    }

    // MARK: - All Methods × London (Default Location)

    func test_monotonic_london_allMethods() {
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let date = Date()

        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: date, location: london, method: method)
            assertMonotonicOrdering(prayers, method: method, location: "London")
        }
    }

    // MARK: - All Methods × Key Cities

    func test_monotonic_makkah() {
        let makkah = Coordinates(latitude: 21.4225, longitude: 39.8262)
        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: Date(), location: makkah, method: method)
            assertMonotonicOrdering(prayers, method: method, location: "Makkah")
        }
    }

    func test_monotonic_newYork() {
        let nyc = Coordinates(latitude: 40.7128, longitude: -74.0060)
        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: Date(), location: nyc, method: method)
            assertMonotonicOrdering(prayers, method: method, location: "New York")
        }
    }

    func test_monotonic_karachi() {
        let karachi = Coordinates(latitude: 24.8607, longitude: 67.0011)
        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: Date(), location: karachi, method: method)
            assertMonotonicOrdering(prayers, method: method, location: "Karachi")
        }
    }

    func test_monotonic_jakarta() {
        let jakarta = Coordinates(latitude: -6.2088, longitude: 106.8456)
        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: Date(), location: jakarta, method: method)
            assertMonotonicOrdering(prayers, method: method, location: "Jakarta")
        }
    }

    func test_monotonic_istanbul() {
        let istanbul = Coordinates(latitude: 41.0082, longitude: 28.9784)
        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: Date(), location: istanbul, method: method)
            assertMonotonicOrdering(prayers, method: method, location: "Istanbul")
        }
    }

    func test_monotonic_cairo() {
        let cairo = Coordinates(latitude: 30.0444, longitude: 31.2357)
        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: Date(), location: cairo, method: method)
            assertMonotonicOrdering(prayers, method: method, location: "Cairo")
        }
    }

    // MARK: - High Latitude Edge Cases

    func test_monotonic_oslo_highLatitude() {
        let oslo = Coordinates(latitude: 59.9139, longitude: 10.7522)
        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: Date(), location: oslo, method: method)
            assertMonotonicOrdering(prayers, method: method, location: "Oslo (60°N)")
        }
    }

    func test_monotonic_helsinki_veryHighLatitude() {
        let helsinki = Coordinates(latitude: 60.1699, longitude: 24.9384)
        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: Date(), location: helsinki, method: method)
            assertMonotonicOrdering(prayers, method: method, location: "Helsinki (60°N)")
        }
    }

    func test_monotonic_stockholm() {
        let stockholm = Coordinates(latitude: 59.3293, longitude: 18.0686)
        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: Date(), location: stockholm, method: method)
            assertMonotonicOrdering(prayers, method: method, location: "Stockholm")
        }
    }

    // MARK: - Southern Hemisphere

    func test_monotonic_sydney() {
        let sydney = Coordinates(latitude: -33.8688, longitude: 151.2093)
        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: Date(), location: sydney, method: method)
            assertMonotonicOrdering(prayers, method: method, location: "Sydney")
        }
    }

    func test_monotonic_capeTown() {
        let capeTown = Coordinates(latitude: -33.9249, longitude: 18.4241)
        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: Date(), location: capeTown, method: method)
            assertMonotonicOrdering(prayers, method: method, location: "Cape Town")
        }
    }

    // MARK: - Seasonal Edge Cases (Summer/Winter Solstice)

    func test_monotonic_london_winterSolstice() {
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let calendar = Calendar.current
        let winterSolstice = calendar.date(from: DateComponents(year: 2025, month: 12, day: 21))!

        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: winterSolstice, location: london, method: method)
            assertMonotonicOrdering(prayers, method: method, location: "London Winter Solstice")
        }
    }

    func test_monotonic_london_summerSolstice() {
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let calendar = Calendar.current
        let summerSolstice = calendar.date(from: DateComponents(year: 2025, month: 6, day: 21))!

        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: summerSolstice, location: london, method: method)
            assertMonotonicOrdering(prayers, method: method, location: "London Summer Solstice")
        }
    }

    // MARK: - Makkah Method Specific (Isha = Maghrib + 90 min)

    func test_makkahMethod_ishaIs90MinAfterMaghrib() {
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let prayers = calculator.calculatePrayerTimes(for: Date(), location: london, method: .makkah)

        guard let maghrib = prayers.first(where: { $0.type == .maghrib }),
              let isha = prayers.first(where: { $0.type == .isha }) else {
            XCTFail("Missing Maghrib or Isha")
            return
        }

        let diff = isha.time.timeIntervalSince(maghrib.time)
        // Should be approximately 90 minutes (5400 seconds), allow ±60s tolerance
        XCTAssertGreaterThanOrEqual(diff, 5340, "Isha should be ~90 min after Maghrib (got \(diff/60) min)")
        XCTAssertLessThanOrEqual(diff, 5460, "Isha should be ~90 min after Maghrib (got \(diff/60) min)")
    }

    // MARK: - Return Count

    func test_calculatePrayerTimes_returns6Prayers() {
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let prayers = calculator.calculatePrayerTimes(for: Date(), location: london, method: .isna)
        XCTAssertEqual(prayers.count, 6)
    }

    func test_calculatePrayerTimes_correctTypes() {
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let prayers = calculator.calculatePrayerTimes(for: Date(), location: london, method: .isna)
        let types = prayers.map { $0.type }
        XCTAssertEqual(types, [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha])
    }

    // MARK: - Absolute Time Sanity (London MWL — the reported bug)

    func test_london_MWL_absoluteTimeSanity() {
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let calendar = Calendar.current
        let feb7 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 7))!

        let prayers = calculator.calculatePrayerTimes(for: feb7, location: london, method: .muslimWorldLeague)

        guard let fajr = prayers.first(where: { $0.type == .fajr }),
              let sunrise = prayers.first(where: { $0.type == .sunrise }),
              let dhuhr = prayers.first(where: { $0.type == .dhuhr }),
              let maghrib = prayers.first(where: { $0.type == .maghrib }),
              let isha = prayers.first(where: { $0.type == .isha }) else {
            XCTFail("Missing prayer times")
            return
        }

        // Fajr should be between 4:00 and 7:00 AM in London in February
        let fajrHour = calendar.component(.hour, from: fajr.time)
        XCTAssertTrue((4...7).contains(fajrHour), "Fajr hour should be 4-7, got \(fajrHour)")

        // Sunrise should be between 7:00 and 8:30 AM
        let sunriseHour = calendar.component(.hour, from: sunrise.time)
        XCTAssertTrue((7...8).contains(sunriseHour), "Sunrise hour should be 7-8, got \(sunriseHour)")

        // Dhuhr should be between 12:00 and 13:00
        let dhuhrHour = calendar.component(.hour, from: dhuhr.time)
        XCTAssertTrue((12...13).contains(dhuhrHour), "Dhuhr hour should be 12-13, got \(dhuhrHour)")

        // Maghrib should be between 16:30 and 17:30 in February
        let maghribHour = calendar.component(.hour, from: maghrib.time)
        XCTAssertTrue((16...17).contains(maghribHour), "Maghrib hour should be 16-17, got \(maghribHour)")

        // Isha must be AFTER Maghrib (the reported bug)
        XCTAssertGreaterThan(isha.time, maghrib.time,
            "Isha (\(isha.timeString)) must be after Maghrib (\(maghrib.timeString))")

        // Isha should be between 18:00 and 20:00 in London in February
        let ishaHour = calendar.component(.hour, from: isha.time)
        XCTAssertTrue((18...20).contains(ishaHour), "Isha hour should be 18-20, got \(ishaHour)")
    }

    // MARK: - All Methods for London Feb (Regression for Reported Bug)

    func test_london_february_allMethods_ishaAfterMaghrib() {
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let calendar = Calendar.current
        let feb7 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 7))!

        for method in CalculationMethod.allCases {
            let prayers = calculator.calculatePrayerTimes(for: feb7, location: london, method: method)
            guard let maghrib = prayers.first(where: { $0.type == .maghrib }),
                  let isha = prayers.first(where: { $0.type == .isha }) else {
                XCTFail("Missing prayer times for \(method.rawValue)")
                continue
            }
            XCTAssertGreaterThan(isha.time, maghrib.time,
                "\(method.rawValue): Isha (\(isha.timeString)) must be after Maghrib (\(maghrib.timeString))")
        }
    }

    // MARK: - Fajr Must Be Before Sunrise

    func test_fajr_beforeSunrise_allMethodsAllCities() {
        let cities: [(String, Coordinates)] = [
            ("London", Coordinates(latitude: 51.5074, longitude: -0.1278)),
            ("Oslo", Coordinates(latitude: 59.9139, longitude: 10.7522)),
            ("Helsinki", Coordinates(latitude: 60.1699, longitude: 24.9384)),
            ("Makkah", Coordinates(latitude: 21.4225, longitude: 39.8262)),
        ]

        for (name, coords) in cities {
            for method in CalculationMethod.allCases {
                let prayers = calculator.calculatePrayerTimes(for: Date(), location: coords, method: method)
                guard let fajr = prayers.first(where: { $0.type == .fajr }),
                      let sunrise = prayers.first(where: { $0.type == .sunrise }) else {
                    XCTFail("Missing Fajr/Sunrise for \(method.rawValue) at \(name)")
                    continue
                }
                XCTAssertLessThan(fajr.time, sunrise.time,
                    "\(method.rawValue) at \(name): Fajr (\(fajr.timeString)) must be before Sunrise (\(sunrise.timeString))")
            }
        }
    }

    // MARK: - Dhuhr Near Solar Noon

    func test_dhuhr_nearSolarNoon() {
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let prayers = calculator.calculatePrayerTimes(for: Date(), location: london, method: .isna)
        guard let dhuhr = prayers.first(where: { $0.type == .dhuhr }) else {
            XCTFail("Missing Dhuhr")
            return
        }

        let hour = Calendar.current.component(.hour, from: dhuhr.time)
        // Dhuhr (solar noon) should always be between 11:30 and 13:30
        XCTAssertTrue((11...13).contains(hour), "Dhuhr should be near solar noon, got hour \(hour)")
    }

    // MARK: - All Days in a Month (Regression Sweep)

    func test_monotonic_london_MWL_everyDayInFebruary() {
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let calendar = Calendar.current

        for day in 1...28 {
            let date = calendar.date(from: DateComponents(year: 2026, month: 2, day: day))!
            let prayers = calculator.calculatePrayerTimes(for: date, location: london, method: .muslimWorldLeague)
            assertMonotonicOrdering(prayers, method: .muslimWorldLeague, location: "London Feb \(day)")
        }
    }
}
