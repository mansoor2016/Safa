// MARK: - ChatView.swift
// PURPOSE: AI companion chat interface
// DEPENDENCIES: SwiftUI, ChatViewModel

import SwiftUI

struct ChatView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var viewModel: ChatViewModel?

    var body: some View {
        Group {
            if FeatureFlags.shared.isDisabled(.aiCompanion) {
                // Defense-in-depth: router is the primary gate, but guard here too
                AIUnavailableView(message: "AI Companion is coming soon.")
            } else if let viewModel = viewModel {
                ChatContentView(viewModel: viewModel)
            } else {
                LoadingView(message: "Loading chat...")
            }
        }
        .task {
            guard !FeatureFlags.shared.isDisabled(.aiCompanion) else { return }

            if viewModel == nil {
                viewModel = ChatViewModel(
                    chatRepository: dependencies.chatRepository,
                    orchestrator: dependencies.chatOrchestrator
                )
            }

            guard let viewModel else { return }

            // Hydrate existing conversation BEFORE any auto-send —
            // prevents beginTurn from creating a spurious new conversation.
            await viewModel.loadActiveConversation()

            // Set context BEFORE prefillAndSend — beginTurn snapshots and clears
            // pendingContext early, so it must already be set.
            if let context = AppRouter.shared.pendingChatContext {
                AppRouter.shared.pendingChatContext = nil
                viewModel.pendingContext = context
            }
            if let pending = AppRouter.shared.pendingChatInput {
                AppRouter.shared.pendingChatInput = nil
                let mode = AppRouter.shared.pendingChatLaunchMode
                AppRouter.shared.pendingChatLaunchMode = .prefillOnly

                switch mode {
                case .autoSend:
                    viewModel.prefillAndSend(pending)
                case .prefillOnly:
                    viewModel.inputText = pending
                }
            }
        }
    }
}

// MARK: - AI Unavailable View

private struct AIUnavailableView: View {
    let message: String

    var body: some View {
        VStack(spacing: SafaSpacing.lg) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundColor(SafaColors.Fallback.tertiaryText)

            Text("AI Companion")
                .font(SafaTypography.headlineMedium)
                .foregroundColor(SafaColors.Fallback.text)

            Text(message)
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SafaSpacing.xl)

            // Alternative actions
            VStack(spacing: SafaSpacing.sm) {
                Text("In the meantime, explore:")
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)

                HStack(spacing: SafaSpacing.md) {
                    alternativeButton(icon: "book.fill", label: "Quran")
                    alternativeButton(icon: "quote.bubble.fill", label: "Hadith")
                    alternativeButton(icon: "hands.sparkles.fill", label: "Duas")
                }
            }
            .padding(.top, SafaSpacing.lg)

            Spacer()
        }
        .navigationTitle("Ask Safa")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func alternativeButton(icon: String, label: String) -> some View {
        VStack(spacing: SafaSpacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)

            Text(label)
                .font(SafaTypography.labelSmall)
                .foregroundColor(SafaColors.Fallback.secondaryText)
        }
        .frame(width: 80, height: 80)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
    }
}

// MARK: - Chat Content View

private struct ChatContentView: View {
    @Bindable var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            messagesView

            // Error banner (only for generation failures, not load/select/delete errors)
            if let error = viewModel.generationError {
                ErrorBanner(
                    message: error.localizedDescription,
                    onRetry: { Task { await viewModel.retryLastMessage() } },
                    onDismiss: { viewModel.dismissError() }
                )
            }

