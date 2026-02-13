// MARK: - TasbeehHelpers.swift
// PURPOSE: Testable pure-function helpers for Tasbeeh counter logic
// DEPENDENCIES: Foundation

import Foundation

enum TasbeehHelpers {

    /// Compute progress as a fraction (0.0 to 1.0), clamped.
    static func progress(count: Int, target: Int) -> Double {
        guard target > 0 else { return 0 }
        return min(Double(count) / Double(target), 1.0)
    }

    /// Whether the count has reached or exceeded the target.
    static func isComplete(count: Int, target: Int) -> Bool {
        guard target > 0 else { return false }
        return count >= target
    }

    /// Accessibility label describing the current counter state.
    static func accessibilityLabel(dhikrName: String, count: Int, target: Int) -> String {
        if count == 0 {
            return "\(dhikrName) counter, \(target) remaining"
        } else if count >= target {
            return "\(dhikrName) counter complete, \(count) repetitions"
        } else {
            let percentage = Int(progress(count: count, target: target) * 100)
            return "\(dhikrName) counter, \(count) of \(target), \(percentage) percent complete"
        }
    }
}
