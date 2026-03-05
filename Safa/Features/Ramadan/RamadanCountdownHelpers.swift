// MARK: - RamadanCountdownHelpers.swift
// PURPOSE: Testable pure-function helpers for Ramadan countdown display logic
// DEPENDENCIES: Foundation

import Foundation
import SafaShared

enum RamadanCountdownHelpers {

    /// Suhoor grace: 15 min (you've stopped eating, brief acknowledgement).
    static let suhoorGraceDefault = PrayerTimeConstants.graceInterval // 15 min

    /// Iftar grace: 30 min (you're breaking fast and eating a meal).
    static let iftarGraceDefault: TimeInterval = 30 * 60

    enum CountdownTarget: Equatable {
        case suhoor(time: Date)
        /// Suhoor time has arrived — show "It's Suhoor time!" with no countdown.
        /// Payload-free by design: no UI consumes an end time, and carrying dead data
        /// would invite bugs if the grace interval changes without updating callers.
        case suhoorGrace
        case iftar(time: Date)
        /// Iftar time has arrived — show "It's Iftar time!" with no countdown.
        /// Payload-free for the same reason as `suhoorGrace`.
        case iftarGrace
        case nextSuhoor(time: Date)
        case complete
    }

    /// Determines which countdown to show based on current time and prayer times.
    ///
    /// Rule: Suhoor is checked first because before Suhoor ends, both Suhoor and Iftar
    /// are in the future. Showing "until Iftar" before Suhoor is misleading.
    /// After both pass, estimates tomorrow's suhoor (~24h after today's) for a subdued countdown.
    ///
    /// Grace windows use the same half-open `[time, time + grace)` semantics as
    /// `isPrayerTimeNow` — the canonical definition of "grace window" in `PrayerTimeLogic`.
    /// Suhoor and iftar have separate grace durations: suhoor is brief (stop eating),
    /// iftar is longer (break fast and eat a meal).
    static func resolveTarget(
        now: Date,
        suhoorTime: Date?,
        iftarTime: Date?,
        suhoorGraceInterval: TimeInterval = suhoorGraceDefault,
        iftarGraceInterval: TimeInterval = iftarGraceDefault
    ) -> CountdownTarget {
        // Before Suhoor -> countdown to Suhoor
        if let suhoor = suhoorTime, suhoor > now {
            return .suhoor(time: suhoor)
        }
        // Suhoor grace window: [suhoor, suhoor + grace)
        if let suhoor = suhoorTime {
            let elapsed = now.timeIntervalSince(suhoor)
            if elapsed >= 0 && elapsed < suhoorGraceInterval {
                return .suhoorGrace
            }
        }
        // Before Iftar -> countdown to Iftar
        if let iftar = iftarTime, iftar > now {
            return .iftar(time: iftar)
        }
        // Iftar grace window: [iftar, iftar + grace)
        if let iftar = iftarTime {
            let elapsed = now.timeIntervalSince(iftar)
            if elapsed >= 0 && elapsed < iftarGraceInterval {
                return .iftarGrace
            }
        }
        // After both + grace -> next suhoor tomorrow
        if let suhoor = suhoorTime,
           let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: suhoor),
           tomorrow > now {
            return .nextSuhoor(time: tomorrow)
        }
        return .complete
    }
}
