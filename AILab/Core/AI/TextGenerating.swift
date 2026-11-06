import Foundation
import FoundationModels

/// Protocol seam so views and tests don't need Apple Intelligence hardware (section 9).
@MainActor
protocol TextGenerating: AnyObject {
    func reset(instructions: String)
    func prewarm()
    /// Yields cumulative text snapshots.
    func stream(_ prompt: String) -> AsyncThrowingStream<String, Error>
}

enum ModelStatus: Equatable {
    case available
    case unavailable(String)

    @MainActor static var current: ModelStatus {
        #if targetEnvironment(simulator)
        // Inference is refused in the Simulator ("Simulator is not supported"),
        // and availability there can misleadingly read as "downloading".
        return .unavailable("The iOS Simulator can't run the on-device model. Run on an Apple Intelligence iPhone.")
        #else
        return deviceStatus
        #endif
    }

    @MainActor private static var deviceStatus: ModelStatus {
        switch SystemLanguageModel.default.availability {
        case .available: return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible: return .unavailable("This device doesn't support Apple Intelligence.")
            case .appleIntelligenceNotEnabled: return .unavailable("Apple Intelligence is turned off in Settings.")
            case .modelNotReady: return .unavailable("The model is still downloading. Try again soon.")
            @unknown default: return .unavailable("The model is unavailable.")
            }
        }
    }
}

@MainActor
final class FoundationModelsGenerator: TextGenerating {
    private var session = LanguageModelSession()

    func reset(instructions: String) {
        session = LanguageModelSession(instructions: instructions)
    }

    func prewarm() { session.prewarm() }

    func stream(_ prompt: String) -> AsyncThrowingStream<String, Error> {
        let responseStream = session.streamResponse(to: prompt)
        return AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                do {
                    for try await snapshot in responseStream {
                        continuation.yield(snapshot.content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: AIError.map(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// Deterministic fake for previews, simulator and tests.
@MainActor
final class FakeGenerator: TextGenerating {
    var reply = "This is a simulated on-device reply used when Apple Intelligence is unavailable."
    var failure: AIError?
    func reset(instructions: String) {}
    func prewarm() {}
    func stream(_ prompt: String) -> AsyncThrowingStream<String, Error> {
        let words = reply.split(separator: " ").map(String.init)
        let failure = failure
        return AsyncThrowingStream { continuation in
            let task = Task {
                if let failure { continuation.finish(throwing: failure); return }
                var text = ""
                for w in words {
                    try? await Task.sleep(for: .milliseconds(40))
                    if Task.isCancelled { break }
                    text += (text.isEmpty ? "" : " ") + w
                    continuation.yield(text)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

@MainActor
func makeGenerator() -> any TextGenerating {
    ModelStatus.current == .available ? FoundationModelsGenerator() : FakeGenerator()
}
