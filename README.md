# AI Lab

A SwiftUI practice app for **on-device AI on iOS**: Foundation Models, Core ML, Vision and Natural Language. Swift 6 (strict concurrency), iOS 26 baseline, no dependencies, no network calls.

## Run it
```bash
brew install xcodegen
xcodegen generate
open AILab.xcodeproj
```
The Foundation Models screens need an Apple Intelligence device; elsewhere they show an availability banner and fall back to a simulated generator (chat, guardrails, injection) or an "unavailable" message (trip planner, tools, latency).

## Structure
```
AILab/App          tab shell
AILab/Core/AI     AIError, Stats, PromptSanitizer, TextGenerating (protocol seam + fake)
AILab/Core/UI     LessonBadge / AboutLessonSheet, banners
AILab/Features    Assistant, Models, Perception, Settings
AILabTests        Swift Testing: stats, sanitizer, error mapping, chat view model
```

## Coverage
Status: **Done** = working screen · **Partial** = simplified · **Not yet** = not implemented.

| Lessons | Topic | Status |
|---|---|---|
| 58.1–58.2 | Availability handling | Done (banner + fallback) |
| 58.3–58.6 | Sessions, personas, streaming, stop | Done (no context-overflow summarization, no SwiftData persistence) |
| 58.7–58.9 | `@Generable` / `@Guide`, partial results | Done (Trip planner) |
| 58.10–58.11 | Tool calling + trace | Done (3 tools) |
| 58.12–58.15 | Multimodal, Vision tools, `LanguageModel` routing, cloud | Not yet |
| 58.16 | Latency / prewarm | Done |
| 58.17 | Guardrails | Done |
| 58.18 | Prompt injection | Done |
| 58.19 | Adapters | Not yet |
| 59.1–59.3 | Core ML predict | Partial (Vision's built-in classifier; no bundled `.mlpackage`) |
| 59.4 | Conversion | Done (`scripts/convert_model.py`, untested here) |
| 59.5–59.7 | Compression / compute-unit benchmarks | Not yet (needs bundled models; `Stats` is ready) |
| 59.8 | MLTensor | Done |
| 59.9–59.11 | Personalization, Core AI, MLX | Not yet |
| 60.1–60.3 | OCR, barcodes | Done (photo-based, no live camera/overlays) |
| 60.4–60.7 | Faces, similarity, document scan, speech | Not yet |
| 60.8 | Natural Language | Done |
| 60.9 | Semantic search | Done |
| 60.10–60.11 | Sound classification, Image Playground | Not yet |
| 61.x | AI-assisted development | Process, see `CLAUDE.md` |

## Verification status
Builds for iOS 26+ and the 8 unit tests pass on an iOS 26.4 simulator. **Nothing has been run on a physical device**; see `docs/device-test-log.md`.
