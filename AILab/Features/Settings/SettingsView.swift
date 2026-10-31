import SwiftUI
import FoundationModels

struct SettingsView: View {
    @AppStorage("debug.timing") private var showTiming = false
    @AppStorage("debug.prompts") private var showPrompts = false
    @AppStorage("debug.tools") private var showTools = true
    private let status = ModelStatus.current

    var body: some View {
        Form {
            Section("System model availability") {
                switch status {
                case .available: Label("Available", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                case .unavailable(let why): Label(why, systemImage: "xmark.circle")
                }
            }
            Section("Model routing") {
                Text("On-device only. Cloud routing (58.14–58.15) is not implemented; nothing leaves the device.")
            }
            Section("Debug overlays") {
                Toggle("Show timing", isOn: $showTiming)
                Toggle("Show raw prompts", isOn: $showPrompts)
                Toggle("Show tool traces", isOn: $showTools)
            }
            Section("Privacy") {
                Text("All processing happens on this device. The app makes no network calls and stores no face data.")
            }
        }
        .navigationTitle("Settings")
    }
}
