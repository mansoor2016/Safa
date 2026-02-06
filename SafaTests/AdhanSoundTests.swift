// MARK: - AdhanSoundTests.swift
// PURPOSE: Unit tests for AdhanSound enum logic
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class AdhanSoundTests: XCTestCase {

    // MARK: - Display Name Tests

    func test_allCases_haveDisplayNames() {
        for sound in AdhanSound.allCases {
            XCTAssertFalse(sound.displayName.isEmpty, "\(sound.rawValue) should have a display name")
        }
    }

    func test_allCases_haveSubtitles() {
        for sound in AdhanSound.allCases {
            XCTAssertFalse(sound.subtitle.isEmpty, "\(sound.rawValue) should have a subtitle")
        }
    }

    func test_defaultSound_displayName() {
        XCTAssertEqual(AdhanSound.defaultSound.displayName, "System Default")
    }

    func test_misharyAlafasy_displayName() {
        XCTAssertEqual(AdhanSound.misharyAlafasy.displayName, "Mishary Rashid Alafasy")
    }

    // MARK: - Fajr Specific Tests

    func test_onlyMisharyFajr_isFajrSpecific() {
        let fajrSounds = AdhanSound.allCases.filter { $0.isFajrSpecific }
        XCTAssertEqual(fajrSounds.count, 1)
        XCTAssertEqual(fajrSounds.first, .misharyAlafasyFajr)
    }

    func test_regularSounds_areNotFajrSpecific() {
        for sound in AdhanSound.allCases where sound != .misharyAlafasyFajr {
            XCTAssertFalse(sound.isFajrSpecific, "\(sound.rawValue) should not be Fajr-specific")
        }
    }

    // MARK: - Regular Options Tests

    func test_regularOptions_excludesFajrSpecific() {
        let regular = AdhanSound.regularOptions
        XCTAssertFalse(regular.contains(.misharyAlafasyFajr))
    }

    func test_regularOptions_excludesDefault() {
        let regular = AdhanSound.regularOptions
        XCTAssertFalse(regular.contains(.defaultSound))
    }

    func test_regularOptions_containsAllOtherSounds() {
        let regular = AdhanSound.regularOptions
        XCTAssertEqual(regular.count, AdhanSound.allCases.count - 2) // minus default and fajr
        XCTAssertTrue(regular.contains(.misharyAlafasy))
        XCTAssertTrue(regular.contains(.abdulbasitAbdusamad))
        XCTAssertTrue(regular.contains(.muhammadRamadanSaadMakkah))
    }

    // MARK: - Raw Value Round Trip Tests

    func test_allCases_roundTripViaRawValue() {
        for sound in AdhanSound.allCases {
            let reconstructed = AdhanSound(rawValue: sound.rawValue)
            XCTAssertEqual(reconstructed, sound, "\(sound.rawValue) should round-trip via rawValue")
        }
    }

    func test_invalidRawValue_returnsNil() {
        XCTAssertNil(AdhanSound(rawValue: "nonexistent_file"))
    }

    // MARK: - Identifiable Tests

    func test_id_matchesRawValue() {
        for sound in AdhanSound.allCases {
            XCTAssertEqual(sound.id, sound.rawValue)
        }
    }

    // MARK: - Codable Tests

    func test_encodeDecode_roundTrip() throws {
        for sound in AdhanSound.allCases {
            let data = try JSONEncoder().encode(sound)
            let decoded = try JSONDecoder().decode(AdhanSound.self, from: data)
            XCTAssertEqual(decoded, sound)
        }
    }
}
