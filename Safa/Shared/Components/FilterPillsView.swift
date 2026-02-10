// MARK: - FilterPillsView.swift
// PURPOSE: Reusable horizontal scrolling filter pill bar
// DEPENDENCIES: SwiftUI

import SwiftUI

struct FilterPillsView<T: Hashable>: View {
    let options: [FilterOption<T>]
    @Binding var selected: T

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SafaSpacing.xs) {
                ForEach(options, id: \.value) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selected = option.value
                        }
                        HapticFeedbackService.shared.play(.selection)
                    } label: {
                        Text(option.label)
                            .font(SafaTypography.labelSmall)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selected == option.value ? Color.accentColor : Color(UIColor.secondarySystemBackground))
                            .foregroundColor(selected == option.value ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, SafaSpacing.xs)
        }
    }
}

struct FilterOption<T: Hashable> {
    let label: String
    let value: T
}
