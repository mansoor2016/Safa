// MARK: - ChatView.swift
// PURPOSE: AI companion chat interface
// DEPENDENCIES: SwiftUI, ChatViewModel

import SwiftUI

struct ChatView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var viewModel: ChatViewModel?

    var body: some View {
        Group {
            let availability = dependencies.llmService.availability
            if !availability.isAvailable {
                // Show fallback for older iOS versions
                AIUnavailableView(message: availability.userMessage)
            } else if let viewModel = viewModel {
                ChatContentView(viewModel: viewModel)
            } else {
                LoadingView(message: "Loading chat...")
            }
        }
        .task {
            if viewModel == nil && dependencies.llmService.availability.isAvailable {
                viewModel = ChatViewModel(
                    chatRepository: dependencies.chatRepository
                )
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
        .task {
            await viewModel.loadActiveConversation()
        }
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
                            MessageBubble(message: message)
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
                        Task { await viewModel.sendMessage() }
                    }

                Button {
                    Task { await viewModel.sendMessage() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(
                            viewModel.inputText.isEmpty || viewModel.isGenerating
                            ? SafaColors.Fallback.tertiaryText
                            : .accentColor
                        )
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isGenerating)
            }
            .padding(SafaSpacing.md)
            .background(Color(UIColor.systemBackground))
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage
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
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                animationOffset = (animationOffset + 1) % 3
            }
        }
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
