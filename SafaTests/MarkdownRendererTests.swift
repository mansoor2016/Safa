// MARK: - MarkdownRendererTests.swift
// PURPOSE: Regression tests for MarkdownRenderer inline parsing
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class MarkdownRendererTests: XCTestCase {

    let renderer = MarkdownRenderer(content: "")

    // MARK: - Inline Parsing (Regression: infinite loop fix)

    func test_parseInlineMarkdown_boldText_doesNotHang() {
        let input = "This is **bold** text and **more bold** here"
        let result = renderer.parseInlineMarkdown(input)
        XCTAssertFalse(String(result.characters).isEmpty)
    }

    func test_parseInlineMarkdown_italicText_doesNotHang() {
        let input = "This is *italic* text and *more italic* here"
        let result = renderer.parseInlineMarkdown(input)
        XCTAssertFalse(String(result.characters).isEmpty)
    }

    func test_parseInlineMarkdown_inlineCode_doesNotHang() {
        let input = "Use `code` and `more code` in text"
        let result = renderer.parseInlineMarkdown(input)
        XCTAssertFalse(String(result.characters).isEmpty)
    }

    func test_parseInlineMarkdown_mixedFormatting_doesNotHang() {
        let input = "**Bold** and *italic* and `code` together"
        let result = renderer.parseInlineMarkdown(input)
        XCTAssertFalse(String(result.characters).isEmpty)
    }

    func test_parseInlineMarkdown_plainText_returnsUnchanged() {
        let input = "Plain text with no formatting"
        let result = renderer.parseInlineMarkdown(input)
        XCTAssertEqual(String(result.characters), input)
    }

    func test_parseInlineMarkdown_emptyString_returnsEmpty() {
        let result = renderer.parseInlineMarkdown("")
        XCTAssertEqual(String(result.characters), "")
    }

    // MARK: - Block Parsing

    func test_parseBlocks_heading_parsesCorrectly() {
        let markdown = "## Heading Two"
        let blocks = renderer.parseBlocks(markdown)
        XCTAssertEqual(blocks.count, 1)
        if case .heading(let level) = blocks.first?.type {
            XCTAssertEqual(level, 2)
        } else {
            XCTFail("Expected heading block")
        }
        XCTAssertEqual(blocks.first?.content, "Heading Two")
    }

    func test_parseBlocks_bulletList_parsesItems() {
        let markdown = "- Item one\n- Item two\n- Item three"
        let blocks = renderer.parseBlocks(markdown)
        XCTAssertEqual(blocks.count, 1)
        if case .bulletList = blocks.first?.type {
            XCTAssertEqual(blocks.first?.items.count, 3)
        } else {
            XCTFail("Expected bullet list block")
        }
    }

    func test_parseBlocks_numberedList_parsesItems() {
        let markdown = "1. First\n2. Second\n3. Third"
        let blocks = renderer.parseBlocks(markdown)
        XCTAssertEqual(blocks.count, 1)
        if case .numberedList = blocks.first?.type {
            XCTAssertEqual(blocks.first?.items.count, 3)
            XCTAssertEqual(blocks.first?.items.first, "First")
        } else {
            XCTFail("Expected numbered list block")
        }
    }

    func test_parseBlocks_codeBlock_parsesLanguageAndContent() {
        let markdown = "```swift\nlet x = 1\n```"
        let blocks = renderer.parseBlocks(markdown)
        XCTAssertEqual(blocks.count, 1)
        if case .codeBlock(let language) = blocks.first?.type {
            XCTAssertEqual(language, "swift")
        } else {
            XCTFail("Expected code block")
        }
        XCTAssertEqual(blocks.first?.content, "let x = 1")
    }

    func test_parseBlocks_blockquote_parsesContent() {
        let markdown = "> This is a quote"
        let blocks = renderer.parseBlocks(markdown)
        XCTAssertEqual(blocks.count, 1)
        if case .blockquote = blocks.first?.type {
            XCTAssertEqual(blocks.first?.content, "This is a quote")
        } else {
            XCTFail("Expected blockquote block")
        }
    }

    func test_parseBlocks_reference_parsesQuranReference() {
        let markdown = "Quran 2:255"
        let blocks = renderer.parseBlocks(markdown)
        XCTAssertEqual(blocks.count, 1)
        if case .reference = blocks.first?.type {
            XCTAssertEqual(blocks.first?.content, "Quran 2:255")
        } else {
            XCTFail("Expected reference block")
        }
    }

    func test_parseBlocks_complexMarkdown_parsesAllBlocks() {
        let markdown = """
        ## How to Perform Wudu

        Wudu is the Islamic procedure for cleansing.

        1. Wash hands three times
        2. Rinse mouth three times
        3. Clean nose three times

        > The Prophet said: "No prayer is accepted without purification."

        Sahih Muslim 224
        """
        let blocks = renderer.parseBlocks(markdown)
        XCTAssertTrue(blocks.count >= 4, "Expected at least 4 blocks, got \(blocks.count)")
    }
}
