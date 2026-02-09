// MARK: - SheetModifiers.swift
// PURPOSE: Standardized bottom sheet presentation modifiers
// DEPENDENCIES: SwiftUI

import SwiftUI

extension View {
    /// Compact sheet for pickers, simple dialogs, and confirmations.
    /// Half-screen with drag indicator.
    func compactSheet() -> some View {
        self
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(SafaSpacing.CornerRadius.xl)
    }

    /// Full sheet for NavigationStack content, scrollable lists, and detail views.
    /// Half-to-full-screen with drag indicator.
    func fullSheet() -> some View {
        self
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(SafaSpacing.CornerRadius.xl)
    }
}
