// MARK: - ScrollableScreen.swift
// PURPOSE: Reusable scroll container with nav bar material morph on scroll
// DEPENDENCIES: SwiftUI

import SwiftUI

/// A ScrollView wrapper that transitions the navigation bar from transparent to
/// frosted material as the user scrolls past a threshold (~50pt).
/// Respects Reduce Motion accessibility setting.
struct ScrollableScreen<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @State private var scrolledPastThreshold = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            content()
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y > 50
                } action: { _, isPast in
                    scrolledPastThreshold = isPast
                }
        }
        .toolbarBackground(
            scrolledPastThreshold ? Material.ultraThin : Material.regular,
            for: .navigationBar
        )
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.2),
            value: scrolledPastThreshold
        )
    }
}
