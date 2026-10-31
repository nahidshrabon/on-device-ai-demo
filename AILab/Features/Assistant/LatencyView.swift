import SwiftUI
import Charts
import FoundationModels

struct LatencySample: Identifiable {
    let id = UUID()
    let label: String
    let firstToken: Double
    let total: Double
}

@MainActor @Observable
final class LatencyModel {
    var prewarm = true
    var samples: [LatencySample] = []
    var isRunning = false
    var error: AIError?

    func run() {
        guard ModelStatus.current == .available else { error = .unavailable; return }
        error = nil; isRunning = true
        let warm = prewarm
        Task {
            do {
                let session = LanguageModelSession(instructions: "Be brief.")
                if warm { session.prewarm(); try await Task.sleep(for: .seconds(1)) }
                let clock = ContinuousClock()
                let start = clock.now
                var first: Double?
                for try await _ in session.streamResponse(to: "Name three fruits.") {
                    if first == nil { first = (clock.now - start).seconds }
                }
                let total = (clock.now - start).seconds
                samples.append(LatencySample(label: warm ? "warm #\(samples.count + 1)" : "cold #\(samples.count + 1)",
                                             firstToken: first ?? total, total: total))
            } catch { self.error = AIError.map(error) }
            isRunning = false
        }
    }
}

extension Duration {
    var seconds: Double { Double(components.seconds) + Double(components.attoseconds) / 1e18 }
}

struct LatencyView: View {
    @State private var model = LatencyModel()
    var body: some View {
        Form {
            Toggle("Pre-warm session", isOn: $model.prewarm)
            Button("Run request") { model.run() }.disabled(model.isRunning)
            if let error = model.error { ErrorBanner(error: error) }
            if !model.samples.isEmpty {
                Chart(model.samples) {
                    BarMark(x: .value("Run", $0.label), y: .value("Time to first token (s)", $0.firstToken))
                }.frame(height: 200)
                let ttft = model.samples.map(\.firstToken)
                Text("Median first token: \(Stats.median(ttft) ?? 0, specifier: "%.2f")s · p95: \(Stats.percentile(ttft, 95) ?? 0, specifier: "%.2f")s")
                    .font(.footnote)
            }
            Text("Budget: aim for under ~1s to first token when warmed.").font(.footnote).foregroundStyle(.secondary)
        }
        .navigationTitle("Latency lab")
        .toolbar {
            LessonBadge(lesson: .init(number: "58.16", title: "Latency",
                summary: "Compare time-to-first-token with and without prewarm()."))
        }
    }
}
