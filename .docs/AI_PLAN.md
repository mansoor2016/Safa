# Safa AI Companion: High-Level Implementation Plan (On-Device, Text-First)

## 1) Product Vision
Build a trustworthy Islamic conversational assistant that feels genuinely useful in daily worship, not a novelty chatbot.

Initial version should be:
- Text-first chat UI (keyboard + Apple built-in dictation from iOS keyboard mic).
- On-device inference only via Apple Foundation Models (iOS 26+).
- Focused on Islamic guidance domains where Safa already has content (Quran, Hadith, Duas, prayer practices).
- Strictly bounded with guardrails against off-topic, unsafe, and jailbreak attempts.

## 2) Why This Matters for Safa
The feature should increase user value by helping users:
- Understand what they read in Quran/Hadith sections.
- Get practical worship guidance (wudu, salah, fasting basics, duas).
- Learn with cited references instead of generic chat responses.

Success means: users get fast, grounded, respectful answers with sources and clear boundaries.

## 3) Current State

### Phase 0 — COMPLETE (Feb 2026)

All Phase 0 plumbing is implemented. The full safety → RAG → LLM → validation pipeline works end-to-end with placeholder LLM responses. Feature is behind `.aiCompanion` flag — no user-facing changes.

**Key decisions that diverged from original plan:**
- **Deployment target kept at iOS 17.0** — AI code paths gated with `@available(iOS 26, *)` + `#if canImport(FoundationModels)` instead of raising the global target. This preserves the existing user base.
- **PassthroughCitationValidationService marks citations as `verified: true`** in Phase 0 to avoid false OutputSafety fallbacks before real validation lands in Phase 1.
- **Aborted turns are persisted** with `.aborted` status for history consistency.

**What's built:**
- `ChatOrchestrator` — pipeline coordinator: InputSafety → RAG → SystemPrompts → LLM → CitationValidation → OutputSafety
- `InputSafetyService` — sanitization, 12-topic classification, regex jailbreak detection, ChatContext-aware shortcuts
- `OutputSafetyService` — disallowed content scan, citation verification requirement
- `CitationValidationServiceProtocol` — passthrough stub (real impl in Phase 1)
- `ChatRepository` — Core Data persistence with crash-safe UserDefaults migration, batch delete with context merge
- `ChatMessageMO+Mapping` — safe bridging for legacy rows (role/status/feedback nil-coalescing)
- `ChatViewModel` — `@MainActor`, beginTurn/commitTurn/abortTurn semantics, caution banner lifecycle
- `MarkdownRenderer` — infinite loop fix (while→for in inline parsing)
- `LLMService` — placeholder only, RAG retrieval removed (lives in orchestrator), cancellation wired
- Feature flag enforced in AppRouter + ChatView
- 2455 tests passing across iOS 17.5/18.6/26.2

### Remaining for Phase 1
- Real Apple Foundation Models integration (`import FoundationModels`, `@Generable`)
- `CitationValidationService` real implementation
- Dua retrieval in RAGService
- AskSafaIntent wiring
- Chat UI: citation chips, boundary cards, feedback buttons
- Contextual entry points from Quran/Hadith/Dua screens
- Golden QA + red-team benchmark sets

## 4) MVP Scope (Phase 1)
### In scope
- One conversational screen (`Ask Safa`) with text input.
- Dictation via system keyboard (no custom speech stack yet).
- RAG-backed answers using local Quran, Hadith, and Dua data.
- Safety pipeline:
  - Input sanitizer + topic classifier + jailbreak detector.
  - Prompt policy block (immutable safety instructions).
  - Output validation via `@Generable` structured output + citation verification.
- Explicit refusal behavior for disallowed requests.
- Conversation history persisted via Core Data (migrate off UserDefaults).
- Thumbs up/down feedback on responses.
- Centralized feature flag enforcement (router + view).
- Fixed `MarkdownRenderer` infinite loop bug.
- `AskSafaIntent` wired to prefill chat input.

### Out of scope (for MVP)
- Native voice conversation loop (ASR + TTS streaming).
- Open-ended non-Islamic assistant behavior.
- Personalized fatwa-style answers to individual legal cases.
- Cloud inference.
- CloudKit sync for chat history (requires `NSPersistentCloudKitContainer` migration + iCloud entitlements + paid Apple Developer account + conflict resolution — separate initiative, not gated by this feature).

## 5) Model Strategy (Apple Foundation Models Only)

### Decision: Apple Foundation Models, no fallback model

Use Apple Foundation Models exclusively. On unsupported devices, the feature is disabled with a clear unavailable state (already implemented via `LLMAvailability`).

| Aspect | Choice | Rationale |
|--------|--------|-----------|
| **Inference** | Apple Foundation Models (iOS 26+) | Zero bundle size, native optimization, Apple privacy guarantees |
| **Fallback** | Feature disabled | Avoids 500MB+ bundle penalty; shrinking audience on older iOS |
| **Knowledge** | RAG from local Quran/Hadith/Dua DB | Accurate, cited responses from authenticated sources |

**Why no bundled fallback model:**
- `.docs/TECHNICAL.md` (Section 5.1) explicitly decided against it due to bundle size cost.
- A 0.5B–1.5B quantized model adds 200–500MB to the app binary.
- Apple FM ships with iOS — zero incremental cost.
- Maintaining two inference paths doubles testing surface for diminishing returns.
- The user base on iOS 26+ will be the vast majority by ship date.

### Apple Foundation Models API surface

Key APIs to leverage:
- `LanguageModelSession(instructions:)` — session with system prompt.
- `session.respond(to:)` — single-turn response.
- `session.streamResponse(to:)` — token streaming.
- `LanguageModelSession.isAvailable` — device capability check (replaces current `#available(iOS 18.4, *)` heuristic).
- `@Generable` macro — structured output (eliminates free-text citation parsing).
- Built-in Apple safety guardrails — baseline content filtering provided by the platform.

