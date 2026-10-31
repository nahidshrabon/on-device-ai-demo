import SwiftUI

@main
struct AILabApp: App {
    var body: some Scene {
        WindowGroup { RootTabView() }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Assistant", systemImage: "sparkles") { NavigationStack { AssistantHome() } }
            Tab("Models", systemImage: "cpu") { NavigationStack { ModelsHome() } }
            Tab("Perception", systemImage: "eye") { NavigationStack { PerceptionHome() } }
            Tab("Settings", systemImage: "gearshape") { NavigationStack { SettingsView() } }
        }
    }
}
