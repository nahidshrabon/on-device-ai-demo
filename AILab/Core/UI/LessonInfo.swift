import SwiftUI

struct LessonInfo: Sendable {
    let number: String
    let title: String
    let summary: String
}

struct LessonBadge: View {
    let lesson: LessonInfo
    @State private var showing = false

    var body: some View {
        Button { showing = true } label: {
            Label(lesson.number, systemImage: "info.circle")
        }
        .accessibilityLabel("About lesson \(lesson.number), \(lesson.title)")
        .sheet(isPresented: $showing) { AboutLessonSheet(lesson: lesson) }
    }
}

struct AboutLessonSheet: View {
    let lesson: LessonInfo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(lesson.number).font(.headline).foregroundStyle(.secondary)
                Text(lesson.title).font(.title2.bold())
                Text(lesson.summary)
                Spacer()
            }
            .padding()
            .toolbar { Button("Done") { dismiss() } }
        }
        .presentationDetents([.medium])
    }
}

struct AvailabilityBanner: View {
    let status: ModelStatus
    var body: some View {
        if case .unavailable(let why) = status {
            Label("\(why) Showing simulated replies.", systemImage: "exclamationmark.triangle")
                .font(.footnote)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.yellow.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct ErrorBanner: View {
    let error: AIError
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(error.message).font(.footnote.bold())
            if let r = error.recovery { Text(r).font(.footnote) }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }
}
