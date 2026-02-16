// MARK: - MetricKitHelpers.swift
// PURPOSE: Pure-function formatting and computation for MetricKit data, testable without MetricKit mocking
// DEPENDENCIES: Foundation

import Foundation

enum MetricKitHelpers {

    // MARK: - Summary Types

    struct MetricSummary: Codable, Equatable {
        let date: Date
        var launchTimeMs: Double?
        var resumeTimeMs: Double?
        var hangTimeMs: Double?
        var peakMemoryMB: Double?
        var cumulativeCPUSeconds: Double?
    }

    struct DiagnosticSummary: Codable, Equatable {
        let date: Date
        var crashCount: Int
        var hangCount: Int
        var diskWriteExceptionCount: Int
        var cpuExceptionCount: Int
    }

    // MARK: - Formatting

    /// Formats a metric summary into a single log line with fixed key order.
    /// Omits nil fields. Returns `"no metrics"` if all fields are nil.
    static func formatMetricSummary(_ summary: MetricSummary) -> String {
        var parts: [String] = []

        if let launch = summary.launchTimeMs {
            parts.append("launch=\(formatted(launch))ms")
        }
        if let resume = summary.resumeTimeMs {
            parts.append("resume=\(formatted(resume))ms")
        }
        if let hang = summary.hangTimeMs {
            parts.append("hang=\(formatted(hang))ms")
        }
        if let peakMem = summary.peakMemoryMB {
            parts.append("peakMem=\(formatted(peakMem))MB")
        }
        if let cpu = summary.cumulativeCPUSeconds {
            parts.append("cpu=\(formatted(cpu))s")
        }

        return parts.isEmpty ? "no metrics" : parts.joined(separator: " ")
    }

    /// Formats a diagnostic summary into a single log line with fixed key order.
    /// Omits zero fields. Returns `"no diagnostics"` if all fields are zero.
    static func formatDiagnosticSummary(_ summary: DiagnosticSummary) -> String {
        var parts: [String] = []

        if summary.crashCount > 0 {
            parts.append("crashes=\(summary.crashCount)")
        }
        if summary.hangCount > 0 {
            parts.append("hangs=\(summary.hangCount)")
        }
        if summary.diskWriteExceptionCount > 0 {
            parts.append("diskWrites=\(summary.diskWriteExceptionCount)")
        }
        if summary.cpuExceptionCount > 0 {
            parts.append("cpuExceptions=\(summary.cpuExceptionCount)")
        }

        return parts.isEmpty ? "no diagnostics" : parts.joined(separator: " ")
    }

    // MARK: - Median Computation

    /// Computes the median value from histogram bucket data.
    /// Uses bucket start value (not midpoint). For even total count, picks lower-middle (floor division).
    /// Returns nil for empty input.
    static func medianValue(from buckets: [(value: Double, count: Int)]) -> Double? {
        let totalCount = buckets.reduce(0) { $0 + $1.count }
        guard totalCount > 0 else { return nil }

        let medianIndex = totalCount / 2
        var cumulative = 0
        for bucket in buckets {
            cumulative += bucket.count
            if cumulative > medianIndex {
                return bucket.value
            }
        }

        return buckets.last?.value
    }

    // MARK: - Private

    private static func formatted(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
