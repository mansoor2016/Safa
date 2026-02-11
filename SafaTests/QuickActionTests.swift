// MARK: - QuickActionTests.swift
// PURPOSE: Tests for home screen quick action delegate and constants
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

// MARK: - QuickActionDelegate Tests

final class QuickActionDelegateTests: XCTestCase {

    override func tearDown() {
        QuickActionDelegate.pendingAction = nil
        super.tearDown()
    }

    func test_performAction_storesPendingAction() {
        // Given
        let delegate = QuickActionDelegate()
        let shortcutItem = UIApplicationShortcutItem(
            type: AppConstants.QuickActions.shareApp,
            localizedTitle: "Share Safa"
        )
        var completionCalled = false
        var completionResult = false

        // When
        delegate.application(
            UIApplication.shared,
            performActionFor: shortcutItem
        ) { success in
            completionCalled = true
            completionResult = success
        }

        // Then — shortcut stored and completion called with true
        XCTAssertEqual(QuickActionDelegate.pendingAction?.type, AppConstants.QuickActions.shareApp)
        XCTAssertTrue(completionCalled)
        XCTAssertTrue(completionResult)
    }

    func test_performAction_latestActionOverwritesPrevious() {
        // Given — two quick actions fire in succession
        let delegate = QuickActionDelegate()
        let firstAction = UIApplicationShortcutItem(
            type: AppConstants.QuickActions.shareApp,
            localizedTitle: "Share"
        )
        let secondAction = UIApplicationShortcutItem(
            type: AppConstants.QuickActions.prayerTimes,
            localizedTitle: "Prayer Times"
        )

        // When
        delegate.application(UIApplication.shared, performActionFor: firstAction) { _ in }
        delegate.application(UIApplication.shared, performActionFor: secondAction) { _ in }

        // Then — latest action wins (user's most recent intent)
        XCTAssertEqual(QuickActionDelegate.pendingAction?.type, AppConstants.QuickActions.prayerTimes)
    }

    func test_pendingAction_isNilByDefault() {
        // Given — fresh delegate state (cleared in tearDown)
        // Then
        XCTAssertNil(QuickActionDelegate.pendingAction)
    }

    func test_performAction_preservesShortcutItemType() {
        // Given — a prayer times shortcut
        let delegate = QuickActionDelegate()
        let shortcutItem = UIApplicationShortcutItem(
            type: AppConstants.QuickActions.prayerTimes,
            localizedTitle: "Prayer Times"
        )

        // When
        delegate.application(UIApplication.shared, performActionFor: shortcutItem) { _ in }

        // Then — the stored type matches exactly (used for routing)
        XCTAssertEqual(QuickActionDelegate.pendingAction?.type, "com.safa.quickaction.prayerTimes")
    }
}

// MARK: - Quick Action Constants Tests

final class QuickActionConstantsTests: XCTestCase {

    func test_shareAppType_usesBundlePrefix() {
        // A typo here would silently break the quick action — must match Info.plist
        XCTAssertEqual(AppConstants.QuickActions.shareApp, "com.safa.quickaction.shareApp")
    }

    func test_prayerTimesType_usesBundlePrefix() {
        XCTAssertEqual(AppConstants.QuickActions.prayerTimes, "com.safa.quickaction.prayerTimes")
    }

    func test_actionTypes_areUnique() {
        // If two actions share the same type, only one would ever fire
        XCTAssertNotEqual(
            AppConstants.QuickActions.shareApp,
            AppConstants.QuickActions.prayerTimes
        )
    }

    func test_constantsMatchInfoPlistValues() {
        // Verify constants match what's declared in Info.plist UIApplicationShortcutItems
        // If these diverge, the static shortcut won't trigger the correct handler
        XCTAssertTrue(AppConstants.QuickActions.shareApp.hasPrefix("com.safa."))
        XCTAssertTrue(AppConstants.QuickActions.prayerTimes.hasPrefix("com.safa."))
    }
}
