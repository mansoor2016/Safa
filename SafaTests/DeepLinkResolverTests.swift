// MARK: - DeepLinkResolverTests.swift
// PURPOSE: Unit tests for DeepLinkResolver pure URL → RoutingAction mapping
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class DeepLinkResolverTests: XCTestCase {

    // MARK: - Scheme Validation

    func test_invalidScheme_returnsNone() {
        let url = URL(string: "https://example.com/prayer")!
        XCTAssertEqual(DeepLinkResolver.resolve(url, isRamadanActive: false), .none)
    }

    func test_httpScheme_returnsNone() {
        let url = URL(string: "http://safa.app/prayer")!
        XCTAssertEqual(DeepLinkResolver.resolve(url, isRamadanActive: false), .none)
    }

    // MARK: - Tab Switching

    func test_quran_switchesToQuranTab() {
        let url = URL(string: "safa://quran")!
        XCTAssertEqual(DeepLinkResolver.resolve(url, isRamadanActive: false), .switchTab(.quran))
    }

    func test_prayer_switchesToPrayerTab() {
        let url = URL(string: "safa://prayer")!
        XCTAssertEqual(DeepLinkResolver.resolve(url, isRamadanActive: false), .switchTab(.prayer))
    }

    func test_eid_switchesToHomeTab() {
        let url = URL(string: "safa://eid")!
        XCTAssertEqual(DeepLinkResolver.resolve(url, isRamadanActive: false), .switchTab(.home))
    }

    // MARK: - Navigation

    func test_qibla_navigatesToQibla() {
        let url = URL(string: "safa://qibla")!
        XCTAssertEqual(DeepLinkResolver.resolve(url, isRamadanActive: false), .navigate(.qibla))
    }

    func test_chat_navigatesToChat() {
        let url = URL(string: "safa://chat")!
        XCTAssertEqual(DeepLinkResolver.resolve(url, isRamadanActive: false), .navigate(.chat))
    }

    func test_hadith_noPath_navigatesWithNils() {
        let url = URL(string: "safa://hadith")!
        XCTAssertEqual(
            DeepLinkResolver.resolve(url, isRamadanActive: false),
            .navigate(.hadith(collection: nil, hadithId: nil))
        )
    }

    func test_hadith_withCollection_navigatesWithCollection() {
        let url = URL(string: "safa://hadith/bukhari")!
        XCTAssertEqual(
            DeepLinkResolver.resolve(url, isRamadanActive: false),
            .navigate(.hadith(collection: "bukhari", hadithId: nil))
        )
    }

    func test_hadith_withCollectionAndId_navigatesFully() {
        let url = URL(string: "safa://hadith/bukhari/42")!
        XCTAssertEqual(
            DeepLinkResolver.resolve(url, isRamadanActive: false),
            .navigate(.hadith(collection: "bukhari", hadithId: "42"))
        )
    }

    func test_dhikr_navigatesToDhikr() {
        let url = URL(string: "safa://dhikr")!
        XCTAssertEqual(DeepLinkResolver.resolve(url, isRamadanActive: false), .navigate(.dhikr))
    }

    func test_calendar_navigatesToCalendar() {
        let url = URL(string: "safa://calendar")!
        XCTAssertEqual(DeepLinkResolver.resolve(url, isRamadanActive: false), .navigate(.calendar))
    }

    func test_settings_navigatesToSettings() {
        let url = URL(string: "safa://settings")!
        XCTAssertEqual(DeepLinkResolver.resolve(url, isRamadanActive: false), .navigate(.settings))
    }

    // MARK: - Learn (switch tab + navigate)

    func test_learn_switchesToHomeAndNavigatesToLearn() {
        let url = URL(string: "safa://learn")!
        XCTAssertEqual(
            DeepLinkResolver.resolve(url, isRamadanActive: false),
            .switchTabAndNavigate(tab: .home, destination: .learn)
        )
    }

    // MARK: - Ramadan

    func test_ramadan_duringRamadan_switchesToPrayerTab() {
        let url = URL(string: "safa://ramadan")!
        XCTAssertEqual(DeepLinkResolver.resolve(url, isRamadanActive: true), .switchTab(.prayer))
    }

    func test_ramadan_outsideRamadan_switchesToHomeAndNavigates() {
        let url = URL(string: "safa://ramadan")!
        XCTAssertEqual(
            DeepLinkResolver.resolve(url, isRamadanActive: false),
            .switchTabAndNavigate(tab: .home, destination: .ramadan)
        )
    }

    // MARK: - Unknown / Empty

    func test_unknownHost_returnsNone() {
        let url = URL(string: "safa://unknown")!
        XCTAssertEqual(DeepLinkResolver.resolve(url, isRamadanActive: false), .none)
    }

    func test_emptyHost_returnsNone() {
        // safa:// with no host
        let url = URL(string: "safa://")!
        XCTAssertEqual(DeepLinkResolver.resolve(url, isRamadanActive: false), .none)
    }

    // MARK: - Extra Path Components Ignored

    func test_quran_withExtraPath_stillSwitchesTab() {
        let url = URL(string: "safa://quran/2/255")!
        XCTAssertEqual(DeepLinkResolver.resolve(url, isRamadanActive: false), .switchTab(.quran))
    }
}
