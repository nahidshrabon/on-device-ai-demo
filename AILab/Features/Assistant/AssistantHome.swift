import SwiftUI

struct AssistantHome: View {
    @State private var status = ModelStatus.current
    var body: some View {
        List {
            Section { AvailabilityBanner(status: status) }
            Section("Foundation Models (Section 58)") {
                NavigationLink("Chat + streaming (58.1–58.6)") { ChatView() }
                NavigationLink("Trip planner: @Generable (58.7–58.9)") { TripPlannerView() }
                NavigationLink("Tools (58.10–58.11)") { ToolsView() }
                NavigationLink("Latency lab (58.16)") { LatencyView() }
                NavigationLink("Guardrails (58.17)") { GuardrailsView() }
                NavigationLink("Prompt injection (58.18)") { InjectionView() }
            }
        }
        .navigationTitle("Assistant")
    }
}
