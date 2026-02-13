// MARK: - LaunchStateResolver.swift
// PURPOSE: Determines initial app launch state, testable without SwiftUI
// DEPENDENCIES: Foundation

import Foundation

enum LaunchState: Equatable {
    case loading
    case onboarding
    case ready
}

enum LaunchStateResolver {

    /// Resolves the launch state from environment and saved preferences.
    static func resolve(isUITesting: Bool, hasCompletedOnboarding: Bool) -> LaunchState {
        if isUITesting { return .ready }
        return hasCompletedOnboarding ? .ready : .onboarding
    }
}
