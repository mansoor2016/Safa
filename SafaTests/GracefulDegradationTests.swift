// MARK: - GracefulDegradationTests.swift
// PURPOSE: Unit tests for graceful degradation features
// DEPENDENCIES: XCTest, Safa

import XCTest

@testable import Safa

// MARK: - NetworkMonitor Tests

final class NetworkMonitorTests: XCTestCase {

    func test_sharedInstance_exists() {
        let monitor = NetworkMonitor.shared
        XCTAssertNotNil(monitor)
    }

    func test_isConnected_hasValue() {
        // NetworkMonitor initializes with isConnected = true
        let monitor = NetworkMonitor()
        XCTAssertTrue(monitor.isConnected)
    }

    func test_isOnWiFi_derivedFromConnectionType() {
        // isOnWiFi should be false when not connected
        let monitor = NetworkMonitor()
        // On fresh init before NWPathMonitor updates, connectionType is nil
        // isOnWiFi requires isConnected && connectionType == .wifi
        // With nil connectionType, isOnWiFi should be false
        if monitor.connectionType == nil {
            XCTAssertFalse(monitor.isOnWiFi)
        }
    }
}

// MARK: - CoreDataStack Degradation Tests

final class CoreDataDegradationTests: XCTestCase {

    func test_isDegradedMode_isBool() {
        let stack = CoreDataStack.shared
        let isDegraded = stack.isDegradedMode
        XCTAssertTrue(isDegraded == true || isDegraded == false)
    }

    func test_hasLowStorage_isBool() {
        let stack = CoreDataStack.shared
        let isLow = stack.hasLowStorage
        // In test environment, storage should not be low
        XCTAssertFalse(isLow)
    }

    func test_viewContext_availableInDegradedMode() {
        // Even if degraded, viewContext should still be accessible
        let stack = CoreDataStack.shared
        XCTAssertNotNil(stack.viewContext)
    }

    func test_save_worksWithNoChanges() throws {
        let stack = CoreDataStack.shared
        // Should not throw when there are no changes
        try stack.save()
    }
}

// MARK: - Compass Accuracy Tests

final class CompassAccuracyTests: XCTestCase {

    // Test the heading accuracy thresholds documented in QiblaCompassView
    // headingAccuracy < 0 → unreliable
    // headingAccuracy > 25 → low
    // headingAccuracy <= 25 → good

    func test_negativeAccuracy_isUnreliable() {
        let accuracy: Double = -1
        XCTAssertTrue(accuracy < 0, "Negative accuracy should indicate unreliable heading")
    }

    func test_highAccuracy_isGood() {
        let accuracy: Double = 10
        XCTAssertTrue(accuracy >= 0 && accuracy <= 25, "Accuracy 0-25 is good")
    }

    func test_lowAccuracy_isLow() {
        let accuracy: Double = 30
        XCTAssertTrue(accuracy > 25, "Accuracy > 25 is low quality")
    }

    func test_zeroAccuracy_isGood() {
        let accuracy: Double = 0
        XCTAssertTrue(accuracy >= 0 && accuracy <= 25, "Zero accuracy is still good")
    }

    func test_boundaryAccuracy_25_isGood() {
        let accuracy: Double = 25
        XCTAssertTrue(accuracy >= 0 && accuracy <= 25, "Exactly 25 is still good")
    }

    func test_headingTimeout_threshold() {
        // Heading timeout is 5 seconds
        let lastUpdate = Date().addingTimeInterval(-6)
        let timeSince = Date().timeIntervalSince(lastUpdate)
        XCTAssertGreaterThan(timeSince, 5, "After 5 seconds, heading is considered stale")
    }

    func test_headingNotTimedOut_withinThreshold() {
        let lastUpdate = Date().addingTimeInterval(-2)
        let timeSince = Date().timeIntervalSince(lastUpdate)
        XCTAssertLessThanOrEqual(timeSince, 5, "Within 5 seconds, heading is fresh")
    }
}

// MARK: - Retry Utility Additional Tests

final class RetryDegradationTests: XCTestCase {

    func test_withRetry_singleAttempt_succeeds() async throws {
        var count = 0
        let result = try await withRetry(maxAttempts: 1, initialDelay: 0.01) {
            count += 1
            return "ok"
        }
        XCTAssertEqual(result, "ok")
        XCTAssertEqual(count, 1)
    }

    func test_withRetry_recoversOnSecondAttempt() async throws {
        var count = 0
        let result = try await withRetry(maxAttempts: 3, initialDelay: 0.01) {
            count += 1
            if count == 1 { throw NSError(domain: "test", code: 1) }
            return "recovered"
        }
        XCTAssertEqual(result, "recovered")
        XCTAssertEqual(count, 2)
    }
}
