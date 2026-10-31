import Foundation

/// Benchmark statistics (lessons 58.16, 59.6).
enum Stats {
    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let s = values.sorted()
        let mid = s.count / 2
        return s.count.isMultiple(of: 2) ? (s[mid - 1] + s[mid]) / 2 : s[mid]
    }

    /// Nearest-rank percentile, `p` in 0...100.
    static func percentile(_ values: [Double], _ p: Double) -> Double? {
        guard !values.isEmpty else { return nil }
        let s = values.sorted()
        let rank = Int((p / 100 * Double(s.count)).rounded(.up))
        return s[min(max(rank, 1), s.count) - 1]
    }

    static func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double? {
        guard a.count == b.count, !a.isEmpty else { return nil }
        let dot = zip(a, b).reduce(0) { $0 + $1.0 * $1.1 }
        let na = a.reduce(0) { $0 + $1 * $1 }.squareRoot()
        let nb = b.reduce(0) { $0 + $1 * $1 }.squareRoot()
        guard na > 0, nb > 0 else { return nil }
        return dot / (na * nb)
    }
}
