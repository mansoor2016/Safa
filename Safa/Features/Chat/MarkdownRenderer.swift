// MARK: - MarkdownRenderer.swift
// PURPOSE: Render markdown content in chat messages
// DEPENDENCIES: SwiftUI, Foundation

import SwiftUI

// MARK: - Markdown Renderer

struct MarkdownRenderer: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseBlocks(content), id: \.id) { block in
                renderBlock(block)
            }
        }
    }

    // MARK: - Block Rendering

    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block.type {
        case .heading(let level):
            renderHeading(block.content, level: level)

        case .paragraph:
            renderParagraph(block.content)

        case .codeBlock(let language):
            renderCodeBlock(block.content, language: language)

        case .bulletList:
            renderBulletList(block.items)

        case .numberedList:
            renderNumberedList(block.items)

        case .blockquote:
            renderBlockquote(block.content)

        case .arabicText:
            renderArabicText(block.content)

        case .reference:
            renderReference(block.content)
        }
    }

    // MARK: - Heading

    private func renderHeading(_ text: String, level: Int) -> some View {
        Text(parseInlineMarkdown(text))
            .font(headingFont(level: level))
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
    }

    private func headingFont(level: Int) -> Font {
        switch level {
        case 1: return .title2
        case 2: return .title3
        case 3: return .headline
        default: return .subheadline
        }
    }

    // MARK: - Paragraph

    private func renderParagraph(_ text: String) -> some View {
        Text(parseInlineMarkdown(text))
            .font(.body)
            .foregroundStyle(.primary)
    }

    // MARK: - Code Block

    private func renderCodeBlock(_ code: String, language: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let language = language, !language.isEmpty {
                Text(language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(code)
                .font(.system(.body, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Lists

    private func renderBulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(parseInlineMarkdown(item))
                        .font(.body)
                }
            }
        }
    }

    private func renderNumberedList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 20, alignment: .trailing)
                    Text(parseInlineMarkdown(item))
                        .font(.body)
                }
            }
        }
    }

    // MARK: - Blockquote

    private func renderBlockquote(_ text: String) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.green.opacity(0.5))
                .frame(width: 3)

            Text(parseInlineMarkdown(text))
                .font(.body)
                .italic()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Arabic Text

    private func renderArabicText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 24, weight: .medium, design: .serif))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Reference

    private func renderReference(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "book.closed")
                .font(.caption)
                .foregroundStyle(.green)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Markdown Block

struct MarkdownBlock: Identifiable {
    let id = UUID()
    let type: BlockType
    let content: String
    var items: [String] = []

    enum BlockType {
        case heading(level: Int)
        case paragraph
        case codeBlock(language: String?)
        case bulletList
        case numberedList
        case blockquote
        case arabicText
        case reference
    }
}

// MARK: - Parser Extension

extension MarkdownRenderer {

    // MARK: - Block Parser

    func parseBlocks(_ markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = markdown.components(separatedBy: "\n")
        var currentIndex = 0

        while currentIndex < lines.count {
            let line = lines[currentIndex]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Empty line
            if trimmed.isEmpty {
                currentIndex += 1
                continue
            }

            // Heading
            if let headingMatch = trimmed.firstMatch(of: /^(#{1,4})\s+(.+)$/) {
                let level = headingMatch.1.count
                let content = String(headingMatch.2)
                blocks.append(MarkdownBlock(type: .heading(level: level), content: content))
                currentIndex += 1
                continue
            }

            // Code block
            if trimmed.hasPrefix("```") {
                let language = String(trimmed.dropFirst(3))
                var codeLines: [String] = []
                currentIndex += 1

                while currentIndex < lines.count && !lines[currentIndex].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[currentIndex])
                    currentIndex += 1
                }
                currentIndex += 1 // Skip closing ```

                blocks.append(MarkdownBlock(
                    type: .codeBlock(language: language.isEmpty ? nil : language),
                    content: codeLines.joined(separator: "\n")
                ))
                continue
            }

            // Bullet list
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                var items: [String] = []
                while currentIndex < lines.count {
                    let currentLine = lines[currentIndex].trimmingCharacters(in: .whitespaces)
                    if currentLine.hasPrefix("- ") {
                        items.append(String(currentLine.dropFirst(2)))
                    } else if currentLine.hasPrefix("* ") {
                        items.append(String(currentLine.dropFirst(2)))
                    } else if currentLine.isEmpty {
                        break
                    } else {
                        break
                    }
                    currentIndex += 1
                }

                var block = MarkdownBlock(type: .bulletList, content: "")
                block.items = items
                blocks.append(block)
                continue
            }

            // Numbered list
            if let _ = trimmed.firstMatch(of: /^\d+\.\s+/) {
                var items: [String] = []
                while currentIndex < lines.count {
                    let currentLine = lines[currentIndex].trimmingCharacters(in: .whitespaces)
                    if let match = currentLine.firstMatch(of: /^\d+\.\s+(.+)$/) {
                        items.append(String(match.1))
                    } else if currentLine.isEmpty {
                        break
                    } else {
                        break
                    }
                    currentIndex += 1
                }

                var block = MarkdownBlock(type: .numberedList, content: "")
                block.items = items
                blocks.append(block)
                continue
            }

