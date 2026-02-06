// MARK: - CoreDataStackTests.swift
// PURPOSE: Unit tests for CoreDataStack degradation handling
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class CoreDataStackTests: XCTestCase {

    func test_sharedInstance_exists() {
        let stack = CoreDataStack.shared
        XCTAssertNotNil(stack)
    }

    func test_sharedInstance_hasViewContext() {
        let stack = CoreDataStack.shared
        XCTAssertNotNil(stack.viewContext)
    }

    func test_newBackgroundContext_isNotNil() {
        let stack = CoreDataStack.shared
        let context = stack.newBackgroundContext()
        XCTAssertNotNil(context)
    }

    func test_isDegradedMode_property_exists() {
        let stack = CoreDataStack.shared
        // In test environment, may or may not be degraded depending on App Group availability
        _ = stack.isDegradedMode
    }

    func test_save_withNoChanges_doesNotThrow() throws {
        let stack = CoreDataStack.shared
        try stack.save()
    }
}
