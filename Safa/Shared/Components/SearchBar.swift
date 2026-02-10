// MARK: - SearchBar.swift
// PURPOSE: Reusable search bar component used across Quran, Hadith, Dua, Names, Calendar
// DEPENDENCIES: SwiftUI, DesignSystem

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var onSubmit: (() -> Void)? = nil
    var onClear: (() -> Void)? = nil

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(SafaColors.Fallback.secondaryText)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button {
                    text = ""
                    onClear?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }
            }
        }
        .padding(SafaSpacing.sm)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
        .padding()
    }
}
