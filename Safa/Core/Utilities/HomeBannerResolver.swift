// MARK: - HomeBannerResolver.swift
// PURPOSE: Pure-function resolver for Home screen banner visibility decisions
// DEPENDENCIES: Foundation, EidType

import Foundation

struct HomeBannerResolver {

    // MARK: - Input Types

    struct IslamicCalendarState {
        let isRamadan: Bool
        let currentRamadanDay: Int
        let isLastTenNights: Bool
        let daysUntilRamadan: Int?
        let currentEidType: EidType?
        let eidDayNumber: Int
        let nextEidType: EidType?
        let daysUntilNextEid: Int?
        let isForceRamadanMode: Bool
        let isForceEidAlFitr: Bool
        let isForceEidAlAdha: Bool
    }

    struct DismissState {
        let isRamadanBannerDismissedToday: Bool
        let isEidBannerDismissedToday: Bool
        let isShareBannerDismissedPermanently: Bool
        let isResumeCardDismissedToday: Bool
    }

    struct QuranState {
        let lastSurah: Int
        let lastAyah: Int
    }

    // MARK: - Output Types

    enum RamadanBannerVisibility: Equatable {
        case hidden
        case duringRamadan(day: Int, isLastTenNights: Bool)
        case preRamadan(daysUntil: Int)
    }

    enum EidBannerVisibility: Equatable {
        case hidden
        case duringEid(type: EidType, dayNumber: Int)
        case preEid(type: EidType, daysUntil: Int)
    }

    enum ShareBannerVisibility: Equatable {
        case hidden
        case visible
    }

    enum ResumeCardVisibility: Equatable {
        case hidden
        case visible(lastSurah: Int, lastAyah: Int)
    }

    enum SupportCardVisibility: Equatable {
        case hidden
        case visible
    }

    struct SupportCardState {
        let isEligibleThisSession: Bool
        let isDismissedThisSession: Bool
        let hasActiveSubscription: Bool
        let isDebugForced: Bool
    }

    // MARK: - Resolve Methods

    static func resolveRamadanBanner(
        calendar: IslamicCalendarState,
        dismiss: DismissState
    ) -> RamadanBannerVisibility {
        if dismiss.isRamadanBannerDismissedToday {
            return .hidden
        }

        // Force Ramadan mode OR natural Ramadan
        if calendar.isForceRamadanMode || calendar.isRamadan {
            let day = max(calendar.currentRamadanDay, 1)
            let lastTen = day >= 21 && day <= 30
            return .duringRamadan(day: day, isLastTenNights: lastTen)
        }

        // Pre-Ramadan countdown (1-30 days)
        if let daysUntil = calendar.daysUntilRamadan,
           daysUntil >= 1 && daysUntil <= 30 {
            return .preRamadan(daysUntil: daysUntil)
        }

        return .hidden
    }

    static func resolveEidBanner(
        calendar: IslamicCalendarState,
        dismiss: DismissState
    ) -> EidBannerVisibility {
        if dismiss.isEidBannerDismissedToday {
            return .hidden
        }

        // Force Eid flags (Fitr takes precedence if both set)
        if calendar.isForceEidAlFitr {
            return .duringEid(type: .fitr, dayNumber: 1)
        }
        if calendar.isForceEidAlAdha {
            return .duringEid(type: .adha, dayNumber: 1)
        }

        // Natural Eid period
        if let eidType = calendar.currentEidType {
            return .duringEid(type: eidType, dayNumber: max(calendar.eidDayNumber, 1))
        }

        // Pre-Eid countdown (1-7 days)
        if let eidType = calendar.nextEidType,
           let daysUntil = calendar.daysUntilNextEid,
           daysUntil >= 1 && daysUntil <= 7 {
            return .preEid(type: eidType, daysUntil: daysUntil)
        }

        return .hidden
    }

    static func resolveShareBanner(
        dismiss: DismissState
    ) -> ShareBannerVisibility {
        dismiss.isShareBannerDismissedPermanently ? .hidden : .visible
    }

    static func resolveSupportCard(
        support: SupportCardState
    ) -> SupportCardVisibility {
        if support.isDebugForced && !support.isDismissedThisSession { return .visible }
        if support.isDismissedThisSession { return .hidden }
        if support.hasActiveSubscription { return .hidden }
        if !support.isEligibleThisSession { return .hidden }
        return .visible
    }

    // MARK: - Community Card

    enum CommunityCardMode: Equatable {
        case hidden
        case shareOnly
        case supportOnly
        case shareAndSupport
        case thankYouWithShare
        case thankYou
    }

    static func resolveCommunityCard(
        shareVisible: Bool,
        supportVisible: Bool,
        isSubscriber: Bool
    ) -> CommunityCardMode {
        if isSubscriber {
            return shareVisible ? .thankYouWithShare : .thankYou
        }
        switch (shareVisible, supportVisible) {
        case (true, true):   return .shareAndSupport
        case (true, false):  return .shareOnly
        case (false, true):  return .supportOnly
        case (false, false): return .hidden
        }
    }

    static func resolveResumeCard(
        quran: QuranState,
        dismiss: DismissState
    ) -> ResumeCardVisibility {
        if quran.lastSurah == 0 || dismiss.isResumeCardDismissedToday {
            return .hidden
        }
        return .visible(lastSurah: quran.lastSurah, lastAyah: quran.lastAyah)
    }
}
