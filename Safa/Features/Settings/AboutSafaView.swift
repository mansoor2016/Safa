// MARK: - AboutSafaView.swift
// PURPOSE: Heartfelt about page explaining why Safa was made
// DEPENDENCIES: SwiftUI

import SwiftUI

struct AboutSafaView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // App icon + name
                VStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.accentColor)

                    Text("Safa")
                        .font(.largeTitle.weight(.bold))

                    Text("صفا")
                        .font(.system(size: 28, weight: .medium, design: .serif))
                        .foregroundStyle(.secondary)

                    Text("Purity · Clarity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                // Mission
                VStack(spacing: 16) {
                    Text("Safa is a comprehensive Islamic companion app designed with privacy, simplicity, and intelligence at its core.")
                        .font(.body)
                        .multilineTextAlignment(.center)

                    Text("No ads. No clutter. No tracking.")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)

                    Text("Just you and your faith.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                // Why
                VStack(alignment: .leading, spacing: 12) {
                    Text("I built Safa because I couldn't find an Islamic app I actually enjoyed using. Free, private, and made with care.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // Closing
                Text("Bismillah. May Safa be a means of benefit for you in this life and the next.")
                    .font(.subheadline)
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .navigationTitle("About Safa")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutSafaView()
    }
}
