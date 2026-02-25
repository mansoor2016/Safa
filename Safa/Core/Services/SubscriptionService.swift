// MARK: - SubscriptionService.swift
// PURPOSE: StoreKit 2 wrapper for voluntary support subscriptions
// DEPENDENCIES: StoreKit, UIKit

import StoreKit
import UIKit

@MainActor @Observable
final class SubscriptionService {
    // MARK: - Shared Instance

    /// Singleton to avoid duplicate `Transaction.updates` listeners from dual Dependencies pattern.
    static let shared = SubscriptionService()

    static let groupID = "PLACEHOLDER" // Set after App Store Connect setup
    static let productIDs: Set<String> = [
        "com.safa.support.monthly",
        "com.safa.support.annual"
    ]

    // MARK: - Published State

    private(set) var hasActiveSubscription = false

    /// Guard for prompt timing — must be true before evaluating subscription status.
    private(set) var entitlementsInitialized = false

    private(set) var isLoading = false

    // MARK: - Private

    private var updateListenerTask: Task<Void, Never>?

    // MARK: - Init

    /// Singleton — never deinits, so no cancellation needed.
    private init() {
        updateListenerTask = listenForTransactions()
        Task { await checkCurrentEntitlements() }
    }

    // MARK: - Public Methods

    /// Checks current entitlements and updates subscription state.
    func checkCurrentEntitlements() async {
        var foundActive = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if Self.productIDs.contains(transaction.productID) {
                foundActive = true
                break
            }
        }

        let wasActive = hasActiveSubscription
        let wasInitialized = entitlementsInitialized
        hasActiveSubscription = foundActive
        entitlementsInitialized = true

        let effects = Self.resolveEntitlementEffects(
            foundActive: foundActive, wasActive: wasActive, wasInitialized: wasInitialized
        )

        if effects.showThankYouToast {
            ToastService.shared.show(Toast(message: "Thank you for supporting Safa!", type: .success))
        }

        if effects.shouldRevertIcon {
            let currentIcon = UIApplication.shared.alternateIconName
            if currentIcon != nil {
                try? await UIApplication.shared.setAlternateIconName(nil)
            }
        }
    }

    /// Syncs with the App Store and refreshes entitlements.
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        try? await AppStore.sync()
        await checkCurrentEntitlements()
    }

    // MARK: - Decision Logic

    /// Pure function for testability — determines side effects of an entitlement check.
    nonisolated static func resolveEntitlementEffects(
        foundActive: Bool,
        wasActive: Bool,
        wasInitialized: Bool
    ) -> (showThankYouToast: Bool, shouldRevertIcon: Bool) {
        let showToast = foundActive && !wasActive && wasInitialized
        let revertIcon = !foundActive && wasActive
        return (showToast, revertIcon)
    }

    // MARK: - Private Methods

    private func listenForTransactions() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                guard Self.productIDs.contains(transaction.productID) else { continue }
                await transaction.finish()
                await checkCurrentEntitlements()
            }
        }
    }
}
