// MARK: - SpotlightIndexTests.swift
// PURPOSE: Tests for SpotlightIndexService identifier parsing and destination mapping
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class SpotlightIndexTests: XCTestCase {

    // MARK: - Identifier Parsing Tests

    func testParseSurahIdentifier() {
        let identifier = "surah_1"
        let destination = SpotlightIndexService.parseIdentifier(identifier)

        XCTAssertNotNil(destination)
        if case .surah(let number) = destination {
            XCTAssertEqual(number, 1)
        } else {
            XCTFail("Expected surah destination")
        }
    }

    func testParseSurahIdentifierWithLargeNumber() {
        let identifier = "surah_114"
        let destination = SpotlightIndexService.parseIdentifier(identifier)

        XCTAssertNotNil(destination)
        if case .surah(let number) = destination {
            XCTAssertEqual(number, 114)
        } else {
            XCTFail("Expected surah destination")
        }
    }

    func testParseAyahIdentifier() {
        let identifier = "ayah_2_255"
        let destination = SpotlightIndexService.parseIdentifier(identifier)

        XCTAssertNotNil(destination)
        if case .ayah(let surah, let ayah) = destination {
            XCTAssertEqual(surah, 2)
            XCTAssertEqual(ayah, 255)
        } else {
            XCTFail("Expected ayah destination")
        }
    }

    func testParseHadithIdentifier() {
        let identifier = "hadith_bukhari_1"
        let destination = SpotlightIndexService.parseIdentifier(identifier)

        XCTAssertNotNil(destination)
        if case .hadith(let collection, let id) = destination {
            XCTAssertEqual(collection, "bukhari")
            XCTAssertEqual(id, "1")
        } else {
            XCTFail("Expected hadith destination")
        }
    }

    func testParseHadithCollectionIdentifier() {
        let identifier = "hadith_muslim"
        let destination = SpotlightIndexService.parseIdentifier(identifier)

        XCTAssertNotNil(destination)
        if case .hadith(let collection, let id) = destination {
            XCTAssertEqual(collection, "muslim")
            XCTAssertNil(id)
        } else {
            XCTFail("Expected hadith destination")
        }
    }

    func testParseDuaIdentifier() {
        let identifier = "dua_before_eating"
        let destination = SpotlightIndexService.parseIdentifier(identifier)

        XCTAssertNotNil(destination)
        if case .dua(let id) = destination {
            XCTAssertEqual(id, "before_eating")
        } else {
            XCTFail("Expected dua destination")
        }
    }

    func testParseNameIdentifier() {
        let identifier = "name_1"
        let destination = SpotlightIndexService.parseIdentifier(identifier)

        XCTAssertNotNil(destination)
        if case .nameOfAllah(let number) = destination {
            XCTAssertEqual(number, 1)
        } else {
            XCTFail("Expected name of Allah destination")
        }
    }

    func testParseInvalidIdentifier() {
        let identifier = "invalid"
        let destination = SpotlightIndexService.parseIdentifier(identifier)

        XCTAssertNil(destination)
    }

    func testParseEmptyIdentifier() {
        let identifier = ""
        let destination = SpotlightIndexService.parseIdentifier(identifier)

        XCTAssertNil(destination)
    }

    func testParseUnknownTypeIdentifier() {
        let identifier = "unknown_123"
        let destination = SpotlightIndexService.parseIdentifier(identifier)

        XCTAssertNil(destination)
    }

    // MARK: - SpotlightContentType Tests

    func testSpotlightContentTypeDomainIdentifiers() {
        XCTAssertEqual(SpotlightContentType.surah.domainIdentifier, "com.safa.surah")
        XCTAssertEqual(SpotlightContentType.ayah.domainIdentifier, "com.safa.ayah")
        XCTAssertEqual(SpotlightContentType.hadith.domainIdentifier, "com.safa.hadith")
        XCTAssertEqual(SpotlightContentType.dua.domainIdentifier, "com.safa.dua")
        XCTAssertEqual(SpotlightContentType.namesOfAllah.domainIdentifier, "com.safa.names_of_allah")
    }

    func testSpotlightContentTypeActivityTypes() {
        XCTAssertEqual(SpotlightContentType.surah.activityType, "com.safa.activity.surah")
        XCTAssertEqual(SpotlightContentType.ayah.activityType, "com.safa.activity.ayah")
        XCTAssertEqual(SpotlightContentType.hadith.activityType, "com.safa.activity.hadith")
        XCTAssertEqual(SpotlightContentType.dua.activityType, "com.safa.activity.dua")
    }

    // MARK: - SpotlightDestination Tests

    func testSpotlightDestinationHashable() {
        let dest1 = SpotlightDestination.surah(number: 1)
        let dest2 = SpotlightDestination.surah(number: 1)
        let dest3 = SpotlightDestination.surah(number: 2)

        XCTAssertEqual(dest1, dest2)
        XCTAssertNotEqual(dest1, dest3)
    }

    func testSpotlightDestinationAyahEquality() {
        let dest1 = SpotlightDestination.ayah(surah: 2, ayah: 255)
        let dest2 = SpotlightDestination.ayah(surah: 2, ayah: 255)
        let dest3 = SpotlightDestination.ayah(surah: 2, ayah: 256)

        XCTAssertEqual(dest1, dest2)
        XCTAssertNotEqual(dest1, dest3)
    }

    func testSpotlightDestinationHadithEquality() {
        let dest1 = SpotlightDestination.hadith(collection: "bukhari", id: "1")
        let dest2 = SpotlightDestination.hadith(collection: "bukhari", id: "1")
        let dest3 = SpotlightDestination.hadith(collection: "muslim", id: "1")

        XCTAssertEqual(dest1, dest2)
        XCTAssertNotEqual(dest1, dest3)
    }
}
