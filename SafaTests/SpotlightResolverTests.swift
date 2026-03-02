// MARK: - SpotlightResolverTests.swift
// PURPOSE: Unit tests for SpotlightResolver pure identifier → RoutingAction mapping
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class SpotlightResolverTests: XCTestCase {

    // MARK: - Surah

    func test_surah_validNumber_navigatesToSurah() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "surah_2"), .navigate(.surah(number: 2)))
    }

    func test_surah_nonNumeric_returnsNone() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "surah_abc"), .none)
    }

    // MARK: - Ayah

    func test_ayah_validSurahAndAyah_navigatesToAyah() {
        XCTAssertEqual(
            SpotlightResolver.resolve(identifier: "ayah_2_255"),
            .navigate(.ayah(surah: 2, ayah: 255))
        )
    }

    func test_ayah_missingAyahNumber_returnsNone() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "ayah_2"), .none)
    }

    func test_ayah_nonNumericSurah_returnsNone() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "ayah_abc_255"), .none)
    }

    func test_ayah_nonNumericAyah_returnsNone() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "ayah_2_abc"), .none)
    }

    // MARK: - Hadith

    func test_hadith_withCollectionOnly_navigates() {
        XCTAssertEqual(
            SpotlightResolver.resolve(identifier: "hadith_bukhari"),
            .navigate(.hadith(collection: "bukhari", hadithId: nil))
        )
    }

    func test_hadith_withCollectionAndId_navigates() {
        XCTAssertEqual(
            SpotlightResolver.resolve(identifier: "hadith_bukhari_1"),
            .navigate(.hadith(collection: "bukhari", hadithId: "1"))
        )
    }

    // MARK: - Dua / Name

    func test_dua_navigatesToDhikr() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "dua_morning"), .navigate(.dhikr))
    }

    func test_name_navigatesToDhikr() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "name_1"), .navigate(.dhikr))
    }

    // MARK: - Prayer

    func test_prayer_switchesToPrayerTab() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "prayer_fajr"), .switchTab(.prayer))
    }

    // MARK: - Feature Variants

    func test_featurePrayerTimes_switchesToPrayerTab() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "feature_prayer_times"), .switchTab(.prayer))
    }

    func test_featureQibla_navigatesToQibla() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "feature_qibla"), .navigate(.qibla))
    }

    func test_featureQuran_switchesToQuranTab() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "feature_quran"), .switchTab(.quran))
    }

    func test_featureHadith_navigatesToHadith() {
        XCTAssertEqual(
            SpotlightResolver.resolve(identifier: "feature_hadith"),
            .navigate(.hadith(collection: nil, hadithId: nil))
        )
    }

    func test_featureDhikr_navigatesToDhikr() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "feature_dhikr"), .navigate(.dhikr))
    }

    func test_featureCalendar_navigatesToCalendar() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "feature_calendar"), .navigate(.calendar))
    }

    func test_featureDua_switchesToDuasTab() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "feature_dua"), .switchTab(.duas))
    }

    func test_featureUnknown_returnsNone() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "feature_nonexistent"), .none)
    }

    func test_featureEmptySuffix_returnsNone() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "feature_"), .none)
    }

    // MARK: - Edge Cases

    func test_singleComponent_returnsNone() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "invalid"), .none)
    }

    func test_unknownType_returnsNone() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: "unknown_123"), .none)
    }

    func test_emptyString_returnsNone() {
        XCTAssertEqual(SpotlightResolver.resolve(identifier: ""), .none)
    }

    func test_extraUnderscoresHandledCorrectly() {
        // "hadith_bukhari_1" has 3 components → collection="bukhari", hadithId="1"
        XCTAssertEqual(
            SpotlightResolver.resolve(identifier: "hadith_bukhari_1"),
            .navigate(.hadith(collection: "bukhari", hadithId: "1"))
        )
    }
}