            // Input
            inputView
        }
        .navigationTitle("Ask Safa")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { viewModel.showConversations = true }) {
                        Label("History", systemImage: "clock")
                    }
                    Button(action: {
                        Task { await viewModel.startNewConversation() }
                    }) {
                        Label("New Chat", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.showConversations) {
            ConversationHistoryView(viewModel: viewModel)
                .fullSheet()
        }
        // Note: loadActiveConversation is called in ChatView's .task (before auto-send)
        // to ensure proper hydration ordering. No separate .task needed here.
    }

    // MARK: - Messages View

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: SafaSpacing.md) {
                    if viewModel.messages.isEmpty {
                        welcomeView
                    } else {
                        ForEach(viewModel.messages) { message in
                            // Show caution banner above the last assistant message
                            if let caution = viewModel.cautionMessage,
                               message.isAssistant,
                               message.id == viewModel.messages.last(where: { $0.isAssistant })?.id {
                                CautionBanner(message: caution)
                            }

                            MessageBubble(message: message, onFeedback: { rating in
                                viewModel.saveFeedback(messageId: message.id, rating: rating)
                            })
                                .id(message.id)
                        }

                        // Typing indicator
                        if viewModel.isGenerating {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isGenerating) { _, isGenerating in
                if isGenerating {
                    withAnimation {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        VStack(spacing: SafaSpacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Assalamu Alaikum!")
                .font(SafaTypography.headlineMedium)

            Text("I'm your Islamic knowledge companion. Ask me about:")
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                suggestionRow("How do I perform wudu?", icon: "drop")
                suggestionRow("What is the dua before eating?", icon: "fork.knife")
                suggestionRow("Explain Surah Al-Fatiha", icon: "book")
                suggestionRow("What breaks the fast?", icon: "moon")
            }

            Text("Note: For complex religious rulings, please consult a qualified scholar.")
                .font(SafaTypography.labelSmall)
                .foregroundColor(SafaColors.Fallback.tertiaryText)
                .multilineTextAlignment(.center)
                .padding(.top)
        }
        .padding()
    }

    private func suggestionRow(_ text: String, icon: String) -> some View {
        Button {
            viewModel.inputText = text
            Task { await viewModel.sendMessage() }
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)

                Text(text)
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.text)

                Spacer()

                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.accentColor)
            }
            .padding(SafaSpacing.sm)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
        }
    }

    // MARK: - Input View

    private var inputView: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: SafaSpacing.sm) {
                TextField("Ask a question...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .onSubmit {
                        guard !viewModel.isGenerating else { return }
                        Task { await viewModel.sendMessage() }
                    }

                if viewModel.isGenerating, viewModel.currentTurnAssistantId != nil {
                    Button { viewModel.abortTurn() } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Stop generating")
                } else {
                    Button {
                        Task { await viewModel.sendMessage() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(
                                viewModel.inputText.isEmpty
                                ? SafaColors.Fallback.tertiaryText
                                : .accentColor
                            )
                    }
                    .disabled(viewModel.inputText.isEmpty)
                }
            }
            .padding(SafaSpacing.md)
            .background(Color(UIColor.systemBackground))
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage
    var onFeedback: ((Int16) -> Void)?
    @State private var showCopied = false

    var body: some View {
        HStack(alignment: .top) {
            if message.isUser {
                Spacer(minLength: 60)
            } else {
                // AI avatar
                Circle()
                    .fill(Color.accentColor.gradient)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: SafaSpacing.xxs) {
                // Message content
                VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                    if message.isUser {
                        Text(message.content)
                            .font(SafaTypography.bodyMedium)
                            .foregroundColor(.white)
                    } else {
                        // Markdown rendering for AI responses
                        MarkdownRenderer(content: message.content)
                    }
                }
                .padding(SafaSpacing.sm)
                .background(
                    message.isUser
                    ? Color.accentColor
                    : Color(UIColor.secondarySystemBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))

                // Citation chips for AI messages
                if !message.isUser && !message.citations.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(message.citations, id: \.self) { citation in
                            CitationChip(citation: citation)
                        }
                    }
                }

                // Actions row for AI messages
                if !message.isUser {
                    HStack(spacing: SafaSpacing.md) {
                        // Copy button
                        Button {
                            copyToClipboard(message.content)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                Text(showCopied ? "Copied" : "Copy")
                            }
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                        }
                        .accessibilityLabel(showCopied ? "Copied to clipboard" : "Copy message")

                        // Feedback thumbs (only for complete messages)
                        if message.status == .complete {
                            HStack(spacing: SafaSpacing.sm) {
                                Button { onFeedback?(1) } label: {
                                    Image(systemName: message.feedbackRating == 1 ? "hand.thumbsup.fill" : "hand.thumbsup")
                                }
                                .accessibilityLabel(message.feedbackRating == 1 ? "Liked" : "Like response")

                                Button { onFeedback?(-1) } label: {
                                    Image(systemName: message.feedbackRating == -1 ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                }
                                .accessibilityLabel(message.feedbackRating == -1 ? "Disliked" : "Dislike response")
                            }
                            .foregroundColor(SafaColors.Fallback.tertiaryText)
                            .font(.subheadline)
                        }

                        // Timestamp
                        Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.tertiaryText)
                    }
                } else {
                    // Timestamp for user messages
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }
            }

            if !message.isUser {
                Spacer(minLength: 40)
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        showCopied = true

        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopied = false
        }
    }
}

