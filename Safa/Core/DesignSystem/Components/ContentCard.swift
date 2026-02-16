// MARK: - ContentCard.swift
// PURPOSE: Generic card container for content sections
// DEPENDENCIES: SwiftUI

import SwiftUI

struct ContentCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(SafaSpacing.cardInsets)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
            .cardShadow()
    }
}

// MARK: - Titled Card Variant

struct TitledCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ContentCard {
            VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text(title)
                        .font(SafaTypography.titleMedium)
                        .foregroundColor(SafaColors.Fallback.text)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(SafaTypography.bodySmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }
                }

                content
            }
        }
    }
}

// MARK: - Interactive Card Variant

struct InteractiveCard<Content: View>: View {
    let action: () -> Void
    let content: Content

    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: {
            HapticFeedbackService.shared.play(.tap)
            action()
        }) {
            ContentCard {
                content
            }
        }
        .buttonStyle(CardButtonStyle())
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: SafaSpacing.md) {
            ContentCard {
                Text("Simple content card")
            }

            TitledCard(title: "Prayer Times", subtitle: "Today") {
                Text("Fajr: 5:30 AM")
            }

            InteractiveCard(action: { }) {
                HStack {
                    Text("Tap me")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
        }
        .padding()
    }
}
