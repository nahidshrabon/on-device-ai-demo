import SwiftUI
import PhotosUI
import Vision
import CoreML

struct ModelsHome: View {
    var body: some View {
        List {
            Section("Core ML (Section 59)") {
                NavigationLink("Image classifier (59.1–59.3)") { ClassifierView() }
                NavigationLink("MLTensor lab (59.8)") { TensorLabView() }
                NavigationLink("Core ML vs Foundation Models (59.2)") { GuidanceView() }
            }
        }
        .navigationTitle("Models")
    }
}

struct Classification: Identifiable, Sendable {
    let id = UUID()
    let label: String
    let confidence: Float
}

enum ImageClassifier {
    /// Runs Apple's built-in classifier off the main actor and returns Sendable results.
    static func classify(_ data: Data) async throws -> [Classification] {
        try await Task.detached {
            let request = VNClassifyImageRequest()
            try VNImageRequestHandler(data: data).perform([request])
            let results = request.results ?? []
            return results.sorted { $0.confidence > $1.confidence }.prefix(5)
                .map { Classification(label: $0.identifier, confidence: $0.confidence) }
        }.value
    }
}

struct ClassifierView: View {
    @State private var item: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var results: [Classification] = []
    @State private var error: AIError?

    var body: some View {
        Form {
            PhotosPicker("Choose photo", selection: $item, matching: .images)
            if let image { Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 220) }
            if let error { ErrorBanner(error: error) }
            Section("Top 5") {
                ForEach(results) { r in
                    HStack { Text(r.label); Spacer(); Text(r.confidence, format: .percent.precision(.fractionLength(1))) }
                }
            }
            Text("Uses the system classifier via Vision. To use your own model, add an .mlpackage and load it with MLModel (see scripts/convert_model.py).")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .navigationTitle("Classifier")
        .toolbar { LessonBadge(lesson: .init(number: "59.1–59.3", title: "Predict with Core ML",
            summary: "Async, off-main-thread prediction with a top-5 result list.")) }
        .onChange(of: item) { _, new in
            guard let new else { return }
            Task {
                do {
                    guard let data = try await new.loadTransferable(type: Data.self) else { return }
                    image = UIImage(data: data)
                    results = try await ImageClassifier.classify(data)
                    error = nil
                } catch { self.error = AIError.map(error) }
            }
        }
    }
}

struct TensorLabView: View {
    @State private var output = ""
    var body: some View {
        Form {
            Button("Run softmax + cosine similarity") {
                Task { output = await Self.compute() }
            }
            Text(output).font(.system(.footnote, design: .monospaced))
        }
        .navigationTitle("MLTensor")
        .toolbar { LessonBadge(lesson: .init(number: "59.8", title: "MLTensor",
            summary: "Small tensor computations: softmax and cosine similarity.")) }
    }

    static func compute() async -> String {
        let logits = MLTensor(shape: [3], scalars: [2.0, 1.0, 0.1], scalarType: Float.self)
        let soft = await logits.softmax().shapedArray(of: Float.self).scalars
        let a: [Double] = [1, 2, 3], b: [Double] = [2, 4, 6.5]
        let cos = Stats.cosineSimilarity(a, b) ?? 0
        return "softmax: \(soft.map { String(format: "%.3f", $0) })\ncosine(a,b): \(String(format: "%.4f", cos))"
    }
}

struct GuidanceView: View {
    var body: some View {
        List {
            Text("Use Foundation Models for open-ended language: summarizing, extracting, chatting, tool use.")
            Text("Use Core ML for fixed-function models you train or convert: image/sound classification, regression, custom NLP, style transfer.")
            Text("Use Vision / Natural Language / Speech first when a system framework already solves the task.")
        }
        .navigationTitle("Which to use?")
    }
}