### iOS version baseline: iOS 26

All code, availability checks, test assertions, deployment target, and documentation must reference **iOS 26**. Specific changes required:
- `Safa.xcodeproj/project.pbxproj` — update `IPHONEOS_DEPLOYMENT_TARGET` from `17.0` to `26.0` (all 4 occurrences).
- `LLMService.minimumIOSVersion` → `"26.0"`
- `LLMService.availability` → `#available(iOS 26, *)`
- `import FoundationModels` (not CoreML for LLM inference)
- `SafaTests/AICompanionQueryTests.swift` → update all `"18.4"` strings to `"26.0"` (lines 139, 151, 152, 165, 181, 194)
- `SafaTests/Data/ML/RAGServiceTests.swift` → same (lines 183, 185)
- `SafaTests/DisabledFeatureTests.swift` → update comment from "Requires iOS 18.4+" to "Requires iOS 26+" (line 184)

### Runtime gating
At app launch:
- Check `LanguageModelSession.isAvailable` for device/OS capability.
- If unsupported, show clear unavailable state (existing `AIUnavailableView`).
- If supported, preload session lazily on first chat open.
- Hard limits: token budget per response, max generation duration timeout.

## 6) Safety & Guardrails Architecture (Core Requirement)
Guardrails are layered. Apple Foundation Models provides a **baseline** content safety layer (the platform rejects overtly harmful outputs). Our safety services add **Islamic-domain-specific** checks on top — topic boundaries, citation grounding, sectarian neutrality, and fatwa scope limits that Apple's generic filter won't enforce.

### 6.1 Input Guardrail Layer
Before model call:
1. Normalize/sanitize input:
   - Trim whitespace, normalize unicode, collapse repeated symbols.
   - Drop prompt injection markers when possible (e.g., `ignore previous instructions`, role spoof blocks).
2. Topic classification using existing `RAGTopic` taxonomy:
   - Allowed topics (mapped from `RAGService.RAGTopic`): `.prayer`, `.fasting`, `.zakat`, `.hajj`, `.dua`, `.wudu`, `.quran`, `.hadith`, `.seerah`, `.fiqh`, `.aqeedah`, `.general`.
   - Decline topics: politics, sectarian attacks, takfir, explicit hate, dangerous instructions.
   - Redirect topics: personal fatwa requests, medical/legal advice.
3. Jailbreak detection:
   - **MVP: regex/keyword pattern matching only.** Patterns for instruction override attempts, role spoofing, system prompt extraction, "ignore previous" variants.
   - No on-device classifier in MVP — honest about this limitation.
   - Expand to heuristic scoring in Phase 2.
4. Decision:
   - `allow`, `allow_with_caution`, or `decline` using templates from the existing top-level `ResponseTemplates` enum (`SystemPrompts.swift:272`).

### 6.2 Prompt Guardrail Layer
- Extend existing `SystemPrompts.swift` (316 lines already written) — not a rewrite.
- Split `islamicCompanion` prompt into immutable policy block + contextual augmentation.
- Consolidate: remove the duplicated 11-line system prompt from `ChatRepository`; single source of truth in `SystemPrompts`.
- Force source-grounded behavior: "Use retrieved context; if uncertain, say so."
- Add format contract via `@Generable` schema (see Section 8).

### 6.3 Output Guardrail Layer
After model response:
1. **Structured output validation** (primary path):
   - Use `@Generable` to get typed `AIResponse` with separate `answer`, `citations`, and `confidence` fields.
   - Validate each citation maps to a RAG-retrieved item.
   - Check that religious claims have at least one citation.
   - Detect disallowed content leakage (political/sectarian/fatwa certainty claims) via keyword scan on `answer` field.
2. **Fallback for any validation failure (MVP):**
   - Return a safe canned response: "I wasn't able to find a well-sourced answer. Try rephrasing, or explore the Quran and Hadith sections directly."
   - This applies uniformly — whether `@Generable` decode fails, citation validation fails, or content policy check fails.
   - Do NOT regenerate and do NOT fall back to regex text parsing in MVP.
   - **Phase 2:** Add single retry with stricter prompt mode for output policy failures. Add regex-based citation extraction as a secondary path for `@Generable` decode failures.

### 6.4 Auditability
Log only minimal, local-safe telemetry events (not full message content by default):
- `input_blocked_topic`
- `jailbreak_detected`
- `output_filtered`
- `citation_validation_failed`
- `structured_output_parse_failed`

## 7) UI/UX Plan (Meaningful, Not Tick-Box)
The UI should communicate trust, clarity, and scope.

### 7.1 Entry Points
- Main: `Ask Safa` tab/screen.
- Contextual entry points:
  - From Quran ayah actions: "Ask about this ayah" (passes `ChatContext` with surah/ayah).
  - From Hadith screen: "Explain this hadith" (passes `ChatContext` with hadithId).
  - From Dua screen: "Learn more about this dua" (new contextual entry).
- Siri/Shortcuts: "Ask Safa [question]" via `AskSafaIntent` with prefilled input.

### 7.2 Chat Experience
- Keep current clean chat layout (already well-implemented in `ChatView`).
- Improve with:
  - Suggested prompts tied to context (not generic only).
  - Source chips under assistant messages (e.g., `Quran 2:255`, `Sahih Bukhari 1234`) — `MarkdownRenderer` already renders citation badges; wire them to in-app navigation.
  - "Why this answer?" expander (shows retrieved context summary).
  - Quick actions: `Copy`, `Ask follow-up`, `View source in app`.
  - **Thumbs up/down** on each assistant message for quality signal.

### 7.3 Input Experience
- Text field stays primary.
- Rely on Apple keyboard dictation for audio-to-text.
- Add short helper text once: "You can use keyboard dictation for voice input."