// MARK: - Citation Chip

private struct CitationChip: View {
    let citation: Citation

    private var icon: String {
        switch citation.type {
        case .quran: return "book.fill"
        case .hadith: return "quote.bubble.fill"
        case .dua: return "hands.sparkles.fill"
        case .none: return "book.fill"
        }
    }

    private var isNavigable: Bool {
        citation.navigationDestination() != nil
    }

    var body: some View {
        Button {
            navigateToCitation()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)

                Text(citation.reference)
                    .font(SafaTypography.labelSmall)
                    .lineLimit(1)

                if citation.verified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(UIColor.tertiarySystemBackground))
            .clipShape(Capsule())
            .foregroundColor(SafaColors.Fallback.secondaryText)
        }
        .buttonStyle(.plain)
        .disabled(!isNavigable)
        .accessibilityLabel("Citation: \(citation.reference)\(citation.verified ? ", verified" : "")")
        .accessibilityHint(isNavigable ? "Tap to navigate to source" : "")
    }

    private func navigateToCitation() {
        guard let destination = citation.navigationDestination() else { return }
        AppRouter.shared.navigate(to: destination)
    }
}

// MARK: - Caution Banner

private struct CautionBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: SafaSpacing.xs) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.orange)
                .font(.subheadline)

            Text(message)
                .font(SafaTypography.labelSmall)
                .foregroundColor(SafaColors.Fallback.secondaryText)
        }
        .padding(SafaSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.sm))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Caution: \(message)")
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var animationOffset = 0

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(SafaColors.Fallback.tertiaryText)
                        .frame(width: 8, height: 8)
                        .offset(y: animationOffset == index ? -4 : 0)
                }
            }
            .padding(SafaSpacing.sm)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))

            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Safa is thinking")
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                animationOffset = (animationOffset + 1) % 3
            }
        }
    }
}

// MARK: - Error Banner

private struct ErrorBanner: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: SafaSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.subheadline)
                .accessibilityHidden(true)

            Text(message)
                .font(SafaTypography.labelSmall)
                .foregroundColor(SafaColors.Fallback.secondaryText)
                .lineLimit(2)
                .accessibilityLabel("Error: \(message)")

            Spacer()

            Button("Retry", action: onRetry)
                .font(SafaTypography.labelSmall)
                .foregroundColor(.accentColor)
                .accessibilityLabel("Retry last message")

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
            .accessibilityLabel("Dismiss error")
        }
        .padding(SafaSpacing.sm)
        .background(Color.red.opacity(0.1))
    }
}

// MARK: - Conversation History View

private struct ConversationHistoryView: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.conversations.isEmpty {
                    EmptyStateView.noConversations
                } else {
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            Button {
                                Task {
                                    await viewModel.selectConversation(conversation)
                                    dismiss()
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                                    Text(conversation.displayTitle)
                                        .font(SafaTypography.bodyLarge)
                                        .foregroundColor(SafaColors.Fallback.text)

                                    HStack {
                                        Text("\(conversation.messageCount) messages")
                                        Text("•")
                                        Text(conversation.updatedAt.relativeString)
                                    }
                                    .font(SafaTypography.labelSmall)
                                    .foregroundColor(SafaColors.Fallback.secondaryText)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await viewModel.deleteConversation(viewModel.conversations[index])
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.conversations.isEmpty {
                        Button("Clear All", role: .destructive) {
                            Task {
                                await viewModel.clearHistory()
                            }
                        }
                    }
                }
            }
            .task {
                await viewModel.loadConversations()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChatView()
            .environment(Dependencies())
    }
}
