// MARK: - LocationInferenceServiceTests.swift
// PURPOSE: Unit tests for LocationInferenceService

import XCTest
import CoreLocation
@testable import Safa

final class LocationInferenceServiceTests: XCTestCase {

    var sut: LocationInferenceService!

    override func setUp() {
        super.setUp()
        sut = LocationInferenceService.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - LocationContext Tests

    func testLocationContextFallback() {
        let fallback = LocationContext.fallback

        XCTAssertEqual(fallback.recommendedMethod, AppDefaults.calculationMethod)
        XCTAssertEqual(fallback.recommendedMadhab, AppDefaults.madhab)
        XCTAssertEqual(fallback.recommendedLanguage, AppDefaults.translationLanguage)
        XCTAssertEqual(fallback.regionName, "Unknown Location")
        // Mecca coordinates
        XCTAssertEqual(fallback.coordinates.latitude, 21.4225, accuracy: 0.001)
        XCTAssertEqual(fallback.coordinates.longitude, 39.8262, accuracy: 0.001)
    }

    func testLocationContextCodable() throws {
        let original = LocationContext(
            coordinates: Coordinates(latitude: 40.7128, longitude: -74.0060),
            city: "New York",
            country: "United States",
            countryCode: "US",
            timezone: TimeZone(identifier: "America/New_York"),
            recommendedMethod: .isna,
            recommendedMadhab: .hanafi,
            recommendedLanguage: "English",
            regionName: "New York, United States"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LocationContext.self, from: data)

        XCTAssertEqual(decoded.city, original.city)
        XCTAssertEqual(decoded.country, original.country)
        XCTAssertEqual(decoded.recommendedMethod, original.recommendedMethod)
        XCTAssertEqual(decoded.recommendedMadhab, original.recommendedMadhab)
    }

    // MARK: - Fast Inference Tests (Coordinate-based)

    func testInferContextFastForNewYork() {
        // New York coordinates
        let coordinates = Coordinates(latitude: 40.7128, longitude: -74.0060)
        let context = sut.inferContextFast(from: coordinates)

        // North America should get ISNA
        XCTAssertEqual(context.recommendedMethod, .isna)
        XCTAssertEqual(context.coordinates.latitude, 40.7128, accuracy: 0.001)
    }

    func testInferContextFastForLondon() {
        // London coordinates
        let coordinates = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let context = sut.inferContextFast(from: coordinates)

        // Europe should get MWL
        XCTAssertEqual(context.recommendedMethod, .muslimWorldLeague)
    }

    func testInferContextFastForMakkah() {
        // Makkah coordinates
        let coordinates = Coordinates(latitude: 21.4225, longitude: 39.8262)
        let context = sut.inferContextFast(from: coordinates)

        // Middle East should get Makkah method
        XCTAssertEqual(context.recommendedMethod, .makkah)
    }

    func testInferContextFastForKarachi() {
        // Karachi coordinates
        let coordinates = Coordinates(latitude: 24.8607, longitude: 67.0011)
        let context = sut.inferContextFast(from: coordinates)

        // South Asia should get Karachi method
        XCTAssertEqual(context.recommendedMethod, .karachi)
    }

    func testInferContextFastForJakarta() {
        // Jakarta coordinates
        let coordinates = Coordinates(latitude: -6.2088, longitude: 106.8456)
        let context = sut.inferContextFast(from: coordinates)

        // Southeast Asia should get MWL
        XCTAssertEqual(context.recommendedMethod, .muslimWorldLeague)
    }

    func testInferContextFastForCairo() {
        // Cairo coordinates
        let coordinates = Coordinates(latitude: 30.0444, longitude: 31.2357)
        let context = sut.inferContextFast(from: coordinates)

        // Africa should get Egypt method
        XCTAssertEqual(context.recommendedMethod, .egypt)
    }

    // MARK: - Country Code Inference Tests

    func testUSAGetsISNA() {
        // US coordinates
        let coordinates = Coordinates(latitude: 40.7128, longitude: -74.0060)
        let context = sut.inferContextFast(from: coordinates)

        // Without country code, relies on coordinates
        XCTAssertEqual(context.recommendedMethod, .isna)
    }

    func testCanadaGetsISNA() {
        // Toronto coordinates
        let coordinates = Coordinates(latitude: 43.6532, longitude: -79.3832)
        let context = sut.inferContextFast(from: coordinates)

        XCTAssertEqual(context.recommendedMethod, .isna)
    }

    // MARK: - Madhab Inference Tests

    func testDefaultMadhabIsHanafi() {
        // Most of the world defaults to Hanafi
        let coordinates = Coordinates(latitude: 40.7128, longitude: -74.0060)
        let context = sut.inferContextFast(from: coordinates)

        // Hanafi is the default
        XCTAssertEqual(context.recommendedMadhab, .hanafi)
    }

    // MARK: - Language Inference Tests

    func testDefaultLanguageIsEnglish() {
        // Default without country code should be English
        let coordinates = Coordinates(latitude: 0, longitude: 0)
        let context = sut.inferContextFast(from: coordinates)

        XCTAssertEqual(context.recommendedLanguage, "English")
    }

    // MARK: - High Latitude Tests

    func testHighLatitudeDetectionNorth() {
        // Stockholm, Sweden (high latitude)
        let coordinates = Coordinates(latitude: 59.3293, longitude: 18.0686)

        XCTAssertTrue(sut.isHighLatitude(coordinates))
    }

    func testHighLatitudeDetectionSouth() {
        // Southern Argentina (high latitude)
        let coordinates = Coordinates(latitude: -52.0, longitude: -68.0)

        XCTAssertTrue(sut.isHighLatitude(coordinates))
    }

    func testNotHighLatitude() {
        // Makkah (not high latitude)
        let coordinates = Coordinates(latitude: 21.4225, longitude: 39.8262)

        XCTAssertFalse(sut.isHighLatitude(coordinates))
    }

    func testEquatorNotHighLatitude() {
        // Equator
        let coordinates = Coordinates(latitude: 0.0, longitude: 0.0)

        XCTAssertFalse(sut.isHighLatitude(coordinates))
    }

    // MARK: - Region Name Tests

    func testRegionNameWithCityAndCountry() {
        let context = LocationContext(
            coordinates: Coordinates(latitude: 40.7128, longitude: -74.0060),
            city: "New York",
            country: "United States",
            countryCode: "US",
            timezone: nil,
            recommendedMethod: .isna,
            recommendedMadhab: .hanafi,
            recommendedLanguage: "English",
            regionName: "New York, United States"
        )

        XCTAssertEqual(context.regionName, "New York, United States")
    }

    func testRegionNameWithCountryOnly() {
        let context = LocationContext(
            coordinates: Coordinates(latitude: 21.4225, longitude: 39.8262),
            city: nil,
            country: "Saudi Arabia",
            countryCode: "SA",
            timezone: nil,
            recommendedMethod: .makkah,
            recommendedMadhab: .hanafi,
            recommendedLanguage: "Arabic",
            regionName: "Saudi Arabia"
        )

        XCTAssertEqual(context.regionName, "Saudi Arabia")
    }

    // MARK: - Fast Context Region Name Tests

    func testFastContext_regionName_isNotGeneric() {
        // inferContextFast should never return "Your Location" — it should
        // at least show "Unknown Location" or a coordinate-based description
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let context = sut.inferContextFast(from: london)

        XCTAssertNotEqual(context.regionName, "Your Location",
                          "Fast context should not use generic 'Your Location' as region name")
    }

    func testFastContext_hasNilCityAndCountry() {
        // Without geocoding, city and country are nil
        let coords = Coordinates(latitude: 40.7128, longitude: -74.0060)
        let context = sut.inferContextFast(from: coords)

        XCTAssertNil(context.city, "Fast context has no reverse geocoding, city should be nil")
        XCTAssertNil(context.country, "Fast context has no reverse geocoding, country should be nil")
    }

    func testFastContext_stillInfersMethod() {
        // Even without geocoding, method should be inferred from coordinates
        let newYork = Coordinates(latitude: 40.7128, longitude: -74.0060)
        let context = sut.inferContextFast(from: newYork)

        XCTAssertEqual(context.recommendedMethod, .isna,
                       "US coordinates should infer ISNA method")
    }

    func testInferContext_returnsRealRegionName() async {
        // Full inferContext with CLGeocoder should return a real city/country
        let london = CLLocation(latitude: 51.5074, longitude: -0.1278)
        let context = await sut.inferContext(from: london)

        // CLGeocoder should resolve to something containing "London" or "United Kingdom"
        XCTAssertNotEqual(context.regionName, "Your Location",
                          "Full inference should return a real region name")
        XCTAssertNotEqual(context.regionName, "Unknown Location",
                          "Full inference for London should resolve to a real name")
        XCTAssertFalse(context.regionName.isEmpty,
                       "Region name should not be empty")
    }

    func testInferContext_populatesCityOrCountry() async {
        let makkah = CLLocation(latitude: 21.4225, longitude: 39.8262)
        let context = await sut.inferContext(from: makkah)

        // At least one of city or country should be populated by geocoder
        let hasLocation = context.city != nil || context.country != nil
        XCTAssertTrue(hasLocation,
                      "Geocoded context should have city or country populated")
    }

    // MARK: - New Method Mapping Tests (via geocoding)

    func testDubaiGetsDubaiMethod() async {
        let dubai = CLLocation(latitude: 25.2048, longitude: 55.2708)
        let context = await sut.inferContext(from: dubai)

        XCTAssertEqual(context.recommendedMethod, .dubai,
                       "UAE should use Dubai (GIAE) method, got \(context.recommendedMethod)")
    }

    func testKuwaitGetsKuwaitMethod() async {
        let kuwait = CLLocation(latitude: 29.3759, longitude: 47.9774)
        let context = await sut.inferContext(from: kuwait)

        XCTAssertEqual(context.recommendedMethod, .kuwait,
                       "Kuwait should use Kuwait method, got \(context.recommendedMethod)")
    }

    func testQatarGetsQatarMethod() async {
        let doha = CLLocation(latitude: 25.2854, longitude: 51.5310)
        let context = await sut.inferContext(from: doha)

        XCTAssertEqual(context.recommendedMethod, .qatar,
                       "Qatar should use Qatar method, got \(context.recommendedMethod)")
    }

    func testSingaporeGetsSingaporeMethod() async {
        let singapore = CLLocation(latitude: 1.3521, longitude: 103.8198)
        let context = await sut.inferContext(from: singapore)

        XCTAssertEqual(context.recommendedMethod, .singapore,
                       "Singapore should use MUIS method, got \(context.recommendedMethod)")
    }

    func testIstanbulGetsTurkeyMethod() async {
        let istanbul = CLLocation(latitude: 41.0082, longitude: 28.9784)
        let context = await sut.inferContext(from: istanbul)

        XCTAssertEqual(context.recommendedMethod, .turkey,
                       "Turkey should use Diyanet method, got \(context.recommendedMethod)")
    }

    // MARK: - Fallback Bounding Box Tests (inferContextFast)

    // These test the coordinate-only path (no geocoding) to verify
    // that smaller country boxes are matched before larger overlapping ones.

    func testFallback_dubaiCoordinates_getsDubaiMethod() {
        let coords = Coordinates(latitude: 25.2048, longitude: 55.2708)
        let context = sut.inferContextFast(from: coords)
        XCTAssertEqual(context.recommendedMethod, .dubai,
                       "UAE fallback should use Dubai method, got \(context.recommendedMethod)")
    }

    func testFallback_kuwaitCoordinates_getsKuwaitMethod() {
        let coords = Coordinates(latitude: 29.3759, longitude: 47.9774)
        let context = sut.inferContextFast(from: coords)
        XCTAssertEqual(context.recommendedMethod, .kuwait,
                       "Kuwait fallback should use Kuwait method, got \(context.recommendedMethod)")
    }

    func testFallback_dohaCoordinates_getsQatarMethod() {
        let coords = Coordinates(latitude: 25.2854, longitude: 51.5310)
        let context = sut.inferContextFast(from: coords)
        XCTAssertEqual(context.recommendedMethod, .qatar,
                       "Qatar fallback should use Qatar method, got \(context.recommendedMethod)")
    }

    func testFallback_singaporeCoordinates_getsSingaporeMethod() {
        let coords = Coordinates(latitude: 1.3521, longitude: 103.8198)
        let context = sut.inferContextFast(from: coords)
        XCTAssertEqual(context.recommendedMethod, .singapore,
                       "Singapore fallback should use Singapore method, got \(context.recommendedMethod)")
    }

    func testFallback_abuDhabi_getsDubaiMethod() {
        // Abu Dhabi is also in UAE — verify the box covers it
        let coords = Coordinates(latitude: 24.4539, longitude: 54.3773)
        let context = sut.inferContextFast(from: coords)
        XCTAssertEqual(context.recommendedMethod, .dubai,
                       "Abu Dhabi fallback should use Dubai method, got \(context.recommendedMethod)")
    }

    func testFallback_riyadh_getsMakkahMethod() {
        // Saudi Arabia should still work after UAE/KW/QA boxes are checked first
        let coords = Coordinates(latitude: 24.7136, longitude: 46.6753)
        let context = sut.inferContextFast(from: coords)
        XCTAssertEqual(context.recommendedMethod, .makkah,
                       "Saudi fallback should use Makkah method, got \(context.recommendedMethod)")
    }

    func testFallback_jakarta_usesCorrectMethod() {
        // Indonesia should still work after Singapore/Malaysia boxes
        let coords = Coordinates(latitude: -6.2088, longitude: 106.8456)
        let context = sut.inferContextFast(from: coords)
        // Indonesia uses MWL
        XCTAssertEqual(context.recommendedMethod, .muslimWorldLeague,
                       "Indonesia fallback should use MWL method, got \(context.recommendedMethod)")
    }

    func testFallback_kualaLumpur_getsSingaporeMethod() {
        // Malaysia maps to Singapore/MUIS method and should match before Indonesia
        let coords = Coordinates(latitude: 3.1390, longitude: 101.6869)
        let context = sut.inferContextFast(from: coords)
        XCTAssertEqual(context.recommendedMethod, .singapore,
                       "Malaysia fallback should use Singapore/MUIS method, got \(context.recommendedMethod)")
    }

    // MARK: - Coordinates Tests

    func testCoordinatesEquality() {
        let coord1 = Coordinates(latitude: 40.7128, longitude: -74.0060)
        let coord2 = Coordinates(latitude: 40.7128, longitude: -74.0060)

        XCTAssertEqual(coord1, coord2)
    }

    func testCoordinatesCodable() throws {
        let original = Coordinates(latitude: 51.5074, longitude: -0.1278)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Coordinates.self, from: data)

        XCTAssertEqual(decoded.latitude, original.latitude, accuracy: 0.0001)
        XCTAssertEqual(decoded.longitude, original.longitude, accuracy: 0.0001)
    }
}
