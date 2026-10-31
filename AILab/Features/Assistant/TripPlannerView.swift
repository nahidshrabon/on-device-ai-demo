import SwiftUI
import FoundationModels

@Generable
struct TripPlan {
    @Guide(description: "A catchy trip title")
    var title: String
    @Guide(description: "One-sentence overview")
    var overview: String
    @Guide(description: "Exactly three itinerary days", .count(3))
    var days: [TripDay]
}

@Generable
struct TripDay {
    @Guide(description: "Day number starting at 1", .range(1...3))
    var day: Int
    @Guide(description: "Short theme for the day")
    var theme: String
    @Guide(description: "Three activities", .count(3))
    var activities: [String]
}

@MainActor @Observable
final class TripPlannerModel {
    var destination = "Lisbon"
    var plan: TripPlan.PartiallyGenerated?
    var isRunning = false
    var error: AIError?
    private var task: Task<Void, Never>?

    func run() {
        guard ModelStatus.current == .available else {
            error = .unavailable
            return
        }
        error = nil
        plan = nil
        isRunning = true
        let destination = destination
        task = Task {
            do {
                let session = LanguageModelSession(instructions: "You plan short trips.")
                let stream = session.streamResponse(to: "Plan a 3-day trip to \(destination).", generating: TripPlan.self)
                for try await snapshot in stream { plan = snapshot.content }
            } catch {
                let mapped = AIError.map(error)
                if mapped != .cancelled { self.error = mapped }
            }
            isRunning = false
        }
    }

    func cancel() { task?.cancel(); isRunning = false }
}

struct TripPlannerView: View {
    @State private var model = TripPlannerModel()
    var body: some View {
        Form {
            Section {
                TextField("Destination", text: $model.destination)
                Button(model.isRunning ? "Stop" : "Plan trip") {
                    model.isRunning ? model.cancel() : model.run()
                }
            }
            if let error = model.error { ErrorBanner(error: error) }
            if let plan = model.plan {
                Section(plan.title ?? "…") {
                    Text(plan.overview ?? "…").foregroundStyle(.secondary)
                    ForEach(Array((plan.days ?? []).enumerated()), id: \.offset) { _, day in
                        VStack(alignment: .leading) {
                            Text("Day \(day.day.map(String.init) ?? "…"): \(day.theme ?? "…")").font(.headline)
                            ForEach(Array((day.activities ?? []).enumerated()), id: \.offset) { _, a in
                                Text("• \(a)")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Trip planner")
        .toolbar {
            LessonBadge(lesson: .init(number: "58.7–58.9", title: "Guided generation",
                summary: "@Generable types with @Guide constraints; PartiallyGenerated fields appear progressively while streaming."))
        }
    }
}
