// MARK: - ScrollableScreenTests.swift
// PURPOSE: Tests for ScrollableScreen generic init paths
// DEPENDENCIES: XCTest, SwiftUI, Safa

import XCTest
import SwiftUI
@testable import Safa

final class ScrollableScreenTests: XCTestCase {

    // MARK: - Convenience Init (No Sticky Content)

    func test_convenienceInit_stickyContentIsNil() {
        let screen = ScrollableScreen {
            Text("Content")
        }
        XCTAssertNil(screen.stickyContent)
    }

    // MARK: - Full Init (With Sticky Content)

    func test_fullInit_stickyContentIsNonNil() {
        let screen = ScrollableScreen(stickyContent: {
            Text("Sticky")
        }) {
            Text("Content")
        }
        XCTAssertNotNil(screen.stickyContent)
    }

    func test_fullInit_stickyContentClosureProducesView() {
        let screen = ScrollableScreen(stickyContent: {
            Text("Sticky Label")
        }) {
            Text("Content")
        }

        // Calling the closure should produce a view without crashing
        let stickyView = screen.stickyContent?()
        XCTAssertNotNil(stickyView)
    }

    // MARK: - Content Closure

    func test_contentClosureProducesView() {
        let screen = ScrollableScreen {
            Text("Main Content")
        }

        // Calling the content closure should produce a view
        let contentView = screen.content()
        XCTAssertNotNil(contentView)
    }

    // MARK: - Generic Type Inference

    func test_convenienceInit_stickyContentTypeIsEmptyView() {
        // This test verifies the `where StickyContent == EmptyView` constraint
        let screen: ScrollableScreen<Text, EmptyView> = ScrollableScreen {
            Text("Content")
        }
        XCTAssertNil(screen.stickyContent)
    }
}
