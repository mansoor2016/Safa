// MARK: - ReviewPromptView.swift
// PURPOSE: Translucent overlay card for collecting app ratings and feedback
// DEPENDENCIES: SwiftUI, StoreKit, AppReviewService, ToastService

import SwiftUI

struct ReviewPromptView: View {
    // MARK: - Environment
    @Environment(\.openURL) private var openURL

    // MARK: - Binding
    @Binding var isPresented: Bool

    // MARK: - State
    @State private var rating: Int = 0
    @State private var feedbackText: String = ""
    @State private var dontAskAgain: Bool = false
    @FocusState private var isTextEditorFocused: Bool

    // MARK: - Body
    var body: some View {
        ZStack {
            dimmedBackground
            card
        }
        .animation(.easeInOut(duration: AppConstants.Timing.animationDuration), value: isPresented)
    }

    // MARK: - Subviews

    private var dimmedBackground: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture { dismiss() }
    }

    private var card: some View {
        VStack(spacing: SafaSpacing.lg) {
            header
            starRating
            textEditor
            optOutCheckbox
            submitButton
        }
        .padding(SafaSpacing.lg)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.xl))
        .elevation(.high)
        .padding(.horizontal, SafaSpacing.lg)
    }

    private var header: some View {
        VStack(spacing: SafaSpacing.xs) {
            Text("Rate Safa")
                .font(SafaTypography.titleLarge)
                .foregroundStyle(SafaColors.Fallback.text)

            Text("How are you enjoying Safa?")
                .font(SafaTypography.bodyMedium)
                .foregroundStyle(SafaColors.Fallback.secondaryText)
        }
    }

    private var starRating: some View {
        HStack(spacing: SafaSpacing.sm) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundStyle(star <= rating ? .accentColor : SafaColors.Fallback.tertiaryText)
                    .onTapGesture { rating = star }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: rating)
    }

    private var textEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $feedbackText)
                .font(SafaTypography.bodyMedium)
                .frame(height: 80)
                .focused($isTextEditorFocused)
                .scrollContentBackground(.hidden)
                .padding(SafaSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md)
                        .fill(SafaColors.Fallback.tertiaryBackground)
                )

            if feedbackText.isEmpty && !isTextEditorFocused {
                Text("Tell us more...")
                    .font(SafaTypography.bodyMedium)
                    .foregroundStyle(SafaColors.Fallback.tertiaryText)
                    .padding(.horizontal, SafaSpacing.sm)
                    .padding(.vertical, SafaSpacing.sm)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private var optOutCheckbox: some View {
        if AppReviewService.promptCount() >= 1 {
            Button {
                dontAskAgain.toggle()
            } label: {
                HStack(spacing: SafaSpacing.xs) {
                    Image(systemName: dontAskAgain ? "checkmark.square.fill" : "square")
                        .foregroundStyle(dontAskAgain ? .accentColor : SafaColors.Fallback.tertiaryText)
                    Text("Don't ask again")
                        .font(SafaTypography.bodySmall)
                        .foregroundStyle(SafaColors.Fallback.secondaryText)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var submitButton: some View {
        Button {
            submitFeedback()
        } label: {
            Text("Submit")
                .font(SafaTypography.labelLarge)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: SafaSpacing.ButtonHeight.md)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
        }
        .disabled(rating == 0)
        .opacity(rating == 0 ? 0.5 : 1)
    }

    // MARK: - Actions

    private func submitFeedback() {
        let currentRating = rating
        let text = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)

        AppReviewService.optOut()

        ToastService.shared.show(Toast(
            message: "Thank you for your feedback!",
            type: .success
        ))

        if !text.isEmpty {
            openFeedbackEmail(rating: currentRating, text: text)
        }

        dismiss()
    }

    private func openFeedbackEmail(rating: Int, text: String) {
        let subject = "Safa Feedback — \(rating) stars"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = text
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:helpmesafa@gmail.com?subject=\(subject)&body=\(body)") {
            openURL(url)
        }
    }

    private func dismiss() {
        if dontAskAgain {
            AppReviewService.optOut()
        }
        isTextEditorFocused = false
        withAnimation(.easeInOut(duration: AppConstants.Timing.animationDuration)) {
            isPresented = false
        }
    }
}
