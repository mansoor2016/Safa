// MARK: - MetricKitSubscriber.swift
// PURPOSE: Receives MetricKit payloads and logs structured summaries via os.Logger
// DEPENDENCIES: MetricKit, Log

import MetricKit

final class MetricKitSubscriber: NSObject, MXMetricManagerSubscriber {

    // MARK: - Singleton

    static let shared = MetricKitSubscriber()
    private var hasRegistered = false

    private override init() {
        super.init()
    }

    // MARK: - Registration

    func register() {
        guard !hasRegistered else { return }
        MXMetricManager.shared.add(self)
        hasRegistered = true
        Log.metrics.info("MetricKit subscriber registered")
    }

    // MARK: - MXMetricManagerSubscriber

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            let summary = MetricKitHelpers.MetricSummary(
                date: payload.timeStampEnd,
                launchTimeMs: medianMs(from: payload.applicationLaunchMetrics?.histogrammedTimeToFirstDraw),
                resumeTimeMs: medianMs(from: payload.applicationLaunchMetrics?.histogrammedApplicationResumeTime),
                hangTimeMs: medianMs(from: payload.applicationResponsivenessMetrics?.histogrammedApplicationHangTime),
                peakMemoryMB: payload.memoryMetrics.map { $0.peakMemoryUsage.converted(to: .megabytes).value },
                cumulativeCPUSeconds: payload.cpuMetrics.map { $0.cumulativeCPUTime.converted(to: .seconds).value }
            )

            let formatted = MetricKitHelpers.formatMetricSummary(summary)
            guard formatted != "no metrics" else { continue }
            Log.metrics.info("Metrics: \(formatted, privacy: .public)")
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            let summary = MetricKitHelpers.DiagnosticSummary(
                date: payload.timeStampEnd,
                crashCount: payload.crashDiagnostics?.count ?? 0,
                hangCount: payload.hangDiagnostics?.count ?? 0,
                diskWriteExceptionCount: payload.diskWriteExceptionDiagnostics?.count ?? 0,
                cpuExceptionCount: payload.cpuExceptionDiagnostics?.count ?? 0
            )

            let formatted = MetricKitHelpers.formatDiagnosticSummary(summary)
            guard formatted != "no diagnostics" else { continue }

            if summary.crashCount > 0 {
                Log.metrics.error("Diagnostics: \(formatted, privacy: .public)")
            } else {
                Log.metrics.info("Diagnostics: \(formatted, privacy: .public)")
            }
        }
    }

    // MARK: - Private

    private func medianMs(from histogram: MXHistogram<UnitDuration>?) -> Double? {
        guard let histogram else { return nil }
        let buckets = collectBuckets(from: histogram.bucketEnumerator)
        return MetricKitHelpers.medianValue(from: buckets)
    }

    private func collectBuckets(from enumerator: NSEnumerator) -> [(value: Double, count: Int)] {
        var result: [(value: Double, count: Int)] = []
        while let bucket = enumerator.nextObject() as? MXHistogramBucket<UnitDuration> {
            let ms = bucket.bucketStart.converted(to: .milliseconds).value
            result.append((value: ms, count: bucket.bucketCount))
        }
        return result
    }
}
