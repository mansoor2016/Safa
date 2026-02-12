// MARK: - AdaptiveTabBarModifier.swift
// PURPOSE: Hide tab bar on deliberate downward scroll, reveal on upward intent
// DEPENDENCIES: SwiftUI
// FEATURE FLAG: .adaptiveTabBar (OFF by default)

import SwiftUI

struct AdaptiveTabBarModifier: ViewModifier {
    @State private var tabBarVisible = true
    @State private var lastScrollOffset: CGFloat = 0

    var isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            if #available(iOS 18.0, *) {
                content
                    .toolbar(tabBarVisible ? .visible : .hidden, for: .tabBar)
                    .animation(.easeInOut(duration: 0.25), value: tabBarVisible)
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.y
                    } action: { oldValue, newValue in
                        let delta = newValue - oldValue

                        // Only react to meaningful scrolls (ignore tiny jitter)
                        guard abs(delta) > 5 else { return }

                        if delta > 0 {
                            // Scrolling down — hide tab bar
                            tabBarVisible = false
                        } else {
                            // Scrolling up — show tab bar
                            tabBarVisible = true
                        }
                    }
            } else {
                // iOS 17: tab bar always visible (no scroll-based hiding)
                content
            }
        } else {
            content
        }
    }
}

extension View {
    func adaptiveTabBar() -> some View {
        modifier(AdaptiveTabBarModifier(
            isEnabled: FeatureFlags.shared.isEnabled(.adaptiveTabBar)
        ))
    }
}