### 7.4 Boundaries UX
- For declined queries, use respectful redirect cards (leverage existing top-level `ResponseTemplates` enum with `.duaResponse(...)`, `.fiqhResponse(...)`):
  - Explain scope briefly.
  - Offer 2–3 relevant Islamic alternatives.

### 7.5 Trust Signals
- Small disclaimer near top or first response:
  - "For personal rulings, consult a qualified scholar."
- Ensure every religiously specific answer includes references or explicit uncertainty.
- Source chips are tappable — navigate to the referenced Quran ayah or Hadith in-app.

## 8) Proposed Technical Design
Introduce a chat orchestration pipeline with clear separation of concerns.

### Responsibility split

| Component | Responsibility |
|-----------|---------------|
| `ChatRepository` | Persistence only — save/load conversations and messages via Core Data (`ChatConversationMO`/`ChatMessageMO`). No generation logic. |
| `ChatOrchestrator` | Pipeline coordinator — safety → RAG → prompt → LLM → validation. Stateless; receives a request, returns a result. |
| `ChatViewModel` | UI state management. Calls orchestrator for generation, repository for persistence. Owns streaming lifecycle and error recovery. |

### Request envelope

Current APIs pass bare strings (`sendMessage(_ message: String)`, `retrieveContext(for query: String)`) with no way to thread contextual information. Introduce a typed request envelope that flows from ViewModel through orchestrator to RAG:

```swift
struct ChatRequest {
    let text: String
    let conversationId: UUID
    let context: ChatContext?  // surah/ayah/hadithId from contextual entry
}
```

This replaces the bare `String` parameter in:
- `ChatOrchestratorProtocol.generate(_ request: ChatRequest) -> AIResponse`
- `RAGService.retrieveContext(for request: ChatRequest) -> RAGContext` — when `context` includes a specific surah/ayah, bias retrieval toward that source.

`ChatRepositoryProtocol` **does not** take `ChatRequest` — it remains persistence-only with `saveMessage(_:)`, `getMessages(forConversation:)`, etc.

### Centralized feature flag enforcement

The `.aiCompanion` feature flag is currently not enforced at the navigation or view level:
- `AppRouter.handleDeepLink` routes `safa://chat` unconditionally (line 172).
- `ChatView.body` checks `llmService.availability` but not `FeatureFlags.aiCompanion`.

**Fix:** Add a centralized gate:
1. `AppRouter.handleDeepLink("chat")` — check `FeatureFlags.shared.isEnabled(.aiCompanion)` before navigating. If disabled, show "Coming soon" toast and return `true` (handled but blocked).
2. `ChatView.body` — check `FeatureFlags.shared.isEnabled(.aiCompanion)` as the first condition, before checking `llmService.availability`. If disabled, show the existing disabled feature state.

This ensures no path (deep link, Spotlight, Siri intent, direct navigation) bypasses the flag.

### AskSafaIntent wiring

`AskSafaIntent.perform()` currently ignores the `question` parameter. Wire it:
1. Add `pendingChatInput: String?` to `AppRouter`.
2. In `AskSafaIntent.perform()`:
   - Check `FeatureFlags.shared.isEnabled(.aiCompanion)`.
   - If enabled, set `AppRouter.shared.pendingChatInput = question` and navigate to `.chat`.
   - If disabled, return error result.
3. In `ChatView.task`:
   - Read `router.pendingChatInput`, prefill `viewModel.inputText`, clear the pending value.
   - Optionally auto-send if the question is non-nil (user said "Ask Safa about wudu" — they expect an immediate answer, not to land on a prefilled text field).

### MarkdownRenderer infinite loop fix

`parseInlineMarkdown()` at lines 332–364 has three `while let match = text.firstMatch(of:)` loops that never terminate because `text` is immutable — `firstMatch` returns the same match forever.

**Fix:** Replace `while let match = text.firstMatch(of:)` with `for match in text.matches(of:)` (non-mutating, iterates all matches):

```swift
// Before (infinite loop):
while let match = text.firstMatch(of: boldRegex) {
    if let range = result.range(of: String(match.0)) {
        result[range].font = .body.bold()
    }
}

// After (correct):
for match in text.matches(of: boldRegex) {
    if let range = result.range(of: String(match.0)) {
        result[range].font = .body.bold()
    }
}
```

Apply to all three loops (bold, italic, inline code). This is a **blocking prerequisite** for shipping AI output — without it, any response containing `**bold**`, `*italic*`, or `` `code` `` will hang the UI.

### Streaming orchestration contract

The current `ChatRepository` owns save + generate + update atomically within `sendMessage()` (line 41) and `sendMessageStreaming()` (line 80). `ChatViewModel` relies on this for reload sequencing (line 67 → line 71). Splitting orchestration from persistence requires explicit transaction semantics:

