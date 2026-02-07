// MARK: - AnalyticsService.swift
// PURPOSE: Privacy-safe product observability for quality measurement
// DEPENDENCIES: Foundation

import Foundation

// MARK: - Analytics Event

struct AnalyticsEvent {
    let name: String
    let flow: String
    let context: [String: String]
    let result: EventResult
    let durationMs: Int?
    let timestamp: Date

    enum EventResult: String {
        case success
        case failure
        case fallback
    }

    init(
        name: String,
        flow: String,
        context: [String: String] = [:],
        result: EventResult = .success,
        durationMs: Int? = nil
    ) {
        self.name = name
        self.flow = flow
        self.context = context
        self.result = result
        self.durationMs = durationMs
        self.timestamp = Date()
    }
}

// MARK: - Standard Events

extension AnalyticsEvent {
    static func prayerLogged(prayer: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "prayer_logged", flow: "prayer", context: ["prayer": prayer])
    }

    static func quranResumed(surah: Int, ayah: Int) -> AnalyticsEvent {
        AnalyticsEvent(name: "quran_resumed", flow: "quran", context: ["surah": "\(surah)", "ayah": "\(ayah)"])
    }

    static func dhikrCompleted(phrase: String, count: Int) -> AnalyticsEvent {
        AnalyticsEvent(name: "dhikr_completed", flow: "dhikr", context: ["phrase": phrase, "count": "\(count)"])
    }

    static func onboardingCompleted(durationMs: Int) -> AnalyticsEvent {
        AnalyticsEvent(name: "onboarding_completed", flow: "onboarding", durationMs: durationMs)
    }

    static func locationFallback(location: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "location_fallback", flow: "location", context: ["fallback": location], result: .fallback)
    }

    static func notificationFailed(prayer: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "notification_failed", flow: "notification", context: ["prayer": prayer], result: .failure)
    }

    static func syncFallback(reason: String) -> AnalyticsEvent {
        AnalyticsEvent(name: "sync_fallback", flow: "sync", context: ["reason": reason], result: .fallback)
    }
}

// MARK: - Analytics Service

/// Privacy-safe analytics service. Never logs religious content, private notes, or AI prompts.
final class AnalyticsService {
    static let shared = AnalyticsService()

    private var events: [AnalyticsEvent] = []
    private let maxBufferSize = 100

    private init() {}

    /// Record an event. Events are buffered locally.
    func track(_ event: AnalyticsEvent) {
        events.append(event)
        if events.count > maxBufferSize {
            events.removeFirst(events.count - maxBufferSize)
        }
    }

    /// Get buffered events (for debugging/export).
    func getEvents() -> [AnalyticsEvent] {
        events
    }

    /// Clear event buffer.
    func clear() {
        events.removeAll()
    }

    /// Event count for a specific flow.
    func count(flow: String) -> Int {
        events.filter { $0.flow == flow }.count
    }

    /// Failure rate for a specific flow.
    func failureRate(flow: String) -> Double {
        let flowEvents = events.filter { $0.flow == flow }
        guard !flowEvents.isEmpty else { return 0 }
        let failures = flowEvents.filter { $0.result == .failure || $0.result == .fallback }.count
        return Double(failures) / Double(flowEvents.count)
    }
}
