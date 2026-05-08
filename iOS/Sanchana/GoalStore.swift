import Foundation
import Combine

// MARK: - Goal model

struct GoalEntry: Codable {
    var goalText: String = ""   // what the goal is

    var hasContent: Bool {
        !goalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Store

final class GoalStore: ObservableObject {

    static let shared = GoalStore()

    @Published private(set) var goals: [String: GoalEntry] = [:]

    private static let udKey = "goal_entries_v1"
    private let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    private init() { load() }

    // MARK: - Public API

    func save(date: Date, entry: GoalEntry) {
        let k = fmt.string(from: date)
        if !entry.hasContent { goals.removeValue(forKey: k) } else { goals[k] = entry }
        persist()
    }

    func goal(for date: Date) -> GoalEntry {
        goals[fmt.string(from: date)] ?? GoalEntry()
    }

    func hasGoal(for date: Date) -> Bool {
        goals[fmt.string(from: date)]?.hasContent ?? false
    }

    // MARK: - Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: Self.udKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.udKey),
              let decoded = try? JSONDecoder().decode([String: GoalEntry].self, from: data)
        else { return }
        goals = decoded
    }
}
