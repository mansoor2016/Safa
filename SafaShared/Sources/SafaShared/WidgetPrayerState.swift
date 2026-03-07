// MARK: - WidgetPrayerState.swift
// PURPOSE: State machine for contextual lock screen widget content
// DEPENDENCIES: Foundation, PrayerTimeLogic

import Foundation

// MARK: - Widget Prayer State

/// Represents the contextual state a lock screen widget should display.
public enum WidgetPrayerState: Equatable, Sendable {
    /// Counting down to next prayer
    case preAdhan(prayerName: String, prayerTime: Date, prayerId: String)
    /// Prayer time has arrived, not yet logged (0–15 min grace window)
    case prayerWindow(prayerName: String, prayerTime: Date, prayerId: String)
    /// Grace window ended, prayer still not logged — gentle prompt (15–30 min)
    case gracePrompt(prayerName: String, prayerId: String)
    /// Prayer was logged — show spiritual content (up to 45 min after prayer time)
    case postPrayer(prayerId: String)
    /// All 5 prayers logged today
    case allComplete(streakCount: Int)
    /// All prayers past, some not logged — peaceful end-of-day
    case dayEnded
}

// MARK: - Constants

public extension PrayerTimeConstants {
    /// How long after grace ends to show "Log" prompt (15 additional minutes).
    static let gracePromptInterval: TimeInterval = 15 * 60
    /// How long after prayer time to show post-prayer spiritual content (45 minutes).
    static let postPrayerInterval: TimeInterval = 45 * 60
    /// If next prayer is within this threshold, show pre-adhan instead of post-prayer content.
    static let imminentThreshold: TimeInterval = 15 * 60
}

// MARK: - Resolver

public struct WidgetPrayerStateResolver {

    public init() {}

    /// Resolves the current widget state from prayer data.
    ///
    /// Resolution priority:
    /// 1. Grace window (0–15 min past): `.prayerWindow` if unlogged, `.postPrayer` if logged
    /// 2. Post-grace prompt (15–30 min past, unlogged): `.gracePrompt`
    /// 3. Post-prayer content (logged, up to 45 min past): `.postPrayer` — unless next prayer is imminent
    /// 4. Pre-adhan countdown to next future prayer: `.preAdhan`
    /// 5. All prayers past + all logged: `.allComplete`
    /// 6. All prayers past + some not logged: `.dayEnded`
    public static func resolve(
        prayers: [PrayerInfo],
        loggedPrayerIds: Set<String>,
        streakCount: Int,
        at now: Date
    ) -> WidgetPrayerState {
        // Find the most recently started prayer (time <= now, most recent first)
        let pastPrayers = prayers.filter { $0.time <= now }.reversed()
        let futurePrayers = prayers.filter { $0.time > now }
        let nextFuture = futurePrayers.first

        for prayer in pastPrayers {
            let elapsed = now.timeIntervalSince(prayer.time)
            let isLogged = loggedPrayerIds.contains(prayer.id)

            // 1. In grace window (0–15 min)
            if elapsed < PrayerTimeConstants.graceInterval {
                if isLogged {
                    return .postPrayer(prayerId: prayer.id)
                } else {
                    return .prayerWindow(prayerName: prayer.name, prayerTime: prayer.time, prayerId: prayer.id)
                }
            }

            // 2. Post-grace prompt (15–30 min, unlogged)
            let gracePromptEnd = PrayerTimeConstants.graceInterval + PrayerTimeConstants.gracePromptInterval
            if elapsed < gracePromptEnd && !isLogged {
                return .gracePrompt(prayerName: prayer.name, prayerId: prayer.id)
            }

            // 3. Post-prayer content (logged, up to 45 min) — skip if next prayer is imminent
            if elapsed < PrayerTimeConstants.postPrayerInterval && isLogged {
                if let next = nextFuture, next.time.timeIntervalSince(now) < PrayerTimeConstants.imminentThreshold {
                    // Next prayer is imminent — fall through to pre-adhan
                    break
                }
                return .postPrayer(prayerId: prayer.id)
            }

            // Past the 45 min window — stop checking older prayers
            break
        }

        // 4. Pre-adhan countdown
        if let next = nextFuture {
            return .preAdhan(prayerName: next.name, prayerTime: next.time, prayerId: next.id)
        }

        // 5. All prayers past — check completion
        let obligatoryIds = Set(prayers.map { $0.id })
        if !obligatoryIds.isEmpty && obligatoryIds.isSubset(of: loggedPrayerIds) {
            return .allComplete(streakCount: streakCount)
        }

        // 6. Day ended, some not logged
        return .dayEnded
    }
}

// MARK: - Snippet & Deep Link Resolution

/// Pure function for resolving snippet content and deep link URL for a given widget state.
/// Shared between widget extension and main app tests.
public enum WidgetSnippetResolver {

    public typealias SnippetData = (arabic: String, translation: String, reference: String, prayerId: String, deepLink: String)
    public typealias ResolvedContent = (snippetArabic: String?, snippetTranslation: String?, snippetReference: String?, deepLink: String)

    /// Returns snippet content and deep link based on state.
    /// Returns nil snippets if state isn't `.postPrayer` or snippet prayerId doesn't match.
    public static func resolve(
        state: WidgetPrayerState,
        snippet: SnippetData?
    ) -> ResolvedContent {
        switch state {
        case .postPrayer(let prayerId):
            if snippet?.prayerId == prayerId {
                return (snippet?.arabic, snippet?.translation, snippet?.reference, snippet?.deepLink ?? "safa://quran")
            } else {
                return (nil, nil, nil, "safa://prayer")
            }

        case .allComplete:
            return (nil, nil, nil, "safa://dhikr")

        case .preAdhan, .prayerWindow, .gracePrompt, .dayEnded:
            return (nil, nil, nil, "safa://prayer")
        }
    }
}

// MARK: - Timeline Boundary Extensions

public extension NextPrayerCalculator {
    /// Generate timeline boundaries that include post-prayer content expiry.
    /// Adds boundaries at prayer.time + 30m (grace prompt end) and prayer.time + 45m (post-prayer end)
    /// in addition to the standard grace boundaries.
    func contextualTimelineBoundaries(from prayers: [PrayerInfo], startingAt now: Date) -> [Date] {
        var dates: Set<Date> = [now]

        for prayer in prayers {
            // Standard boundaries
            dates.insert(prayer.time)
            dates.insert(prayer.time.addingTimeInterval(PrayerTimeConstants.graceInterval))
            // Extended boundaries for contextual states
            dates.insert(prayer.time.addingTimeInterval(
                PrayerTimeConstants.graceInterval + PrayerTimeConstants.gracePromptInterval
            ))
            dates.insert(prayer.time.addingTimeInterval(PrayerTimeConstants.postPrayerInterval))
        }

        // Filter to future dates (or now) and sort
        return dates.filter { $0 >= now }.sorted()
    }
}
