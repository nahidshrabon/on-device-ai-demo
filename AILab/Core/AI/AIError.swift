import Foundation

/// One user-facing error type for every AI boundary (lesson 58.17 / 61.10).
enum AIError: Error, Equatable, Sendable {
    case unavailable
    case guardrail
    case contextOverflow
    case cancelled
    case permissionDenied(String)
    case other(String)

    /// Maps framework errors by name so we stay resilient to SDK drift.
    static func map(_ error: Error) -> AIError {
        if error is CancellationError { return .cancelled }
        if let ai = error as? AIError { return ai }
        let text = String(describing: error).lowercased()
        if text.contains("guardrail") || text.contains("refusal") { return .guardrail }
        if text.contains("exceededcontextwindow") || text.contains("contextwindow") { return .contextOverflow }
        if text.contains("assetsunavailable") || text.contains("unavailable") { return .unavailable }
        return .other(error.localizedDescription)
    }

    var message: String {
        switch self {
        case .unavailable: "The on-device model isn't available right now."
        case .guardrail: "The model declined this request (safety guardrails)."
        case .contextOverflow: "The conversation is too long for the model's context window."
        case .cancelled: "Cancelled."
        case .permissionDenied(let what): "Permission denied: \(what). Enable it in Settings."
        case .other(let text): text
        }
    }

    var recovery: String? {
        switch self {
        case .guardrail: "Try rephrasing your request."
        case .contextOverflow: "Start a new chat; a summary can be carried over."
        case .unavailable: "Check Settings > Apple Intelligence."
        default: nil
        }
    }
}
