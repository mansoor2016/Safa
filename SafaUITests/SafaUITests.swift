// MARK: - SafaUITests.swift
// PURPOSE: UI tests for the Safa app
// DEPENDENCIES: XCTest

import XCTest

final class SafaUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tab Bar Tests

    @MainActor
    func testTabBarExists() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
    }

    @MainActor
    func testHomeTabExists() throws {
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.exists, "Home tab should exist")
    }

    @MainActor
    func testQuranTabExists() throws {
        let quranTab = app.tabBars.buttons["Quran"]
        XCTAssertTrue(quranTab.exists, "Quran tab should exist")
    }

    @MainActor
    func testPrayerTabExists() throws {
        let prayerTab = app.tabBars.buttons["Prayer"]
        XCTAssertTrue(prayerTab.exists, "Prayer tab should exist")
    }

    @MainActor
    func testLearnTabExists() throws {
        let learnTab = app.tabBars.buttons["Learn"]
        XCTAssertTrue(learnTab.exists, "Learn tab should exist")
    }

    @MainActor
    func testMoreTabExists() throws {
        let moreTab = app.tabBars.buttons["More"]
        XCTAssertTrue(moreTab.exists, "More tab should exist")
    }

    // MARK: - Tab Navigation Tests

    @MainActor
    func testNavigateToQuranTab() throws {
        let quranTab = app.tabBars.buttons["Quran"]
        quranTab.tap()

        // Verify navigation occurred
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.exists)
    }

    @MainActor
    func testNavigateToPrayerTab() throws {
        let prayerTab = app.tabBars.buttons["Prayer"]
        prayerTab.tap()

        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.exists)
    }

    @MainActor
    func testNavigateToLearnTab() throws {
        let learnTab = app.tabBars.buttons["Learn"]
        learnTab.tap()

        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.exists)
    }

    @MainActor
    func testNavigateToMoreTab() throws {
        let moreTab = app.tabBars.buttons["More"]
        moreTab.tap()

        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.exists)
    }

    // MARK: - Home Screen Tests

    @MainActor
    func testHomeScreenLoads() throws {
        // Home should be default or quickly accessible
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        // Screen should have content
        XCTAssertTrue(app.otherElements.count > 0 || app.scrollViews.count > 0)
    }

    // MARK: - Scroll Tests

    @MainActor
    func testHomeScreenScrolls() throws {
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeDown()
        }
    }

    // MARK: - More Screen Tests

    @MainActor
    func testMoreScreenShowsOptions() throws {
        let moreTab = app.tabBars.buttons["More"]
        moreTab.tap()

        // The More screen should have content
        let exists = app.scrollViews.firstMatch.exists ||
                     app.collectionViews.firstMatch.exists ||
                     app.tables.firstMatch.exists
        XCTAssertTrue(exists)
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testTabBarAccessibility() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.isHittable, "Tab bar should be accessible")
    }

    @MainActor
    func testNavigationBarsAreAccessible() throws {
        let tabs = ["Home", "Quran", "Prayer", "Learn", "More"]

        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            if tab.exists {
                tab.tap()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
    }

    // MARK: - Performance Tests

    @MainActor
    func testTabSwitchingPerformance() throws {
        measure {
            let tabs = ["Quran", "Prayer", "Learn", "More", "Home"]
            for tabName in tabs {
                let tab = app.tabBars.buttons[tabName]
                if tab.exists {
                    tab.tap()
                }
            }
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

// MARK: - Prayer Screen UI Tests

final class PrayerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        app.tabBars.buttons["Prayer"].tap()
    }

    @MainActor
    func testPrayerScreenLoads() throws {
        let exists = app.scrollViews.firstMatch.exists ||
                     app.collectionViews.firstMatch.exists ||
                     app.tables.firstMatch.exists
        XCTAssertTrue(exists)
    }
}

// MARK: - Quran Screen UI Tests

final class QuranUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        app.tabBars.buttons["Quran"].tap()
    }

    @MainActor
    func testQuranScreenLoads() throws {
        let exists = app.scrollViews.firstMatch.exists ||
                     app.collectionViews.firstMatch.exists ||
                     app.tables.firstMatch.exists
        XCTAssertTrue(exists)
    }

    @MainActor
    func testQuranScreenScrolls() throws {
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
        }
    }
}

// MARK: - Learn Screen UI Tests

final class LearnUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        app.tabBars.buttons["Learn"].tap()
    }

    @MainActor
    func testLearnScreenLoads() throws {
        let exists = app.scrollViews.firstMatch.exists ||
                     app.collectionViews.firstMatch.exists ||
                     app.tables.firstMatch.exists
        XCTAssertTrue(exists)
    }
}
