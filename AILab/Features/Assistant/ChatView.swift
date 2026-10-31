import SwiftUI

struct ChatLine: Identifiable, Equatable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    var text: String
}

enum Persona: String, CaseIterable, Identifiable {
    case helpful = "Helpful"
    case pirate = "Pirate"
    case terse = "Terse"
    var id: String { rawValue }
    var instructions: String {
        switch self {
        case .helpful: "You are a friendly, helpful assistant."
        case .pirate: "You answer everything like a cheerful pirate."
        case .terse: "You answer in at most one short sentence."
        }
    }
}

@MainActor @Observable
final class ChatViewModel {
    var lines: [ChatLine] = []
    var input = ""
    var isResponding = false
    var error: AIError?
    var persona: Persona = .helpful { didSet { reset() } }
    private let generator: any TextGenerating
    private var task: Task<Void, Never>?

    init(generator: any TextGenerating) {
        self.generator = generator
        generator.reset(instructions: persona.instructions)
    }

    func reset() {
        cancel()
        lines = []
        error = nil
        generator.reset(instructions: persona.instructions)
    }

    func send() {
        let prompt = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isResponding else { return }
        input = ""
        error = nil
        lines.append(ChatLine(role: .user, text: prompt))
        lines.append(ChatLine(role: .assistant, text: ""))
        isResponding = true
        task = Task {
            do {
                for try await text in generator.stream(prompt) {
                    lines[lines.count - 1].text = text
                }
            } catch {
                let mapped = AIError.map(error)
                if mapped != .cancelled { self.error = mapped }
            }
            if lines.last?.text.isEmpty == true { lines.removeLast() }
            isResponding = false
        }
    }

    /// Stop leaves the partial reply in the transcript (58.6).
    func cancel() {
        task?.cancel()
        task = nil
        isResponding = false
    }
}

struct ChatView: View {
    @State private var model = ChatViewModel(generator: makeGenerator())
    private let status = ModelStatus.current

    var body: some View {
        VStack(spacing: 8) {
            AvailabilityBanner(status: status)
            Picker("Persona", selection: $model.persona) {
                ForEach(Persona.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(model.lines) { line in
                        Text(line.text)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: line.role == .user ? .trailing : .leading)
                            .background(line.role == .user ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12),
                                        in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("\(line.role == .user ? "You" : "Assistant"): \(line.text)")
                    }
                }
            }
            if let error = model.error { ErrorBanner(error: error) }
            HStack {
                TextField("Message", text: $model.input).textFieldStyle(.roundedBorder)
                    .onSubmit { model.send() }
                if model.isResponding {
                    Button("Stop", systemImage: "stop.fill") { model.cancel() }.labelStyle(.iconOnly)
                } else {
                    Button("Send", systemImage: "arrow.up.circle.fill") { model.send() }.labelStyle(.iconOnly)
                }
            }
        }
        .padding()
        .navigationTitle("Chat")
        .toolbar {
            LessonBadge(lesson: .init(number: "58.3–58.6", title: "Sessions & streaming",
                summary: "A multi-turn LanguageModelSession with persona instructions, streamed token snapshots and a stop button."))
            Button("New", systemImage: "trash") { model.reset() }
        }
    }
}
