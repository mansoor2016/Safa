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
                .modifier(ScrollGeometryChangeModifier(scrolledPastThreshold: $scrolledPastThreshold))
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .modifier(ToolbarVisibilityModifier(scrolledPastThreshold: scrolledPastThreshold))
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

// MARK: - iOS 18+ Availability Wrappers

/// Wraps `onScrollGeometryChange` which requires iOS 18+.
/// On iOS 17, the toolbar stays visible (no scroll-based morph).
private struct ScrollGeometryChangeModifier: ViewModifier {
    @Binding var scrolledPastThreshold: Bool

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y > 50
                } action: { _, isPast in
                    scrolledPastThreshold = isPast
                }
        } else {
            content
        }
    }
}

/// Wraps `toolbarBackgroundVisibility` which requires iOS 18+.
/// On iOS 17, the toolbar material is always visible.
private struct ToolbarVisibilityModifier: ViewModifier {
    let scrolledPastThreshold: Bool

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .toolbarBackgroundVisibility(scrolledPastThreshold ? .visible : .hidden, for: .navigationBar)
        } else {
            content
        }
    }
}
