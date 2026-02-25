// MARK: - PrayerRakatsTests.swift
// PURPOSE: Correctness tests for PrayerRakatInfo lookup and summary formatting

import XCTest
@testable import Safa

final class PrayerRakatsTests: XCTestCase {

    // MARK: - Sunrise Returns Nil

    func test_sunrise_returns_nil() {
        XCTAssertNil(PrayerRakats.info(for: .sunrise, madhab: .hanafi))
        XCTAssertNil(PrayerRakats.info(for: .sunrise, madhab: .shafi))
    }

    // MARK: - Fajr (Same for Both Madhabs)

    func test_fajr_hanafi() {
        let info = PrayerRakats.info(for: .fajr, madhab: .hanafi)!
        XCTAssertEqual(info.sunnahBefore, 2)
        XCTAssertEqual(info.naflBefore, 0)
        XCTAssertEqual(info.fard, 2)
        XCTAssertEqual(info.sunnahAfter, 0)
        XCTAssertEqual(info.naflAfter, 0)
        XCTAssertEqual(info.witr, 0)
    }

    func test_fajr_shafi() {
        let info = PrayerRakats.info(for: .fajr, madhab: .shafi)!
        XCTAssertEqual(info.sunnahBefore, 2)
        XCTAssertEqual(info.naflBefore, 0)
        XCTAssertEqual(info.fard, 2)
        XCTAssertEqual(info.sunnahAfter, 0)
        XCTAssertEqual(info.naflAfter, 0)
        XCTAssertEqual(info.witr, 0)
    }

    // MARK: - Dhuhr (Differs by Madhab)

    func test_dhuhr_hanafi() {
        let info = PrayerRakats.info(for: .dhuhr, madhab: .hanafi)!
        XCTAssertEqual(info.sunnahBefore, 4, "Hanafi: 4 Sunnah before Fard")
        XCTAssertEqual(info.naflBefore, 0)
        XCTAssertEqual(info.fard, 4)
        XCTAssertEqual(info.sunnahAfter, 2, "Hanafi: 2 Sunnah after Fard")
        XCTAssertEqual(info.naflAfter, 2, "Hanafi: 2 Nafl after Fard")
        XCTAssertEqual(info.witr, 0)
    }

    func test_dhuhr_shafi() {
        let info = PrayerRakats.info(for: .dhuhr, madhab: .shafi)!
        XCTAssertEqual(info.sunnahBefore, 2, "Shafi'i: 2 Sunnah before Fard")
        XCTAssertEqual(info.naflBefore, 2, "Shafi'i: 2 Nafl before Fard")
        XCTAssertEqual(info.fard, 4)
        XCTAssertEqual(info.sunnahAfter, 2, "Shafi'i: 2 Sunnah after Fard")
        XCTAssertEqual(info.naflAfter, 2, "Shafi'i: 2 Nafl after Fard")
        XCTAssertEqual(info.witr, 0)
    }

    // MARK: - Asr (Same for Both)

    func test_asr_hanafi() {
        let info = PrayerRakats.info(for: .asr, madhab: .hanafi)!
        XCTAssertEqual(info.sunnahBefore, 0)
        XCTAssertEqual(info.naflBefore, 4)
        XCTAssertEqual(info.fard, 4)
        XCTAssertEqual(info.sunnahAfter, 0)
        XCTAssertEqual(info.naflAfter, 0)
        XCTAssertEqual(info.witr, 0)
    }

    func test_asr_shafi() {
        let info = PrayerRakats.info(for: .asr, madhab: .shafi)!
        XCTAssertEqual(info.sunnahBefore, 0)
        XCTAssertEqual(info.naflBefore, 4)
        XCTAssertEqual(info.fard, 4)
        XCTAssertEqual(info.sunnahAfter, 0)
        XCTAssertEqual(info.naflAfter, 0)
        XCTAssertEqual(info.witr, 0)
    }

    // MARK: - Maghrib (Same for Both)