            // Blockquote
            if trimmed.hasPrefix("> ") {
                var quoteLines: [String] = []
                while currentIndex < lines.count {
                    let currentLine = lines[currentIndex].trimmingCharacters(in: .whitespaces)
                    if currentLine.hasPrefix("> ") {
                        quoteLines.append(String(currentLine.dropFirst(2)))
                    } else if currentLine.isEmpty {
                        break
                    } else {
                        break
                    }
                    currentIndex += 1
                }

                blocks.append(MarkdownBlock(
                    type: .blockquote,
                    content: quoteLines.joined(separator: " ")
                ))
                continue
            }

            // Arabic text detection (contains Arabic characters)
            if containsArabic(trimmed) && !containsLatin(trimmed) {
                blocks.append(MarkdownBlock(type: .arabicText, content: trimmed))
                currentIndex += 1
                continue
            }

            // Reference pattern (e.g., "Quran 2:255" or "Sahih Bukhari 1234")
            if let _ = trimmed.firstMatch(of: /^(Quran|Sahih|Sunan|Musnad|Hadith)\s+[\d:]+/) {
                blocks.append(MarkdownBlock(type: .reference, content: trimmed))
                currentIndex += 1
                continue
            }

            // Default: paragraph
            blocks.append(MarkdownBlock(type: .paragraph, content: trimmed))
            currentIndex += 1
        }

        return blocks
    }

    // MARK: - Inline Parser

    func parseInlineMarkdown(_ text: String) -> AttributedString {
        var result = AttributedString(text)

        // Bold **text**
        if let boldRegex = try? Regex(#"\*\*(.+?)\*\*"#) {
            while let match = text.firstMatch(of: boldRegex) {
                if let range = result.range(of: String(match.0)) {
                    result[range].font = .body.bold()
                }
            }
        }

        // Italic *text* or _text_
        if let italicRegex = try? Regex(#"(?<!\*)\*([^*]+)\*(?!\*)"#) {
            while let match = text.firstMatch(of: italicRegex) {
                if let range = result.range(of: String(match.0)) {
                    result[range].font = .body.italic()
                }
            }
        }

        // Inline code `code`
        if let codeRegex = try? Regex(#"`([^`]+)`"#) {
            while let match = text.firstMatch(of: codeRegex) {
                if let range = result.range(of: String(match.0)) {
                    result[range].font = .system(.body, design: .monospaced)
                    result[range].backgroundColor = .gray.opacity(0.2)
                }
            }
        }

        return result
    }

    // MARK: - Helpers

    private func containsArabic(_ text: String) -> Bool {
        let arabicRange = 0x0600...0x06FF
        return text.unicodeScalars.contains { arabicRange.contains(Int($0.value)) }
    }

    private func containsLatin(_ text: String) -> Bool {
        let latinRange = 0x0041...0x007A
        return text.unicodeScalars.contains { latinRange.contains(Int($0.value)) }
    }
}

// MARK: - Message Bubble with Markdown

struct MarkdownMessageBubble: View {
    let message: ChatMessage
    let onCopy: () -> Void

    @State private var showCopied = false

    private var isFromUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack(alignment: .top) {
            if !isFromUser {
                // AI avatar
                Circle()
                    .fill(Color.green.gradient)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
            }

            VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
                // Message content
                VStack(alignment: .leading) {
                    if isFromUser {
                        Text(message.content)
                            .font(.body)
                    } else {
                        MarkdownRenderer(content: message.content)
                    }
                }
                .padding()
                .background(isFromUser ? Color.green : Color(.secondarySystemBackground))
                .foregroundStyle(isFromUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Actions
                if !isFromUser {
                    HStack(spacing: 16) {
                        Button {
                            onCopy()
                            showCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCopied = false
                            }
                        } label: {
                            Label(showCopied ? "Copied" : "Copy", systemImage: showCopied ? "checkmark" : "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: 300, alignment: isFromUser ? .trailing : .leading)

            if isFromUser {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: isFromUser ? .trailing : .leading)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            MarkdownRenderer(content: """
            ## How to Perform Wudu

            Wudu (ablution) is the Islamic procedure for cleansing parts of the body before prayer.

            ### Steps:

            1. Begin with the intention (niyyah)
            2. Say "Bismillah" (In the name of Allah)
            3. Wash your hands three times
            4. Rinse your mouth three times
            5. Clean your nose three times

            > The Prophet (ﷺ) said: "No prayer is accepted without purification."

            بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ

            Sahih Muslim 224

            ### Important Notes:

            - Water should reach all parts
            - Perform actions in order
            - Do not waste water

            For more details, refer to **Fiqh al-Sunnah** or consult a local scholar.
            """)
        }
        .padding()
    }
}
