import SwiftUI
import PhotosUI
import Vision
import NaturalLanguage

struct PerceptionHome: View {
    var body: some View {
        List {
            Section("Vision & Language (Section 60)") {
                NavigationLink("Text scanner OCR (60.1–60.2)") { OCRView() }
                NavigationLink("Code scanner (60.3)") { BarcodeView() }
                NavigationLink("Text analysis (60.8)") { TextAnalysisView() }
                NavigationLink("Semantic search (60.9)") { SemanticSearchView() }
            }
        }
        .navigationTitle("Perception")
    }
}

enum VisionService {
    static func recognizeText(_ data: Data) async throws -> [String] {
        try await Task.detached {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            try VNImageRequestHandler(data: data).perform([request])
            return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        }.value
    }

    static func detectBarcodes(_ data: Data) async throws -> [String] {
        try await Task.detached {
            let request = VNDetectBarcodesRequest()
            try VNImageRequestHandler(data: data).perform([request])
            return (request.results ?? []).compactMap(\.payloadStringValue)
        }.value
    }
}

/// Shared picker-to-analysis scaffold for the image-based screens.
struct ImageAnalysisScreen: View {
    let title: String
    let lesson: LessonInfo
    let analyze: @Sendable (Data) async throws -> [String]
    @State private var item: PhotosPickerItem?
    @State private var lines: [String] = []
    @State private var error: AIError?
    @State private var emptyNote = false

    var body: some View {
        Form {
            PhotosPicker("Choose photo", selection: $item, matching: .images)
            if let error { ErrorBanner(error: error) }
            if emptyNote { Text("Nothing found.").foregroundStyle(.secondary) }
            ForEach(Array(lines.enumerated()), id: \.offset) { _, l in Text(l).textSelection(.enabled) }
            if !lines.isEmpty {
                Button("Copy all", systemImage: "doc.on.doc") { UIPasteboard.general.string = lines.joined(separator: "\n") }
            }
        }
        .navigationTitle(title)
        .toolbar { LessonBadge(lesson: lesson) }
        .onChange(of: item) { _, new in
            guard let new else { return }
            Task {
                do {
                    guard let data = try await new.loadTransferable(type: Data.self) else { return }
                    lines = try await analyze(data)
                    emptyNote = lines.isEmpty
                    error = nil
                } catch { self.error = AIError.map(error) }
            }
        }
    }
}

struct OCRView: View {
    var body: some View {
        ImageAnalysisScreen(title: "Text scanner",
            lesson: .init(number: "60.1–60.2", title: "Text recognition", summary: "Vision text recognition on a photo; copy the result."),
            analyze: VisionService.recognizeText)
    }
}

struct BarcodeView: View {
    var body: some View {
        ImageAnalysisScreen(title: "Code scanner",
            lesson: .init(number: "60.3", title: "Barcodes & QR", summary: "Vision barcode detection on an imported photo."),
            analyze: VisionService.detectBarcodes)
    }
}

struct TextAnalysisView: View {
    @State private var text = "Tim Cook announced new products in Cupertino on Tuesday."
    @State private var rows: [String] = []

    var body: some View {
        Form {
            TextField("Text", text: $text, axis: .vertical)
            Button("Analyze") { rows = Self.analyze(text) }
            ForEach(Array(rows.enumerated()), id: \.offset) { _, r in Text(r).font(.footnote) }
        }
        .navigationTitle("Text analysis")
        .toolbar { LessonBadge(lesson: .init(number: "60.8", title: "Natural Language",
            summary: "Language ID, tokens, lemmas, parts of speech and named entities.")) }
    }

    static func analyze(_ text: String) -> [String] {
        var out: [String] = []
        if let lang = NLLanguageRecognizer.dominantLanguage(for: text) { out.append("Language: \(lang.rawValue)") }
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass, .lemma])
        tagger.string = text
        let opts: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: opts) { tag, range in
            if let tag, tag != .otherWord { out.append("Entity: \(text[range]) (\(tag.rawValue))") }
            return true
        }
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: opts) { tag, range in
            let lemma = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lemma).0?.rawValue ?? "-"
            out.append("\(text[range]) → \(tag?.rawValue ?? "?") · lemma \(lemma)")
            return true
        }
        return out
    }
}

struct SemanticSearchView: View {
    static let notes = [
        "Buy milk, eggs and bread at the grocery store",
        "Schedule a dentist appointment next week",
        "Ideas for the team offsite in the mountains",
        "Fix the crash in the login screen",
        "Recipe: pasta with tomato and basil",
        "Book flights for the holiday in Italy",
    ]
    @State private var query = "food shopping"
    @State private var semantic: [String] = []
    @State private var keyword: [String] = []
    @State private var note: String?

    var body: some View {
        Form {
            TextField("Query", text: $query)
            Button("Search") { search() }
            if let note { Text(note).font(.footnote).foregroundStyle(.secondary) }
            Section("Semantic (embeddings)") { ForEach(semantic, id: \.self, content: Text.init) }
            Section("Keyword") {
                if keyword.isEmpty { Text("No keyword matches").foregroundStyle(.secondary) }
                ForEach(keyword, id: \.self, content: Text.init)
            }
        }
        .navigationTitle("Semantic search")
        .toolbar { LessonBadge(lesson: .init(number: "60.9", title: "Embeddings",
            summary: "Sentence embeddings rank notes by meaning; compare with plain keyword matching.")) }
    }

    private func search() {
        keyword = Self.notes.filter { n in query.lowercased().split(separator: " ").contains { n.lowercased().contains($0) } }
        guard let embedding = NLEmbedding.sentenceEmbedding(for: .english) else {
            note = "Sentence embeddings aren't available on this device."; semantic = []; return
        }
        note = nil
        semantic = Self.notes
            .map { ($0, embedding.distance(between: query, and: $0)) }
            .sorted { $0.1 < $1.1 }.prefix(3).map(\.0)
    }
}
