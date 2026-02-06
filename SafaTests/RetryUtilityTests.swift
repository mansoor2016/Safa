// MARK: - RetryUtilityTests.swift
// PURPOSE: Unit tests for exponential backoff retry utility
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class RetryUtilityTests: XCTestCase {

    func test_withRetry_succeedsOnFirstAttempt() async throws {
        var callCount = 0
        let result = try await withRetry {
            callCount += 1
            return "success"
        }
        XCTAssertEqual(result, "success")
        XCTAssertEqual(callCount, 1)
    }

    func test_withRetry_retriesOnFailure() async throws {
        var callCount = 0
        let result = try await withRetry(maxAttempts: 3, initialDelay: 0.01) {
            callCount += 1
            if callCount < 3 {
                throw TestRetryError.temporary
            }
            return "success after retries"
        }
        XCTAssertEqual(result, "success after retries")
        XCTAssertEqual(callCount, 3)
    }

    func test_withRetry_throwsAfterMaxAttempts() async {
        var callCount = 0
        do {
            _ = try await withRetry(maxAttempts: 2, initialDelay: 0.01) { () -> String in
                callCount += 1
                throw TestRetryError.permanent
            }
            XCTFail("Should have thrown")
        } catch {
            XCTAssertEqual(callCount, 2)
        }
    }

    func test_withRetry_respectsMaxAttempts() async {
        var callCount = 0
        do {
            _ = try await withRetry(maxAttempts: 5, initialDelay: 0.01) { () -> String in
                callCount += 1
                throw TestRetryError.permanent
            }
        } catch {
            XCTAssertEqual(callCount, 5)
        }
    }
}

private enum TestRetryError: Error {
    case temporary
    case permanent
}
