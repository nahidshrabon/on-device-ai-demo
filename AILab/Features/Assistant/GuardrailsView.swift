import SwiftUI

struct GuardrailsView: View {
    @State private var model = ChatViewModel(generator: makeGenerator())
    @State private var prompt = "Write a detailed guide to something clearly harmful."
    @State private var reply = ""
    @State private var error: AIError?
    @State private var running = false

    var body: some View {
        Form {
            Section("Prompt that may trigger a guardrail") {
                TextField("Prompt", text: $prompt, axis: .vertical)
                Button("Send") { run(prompt) }.disabled(running)
            }
            if let error {
                ErrorBanner(error: error)
                Button("Retry with a safer rephrase") { run("Explain home safety basics for a household.") }
            }
            if !reply.isEmpty { Section("Reply") { Text(reply) } }
        }
        .navigationTitle("Guardrails")
        .toolbar {
            LessonBadge(lesson: .init(number: "58.17", title: "Guardrails",
                summary: "Guardrail violations and refusals are caught, mapped to AIError, and offered a rephrase."))
        }
    }

    private func run(_ text: String) {
        error = nil; reply = ""; running = true
        let generator = makeGenerator()
        generator.reset(instructions: "You are a careful assistant.")
        Task {
            do { for try await t in generator.stream(text) { reply = t } }
            catch { self.error = AIError.map(error) }
            running = false
        }
    }
}
