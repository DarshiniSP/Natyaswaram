import Foundation
import NaturalLanguage

// MARK: - On-device sentiment analysis using Apple's NaturalLanguage framework
// Uses a trained neural model that ships with iOS — no API, no network required.

struct SentimentEngine {

    /// Minimum word count before sentiment analysis is considered reliable.
    private static let minWordCount = 15

    // MARK: - Public API

    /// Returns a sentiment score in [-1.0, 1.0] for the given text,
    /// or nil if the text is too short to produce a meaningful result.
    /// -1.0 = strongly negative, 0.0 = neutral, +1.0 = strongly positive.
    static func score(for text: String) -> Double? {
        let wordCount = text.split(separator: " ").count
        guard wordCount >= minWordCount else { return nil }

        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        var totalScore: Double = 0
        var sampleCount = 0

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .paragraph,
            scheme: .sentimentScore,
            options: []
        ) { tag, _ in
            if let tag, let value = Double(tag.rawValue) {
                totalScore   += value
                sampleCount  += 1
            }
            return true
        }

        guard sampleCount > 0 else { return nil }
        return totalScore / Double(sampleCount)
    }

    /// Scores multiple remarks and returns their average, or nil if no
    /// remark was long enough for reliable analysis.
    static func averageScore(for remarks: [String]) -> Double? {
        let scores = remarks.compactMap { score(for: $0) }
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    /// Converts an average score to a human-readable insight string,
    /// or nil if the score is too close to neutral to be meaningful.
    static func insightNote(for averageScore: Double) -> String? {
        switch averageScore {
        case 0.35...:
            return "Your practice notes reflect a growing confidence. The positivity in your writing suggests your technique is settling in well."
        case ..<(-0.25):
            return "Your session notes suggest recent difficulty. Struggle is a natural part of mastering classical dance — consider focusing on one element at a time before moving forward."
        default:
            return nil   // neutral — not meaningful enough to surface
        }
    }
}
