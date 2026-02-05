// MARK: - Spacing.swift
// PURPOSE: Design system spacing and layout constants for the Safa app
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Spacing

enum SafaSpacing {
    // MARK: - Base Unit
    static let unit: CGFloat = 4

    // MARK: - Standard Spacing
    static let xxs: CGFloat = unit // 4
    static let xs: CGFloat = unit * 2 // 8
    static let sm: CGFloat = unit * 3 // 12
    static let md: CGFloat = unit * 4 // 16
    static let lg: CGFloat = unit * 6 // 24
    static let xl: CGFloat = unit * 8 // 32
    static let xxl: CGFloat = unit * 12 // 48

    // MARK: - Content Insets
    static let contentInsets = EdgeInsets(
        top: md,
        leading: md,
        bottom: md,
        trailing: md
    )

    static let cardInsets = EdgeInsets(
        top: md,
        leading: md,
        bottom: md,
        trailing: md
    )

    static let listInsets = EdgeInsets(
        top: xs,
        leading: md,
        bottom: xs,
        trailing: md
    )

    // MARK: - Corner Radius
    enum CornerRadius {
        static let none: CGFloat = 0
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let full: CGFloat = 9999
    }

    // MARK: - Icon Sizes
    enum IconSize {
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 24
        static let lg: CGFloat = 32
        static let xl: CGFloat = 48
        static let xxl: CGFloat = 64
    }

    // MARK: - Button Heights
    enum ButtonHeight {
        static let sm: CGFloat = 32
        static let md: CGFloat = 44
        static let lg: CGFloat = 56
    }

    // MARK: - Card Sizes
    enum CardSize {
        static let smallHeight: CGFloat = 80
        static let mediumHeight: CGFloat = 120
        static let largeHeight: CGFloat = 180
    }
}

// MARK: - Layout Helpers

extension View {
    func safaPadding(_ edges: Edge.Set = .all, _ amount: CGFloat = SafaSpacing.md) -> some View {
        padding(edges, amount)
    }

    func safaContentPadding() -> some View {
        padding(SafaSpacing.contentInsets)
    }

    func safaCardPadding() -> some View {
        padding(SafaSpacing.cardInsets)
    }

    func safaCornerRadius(_ radius: CGFloat = SafaSpacing.CornerRadius.md) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

// MARK: - Spacing Stack Extension

// Note: Default spacing extensions removed to avoid infinite recursion.
// Use VStack(spacing: SafaSpacing.md) or HStack(spacing: SafaSpacing.md) explicitly.