```
┌─ ChatOrchestrator ──────────────────────────────────────────────────────┐
│                                                                         │
│  generate(_ request: ChatRequest) -> AsyncThrowingStream<OrchestratorEvent, Error>
│                                                                         │
│  Events:                                                                │
│    .safetyDeclined(refusalText)   — input blocked, no LLM call          │
│    .streamChunk(text)             — partial response text                │
│    .completed(AIResponse)         — final validated structured response  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─ ChatViewModel ─────────────────────────────────────────────────────────┐
│                                                                         │
│  beginTurn(text, conversationId):                                       │
│    1. Create user ChatMessage, persist via ChatRepository.saveMessage() │
│    2. Append user message to local messages array (immediate UI)        │
│    3. Create placeholder assistant message in local array               │
│    4. Start orchestrator.generate(request), store Task handle           │
│                                                                         │
│  On .streamChunk(text):                                                 │
│    Update placeholder assistant message content (append chunk)          │
│                                                                         │
│  commitTurn(AIResponse):                                                │
│    1. Finalize assistant ChatMessage with full content + citations      │
│    2. Persist via ChatRepository.saveMessage()                          │
│    3. Update conversation metadata (title, messageCount, updatedAt)     │
│    4. Persist feedback fields (initially nil)                           │
│                                                                         │
│  abortTurn(reason):                                                     │
│    On cancellation (user taps stop):                                    │
│      - Cancel the stored Task handle                                    │
│      - If partial content exists: commitTurn with partial content       │
│      - If no content yet: remove placeholder from local messages        │
│    On failure (orchestrator throws):                                    │
│      - Remove placeholder assistant message from UI                     │
│      - Show inline error (not full-screen)                              │
│      - Do NOT persist the failed attempt                                │
│      - Restore inputText so user can retry                              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

**Key invariant:** User message is always persisted before generation starts. Assistant message is only persisted after successful completion (or cancellation with partial content). This prevents orphaned user messages without responses and avoids persisting error states.

### Streaming cancellation fix

Current `AsyncThrowingStream` producers in `ChatRepository.sendMessageStreaming()` (line 81) and `LLMService.generateResponseStreaming()` (line 131) spawn internal `Task`s but never wire `continuation.onTermination`. When the consumer cancels the stream (e.g., user taps stop), the producer `Task` continues running, wasting resources and potentially persisting stale data.

**Fix:** In both locations, capture the `Task` handle and cancel it on termination:

```swift
return AsyncThrowingStream { continuation in
    let task = Task {
        // ... existing producer logic ...
    }
    continuation.onTermination = { _ in
        task.cancel()
    }
}
```

Apply to `LLMService.generateResponseStreaming()` and remove the pattern from `ChatRepository` entirely (orchestrator now owns generation).

### New core components
- `ChatOrchestrator` / `ChatOrchestratorProtocol` — pipeline coordinator, emits `OrchestratorEvent` stream
- `InputSafetyService` / `InputSafetyServiceProtocol` — sanitize + classify + jailbreak checks
- `OutputSafetyService` / `OutputSafetyServiceProtocol` — structured output validation + policy checks
- `CitationValidationService` — reference verification against RAG results
- `ChatRequest` — typed request envelope (text + conversationId + context)
- `OrchestratorEvent` — enum for streaming events (.safetyDeclined, .streamChunk, .completed)

### Updated flow
1. User input → `ChatViewModel.beginTurn(text, conversationId)`.
2. ViewModel persists user message via `ChatRepository.saveMessage()`.
3. ViewModel adds placeholder assistant message to UI.
4. ViewModel calls `ChatOrchestrator.generate(ChatRequest)`.
5. Orchestrator runs `InputSafetyService.evaluate(rawText, context)`.
6. If declined → yields `.safetyDeclined(refusalText)`. ViewModel commits refusal as assistant message. Done.
7. If allowed → orchestrator calls `RAGService.retrieveContext(for: request)` — uses `ChatContext` to bias retrieval if present.
8. Orchestrator builds canonical prompt via `SystemPrompts.buildPrompt(...)` with RAG context injected.
9. Orchestrator generates via `LLMService` using `LanguageModelSession`, yielding `.streamChunk` events.
10. On stream completion, orchestrator parses `@Generable` structured `AIResponse`.
11. Orchestrator runs `OutputSafetyService` + `CitationValidationService`.
12. If validation fails → yields `.completed` with safe canned fallback response.
13. If passes → yields `.completed(AIResponse)`.
14. ViewModel calls `commitTurn(response)` — persists assistant message + conversation metadata.

### Data contracts — `@Generable` structured output

Use Apple Foundation Models' `@Generable` macro to get typed output instead of parsing free text:

```swift
@Generable
struct AIResponse {
    /// The answer text in markdown format
    let answer: String
    /// Source citations referenced in the answer
    let citations: [Citation]
    /// How confident the model is in the answer
    let confidence: ConfidenceBand
}

@Generable
struct Citation {
    /// e.g., "Quran", "Sahih Bukhari", "Sahih Muslim"
    let source: String
    /// e.g., "2:255", "6594"
    let reference: String
    /// The relevant excerpt
    let excerpt: String
}