    func test_maghrib_hanafi() {
        let info = PrayerRakats.info(for: .maghrib, madhab: .hanafi)!
        XCTAssertEqual(info.sunnahBefore, 0)
        XCTAssertEqual(info.naflBefore, 0)
        XCTAssertEqual(info.fard, 3)
        XCTAssertEqual(info.sunnahAfter, 2)
        XCTAssertEqual(info.naflAfter, 2)
        XCTAssertEqual(info.witr, 0)
    }

    func test_maghrib_shafi() {
        let info = PrayerRakats.info(for: .maghrib, madhab: .shafi)!
        XCTAssertEqual(info.sunnahBefore, 0)
        XCTAssertEqual(info.naflBefore, 0)
        XCTAssertEqual(info.fard, 3)
        XCTAssertEqual(info.sunnahAfter, 2)
        XCTAssertEqual(info.naflAfter, 2)
        XCTAssertEqual(info.witr, 0)
    }

    // MARK: - Isha (Differs by Madhab)

    func test_isha_hanafi() {
        let info = PrayerRakats.info(for: .isha, madhab: .hanafi)!
        XCTAssertEqual(info.sunnahBefore, 0)
        XCTAssertEqual(info.naflBefore, 4, "Hanafi: 4 Nafl before Fard")
        XCTAssertEqual(info.fard, 4)
        XCTAssertEqual(info.sunnahAfter, 2, "Hanafi: 2 Sunnah after Fard")
        XCTAssertEqual(info.naflAfter, 2, "Hanafi: 2 Nafl after Fard")
        XCTAssertEqual(info.witr, 3, "Hanafi Witr is fixed at 3 (Wajib)")
        XCTAssertFalse(info.witrIsRange)
    }

    func test_isha_shafi() {
        let info = PrayerRakats.info(for: .isha, madhab: .shafi)!
        XCTAssertEqual(info.sunnahBefore, 0)
        XCTAssertEqual(info.naflBefore, 2, "Shafi'i: 2 Nafl before Fard")
        XCTAssertEqual(info.fard, 4)
        XCTAssertEqual(info.sunnahAfter, 2, "Shafi'i: 2 Sunnah after Fard")
        XCTAssertEqual(info.naflAfter, 2, "Shafi'i: 2 Nafl after Fard")
        XCTAssertEqual(info.witr, 1, "Shafi'i Witr starts at 1 (range)")
        XCTAssertTrue(info.witrIsRange)
    }

    // MARK: - Compact Summary: Exact Output + Order

    func test_compactSummary_fajr() {
        let info = PrayerRakats.info(for: .fajr, madhab: .hanafi)!
        XCTAssertEqual(info.compactSummary, "2S · 2F")
    }

    func test_compactSummary_dhuhr_hanafi() {
        let info = PrayerRakats.info(for: .dhuhr, madhab: .hanafi)!
        XCTAssertEqual(info.compactSummary, "4S · 4F · 2S · 2N")
    }

    func test_compactSummary_dhuhr_shafi() {
        let info = PrayerRakats.info(for: .dhuhr, madhab: .shafi)!
        XCTAssertEqual(info.compactSummary, "2S · 2N · 4F · 2S · 2N")
    }

    func test_compactSummary_asr() {
        let info = PrayerRakats.info(for: .asr, madhab: .hanafi)!
        XCTAssertEqual(info.compactSummary, "4N · 4F")
    }

    func test_compactSummary_maghrib() {
        let info = PrayerRakats.info(for: .maghrib, madhab: .hanafi)!
        XCTAssertEqual(info.compactSummary, "3F · 2S · 2N")
    }

    func test_compactSummary_isha_hanafi() {
        let info = PrayerRakats.info(for: .isha, madhab: .hanafi)!
        XCTAssertEqual(info.compactSummary, "4N · 4F · 2S · 2N · 3W")
    }

