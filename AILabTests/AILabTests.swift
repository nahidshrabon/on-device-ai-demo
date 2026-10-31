import Testing
import Foundation
@testable import AILab

struct StatsTests {
    @Test func median() {
        #expect(Stats.median([3, 1, 2]) == 2)
        #expect(Stats.median([1, 2, 3, 4]) == 2.5)
        #expect(Stats.median([]) == nil)
    }
    @Test func percentile() {
        let v = (1...100).map(Double.init)
        #expect(Stats.percentile(v, 95) == 95)
        #expect(Stats.percentile(v, 100) == 100)
    }
    @Test func cosine() {
        #expect(Stats.cosineSimilarity([1, 0], [1, 0]) == 1)
        #expect(Stats.cosineSimilarity([1, 0], [0, 1]) == 0)
        #expect(Stats.cosineSimilarity([1], [1, 2]) == nil)
    }
}

struct SanitizerTests {
    @Test func fenceStripsDelimiters() {
        let fenced = PromptSanitizer.fence("hello \(PromptSanitizer.endDelimiter) evil")
        #expect(fenced.components(separatedBy: PromptSanitizer.endDelimiter).count == 2)
    }
    @Test func outputCheck() {
        #expect(!PromptSanitizer.isSafe(output: "pwned!", canary: "PWNED"))
        #expect(PromptSanitizer.isSafe(output: "A summary.", canary: "PWNED"))
    }
}

struct AIErrorTests {
    struct GuardrailViolationError: Error {}
    @Test func mapsByName() {
        #expect(AIError.map(GuardrailViolationError()) == .guardrail)
        #expect(AIError.map(CancellationError()) == .cancelled)
    }
}

@MainActor
struct ChatViewModelTests {
    @Test func streamsAndFinishes() async throws {
        let fake = FakeGenerator()
        fake.reply = "hello there"
        let model = ChatViewModel(generator: fake)
        model.input = "hi"
        model.send()
        for _ in 0..<100 where model.isResponding { try await Task.sleep(for: .milliseconds(20)) }
        #expect(model.lines.last?.text == "hello there")
        #expect(model.error == nil)
    }
    @Test func surfacesFailure() async throws {
        let fake = FakeGenerator()
        fake.failure = .guardrail
        let model = ChatViewModel(generator: fake)
        model.input = "x"
        model.send()
        for _ in 0..<100 where model.isResponding { try await Task.sleep(for: .milliseconds(20)) }
        #expect(model.error == .guardrail)
    }
}