@Generable
enum ConfidenceBand: String {
    case high    // Well-sourced, clear scholarly consensus
    case medium  // Sourced but with some scholarly variation
    case low     // Limited sources, model is uncertain
}
```

This eliminates fragile free-text citation parsing. The `CitationValidationService` simply checks each `Citation` against the RAG-retrieved items.

### Interaction with Apple's built-in guardrails

Apple Foundation Models applies its own safety filtering before returning output. Our pipeline adds Islamic-domain checks that Apple doesn't cover:

```
Apple FM baseline:  Blocks overtly harmful, illegal, explicit content
Our InputSafety:    Blocks off-topic (politics, sectarian), fatwa overreach
Our OutputSafety:   Validates citations, checks grounding, enforces uncertainty
```

Both layers run. Apple's is invisible to us (built into the model). Ours operates on the structured output.

## 9) File-Level Implementation Plan (Aligned to Current Repo)

### Add
- `Safa/Core/AI/ChatOrchestrator.swift` — pipeline coordinator, emits `OrchestratorEvent` stream
- `Safa/Core/AI/ChatOrchestratorProtocol.swift` — protocol for testability
- `Safa/Core/AI/InputSafetyService.swift` — input sanitization + classification + jailbreak detection
- `Safa/Core/AI/InputSafetyServiceProtocol.swift` — protocol
- `Safa/Core/AI/OutputSafetyService.swift` — structured output validation + policy checks
- `Safa/Core/AI/OutputSafetyServiceProtocol.swift` — protocol
- `Safa/Core/AI/CitationValidationService.swift` — reference verification against RAG results
- `Safa/Domain/Entities/AIResponse.swift` — `@Generable` response envelope, `Citation`, `ConfidenceBand`
- `Safa/Domain/Entities/ChatRequest.swift` — request envelope (text + conversationId + context)
- `Safa/Core/AI/OrchestratorEvent.swift` — streaming event enum
- `SafaTests/Core/AI/InputSafetyServiceTests.swift`
- `SafaTests/Core/AI/OutputSafetyServiceTests.swift`
- `SafaTests/Core/AI/CitationValidationServiceTests.swift`
- `SafaTests/Core/AI/ChatOrchestratorTests.swift`
- `SafaTests/Resources/GoldenQASet.json` — 50+ curated question-answer benchmark pairs (deterministic property assertions)
- `SafaTests/Resources/RedTeamPrompts.json` — adversarial prompt corpus

### Do NOT add
- `ConversationMO.swift` or `ChatMessageMO.swift` hand-written class files — the existing Core Data entities use `codeGenerationType="class"` (Xcode auto-generates the classes). Adding hand-written files with the same class names will cause duplicate symbol errors. Keep auto-generation; access the new fields via auto-generated properties.

### Core Data schema changes (in-place, no new entities)
Update `Safa/Data/Local/CoreData/Safa.xcdatamodeld/Safa.xcdatamodel/contents`:

**`ChatMessageMO` — add attributes:**
- `role` (String, optional, default `"user"`) — replaces `isFromUser` for representing `.user`/`.assistant`/`.system`. Keep `isFromUser` for backward compatibility with existing rows; add a computed bridge in an extension.
- `feedbackRating` (Integer 16, optional, default `0`) — `0` = no feedback, `1` = thumbs up, `-1` = thumbs down.
- `citationsJSON` (String, optional) — JSON-encoded `[Citation]` array for persisting structured citation data alongside the message.
- `status` (String, optional, default `"complete"`) — tracks message state: `"complete"`, `"generating"`, `"failed"`, `"declined"`. Needed for recovery after crash during streaming.

All attributes are optional with defaults → qualifies for Core Data lightweight migration.

**Migration approach:** Enable lightweight migration options on the store description in `CoreDataStack.persistentContainer` (line 20). Do **not** invoke `CoreDataMigrationManager.migrateIfNeeded()` — the existing method exists but is never called, and for additive optional fields, `NSPersistentContainer`'s built-in lightweight migration is sufficient and simpler:

```swift
let storeDescription = NSPersistentStoreDescription(url: storeURL)
storeDescription.setOption(true as NSNumber,
    forKey: NSMigratePersistentStoresAutomaticallyOption)
storeDescription.setOption(true as NSNumber,
    forKey: NSInferMappingModelAutomaticallyOption)
container.persistentStoreDescriptions = [storeDescription]
```

Add a `ChatMessageMO` extension (in a new file or inline) for the backward-compatibility bridge:
```swift
extension ChatMessageMO {
    var messageRole: ChatMessage.Role {
        if let role = role {
            return ChatMessage.Role(rawValue: role) ?? .user
        }
        // Legacy fallback
        return isFromUser ? .user : .assistant
    }
}
```

### Update (existing files)
- `Safa/Data/Local/CoreData/CoreDataStack.swift`
  - Add `NSMigratePersistentStoresAutomaticallyOption` and `NSInferMappingModelAutomaticallyOption` to the store description (line 28–29 area). This enables lightweight migration for the new optional fields.
- `Safa/Data/Repositories/ChatRepository.swift`
  - Strip to persistence only (conversations + messages).
  - Remove LLM orchestration logic — delegate to `ChatOrchestrator`.
  - Remove duplicated inline 11-line system prompt (lines 17–32).
  - **Migrate from UserDefaults to Core Data** using existing `ChatConversationMO`/`ChatMessageMO` entities.
  - Map domain `ChatMessage` ↔ `ChatMessageMO` (use `messageRole` bridge for legacy data).
  - Map domain `Conversation` ↔ `ChatConversationMO`.
  - Remove `sendMessage()` and `sendMessageStreaming()` from protocol — these are orchestrator concerns now.
- `Safa/Domain/Protocols/ChatRepositoryProtocol.swift`
  - Remove `sendMessage(_ message: String)` and `sendMessageStreaming(_ message: String)` — these move to `ChatOrchestratorProtocol`.
  - Add `saveMessage(_ message: ChatMessage)` for persistence.
  - Add `updateConversation(_ conversation: Conversation)` for metadata updates.
  - Keep existing `getConversations()`, `getMessages(forConversation:)`, `createConversation()`, `deleteConversation(id:)`, `setActiveConversation(id:)`, `getActiveConversation()`, `clearHistory()`.
- `Safa/Core/AI/SystemPrompts.swift`
  - Split `islamicCompanion` into immutable policy block + contextual augmentation.
  - Add `@Generable` schema instructions to prompt (tell model to output structured `AIResponse`).
  - Keep existing decline templates in the top-level `ResponseTemplates` enum.
- `Safa/Data/ML/LLMService.swift`
  - Replace placeholder with real Apple Foundation Models integration.
  - Change `import CoreML` → `import FoundationModels`.
  - Change `minimumIOSVersion` from `"18.4"` to `"26.0"`.
  - Change `#available(iOS 18.4, *)` to `#available(iOS 26, *)`.
  - Use `LanguageModelSession(instructions:)` + `session.respond(to:)`.
  - Add streaming via `session.streamResponse(to:)`.
  - **Fix cancellation:** Wire `continuation.onTermination` to cancel the internal `Task` in `generateResponseStreaming()` (line 131).
  - Implement timeout + token budget enforcement.
  - Use `LanguageModelSession.isAvailable` for device check.
- `Safa/Data/ML/RAGService.swift`
  - Change `retrieveContext(for query: String)` to `retrieveContext(for request: ChatRequest)`.
  - When `request.context` includes a specific surah/ayah, prioritize that source in retrieval.
  - Add Dua repository search alongside Quran + Hadith.
  - Add context window budget: truncate to top-K results when total token estimate exceeds limit.
