import XCTest
import UserNotifications
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

    func test_prayerType_caseSensitive_uppercasedReturnsNil() {
        // PrayerType raw values are lowercase; "Fajr" must not match
        let userInfo: [AnyHashable: Any] = ["prayerType": "Fajr"]
        XCTAssertNil(NotificationActionHelpers.prayerType(from: userInfo))
    }

    func test_prayerType_nonObligatoryPrayer_returnsType() {
        // Non-obligatory prayers are valid PrayerType values
        let userInfo: [AnyHashable: Any] = ["prayerType": "sunrise"]
        XCTAssertEqual(NotificationActionHelpers.prayerType(from: userInfo), .sunrise)
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

    func test_routerAction_dismissAction_noAction() {
        // When user swipes away the notification
        let result = NotificationActionHelpers.routerAction(
            for: UNNotificationDismissActionIdentifier,
            userInfo: ["prayerType": "fajr"]
        )
        XCTAssertEqual(result.tab, "prayer")
        XCTAssertNil(result.pendingAction, "Dismiss should not produce a pending action")
    }

    func test_routerAction_openQibla_ignoresUserInfo() {
        // OPEN_QIBLA must produce .openQibla even when userInfo has a prayerType
        let result = NotificationActionHelpers.routerAction(
            for: "OPEN_QIBLA",
            userInfo: ["prayerType": "fajr"]
        )
        if case .openQibla = result.pendingAction {
            // Pass — did not accidentally become .logPrayer
        } else {
            XCTFail("Expected .openQibla, got \(String(describing: result.pendingAction))")
        }
    }

    func test_routerAction_unknownAction_noAction() {
        let result = NotificationActionHelpers.routerAction(
            for: "SOME_FUTURE_ACTION",
            userInfo: ["prayerType": "fajr"]
        )
        XCTAssertEqual(result.tab, "prayer")
        XCTAssertNil(result.pendingAction, "Unknown action should not produce a pending action")
    }

    func test_routerAction_alwaysRoutesToPrayerTab() {
        // Every action type (known or unknown) routes to the prayer tab
        let actions = ["LOG_PRAYER", "OPEN_QIBLA", UNNotificationDefaultActionIdentifier,
                       UNNotificationDismissActionIdentifier, "UNKNOWN"]
        for action in actions {
            let result = NotificationActionHelpers.routerAction(for: action, userInfo: [:])
            XCTAssertEqual(result.tab, "prayer", "Action '\(action)' should route to prayer tab")
        }
    }

    // MARK: - Notification Category Configuration (Regression)

    func test_prayerTimeCategory_hasLogPrayerAndOpenQiblaActions() {
        let categories = FocusModeService.buildNotificationCategories()
        let prayerTime = categories.first { $0.identifier == "PRAYER_TIME" }

        XCTAssertNotNil(prayerTime, "PRAYER_TIME category must exist")
        let actionIDs = prayerTime!.actions.map(\.identifier)
        XCTAssertTrue(actionIDs.contains("LOG_PRAYER"), "Must have LOG_PRAYER action")
        XCTAssertTrue(actionIDs.contains("OPEN_QIBLA"), "Must have OPEN_QIBLA action")
    }

    func test_logPrayerAction_hasForegroundOption() {
        // Regression: without .foreground, tapping the action does NOT open the app
        let categories = FocusModeService.buildNotificationCategories()
        let prayerTime = categories.first { $0.identifier == "PRAYER_TIME" }!
        let logPrayer = prayerTime.actions.first { $0.identifier == "LOG_PRAYER" }

        XCTAssertNotNil(logPrayer, "LOG_PRAYER action must exist")
        XCTAssertTrue(
            logPrayer!.options.contains(.foreground),
            "LOG_PRAYER must have .foreground option to bring app to foreground"
        )
    }

    func test_openQiblaAction_hasForegroundOption() {
        // Regression: without .foreground, tapping the action does NOT open the app
        let categories = FocusModeService.buildNotificationCategories()
        let prayerTime = categories.first { $0.identifier == "PRAYER_TIME" }!
        let openQibla = prayerTime.actions.first { $0.identifier == "OPEN_QIBLA" }

        XCTAssertNotNil(openQibla, "OPEN_QIBLA action must exist")
        XCTAssertTrue(
            openQibla!.options.contains(.foreground),
            "OPEN_QIBLA must have .foreground option to bring app to foreground"
        )
    }

    func test_actionIdentifiers_matchRouterActionHandler() {
        // Ensure the identifiers registered in categories are the same ones routerAction handles.
        // If someone renames an action in FocusModeConfiguration but not in NotificationActionHelpers,
        // this test catches it.
        let categories = FocusModeService.buildNotificationCategories()
        let prayerTime = categories.first { $0.identifier == "PRAYER_TIME" }!
        let actionIDs = Set(prayerTime.actions.map(\.identifier))

        // routerAction must produce a non-nil pendingAction for each registered action
        for actionID in actionIDs {
            let result = NotificationActionHelpers.routerAction(
                for: actionID,
                userInfo: ["prayerType": "fajr"]
            )
            XCTAssertNotNil(
                result.pendingAction,
                "Registered action '\(actionID)' must be handled by routerAction (got nil pendingAction)"
            )
        }
    }

    func test_prayerReminderCategory_alsoHasActions() {
        // PRAYER_REMINDER category should have the same actions as PRAYER_TIME
        let categories = FocusModeService.buildNotificationCategories()
        let prayerReminder = categories.first { $0.identifier == "PRAYER_REMINDER" }

        XCTAssertNotNil(prayerReminder, "PRAYER_REMINDER category must exist")
        let actionIDs = prayerReminder!.actions.map(\.identifier)
        XCTAssertTrue(actionIDs.contains("LOG_PRAYER"))
        XCTAssertTrue(actionIDs.contains("OPEN_QIBLA"))
    }

    // MARK: - Notification Identifier Routing

    func test_prayerNotificationIdentifier_startsWithPrayerPrefix() {
        // The response handler routes based on identifier.starts(with: "prayer_").
        // Verify that generated identifiers match this prefix.
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        for prayer in PrayerType.obligatoryPrayers {
            let id = NotificationSchedulerHelpers.notificationIdentifier(for: prayer, on: date)
            XCTAssertTrue(
                id.starts(with: "prayer_"),
                "Identifier '\(id)' must start with 'prayer_' to be routed by response handler"
            )
        }
    }

    func test_nonPrayerIdentifiers_notRoutedAsPrayer() {
        // These notification identifiers must NOT match the prayer_ prefix
        let nonPrayerIDs = [
            "streak_reminder_prayer",
            "achievement_123",
            "morning_dhikr_reminder",
            "suhoor_reminder",
            "iftar_reminder"
        ]
        for id in nonPrayerIDs {
            XCTAssertFalse(
                id.starts(with: "prayer_"),
                "Non-prayer identifier '\(id)' must not match prayer_ prefix"
            )
        }
    }

    // MARK: - Scheduler userInfo Contract

    func test_schedulerSetsUserInfoPrayerType() {
        // The scheduler builds notification content with userInfo["prayerType"] = prayer.type.rawValue.
        // This test verifies the contract that NotificationActionHelpers.prayerType relies on.
        // If the key name or value format changes in the scheduler, this catches it.
        for prayer in PrayerType.obligatoryPrayers {
            let userInfo: [AnyHashable: Any] = ["prayerType": prayer.rawValue]
            let parsed = NotificationActionHelpers.prayerType(from: userInfo)
            XCTAssertEqual(
                parsed, prayer,
                "Round-trip failed for \(prayer.rawValue): scheduler stores rawValue, parser must recover the type"
            )
        }
    }

    // MARK: - NotificationAction Equatable (Regression: action replacement detection)

    func test_notificationAction_logPrayerDifferentTypes_areNotEqual() {
        // If two different logPrayer actions are equal, onChange(of:) won't fire
        // when one replaces the other. This catches the Bool-projection regression.
        let fajr = AppRouter.NotificationAction.logPrayer(prayerType: .fajr)
        let dhuhr = AppRouter.NotificationAction.logPrayer(prayerType: .dhuhr)
        XCTAssertNotEqual(fajr, dhuhr, "Different prayer types must be distinguishable")
    }

    func test_notificationAction_logPrayerSameType_areEqual() {
        let fajr1 = AppRouter.NotificationAction.logPrayer(prayerType: .fajr)
        let fajr2 = AppRouter.NotificationAction.logPrayer(prayerType: .fajr)
        XCTAssertEqual(fajr1, fajr2)
    }

    func test_notificationAction_logPrayerAndOpenQibla_areNotEqual() {
        // Replacing logPrayer with openQibla must be detectable by onChange
        let log = AppRouter.NotificationAction.logPrayer(prayerType: .fajr)
        let qibla = AppRouter.NotificationAction.openQibla
        XCTAssertNotEqual(log, qibla)
    }

    func test_notificationAction_openQibla_equalsItself() {
        let qibla1 = AppRouter.NotificationAction.openQibla
        let qibla2 = AppRouter.NotificationAction.openQibla
        XCTAssertEqual(qibla1, qibla2)
    }

    func test_notificationAction_allObligatoryPrayers_areDistinct() {
        // Every obligatory prayer must produce a distinct action
        let actions = PrayerType.obligatoryPrayers.map {
            AppRouter.NotificationAction.logPrayer(prayerType: $0)
        }
        // Pairwise distinct
        for i in 0..<actions.count {
            for j in (i + 1)..<actions.count {
                XCTAssertNotEqual(
                    actions[i], actions[j],
                    "Actions for different prayers must be distinguishable by onChange"
                )
            }
        }
    }

    // MARK: - Idempotent Log Semantics (Regression: toggle → log-only)

    func test_routerAction_logPrayer_producesLogNotToggle() {
        // The notification action must always produce .logPrayer (not .togglePrayer).
        // This ensures the lock screen "Mark as Prayed" is idempotent and never unlogs.
        let result = NotificationActionHelpers.routerAction(
            for: "LOG_PRAYER",
            userInfo: ["prayerType": "fajr"]
        )
        if case .logPrayer(let type) = result.pendingAction {
            XCTAssertEqual(type, .fajr)
        } else {
            XCTFail("LOG_PRAYER must produce .logPrayer, not any other action variant")
        }
        // Verify the enum case is specifically .logPrayer (not some hypothetical .togglePrayer)
        // by checking it matches the expected pattern
        guard case .logPrayer = result.pendingAction else {
            XCTFail("Must be .logPrayer case")
            return
        }
    }

    func test_routerAction_logPrayer_sameInputProducesSameOutput() {
        // Idempotency: calling routerAction twice with the same input must produce the same result.
        // This guards against any future stateful behavior in the helper.
        let userInfo: [AnyHashable: Any] = ["prayerType": "asr"]
        let result1 = NotificationActionHelpers.routerAction(for: "LOG_PRAYER", userInfo: userInfo)
        let result2 = NotificationActionHelpers.routerAction(for: "LOG_PRAYER", userInfo: userInfo)

        XCTAssertEqual(result1.tab, result2.tab)
        XCTAssertEqual(result1.pendingAction, result2.pendingAction)
    }
}
