// MARK: - EidGreetingCard.swift
// PURPOSE: Premium two-sided Eid greeting card rendered as a single image for sharing
// DEPENDENCIES: SwiftUI, EidType

import SwiftUI

struct EidGreetingCard: View {
    let eidType: EidType
    let message: String
    let hijriYear: Int

    private var frontGradient: [Color] {
        switch eidType {
        case .fitr: return [Color(red: 0.11, green: 0.37, blue: 0.13), Color(red: 0.0, green: 0.30, blue: 0.25)]
        case .adha: return [Color(red: 0.90, green: 0.32, blue: 0.0), Color(red: 0.75, green: 0.21, blue: 0.05)]
        }
    }

    private var backColor: Color {
        switch eidType {
        case .fitr: return Color(red: 0.95, green: 0.98, blue: 0.95)
        case .adha: return Color(red: 0.99, green: 0.96, blue: 0.92)
        }
    }

    private var backTextColor: Color {
        switch eidType {
        case .fitr: return Color(red: 0.11, green: 0.37, blue: 0.13)
        case .adha: return Color(red: 0.55, green: 0.22, blue: 0.0)
        }
    }

    private var accentColor: Color {
        switch eidType {
        case .fitr: return Color(red: 0.75, green: 0.88, blue: 0.75)
        case .adha: return Color(red: 0.95, green: 0.82, blue: 0.65)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            frontSide
            backSide
        }
        .frame(maxWidth: 350)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Front Side

    private var frontSide: some View {
        ZStack {
            LinearGradient(
                colors: frontGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            geometricPattern
                .opacity(0.05)

            VStack(spacing: 20) {
                decorativeStars

                Text("EID MUBARAK")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .tracking(4)
                    .foregroundColor(.white)

                Text("\u{0639}\u{064A}\u{062F} \u{0645}\u{0628}\u{0627}\u{0631}\u{0643}")
                    .font(.system(size: 32, weight: .regular, design: .serif))
                    .foregroundColor(.white.opacity(0.9))

                ornamentalDivider()

                Text("\(eidType.displayName) \(hijriYear) AH")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 50)
        }
        .frame(height: 380)
    }

    // MARK: - Back Side

    private var backSide: some View {
        ZStack {
            backColor

            VStack(spacing: 16) {
                Spacer()

                Text(message)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundColor(backTextColor)
                    .padding(.horizontal, 30)

                Text(eidType.acceptanceDuaArabic)
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundColor(backTextColor.opacity(0.8))
                    .environment(\.layoutDirection, .rightToLeft)
                    .accessibilityArabic()

                ornamentalDivider(color: backTextColor.opacity(0.3))

                VStack(spacing: 4) {
                    Text("\u{0635}\u{0641}\u{0627} \u{00B7} Safa")
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundColor(backTextColor.opacity(0.6))

                    Text("Your Islamic Companion")
                        .font(.system(size: 11, weight: .regular, design: .serif))
                        .foregroundColor(backTextColor.opacity(0.4))
                }

                Spacer()
            }
            .padding(.vertical, 30)
        }
        .frame(height: 300)
    }

    // MARK: - Decorative Elements

    private var decorativeStars: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 8))
            Image(systemName: "star.fill")
                .font(.system(size: 12))
            Image(systemName: "star.fill")
                .font(.system(size: 8))
        }
        .foregroundColor(.white.opacity(0.6))
    }

    private func ornamentalDivider(color: Color = .white.opacity(0.4)) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(color)
                .frame(width: 40, height: 1)
            Image(systemName: "star.fill")
                .font(.system(size: 6))
                .foregroundColor(color)
            Rectangle()
                .fill(color)
                .frame(width: 40, height: 1)
        }
    }

    private var geometricPattern: some View {
        Canvas { context, size in
            let spacing: CGFloat = 30
            for x in stride(from: 0, through: size.width, by: spacing) {
                for y in stride(from: 0, through: size.height, by: spacing) {
                    let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                    let path = Path { p in
                        p.addEllipse(in: rect)
                    }
                    context.fill(path, with: .color(.white))
                }
            }
        }
    }
}

// MARK: - Card Rendering

extension EidGreetingCard {
    /// Renders the card as a UIImage at 2x scale for crisp sharing
    @MainActor
    func renderImage() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = 2.0
        return renderer.uiImage
    }
}

// MARK: - Preview

#Preview("Eid Greeting Card - Fitr") {
    ScrollView {
        EidGreetingCard(
            eidType: .fitr,
            message: "Wishing you and your family a joyous Eid al-Fitr! May the blessings of Ramadan continue throughout the year.",
            hijriYear: 1447
        )
        .padding()
    }
}

#Preview("Eid Greeting Card - Adha") {
    ScrollView {
        EidGreetingCard(
            eidType: .adha,
            message: "Wishing you a blessed Eid al-Adha! May the spirit of sacrifice bring you closer to Allah.",
            hijriYear: 1447
        )
        .padding()
    }
}
