// MARK: - MetricKitHelpersTests.swift
// PURPOSE: Behavior tests for MetricKitHelpers formatting and median computation
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class MetricKitHelpersTests: XCTestCase {

    // MARK: - Median Value

    func test_medianValue_emptyBuckets() {
        let result = MetricKitHelpers.medianValue(from: [])
        XCTAssertNil(result)
    }

    func test_medianValue_singleBucket() {
        let buckets: [(value: Double, count: Int)] = [(value: 200.0, count: 1)]
        let result = MetricKitHelpers.medianValue(from: buckets)
        XCTAssertEqual(result, 200.0)
    }

    func test_medianValue_oddTotalCount() {
        // 3 items: [100, 200, 300] → median index = 3/2 = 1 → value at index 1 = 200
        let buckets: [(value: Double, count: Int)] = [
            (value: 100.0, count: 1),
            (value: 200.0, count: 1),
            (value: 300.0, count: 1)
        ]
        let result = MetricKitHelpers.medianValue(from: buckets)
        XCTAssertEqual(result, 200.0)
    }

    func test_medianValue_evenTotalCount() {
        // 4 items: [100, 200, 300, 400] → median index = 4/2 = 2 → value at index 2 = 300
        let buckets: [(value: Double, count: Int)] = [
            (value: 100.0, count: 1),
            (value: 200.0, count: 1),
            (value: 300.0, count: 1),
            (value: 400.0, count: 1)
        ]
        let result = MetricKitHelpers.medianValue(from: buckets)
        XCTAssertEqual(result, 300.0)
    }

    func test_medianValue_multipleBucketsWeighted() {
        // Bucket 100 (count 5), 200 (count 3), 300 (count 2) → total 10
        // Median index = 10/2 = 5
        // Cumulative: bucket 100 → 5, passes index 5 → value = 100
        // Wait: cumulative 5 > 5? No. cumulative after bucket 200 → 8 > 5 → value = 200
        // Actually: after bucket 100, cumulative = 5, need > 5, so not yet.
        // After bucket 200, cumulative = 8 > 5 → median = 200
        let buckets: [(value: Double, count: Int)] = [
            (value: 100.0, count: 5),
            (value: 200.0, count: 3),
            (value: 300.0, count: 2)
        ]
        let result = MetricKitHelpers.medianValue(from: buckets)
        XCTAssertEqual(result, 200.0)
    }

    // MARK: - Format Metric Summary

    func test_formatMetricSummary_allFieldsPresent() {
        let summary = MetricKitHelpers.MetricSummary(
            date: Date(),
            launchTimeMs: 450.0,
            resumeTimeMs: 120.5,
            hangTimeMs: 300.0,
            peakMemoryMB: 85.3,
            cumulativeCPUSeconds: 12.7
        )
        let result = MetricKitHelpers.formatMetricSummary(summary)
        XCTAssertTrue(result.contains("launch=450.0ms"))
        XCTAssertTrue(result.contains("resume=120.5ms"))
        XCTAssertTrue(result.contains("hang=300.0ms"))
        XCTAssertTrue(result.contains("peakMem=85.3MB"))
        XCTAssertTrue(result.contains("cpu=12.7s"))
    }

    func test_formatMetricSummary_keyOrder() {
        let summary = MetricKitHelpers.MetricSummary(
            date: Date(),
            launchTimeMs: 1.0,
            resumeTimeMs: 2.0,
            hangTimeMs: 3.0,
            peakMemoryMB: 4.0,
            cumulativeCPUSeconds: 5.0
        )
        let result = MetricKitHelpers.formatMetricSummary(summary)
        let parts = result.components(separatedBy: " ")
        XCTAssertEqual(parts.count, 5)
        XCTAssertTrue(parts[0].hasPrefix("launch="))
        XCTAssertTrue(parts[1].hasPrefix("resume="))
        XCTAssertTrue(parts[2].hasPrefix("hang="))
        XCTAssertTrue(parts[3].hasPrefix("peakMem="))
        XCTAssertTrue(parts[4].hasPrefix("cpu="))
    }

    func test_formatMetricSummary_partialFields() {
        let summary = MetricKitHelpers.MetricSummary(
            date: Date(),
            launchTimeMs: 450.0,
            resumeTimeMs: nil,
            hangTimeMs: nil,
            peakMemoryMB: 85.0,
            cumulativeCPUSeconds: nil
        )
        let result = MetricKitHelpers.formatMetricSummary(summary)
        XCTAssertTrue(result.contains("launch=450.0ms"))
        XCTAssertTrue(result.contains("peakMem=85.0MB"))
        XCTAssertFalse(result.contains("resume"))
        XCTAssertFalse(result.contains("hang"))
        XCTAssertFalse(result.contains("cpu"))
    }

    func test_formatMetricSummary_allNil() {
        let summary = MetricKitHelpers.MetricSummary(
            date: Date(),
            launchTimeMs: nil,
            resumeTimeMs: nil,
            hangTimeMs: nil,
            peakMemoryMB: nil,
            cumulativeCPUSeconds: nil
        )
        let result = MetricKitHelpers.formatMetricSummary(summary)
        XCTAssertEqual(result, "no metrics")
    }

    // MARK: - Format Diagnostic Summary

    func test_formatDiagnosticSummary_withIssues() {
        let summary = MetricKitHelpers.DiagnosticSummary(
            date: Date(),
            crashCount: 2,
            hangCount: 0,
            diskWriteExceptionCount: 1,
            cpuExceptionCount: 0
        )
        let result = MetricKitHelpers.formatDiagnosticSummary(summary)
        XCTAssertTrue(result.contains("crashes=2"))
        XCTAssertTrue(result.contains("diskWrites=1"))
        XCTAssertFalse(result.contains("hangs"))
        XCTAssertFalse(result.contains("cpuExceptions"))
    }

    func test_formatDiagnosticSummary_allZero() {
        let summary = MetricKitHelpers.DiagnosticSummary(
            date: Date(),
            crashCount: 0,
            hangCount: 0,
            diskWriteExceptionCount: 0,
            cpuExceptionCount: 0
        )
        let result = MetricKitHelpers.formatDiagnosticSummary(summary)
        XCTAssertEqual(result, "no diagnostics")
    }

    func test_formatDiagnosticSummary_allNonZero_keyOrder() {
        let summary = MetricKitHelpers.DiagnosticSummary(
            date: Date(),
            crashCount: 1,
            hangCount: 2,
            diskWriteExceptionCount: 3,
            cpuExceptionCount: 4
        )
        let result = MetricKitHelpers.formatDiagnosticSummary(summary)
        let parts = result.components(separatedBy: " ")
        XCTAssertEqual(parts.count, 4)
        XCTAssertTrue(parts[0].hasPrefix("crashes="))
        XCTAssertTrue(parts[1].hasPrefix("hangs="))
        XCTAssertTrue(parts[2].hasPrefix("diskWrites="))
        XCTAssertTrue(parts[3].hasPrefix("cpuExceptions="))
    }

    // MARK: - Codable Round Trip

    func test_metricSummary_codableRoundTrip() throws {
        let original = MetricKitHelpers.MetricSummary(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            launchTimeMs: 450.0,
            resumeTimeMs: nil,
            hangTimeMs: 300.0,
            peakMemoryMB: 85.3,
            cumulativeCPUSeconds: nil
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MetricKitHelpers.MetricSummary.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func test_diagnosticSummary_codableRoundTrip() throws {
        let original = MetricKitHelpers.DiagnosticSummary(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            crashCount: 2,
            hangCount: 0,
            diskWriteExceptionCount: 1,
            cpuExceptionCount: 0
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MetricKitHelpers.DiagnosticSummary.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