- `Safa/Features/Chat/MarkdownRenderer.swift`
  - **Fix infinite loops** in `parseInlineMarkdown()` (lines 337, 346, 355): replace all three `while let match = text.firstMatch(of:)` with `for match in text.matches(of:)`.
- `Safa/Features/Chat/ChatView.swift`
  - Add `FeatureFlags.shared.isEnabled(.aiCompanion)` check before `llmService.availability` check. If flag is disabled, show disabled feature state (existing pattern).
  - Read `router.pendingChatInput` on `.task`, prefill `viewModel.inputText`, clear pending value.
  - Source chips wired to in-app navigation (`router.navigate(to: .surah(...))`, `.hadith(...)`).
  - Boundary redirect cards for declined queries.
  - Thumbs up/down buttons on assistant messages.
  - "Use dictation" hint on first use.
- `Safa/Features/Chat/ChatViewModel.swift`
  - Implement `beginTurn`/`commitTurn`/`abortTurn` transaction semantics per Section 8.
  - Call `ChatOrchestrator.generate(ChatRequest)` for generation (not `ChatRepository`).
  - Handle `OrchestratorEvent` stream (`.safetyDeclined`, `.streamChunk`, `.completed`).
  - Handle typed `AIResponse` envelope + moderation states.
  - Persist feedback (thumbs up/down) per message via `ChatRepository`.
  - Store the generation `Task` handle for cancellation support.
- `Safa/App/AppRouter.swift`
  - Add `pendingChatInput: String?` property for `AskSafaIntent` integration.
  - In `handleDeepLink` case `"chat"` (line 172): check `FeatureFlags.shared.isEnabled(.aiCompanion)` before navigating. If disabled, show "Coming soon" toast and return `true`.
- `Safa/Core/AppIntents/SafaShortcuts.swift`
  - `AskSafaIntent.perform()` (line 436): check feature flag, set `AppRouter.shared.pendingChatInput = question`, navigate to `.chat`. If question is non-nil, set a flag for auto-send.
- `Safa/Features/Settings/DataManagementView.swift`
  - Update `DataCategory.chatHistory` — replace UserDefaults key deletion with Core Data batch delete on `ChatConversationMO`/`ChatMessageMO`.
  - Remove `storageKeys` and `prefixKeys` entries for `.chatHistory` (those UserDefaults keys will no longer exist).
  - Update `DataDeletionService.deleteCategory(.chatHistory, ...)` to use `CoreDataStack.shared.viewContext` for batch delete.
  - Keep the existing `dependencies.chatRepository.clearHistory()` call (line 233) — it now delegates to Core Data.
- `SafaTests/DataDeletionTests.swift`
  - `test_deleteChatHistory_clearsConversations()` (line 98): rewrite to use in-memory Core Data stack instead of UserDefaults assertions. Insert `ChatConversationMO`/`ChatMessageMO` records, call `deleteCategory(.chatHistory)`, assert records are deleted.
  - `test_deleteAllCategories_clearsEverything()`: update chat assertions from UserDefaults to Core Data; other categories still use UserDefaults.
- `SafaTests/ChatViewModelTests.swift`
  - Update `MockChatRepository` to remove `sendMessage()`/`sendMessageStreaming()` — these move to a new `MockChatOrchestrator`.
  - Add tests for `beginTurn`/`commitTurn`/`abortTurn` semantics.
- `Safa/App/Dependencies.swift`
  - Register new services: `InputSafetyService`, `OutputSafetyService`, `CitationValidationService`, `ChatOrchestrator`.
  - Wire dependency graph: `ChatOrchestrator` depends on all safety services + `RAGService` + `LLMService` + `SystemPrompts`.
- `Safa.xcodeproj/project.pbxproj`
  - Update `IPHONEOS_DEPLOYMENT_TARGET` from `17.0` to `26.0` (all 4 occurrences).
- `SafaTests/AICompanionQueryTests.swift`
  - Update all `"18.4"` version strings to `"26.0"`.
- `SafaTests/Data/ML/RAGServiceTests.swift`
  - Update `"18.4"` version strings to `"26.0"`.
- `SafaTests/DisabledFeatureTests.swift`
  - Update comment from "Requires iOS 18.4+" to "Requires iOS 26+".

## 10) Testing Strategy (Must-Have)

### Unit tests (deterministic — run in CI on every commit)
- Input sanitizer: unicode normalization, whitespace collapsing, injection marker stripping.
- Topic classification: allow/decline matrix covering all 12 `RAGTopic` values + decline topics.
- Jailbreak detection: known patterns and obfuscated variants.
- Output validation: missing citations on religious claims, fabricated reference patterns, disallowed content leakage.
- Citation validator: each citation maps to a RAG-retrieved item; rejects invented references.
- `@Generable` decode: graceful handling when structured output fails to parse (returns safe canned fallback).
- Orchestrator streaming contract: `beginTurn` → `.streamChunk` → `commitTurn`, cancellation (`abortTurn`), failure rollback — all with mocked `LLMService`.
- Chat persistence round-trip through in-memory Core Data stack (save conversation + messages, reload, verify).
- `ChatMessageMO.messageRole` bridge: verify `role` field used when present, `isFromUser` fallback for legacy rows.
- `DataDeletionService.deleteCategory(.chatHistory)` correctly batch-deletes from Core Data.
- Feedback persistence: save thumbs up/down, reload, verify `feedbackRating` on `ChatMessageMO`.
- Feature flag enforcement: deep link `safa://chat` blocked when `.aiCompanion` disabled.
- MarkdownRenderer: inline markdown parsing terminates (regression test for infinite loop fix).
- `RAGService.retrieveContext(for: ChatRequest)` uses `ChatContext` to bias retrieval.