    func test_compactSummary_isha_shafi() {
        let info = PrayerRakats.info(for: .isha, madhab: .shafi)!
        XCTAssertEqual(info.compactSummary, "2N · 4F · 2S · 2N · 1+W")
    }

    // MARK: - Detailed Summary: Verify Segment Order (not just "contains")

    func test_detailedSummary_fajr_order() {
        let info = PrayerRakats.info(for: .fajr, madhab: .hanafi)!
        let segments = info.detailedSummary.components(separatedBy: " · ")
        // Fajr: 2 Sunnah before, 2 Fard — two segments only
        XCTAssertEqual(segments.count, 2)
        XCTAssertTrue(segments[0].contains("Sunnah"), "First segment should be Sunnah (before)")
        XCTAssertTrue(segments[1].contains("Fard"), "Second segment should be Fard")
    }

    func test_detailedSummary_dhuhr_hanafi_order() {
        let info = PrayerRakats.info(for: .dhuhr, madhab: .hanafi)!
        let segments = info.detailedSummary.components(separatedBy: " · ")
        // 4S before · 4F · 2S after · 2N after
        XCTAssertEqual(segments.count, 4)
        XCTAssertTrue(segments[0].contains("Sunnah"), "First: Sunnah before Fard")
        XCTAssertTrue(segments[1].contains("Fard"), "Second: Fard")
        XCTAssertTrue(segments[2].contains("Sunnah"), "Third: Sunnah after Fard")
        XCTAssertTrue(segments[3].contains("Nafl"), "Fourth: Nafl after Fard")
    }

    func test_detailedSummary_dhuhr_shafi_has_nafl_before_fard() {
        let info = PrayerRakats.info(for: .dhuhr, madhab: .shafi)!
        let segments = info.detailedSummary.components(separatedBy: " · ")
        // 2S before · 2N before · 4F · 2S after · 2N after
        XCTAssertEqual(segments.count, 5, "Shafi'i Dhuhr has 5 segments (Nafl before Fard)")
        XCTAssertTrue(segments[0].contains("Sunnah"), "First: Sunnah before")
        XCTAssertTrue(segments[1].contains("Nafl"), "Second: Nafl before")
        XCTAssertTrue(segments[2].contains("Fard"), "Third: Fard")
    }

    func test_detailedSummary_isha_hanafi_includes_witr_at_end() {
        let info = PrayerRakats.info(for: .isha, madhab: .hanafi)!
        let segments = info.detailedSummary.components(separatedBy: " · ")
        // 4N before · 4F · 2S after · 2N after · 3 Witr
        XCTAssertEqual(segments.count, 5)
        XCTAssertTrue(segments.last!.contains("Witr"), "Witr should be the last segment")
        XCTAssertTrue(segments.last!.contains("3"), "Hanafi Witr is 3")
    }

    func test_detailedSummary_isha_shafi_witr_shows_range() {
        let info = PrayerRakats.info(for: .isha, madhab: .shafi)!
        let segments = info.detailedSummary.components(separatedBy: " · ")
        XCTAssertTrue(segments.last!.contains("1+"), "Shafi'i Witr shows range notation")
        XCTAssertTrue(segments.last!.contains("Witr"))
    }

    func test_detailedSummary_asr_omits_sunnah_includes_nafl() {
        let info = PrayerRakats.info(for: .asr, madhab: .hanafi)!
        let segments = info.detailedSummary.components(separatedBy: " · ")
        // 4N before · 4F — only 2 segments, no Sunnah
        XCTAssertEqual(segments.count, 2)
        XCTAssertTrue(segments[0].contains("Nafl"), "First: Nafl before Fard")
        XCTAssertTrue(segments[1].contains("Fard"), "Second: Fard")
        XCTAssertFalse(info.detailedSummary.contains("Sunnah"), "No Sunnah in Asr")
    }

