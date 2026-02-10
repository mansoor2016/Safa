// MARK: - LoadingView.swift
// PURPOSE: Loading state view component
// DEPENDENCIES: SwiftUI

import SwiftUI

struct LoadingView: View {
    let message: String?

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: SafaSpacing.md) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))

            if let message = message {
                Text(message)
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Full Screen Loading

struct FullScreenLoadingView: View {
    let message: String?

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            LoadingView(message: message)
        }
    }
}

// MARK: - Overlay Loading

struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let message: String?

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)

            if isLoading {
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()

                ContentCard {
                    LoadingView(message: message)
                        .frame(width: 150, height: 150)
                }
            }
        }
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: SafaSpacing.xl) {
        LoadingView(message: "Loading prayers...")

        Divider()

        Text("Content behind overlay")
            .frame(maxWidth: .infinity, maxHeight: 200)
            .background(Color.gray.opacity(0.2))
            .loadingOverlay(isLoading: true, message: "Please wait...")
    }
    .padding()
}
