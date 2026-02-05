// MARK: - View+Extensions.swift
// PURPOSE: SwiftUI View utilities and modifiers
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Conditional Modifiers

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func ifLet<T, Content: View>(_ optional: T?, transform: (Self, T) -> Content) -> some View {
        if let value = optional {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Layout Helpers

extension View {
    func frame(size: CGFloat) -> some View {
        frame(width: size, height: size)
    }

    func fillWidth(alignment: Alignment = .center) -> some View {
        frame(maxWidth: .infinity, alignment: alignment)
    }

    func fillHeight(alignment: Alignment = .center) -> some View {
        frame(maxHeight: .infinity, alignment: alignment)
    }

    func fillSpace(alignment: Alignment = .center) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
}

// MARK: - Navigation Helpers

extension View {
    func hideNavigationBar() -> some View {
        self
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Visibility

extension View {
    @ViewBuilder
    func hidden(_ isHidden: Bool) -> some View {
        if isHidden {
            hidden()
        } else {
            self
        }
    }

    @ViewBuilder
    func visible(_ isVisible: Bool) -> some View {
        if isVisible {
            self
        } else {
            hidden()
        }
    }
}

// MARK: - Haptic Feedback

extension View {
    func hapticFeedback(_ type: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: type)
            generator.impactOccurred()
        }
    }

    func hapticOnChange<Value: Equatable>(of value: Value, type: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onChange(of: value) { _, _ in
            let generator = UIImpactFeedbackGenerator(style: type)
            generator.impactOccurred()
        }
    }
}

// MARK: - Loading State

struct LoadingModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .opacity(isLoading ? 0.5 : 1)

            if isLoading {
                ProgressView()
            }
        }
    }
}

extension View {
    func loading(_ isLoading: Bool) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }
}

// MARK: - Shadow Helpers

extension View {
    func softShadow(
        color: Color = .black.opacity(0.1),
        radius: CGFloat = 10,
        x: CGFloat = 0,
        y: CGFloat = 4
    ) -> some View {
        shadow(color: color, radius: radius, x: x, y: y)
    }

    func cardShadow() -> some View {
        softShadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Border Helpers

extension View {
    func border(_ color: Color, width: CGFloat = 1, cornerRadius: CGFloat = 0) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, lineWidth: width)
        )
    }
}

// MARK: - Debug

extension View {
    func debugBorder(_ color: Color = .red) -> some View {
        #if DEBUG
        border(color, width: 1)
        #else
        self
        #endif
    }

    func debugBackground(_ color: Color = .red.opacity(0.2)) -> some View {
        #if DEBUG
        background(color)
        #else
        self
        #endif
    }
}