    func test_detailedSummary_maghrib_no_before_segments() {
        let info = PrayerRakats.info(for: .maghrib, madhab: .hanafi)!
        let segments = info.detailedSummary.components(separatedBy: " · ")
        // 3F · 2S after · 2N after — Fard is first because nothing before
        XCTAssertEqual(segments.count, 3)
        XCTAssertTrue(segments[0].contains("Fard"), "Fard should be first when nothing comes before")
    }

    // MARK: - Zero Fields Are Omitted

    func test_compactSummary_omits_zero_sunnahBefore() {
        let info = PrayerRakats.info(for: .maghrib, madhab: .hanafi)!
        // Maghrib has 0 sunnahBefore and 0 naflBefore — summary should start with Fard
        XCTAssertTrue(info.compactSummary.hasPrefix("3F"), "Should start with Fard when no before-prayers")
    }

    func test_compactSummary_omits_zero_witr() {
        let info = PrayerRakats.info(for: .dhuhr, madhab: .hanafi)!
        XCTAssertFalse(info.compactSummary.contains("W"), "No Witr in Dhuhr")
    }

    func test_compactSummary_omits_zero_naflBefore() {
        let info = PrayerRakats.info(for: .dhuhr, madhab: .hanafi)!
        let segments = info.compactSummary.components(separatedBy: " · ")
        // Hanafi Dhuhr has 0 naflBefore — should not have N before F
        let fardIndex = segments.firstIndex(where: { $0.hasSuffix("F") })!
        for i in 0..<fardIndex {
            XCTAssertFalse(segments[i].hasSuffix("N"), "No Nafl before Fard in Hanafi Dhuhr")
        }
    }

    // MARK: - Compact and Detailed Summaries Agree on Segment Count

    func test_compact_and_detailed_segment_counts_match() {
        for prayer in PrayerType.obligatoryPrayers {
            for madhab in [Madhab.hanafi, .shafi] {
                guard let info = PrayerRakats.info(for: prayer, madhab: madhab) else { continue }
                let compactCount = info.compactSummary.components(separatedBy: " · ").count
                let detailedCount = info.detailedSummary.components(separatedBy: " · ").count
                XCTAssertEqual(
                    compactCount, detailedCount,
                    "\(prayer) \(madhab): compact has \(compactCount) segments but detailed has \(detailedCount)"
                )
            }
        }
    }

    // MARK: - Key Madhab Differences

    func test_dhuhr_hanafi_has_more_sunnah_before_than_shafi() {
        let hanafi = PrayerRakats.info(for: .dhuhr, madhab: .hanafi)!
        let shafi = PrayerRakats.info(for: .dhuhr, madhab: .shafi)!
        XCTAssertGreaterThan(hanafi.sunnahBefore, shafi.sunnahBefore,
                             "Hanafi has 4 Sunnah before Dhuhr vs Shafi'i's 2")
    }

    func test_dhuhr_shafi_has_nafl_before_but_hanafi_does_not() {
        let hanafi = PrayerRakats.info(for: .dhuhr, madhab: .hanafi)!
        let shafi = PrayerRakats.info(for: .dhuhr, madhab: .shafi)!
        XCTAssertEqual(hanafi.naflBefore, 0, "Hanafi has no Nafl before Dhuhr")
        XCTAssertGreaterThan(shafi.naflBefore, 0, "Shafi'i has Nafl before Dhuhr")
    }

    func test_isha_hanafi_has_more_nafl_before_than_shafi() {
        let hanafi = PrayerRakats.info(for: .isha, madhab: .hanafi)!
        let shafi = PrayerRakats.info(for: .isha, madhab: .shafi)!
        XCTAssertGreaterThan(hanafi.naflBefore, shafi.naflBefore,
                             "Hanafi has 4 Nafl before Isha vs Shafi'i's 2")
    }

    func test_isha_hanafi_witr_fixed_vs_shafi_range() {
        let hanafi = PrayerRakats.info(for: .isha, madhab: .hanafi)!
        let shafi = PrayerRakats.info(for: .isha, madhab: .shafi)!
        XCTAssertFalse(hanafi.witrIsRange, "Hanafi Witr is fixed (Wajib)")
        XCTAssertTrue(shafi.witrIsRange, "Shafi'i Witr is a range (Sunnah Mu'akkadah)")
        XCTAssertGreaterThan(hanafi.witr, shafi.witr, "Hanafi Witr 3 > Shafi'i Witr 1")
    }

