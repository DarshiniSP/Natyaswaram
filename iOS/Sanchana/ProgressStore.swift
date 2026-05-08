import Foundation
import Combine

// MARK: - Entry model

struct PracticeEntry: Codable {
    var workTitle: String = ""   // what they worked on (short name)
    var hours:     Int    = 0    // practice hours (0-8)
    var minutes:   Int    = 0    // practice minutes (0,5,10…55)
    var remark:    String = ""   // free-form description
    var quality:   Int    = 0    // session quality 1–5 (0 = unrated)

    // Custom decoder — existing stored entries that pre-date the quality field
    // will decode quality as 0 (unrated) rather than throwing an error.
    enum CodingKeys: String, CodingKey {
        case workTitle, hours, minutes, remark, quality
    }

    init(workTitle: String = "", hours: Int = 0, minutes: Int = 0,
         remark: String = "", quality: Int = 0) {
        self.workTitle = workTitle
        self.hours     = hours
        self.minutes   = minutes
        self.remark    = remark
        self.quality   = quality
    }

    init(from decoder: Decoder) throws {
        let c     = try decoder.container(keyedBy: CodingKeys.self)
        workTitle = try c.decodeIfPresent(String.self, forKey: .workTitle) ?? ""
        hours     = try c.decodeIfPresent(Int.self,    forKey: .hours)     ?? 0
        minutes   = try c.decodeIfPresent(Int.self,    forKey: .minutes)   ?? 0
        remark    = try c.decodeIfPresent(String.self, forKey: .remark)    ?? ""
        quality   = try c.decodeIfPresent(Int.self,    forKey: .quality)   ?? 0
    }

    var hasContent: Bool {
        !workTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        hours > 0 || minutes > 0 ||
        !remark.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var practiceTimeString: String {
        switch (hours, minutes) {
        case (0, 0): return ""
        case (0, _): return "\(minutes)m"
        case (_, 0): return "\(hours)h"
        default:     return "\(hours)h \(minutes)m"
        }
    }
}

// MARK: - Store

final class ProgressStore: ObservableObject {

    static let shared = ProgressStore()

    // Internal storage: multiple sessions per day
    @Published private(set) var entryArrays: [String: [PracticeEntry]] = [:]

    // Backward compat — returns last entry per day (used by calendar, streak, ReportEngine)
    var entries: [String: PracticeEntry] {
        entryArrays.compactMapValues { $0.last }
    }

    // All sessions as a flat sorted list (used by analytics views)
    var allSessionsList: [(dateKey: String, entry: PracticeEntry)] {
        entryArrays
            .flatMap { k, v in v.map { (dateKey: k, entry: $0) } }
            .sorted { $0.dateKey < $1.dateKey }
    }

    private static let udKey   = "pt_entries_v3"
    private static let udKeyV2 = "pt_entries_v2"

    private let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    private init() { load() }

    // MARK: - Public API

    /// Append a new session for the given day — allows multiple sessions per day.
    /// Used by SessionTimerView.
    func saveSession(date: Date, entry: PracticeEntry) {
        guard entry.hasContent else { return }
        let k = fmt.string(from: date)
        entryArrays[k, default: []].append(entry)
        persist()
    }

    /// Replace all sessions for a day with a single entry.
    /// Used by manual log (ProgressTrackerView). Passing an empty entry removes the day.
    func save(date: Date, entry: PracticeEntry) {
        let k = fmt.string(from: date)
        if !entry.hasContent { entryArrays.removeValue(forKey: k) }
        else { entryArrays[k] = [entry] }
        persist()
    }

    func entry(for date: Date) -> PracticeEntry {
        entryArrays[fmt.string(from: date)]?.last ?? PracticeEntry()
    }

    func hasEntry(for date: Date) -> Bool {
        entryArrays[fmt.string(from: date)]?.contains(where: { $0.hasContent }) ?? false
    }

    // MARK: - Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(entryArrays) {
            UserDefaults.standard.set(data, forKey: Self.udKey)
        }
    }

    private func load() {
        // Try v3 format first
        if let data = UserDefaults.standard.data(forKey: Self.udKey),
           let decoded = try? JSONDecoder().decode([String: [PracticeEntry]].self, from: data) {
            entryArrays = decoded
            return
        }
        // Migrate from v2 (single entry per day → wrap in array)
        if let data = UserDefaults.standard.data(forKey: Self.udKeyV2),
           let decoded = try? JSONDecoder().decode([String: PracticeEntry].self, from: data) {
            entryArrays = decoded.mapValues { [$0] }
            persist()   // write v3 immediately
        }
    }
}
