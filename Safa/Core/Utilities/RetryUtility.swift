// MARK: - RetryUtility.swift
// PURPOSE: Exponential backoff retry for async operations
// DEPENDENCIES: Foundation

import Foundation

/// Retries an async throwing operation with exponential backoff
/// - Parameters:
///   - maxAttempts: Maximum number of attempts (default: 3)
///   - initialDelay: Initial delay in seconds before first retry (default: 1.0)
///   - multiplier: Delay multiplier for each subsequent retry (default: 2.0)
///   - operation: The async throwing operation to retry
/// - Returns: The operation's result
func withRetry<T>(
    maxAttempts: Int = 3,
    initialDelay: TimeInterval = 1.0,
    multiplier: Double = 2.0,
    _ operation: @Sendable () async throws -> T
) async throws -> T {
    var delay = initialDelay
    for attempt in 1...maxAttempts {
        do {
            return try await operation()
        } catch {
            if attempt == maxAttempts {
                throw error
            }
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            delay *= multiplier
        }
    }
    // Should never reach here, but compiler needs it
    return try await operation()
}
