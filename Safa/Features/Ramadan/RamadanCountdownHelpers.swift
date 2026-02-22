// MARK: - RamadanCountdownHelpers.swift
// PURPOSE: Testable pure-function helpers for Ramadan countdown display logic
// DEPENDENCIES: Foundation

import Foundation

enum RamadanCountdownHelpers {

    enum CountdownTarget: Equatable {
        case suhoor(time: Date)
        case iftar(time: Date)
        case nextSuhoor(time: Date)
        case complete
    }

    /// Determines which countdown to show based on current time and prayer times.
    /// Rule: Suhoor is checked first because before Suhoor ends, both Suhoor and Iftar
    /// are in the future. Showing "until Iftar" before Suhoor is misleading.
    /// After both pass, estimates tomorrow's suhoor (~24h after today's) for a subdued countdown.
    static func resolveTarget(
        now: Date,
        suhoorTime: Date?,
        iftarTime: Date?
    ) -> CountdownTarget {
        if let suhoor = suhoorTime, suhoor > now {
            return .suhoor(time: suhoor)
        }
        if let iftar = iftarTime, iftar > now {
            return .iftar(time: iftar)
        }
        if let suhoor = suhoorTime,
           let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: suhoor),
           tomorrow > now {
            return .nextSuhoor(time: tomorrow)
        }
        return .complete
    }
}
