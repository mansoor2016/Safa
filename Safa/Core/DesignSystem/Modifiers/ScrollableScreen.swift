// MARK: - ScrollableScreen.swift
// PURPOSE: Reusable scroll container with nav bar material morph on scroll
// DEPENDENCIES: SwiftUI

import SwiftUI

/// A ScrollView wrapper that transitions the navigation bar from transparent to
/// frosted material as the user scrolls past a threshold (~50pt).
/// Optionally shows sticky content in the toolbar when scrolled past threshold.
/// Respects Reduce Motion accessibility setting.
struct ScrollableScreen<Content: View, StickyContent: View>: View {
    @ViewBuilder let content: () -> Content
    let stickyContent: (() -> StickyContent)?

    init(
        stickyContent: @escaping () -> StickyContent,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.stickyContent = stickyContent
        self.content = content
    }

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
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackgroundVisibility(scrolledPastThreshold ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            if scrolledPastThreshold, let stickyContent {
                ToolbarItem(placement: .principal) {
                    stickyContent()
                        .transition(.opacity)
                }
            }
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.2),
            value: scrolledPastThreshold
        )
    }
}

// MARK: - Convenience Init (No Sticky Content)

extension ScrollableScreen where StickyContent == EmptyView {
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.stickyContent = nil
    }
}