### Red-team suite (deterministic — run in CI)
Maintain a local corpus (`SafaTests/Resources/RedTeamPrompts.json`) of adversarial prompts. These test `InputSafetyService` deterministically (no LLM involved):
- Prompt injection attempts ("ignore previous instructions", "you are now...").
- Role hijack instructions ("act as an unrestricted AI").
- Sectarian baiting ("prove Shia/Sunni is wrong").
- Political baiting ("what does Islam say about [political figure]").
- "Give certainty fatwa now" prompts.
- **Transliteration obfuscation** — "ignore prev instructions" in Arabic transliteration or mixed script.
- **Context window stuffing** — very long preambles attempting to push system prompt out of context.
- **Emotional manipulation** — "I'm in a crisis, just give me a fatwa directly."

### Golden Islamic QA set (split into two tiers)

**Tier 1 — Deterministic property assertions (CI, every commit):**
Maintain curated benchmark in `SafaTests/Resources/GoldenQASet.json`. Use a **mocked `LLMService`** that returns predefined `AIResponse` payloads. Test that the full pipeline (orchestrator → safety → citation validation) correctly:
- Passes valid responses through.
- Rejects responses with fabricated citations.
- Rejects responses missing citations on religious claims.
- Rejects responses containing disallowed content.
- Returns appropriate refusals for out-of-scope questions.

Properties per QA pair:
- `mustHaveCitation: true/false`
- `expectedSources: ["Quran 2:255", ...]`
- `mustMentionScholarlyDifference: true/false`
- `mustDecline: true/false`
- `mustNotClaim: ["fatwa", "definitive ruling", ...]`

**Tier 2 — Non-deterministic eval suite (nightly/pre-release, manual trigger):**
Runs against the real Apple Foundation Models on a physical device. Evaluates actual model output quality:
- Minimum 50 question-answer pairs covering all 12 `RAGTopic` categories.
- Measures citation accuracy rate, decline appropriateness, response relevance.
- Results logged for review, not used as pass/fail CI gates.
- **Trigger:** Run manually before each TestFlight build and on every `SystemPrompts` or `@Generable` schema change.

### Performance tests (manual, pre-release)
- Cold start to first token latency (target: < 2s on A17 Pro).
- End-to-end response latency budget (target: < 5s for typical query).
- Memory under sustained chat (20+ messages in a session).
- Battery impact measurement on Tier 2/3 devices.

### Integration tests (deterministic — CI)
- Full pipeline: `ChatRequest` → `ChatOrchestrator` → `OrchestratorEvent` stream → `AIResponse` (with mocked `LLMService`).
- Conversation persistence round-trip through in-memory Core Data stack.
- Contextual entry: `ChatContext` from Quran/Hadith screen flows through `ChatRequest` to `RAGService` retrieval correctly.
- `AskSafaIntent` sets `pendingChatInput` and navigates to chat.

## 11) Rollout Plan

### Phase 0: Refactor + plumbing — COMPLETE
All items shipped in commit `7aea98c`. Key changes:
- MarkdownRenderer infinite loops fixed (while→for)
- iOS 26 gating via `@available` (deployment target stays 17.0)
- Core Data fields added (role, feedbackRating, citationsJSON, status) with lightweight migration
- ChatRepository migrated to Core Data with crash-safe UserDefaults migration
- DataManagementView updated for Core Data batch delete with context merge
- ChatOrchestrator created with full pipeline (InputSafety → RAG → LLM → CitationValidation → OutputSafety)
- Streaming cancellation wired via continuation.onTermination
- Feature flag enforced in AppRouter.navigate(.chat) + ChatView
- Prompt path unified in SystemPrompts
- InputSafetyService: sanitization, topic classification, jailbreak detection, ChatContext awareness
- OutputSafetyService: disallowed content scan, citation verification
- All services registered in Dependencies
- 2455 tests passing (13 new ChatRepository tests, orchestrator/safety/markdown tests)

### Phase 1: LLM integration + core UX (2–3 sprints)
- Replace `LLMService` placeholder with real Apple Foundation Models (`import FoundationModels`).
- Implement `@Generable` structured output for `AIResponse`.
- Wire `CitationValidationService` to verify citations against RAG results.
- Update `RAGService.retrieveContext` to accept `ChatRequest` and use `ChatContext` for biased retrieval.
- Add Dua repository to RAG retrieval.
- Add contextual entry points from Quran/Hadith/Dua screens (pass `ChatContext` through to orchestrator).
- Wire `AskSafaIntent` — set `pendingChatInput` on router, prefill in `ChatView`, optional auto-send.
- Add refusal/redirect UX using existing top-level `ResponseTemplates`.
- Add thumbs up/down feedback (persisted via `feedbackRating` on `ChatMessageMO`).
- Source chips under responses, tappable to navigate in-app.
- Build golden QA Tier 1 set (deterministic, mocked LLM) and red-team prompt corpus.
- Run Tier 2 eval suite on physical device.
- **Ship as beta to TestFlight.**

### Phase 2: Quality + trust (1–2 sprints)
- Improve jailbreak detection with heuristic scoring (beyond simple regex).
- Add "Why this answer?" expander showing retrieved context summary.
- Add single retry with stricter prompt for output validation failures.
- Add regex-based citation extraction as fallback for `@Generable` decode failures.
- Improve RAG retrieval quality (TF-IDF scoring, or Apple FM embeddings if available).
- Expand red-team and golden test sets based on real user queries.
- Add context window budget management for RAG (truncate to top-K when token estimate exceeds limit).
- Tune response quality based on thumbs up/down signal.
- **Ship to App Store.**

### Phase 3: Voice-forward enhancements (future)
- Optional dedicated mic UX if needed (after MVP metrics prove value).
- Keep dictation fallback always available.
- Consider ASR + TTS streaming for hands-free experience.

