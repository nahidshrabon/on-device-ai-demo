import SwiftUI
import FoundationModels

struct ToolCall: Identifiable {
    let id = UUID()
    let tool: String
    let arguments: String
    let result: String
}

@MainActor @Observable
final class ToolTraceLog {
    var calls: [ToolCall] = []
    func record(tool: String, arguments: String, result: String) {
        calls.append(ToolCall(tool: tool, arguments: arguments, result: result))
    }
}

struct WeatherTool: Tool {
    let name = "getWeather"
    let description = "Gets the current weather for a city (mock data)."
    let log: ToolTraceLog

    @Generable struct Arguments {
        @Guide(description: "City name") var city: String
    }

    func call(arguments: Arguments) async throws -> String {
        let table = ["lisbon": "24°C, sunny", "london": "13°C, rain", "tokyo": "19°C, cloudy"]
        let result = table[arguments.city.lowercased()] ?? "20°C, clear"
        await log.record(tool: name, arguments: arguments.city, result: result)
        return result
    }
}

struct UnitConversionTool: Tool {
    let name = "convertTemperature"
    let description = "Converts a temperature between Celsius and Fahrenheit."
    let log: ToolTraceLog

    @Generable struct Arguments {
        @Guide(description: "Temperature value") var value: Double
        @Guide(description: "Target unit", .anyOf(["C", "F"])) var to: String
    }

    func call(arguments: Arguments) async throws -> String {
        let out = arguments.to == "F" ? arguments.value * 9 / 5 + 32 : (arguments.value - 32) * 5 / 9
        let result = String(format: "%.1f°%@", out, arguments.to)
        await log.record(tool: name, arguments: "\(arguments.value) → \(arguments.to)", result: result)
        return result
    }
}

struct TimeTool: Tool {
    let name = "currentTime"
    let description = "Gets the current local time on this device."
    let log: ToolTraceLog

    @Generable struct Arguments {
        @Guide(description: "Ignored; pass 'now'") var note: String
    }

    func call(arguments: Arguments) async throws -> String {
        let result = Date.now.formatted(date: .abbreviated, time: .shortened)
        await log.record(tool: name, arguments: arguments.note, result: result)
        return result
    }
}

@MainActor @Observable
final class ToolsModel {
    let log = ToolTraceLog()
    var prompt = "What's the weather in Lisbon, in Fahrenheit?"
    var answer = ""
    var isRunning = false
    var error: AIError?

    func run() {
        guard ModelStatus.current == .available else { error = .unavailable; return }
        error = nil; answer = ""; log.calls = []; isRunning = true
        let prompt = prompt
        let tools: [any Tool] = [WeatherTool(log: log), UnitConversionTool(log: log), TimeTool(log: log)]
        Task {
            do {
                let session = LanguageModelSession(tools: tools, instructions: "Use tools to answer. Be brief.")
                answer = try await session.respond(to: prompt).content
            } catch { self.error = AIError.map(error) }
            isRunning = false
        }
    }
}

struct ToolsView: View {
    @State private var model = ToolsModel()
    var body: some View {
        Form {
            Section("Prompt") {
                TextField("Prompt", text: $model.prompt, axis: .vertical)
                Button("Run") { model.run() }.disabled(model.isRunning)
            }
            if let error = model.error { ErrorBanner(error: error) }
            if !model.answer.isEmpty { Section("Answer") { Text(model.answer) } }
            Section("Tool trace") {
                if model.log.calls.isEmpty { Text("No tool calls yet").foregroundStyle(.secondary) }
                ForEach(model.log.calls) { c in
                    VStack(alignment: .leading) {
                        Text(c.tool).font(.headline)
                        Text("args: \(c.arguments)").font(.footnote)
                        Text("result: \(c.result)").font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Tools")
        .toolbar {
            LessonBadge(lesson: .init(number: "58.10–58.11", title: "Tool calling",
                summary: "Three Tools the model can call. The trace shows each call; the default prompt needs two (weather, then conversion)."))
        }
    }
}
