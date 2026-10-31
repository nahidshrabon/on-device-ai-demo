# AI Lab

Practice app for on-device AI (Foundation Models, Core ML, Vision, Natural Language). See README for the lesson map.

## Build & test
- Regenerate project: `xcodegen generate` (project.yml is the source of truth; `.xcodeproj` is committed for convenience).
- Build: `xcodebuild -scheme AILab -destination 'generic/platform=iOS Simulator' build`
- Test: create/choose an iOS 26+ simulator, then `xcodebuild test -scheme AILab -destination 'id=<UDID>'`

## Rules
- Swift 6, strict concurrency complete. View models are `@MainActor @Observable`.
- AI boundaries go behind protocols (`TextGenerating`) with fakes; tests must not need Apple Intelligence.
- Map framework errors through `AIError.map`. No force-unwraps. Treat model output as untrusted.
- No secrets in git; keys go in git-ignored `Secrets.xcconfig`.
- Review AI-generated changes for: missing `@MainActor`, non-Sendable captures, unbounded Tasks, retain cycles.