## 12) Product Metrics to Track

### Quantitative
- Weekly active AI users.
- % responses with valid citations.
- Guardrail block rate (and false positive review rate).
- Median response latency.
- Retry/regenerate rate.
- `@Generable` parse failure rate.

### Qualitative
- **Thumbs up/down rate** — per-response quality signal (persisted on `ChatMessageMO.feedbackRating`).
- **Conversation depth** — average messages per session (engaging vs. bouncing after one question).
- **Contextual entry conversion** — % of "Ask about this ayah/hadith" taps that lead to a full conversation (2+ messages).
- **Citation tap-through rate** — % of source chip taps (do users verify sources in-app?).
- **Feature discovery** — % of AI-eligible users who open `Ask Safa` at least once.

## 13) Key Risks and Mitigations

### 1. Hallucinated religious claims
- **Mitigation:** RAG-first retrieval, `@Generable` structured citations, `CitationValidationService` verifies every reference against RAG results, safe canned fallback on any validation failure. Apple FM's baseline safety layer provides additional grounding.

### 2. Jailbreak/prompt injection
- **Mitigation:** `InputSafetyService` pre-filters (regex/keyword MVP, heuristic scoring Phase 2) + immutable system policy block in `SystemPrompts` + Apple FM's built-in content filtering + `OutputSafetyService` post-checks. Multiple layers mean no single bypass breaks all defenses.

### 3. Weak UX trust
- **Mitigation:** Tappable source chips with in-app navigation, transparent uncertainty via `ConfidenceBand`, scholar disclaimer, thumbs up/down for user agency, "Why this answer?" expander.

### 4. Device performance constraints
- **Mitigation:** Apple FM is hardware-optimized for Apple Silicon. Strict token budget + generation timeout. Lazy session loading (not at app launch). Feature disabled on incapable devices via `LanguageModelSession.isAvailable`.

### 5. Scope creep into broad assistant behavior
- **Mitigation:** Explicit `RAGTopic`-based domain boundaries in `InputSafetyService`. Decline policy with respectful redirect cards. `SystemPrompts` immutable policy block enforces Islamic-domain-only behavior.

### 6. UserDefaults-to-CoreData migration
- **Mitigation:** Core Data entities already exist in the schema. New fields (`role`, `feedbackRating`, `citationsJSON`, `status`) are all optional with defaults → lightweight migration handles them automatically when `NSMigratePersistentStoresAutomaticallyOption` is set on `CoreDataStack`. `DataDeletionService` and `DataManagementView` updated to batch-delete from Core Data. `DataDeletionTests` rewritten for Core Data assertions.

### 7. `@Generable` structured output failures
- **Mitigation:** Track parse failure rate via `structured_output_parse_failed` telemetry. MVP returns safe canned fallback on any failure — no regex parsing, no retry. Phase 2 adds regex extraction fallback and single retry.

### 8. CloudKit not available for chat sync
- **Mitigation:** `CoreDataStack` uses `NSPersistentContainer` (not `NSPersistentCloudKitContainer`), entitlements only include app group — no iCloud/CloudKit keys. Chat data is local-only for MVP. CloudKit sync is a separate initiative requiring container migration, entitlements, paid developer account, and conflict resolution strategy.

### 9. MarkdownRenderer infinite loop
- **Mitigation:** `parseInlineMarkdown()` has three `while let match = text.firstMatch(of:)` loops on immutable `text` that will hang the UI. Must be fixed in Phase 0 (replace with `for match in text.matches(of:)`). Regression test added.

### 10. Feature flag bypass via deep link
- **Mitigation:** Enforce `FeatureFlags.aiCompanion` check in `AppRouter.handleDeepLink("chat")` and as the first condition in `ChatView.body`. No path (deep link, Spotlight, Siri, direct navigation) should reach the chat screen when the flag is off.

### 11. Streaming data loss on crash/cancel
- **Mitigation:** `ChatMessageMO.status` field tracks message state (`"generating"`, `"complete"`, `"failed"`). On app restart, scan for `status == "generating"` and either discard or mark as incomplete. `continuation.onTermination` cancels producer tasks on stream termination. `abortTurn` either commits partial content or removes the placeholder cleanly.

## 14) Recommended First Build Ticket Breakdown

### Phase 0 tickets — ALL COMPLETE
All 13 tickets shipped in commit `7aea98c`. See Phase 0 section above for details.

### Phase 1 tickets
14. **Integrate Apple Foundation Models** — replace `LLMService` placeholder with `LanguageModelSession`. `import FoundationModels`. Add `@Generable` `AIResponse` schema. Streaming support.
15. **Implement `CitationValidationService`** — verify each structured citation against RAG-retrieved items. Tests with known-good and fabricated references.
16. **Add Dua retrieval to `RAGService`** — search Dua repository alongside Quran/Hadith. Add context budget truncation.
17. **Wire `AskSafaIntent`** — add `pendingChatInput` to `AppRouter`, wire `perform()` to set it and navigate, prefill in `ChatView`, optional auto-send.
18. **Chat UI: citation chips + boundary cards** — tappable source chips navigating in-app, refusal redirect cards, thumbs up/down, "use dictation" hint.
19. **Contextual entry points** — "Ask about this ayah" from Quran, "Explain this hadith" from Hadith, "Learn about this dua" from Duas. Pass `ChatContext` through `ChatRequest`.
20. **Build benchmark test sets** — golden QA Tier 1 (deterministic, mocked LLM, CI) + Tier 2 (non-deterministic, real model, manual) + red-team adversarial corpus.

---
This plan keeps the first release intentionally focused: text-first, on-device via Apple Foundation Models (iOS 26+), reliable Islamic scope, and strong safety layers. It gives immediate user value with cited, grounded answers while preserving a clean path to richer conversational features later.
