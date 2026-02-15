import XCTest
@testable import Safa

final class NotificationActionTests: XCTestCase {

    // MARK: - NotificationActionHelpers.prayerType(from:)

    func test_prayerType_fromUserInfo_returnsFajr() {
        let userInfo: [AnyHashable: Any] = ["prayerType": "fajr"]
        XCTAssertEqual(NotificationActionHelpers.prayerType(from: userInfo), .fajr)
    }

    func test_prayerType_fromUserInfo_allObligatoryPrayers() {
        let prayers: [(String, PrayerType)] = [
            ("fajr", .fajr),
            ("dhuhr", .dhuhr),
            ("asr", .asr),
            ("maghrib", .maghrib),
            ("isha", .isha)
        ]
        for (rawValue, expected) in prayers {
            let userInfo: [AnyHashable: Any] = ["prayerType": rawValue]
            XCTAssertEqual(
                NotificationActionHelpers.prayerType(from: userInfo),
                expected,
                "Failed for rawValue: \(rawValue)"
            )
        }
    }

    func test_prayerType_missingKey_returnsNil() {
        let userInfo: [AnyHashable: Any] = ["otherKey": "fajr"]
        XCTAssertNil(NotificationActionHelpers.prayerType(from: userInfo))
    }

    func test_prayerType_emptyUserInfo_returnsNil() {
        let userInfo: [AnyHashable: Any] = [:]
        XCTAssertNil(NotificationActionHelpers.prayerType(from: userInfo))
    }

    func test_prayerType_invalidRawValue_returnsNil() {
        let userInfo: [AnyHashable: Any] = ["prayerType": "invalid"]
        XCTAssertNil(NotificationActionHelpers.prayerType(from: userInfo))
    }

    func test_prayerType_nonStringValue_returnsNil() {
        let userInfo: [AnyHashable: Any] = ["prayerType": 42]
        XCTAssertNil(NotificationActionHelpers.prayerType(from: userInfo))
    }

    // MARK: - NotificationActionHelpers.routerAction(for:userInfo:)

    func test_routerAction_logPrayer_switchesToPrayerTabWithLogAction() {
        let result = NotificationActionHelpers.routerAction(
            for: "LOG_PRAYER",
            userInfo: ["prayerType": "dhuhr"]
        )
        XCTAssertEqual(result.tab, "prayer")
        if case .logPrayer(let type) = result.pendingAction {
            XCTAssertEqual(type, .dhuhr)
        } else {
            XCTFail("Expected .logPrayer(.dhuhr), got \(String(describing: result.pendingAction))")
        }
    }

    func test_routerAction_logPrayer_missingUserInfo_switchesTabWithNoAction() {
        let result = NotificationActionHelpers.routerAction(
            for: "LOG_PRAYER",
            userInfo: [:]
        )
        XCTAssertEqual(result.tab, "prayer")
        XCTAssertNil(result.pendingAction, "Missing userInfo should not produce a pending action")
    }

    func test_routerAction_logPrayer_invalidPrayerType_noAction() {
        let result = NotificationActionHelpers.routerAction(
            for: "LOG_PRAYER",
            userInfo: ["prayerType": "invalid"]
        )
        XCTAssertEqual(result.tab, "prayer")
        XCTAssertNil(result.pendingAction, "Invalid prayer type should not produce a pending action")
    }

    func test_routerAction_openQibla_switchesToPrayerTabWithQiblaAction() {
        let result = NotificationActionHelpers.routerAction(
            for: "OPEN_QIBLA",
            userInfo: [:]
        )
        XCTAssertEqual(result.tab, "prayer")
        if case .openQibla = result.pendingAction {
            // Pass
        } else {
            XCTFail("Expected .openQibla, got \(String(describing: result.pendingAction))")
        }
    }

    func test_routerAction_defaultTap_switchesToPrayerTabWithNoAction() {
        let result = NotificationActionHelpers.routerAction(
            for: UNNotificationDefaultActionIdentifier,
            userInfo: [:]
        )
        XCTAssertEqual(result.tab, "prayer")
        XCTAssertNil(result.pendingAction, "Default tap should not set a pending action")
    }

    func test_routerAction_logPrayer_allObligatoryPrayers() {
        let prayers: [(String, PrayerType)] = [
            ("fajr", .fajr),
            ("dhuhr", .dhuhr),
            ("asr", .asr),
            ("maghrib", .maghrib),
            ("isha", .isha)
        ]
        for (rawValue, expected) in prayers {
            let result = NotificationActionHelpers.routerAction(
                for: "LOG_PRAYER",
                userInfo: ["prayerType": rawValue]
            )
            if case .logPrayer(let type) = result.pendingAction {
                XCTAssertEqual(type, expected, "Failed for rawValue: \(rawValue)")
            } else {
                XCTFail("Expected .logPrayer(.\(expected)) for \(rawValue)")
            }
        }
    }
}
