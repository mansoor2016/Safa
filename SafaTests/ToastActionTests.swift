// MARK: - ToastActionTests.swift
// PURPOSE: Tests for Toast action button support (undo rail)
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class ToastActionTests: XCTestCase {

    func test_toast_undoFactory_setsDefaults() {
        // Given/When
        let toast = Toast.undoAction(message: "Fajr logged") {}

        // Then
        XCTAssertEqual(toast.message, "Fajr logged")
        XCTAssertEqual(toast.actionTitle, "Undo")
        XCTAssertEqual(toast.duration, 4.0)
        XCTAssertNotNil(toast.action)
    }

    func test_toast_undoFactory_respectsCustomType() {
        // Given/When
        let toast = Toast.undoAction(message: "Fajr unlogged", type: .info) {}

        // Then
        XCTAssertEqual(toast.message, "Fajr unlogged")
        XCTAssertEqual(toast.actionTitle, "Undo")
    }

    func test_toast_withoutAction_hasNilActionTitle() {
        // Given/When
        let toast = Toast(message: "Hello")

        // Then
        XCTAssertNil(toast.actionTitle)
        XCTAssertNil(toast.action)
    }

    func test_toast_withAction_hasActionTitle() {
        // Given/When
        let toast = Toast(message: "Done", actionTitle: "Undo", action: {})

        // Then
        XCTAssertEqual(toast.actionTitle, "Undo")
        XCTAssertNotNil(toast.action)
    }

    func test_toast_comingSoon_hasNoAction() {
        // Given/When
        let toast = Toast.comingSoon("AI Chat")

        // Then
        XCTAssertNil(toast.actionTitle)
        XCTAssertNil(toast.action)
    }
}