    // MARK: - All Obligatory Prayers Return Non-Nil

    func test_all_obligatory_prayers_return_info() {
        for prayer in PrayerType.obligatoryPrayers {
            XCTAssertNotNil(PrayerRakats.info(for: prayer, madhab: .hanafi), "\(prayer) should return rakat info for Hanafi")
            XCTAssertNotNil(PrayerRakats.info(for: prayer, madhab: .shafi), "\(prayer) should return rakat info for Shafi'i")
        }
    }

    // MARK: - Fard Counts Are Same Across Madhabs

    func test_fard_counts_match_known_values() {
        let expectedFard: [PrayerType: Int] = [.fajr: 2, .dhuhr: 4, .asr: 4, .maghrib: 3, .isha: 4]
        for (prayer, expected) in expectedFard {
            let hanafi = PrayerRakats.info(for: prayer, madhab: .hanafi)!
            let shafi = PrayerRakats.info(for: prayer, madhab: .shafi)!
            XCTAssertEqual(hanafi.fard, expected, "\(prayer) Hanafi fard")
            XCTAssertEqual(shafi.fard, expected, "\(prayer) Shafi'i fard — fard is the same across madhabs")
        }
    }

    // MARK: - Fard Always Appears Exactly Once in Summary

    func test_compactSummary_fard_appears_exactly_once() {
        for prayer in PrayerType.obligatoryPrayers {
            for madhab in [Madhab.hanafi, .shafi] {
                guard let info = PrayerRakats.info(for: prayer, madhab: madhab) else { continue }
                let fardSegments = info.compactSummary.components(separatedBy: " · ").filter { $0.hasSuffix("F") }
                XCTAssertEqual(fardSegments.count, 1, "\(prayer) \(madhab): Fard should appear exactly once")
            }
        }
    }

    // MARK: - Prayer Order in Compact Summary

    func test_compactSummary_dhuhr_hanafi_sunnah_before_appears_first() {
        let info = PrayerRakats.info(for: .dhuhr, madhab: .hanafi)!
        let segments = info.compactSummary.components(separatedBy: " · ")
        XCTAssertEqual(segments[0], "4S", "Sunnah before should come first")
        XCTAssertEqual(segments[1], "4F", "Fard should come second")
        XCTAssertEqual(segments[2], "2S", "Sunnah after should come third")
        XCTAssertEqual(segments[3], "2N", "Nafl after should come fourth")
    }

    func test_compactSummary_isha_hanafi_nafl_before_appears_first() {
        let info = PrayerRakats.info(for: .isha, madhab: .hanafi)!
        let segments = info.compactSummary.components(separatedBy: " · ")
        XCTAssertEqual(segments[0], "4N", "Nafl before should come first")
        XCTAssertEqual(segments[1], "4F", "Fard should come second")
    }

    // MARK: - Backward-Compatible UserPreferences Decode

    func test_userPreferences_decode_without_showRakatInfo_defaults_false() throws {
        let prefs = UserPreferences()
        let encoder = JSONEncoder()
        var data = try encoder.encode(prefs)

        // Remove showRakatInfo from the JSON to simulate old saved prefs
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json.removeValue(forKey: "showRakatInfo")
        data = try JSONSerialization.data(withJSONObject: json)

        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)
        XCTAssertFalse(decoded.showRakatInfo, "Missing showRakatInfo should default to false")
    }

    func test_userPreferences_roundtrip_preserves_showRakatInfo() throws {
        var prefs = UserPreferences()
        prefs.showRakatInfo = true
        let data = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)
        XCTAssertTrue(decoded.showRakatInfo, "showRakatInfo=true should survive encode/decode")
    }
}
