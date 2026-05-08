import Foundation

// MARK: - Quality trend enum

enum QualityTrend {
    case improving      // recent sessions clearly better than before
    case declining      // recent sessions clearly worse
    case stable         // no significant change
    case insufficient   // not enough rated sessions to compare
}

// MARK: - Report data model

struct ProgressReport {

    // Milestones
    let totalMilestones:               Int
    let milestonesCompleted:           Int
    let completedMilestones:           [(title: String, date: Date)]
    let currentMilestone:              String?
    let averageDaysBetweenMilestones:  Int?

    // Practice — raw stats
    let totalSessions:         Int
    let totalPracticeMinutes:  Int
    let mostPracticedItem:     (title: String, sessions: Int)?
    let currentStreak:         Int
    let longestStreak:         Int
    let lastPracticeDate:      Date?
    let averageSessionMinutes: Int

    // Goals
    let totalGoalsSet:  Int
    let upcomingGoals:  [(text: String, deadline: Date)]

    // ── Intelligence layer ────────────────────────────────────────────────────
    let avgQualityRating:      Double?         // 1–5 average, nil if < 3 rated sessions
    let qualityTrend:          QualityTrend    // computed from last 7 vs previous 7 rated sessions
    let bestPracticeDay:       String?         // e.g. "Tuesday"
    let optimalSessionRange:   String?         // e.g. "30–60 min"
    let struggleAlert:         Bool            // 3 of last 5 rated sessions ≤ 2
    let milestoneProjection:   String?         // e.g. "approximately 3 weeks"
    let nlpInsightNote:        String?         // from Apple NL sentiment on long remarks
    let aiRecommendations:     [String]        // actionable, prioritised advice strings

    // ── Extended Viveka intelligence ──────────────────────────────────────────
    let burnoutWarning:        String?         // detected overtraining / fatigue pattern
    let goalFeasibility:       [(goal: String, deadline: Date, verdict: String, detail: String)]
    let crossPatternInsights:  [String]        // multi-signal observations

    // ── Deep Viveka intelligence (new) ────────────────────────────────────────
    // Per-composition quality arc: first-third avg vs last-third avg (≥5 rated sessions needed)
    let compositionArcs:           [(comp: String, firstAvg: Double, recentAvg: Double, count: Int)]
    // Personal pattern observations (gap length vs quality, duration vs quality)
    let personalPatterns:          [String]
    // One-line acknowledgement when a session or hour milestone is crossed
    let sessionMilestone:          String?
    // Human-readable summary of last week's practice
    let weeklyNarrative:           String?
    // Upcoming goal deadlines within 14 days — just the fact, no advice
    let upcomingDeadlineReminders: [(goal: String, daysLeft: Int)]
    // Surfaced NLP sentiment note (already computed; now exposed for display)
    var sentimentNote: String? { nlpInsightNote }

    // Summary
    let summaryLine: String

    // MARK: - Computed display helpers

    var totalHoursDisplay: String {
        let h = totalPracticeMinutes / 60
        let m = totalPracticeMinutes % 60
        if h == 0 && m == 0 { return "0m" }
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    var averageSessionDisplay: String {
        if averageSessionMinutes == 0 { return "—" }
        let h = averageSessionMinutes / 60
        let m = averageSessionMinutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    var avgQualityDisplay: String {
        guard let q = avgQualityRating else { return "—" }
        return String(format: "%.1f / 5", q)
    }
}

// MARK: - Engine

struct ReportEngine {

    private static let milestoneCount = 7
    private static let milestoneOrder = [
        "Adavu Basics", "Asamyutha Hastas", "Samyutha Hastas",
        "Alaripu", "Jathiswaram", "Shabdam", "Varnam"
    ]

    static func generate(
        progressStore:  ProgressStore,
        goalStore:      GoalStore,
        milestoneStore: MilestoneStore
    ) -> ProgressReport {

        let fmt = dateFmt()
        let cal = Calendar.current

        // ── Milestones ────────────────────────────────────────────────────────
        let achievements = milestoneStore.achievements

        let completedMilestones: [(title: String, date: Date)] = (0..<milestoneOrder.count)
            .compactMap { i -> (String, Date)? in
                guard let ach = achievements[i] else { return nil }
                return (milestoneOrder[i], ach.date)
            }
            .sorted { $0.date < $1.date }

        let currentMilestone: String? = {
            for i in 0..<milestoneOrder.count {
                if achievements[i] == nil { return milestoneOrder[i] }
            }
            return nil
        }()

        let averageDaysBetweenMilestones: Int? = {
            guard completedMilestones.count >= 2 else { return nil }
            let dates = completedMilestones.map { $0.date }
            var total = 0
            for i in 1..<dates.count {
                let diff = cal.dateComponents([.day], from: dates[i - 1], to: dates[i]).day ?? 0
                total += abs(diff)
            }
            return total / (dates.count - 1)
        }()

        // ── Practice — base stats (uses allSessionsList so multiple sessions/day count) ──
        let allSessions   = progressStore.allSessionsList.filter { $0.entry.hasContent }
        let totalSessions = allSessions.count
        let totalMinutes  = allSessions.reduce(0) { $0 + $1.entry.hours * 60 + $1.entry.minutes }
        let avgSession    = totalSessions > 0 ? totalMinutes / totalSessions : 0

        let mostPracticedItem: (title: String, sessions: Int)? = {
            var counts: [String: Int] = [:]
            for pair in allSessions {
                let t = pair.entry.workTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !t.isEmpty else { continue }
                counts[t, default: 0] += 1
            }
            guard let top = counts.max(by: { $0.value < $1.value }) else { return nil }
            return (top.key, top.value)
        }()

        // Streak is per-day so still use unique date keys
        let practiceDateKeys: Set<String> = Set(allSessions.map { $0.dateKey })

        var currentStreak = 0
        var checkDate     = Date()
        if !practiceDateKeys.contains(fmt.string(from: checkDate)) {
            checkDate = cal.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        while practiceDateKeys.contains(fmt.string(from: checkDate)) {
            currentStreak += 1
            checkDate = cal.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        var longestStreak = currentStreak
        if practiceDateKeys.count >= 2 {
            let sorted = practiceDateKeys.sorted()
            var run    = 1
            for i in 1..<sorted.count {
                if let d1 = fmt.date(from: sorted[i - 1]),
                   let d2 = fmt.date(from: sorted[i]),
                   cal.dateComponents([.day], from: d1, to: d2).day == 1 {
                    run += 1
                    longestStreak = max(longestStreak, run)
                } else {
                    run = 1
                }
            }
        }

        let lastPracticeDate: Date? = practiceDateKeys.sorted().last.flatMap { fmt.date(from: $0) }

        // ── Goals ─────────────────────────────────────────────────────────────
        let goals      = goalStore.goals
        let totalGoals = goals.values.filter { $0.hasContent }.count
        let now        = Date()
        let upcomingGoals: [(text: String, deadline: Date)] = goals
            .compactMap { k, v -> (String, Date)? in
                guard v.hasContent, let d = fmt.date(from: k), d >= now else { return nil }
                return (v.goalText, d)
            }
            .sorted { $0.deadline < $1.deadline }

        // ── Intelligence — rated sessions dataset ─────────────────────────────
        // Build a sorted array of (date, quality, sessionMinutes) for all
        // sessions that have been given a quality rating.
        typealias RatedSession = (date: Date, quality: Int, minutes: Int)
        let ratedSessions: [RatedSession] = allSessions
            .compactMap { pair -> RatedSession? in
                guard pair.entry.quality > 0, let d = fmt.date(from: pair.dateKey) else { return nil }
                return (d, pair.entry.quality, pair.entry.hours * 60 + pair.entry.minutes)
            }
            .sorted { $0.date < $1.date }

        // Average quality rating (need ≥ 3 rated sessions)
        let avgQuality: Double? = ratedSessions.count >= 3
            ? Double(ratedSessions.reduce(0) { $0 + $1.quality }) / Double(ratedSessions.count)
            : nil

        // Quality trend — last 7 rated vs previous 7 rated sessions
        let qualityTrend: QualityTrend = {
            guard ratedSessions.count >= 6 else { return .insufficient }
            let recent   = Array(ratedSessions.suffix(7))
            let previous = Array(ratedSessions.dropLast(7).suffix(7))
            guard !previous.isEmpty else { return .insufficient }
            let recentAvg  = Double(recent.reduce(0)   { $0 + $1.quality }) / Double(recent.count)
            let prevAvg    = Double(previous.reduce(0) { $0 + $1.quality }) / Double(previous.count)
            if recentAvg - prevAvg >  0.4 { return .improving }
            if prevAvg - recentAvg >  0.4 { return .declining }
            return .stable
        }()

        // Best practice day — day of week with highest avg quality (≥ 2 sessions)
        let bestPracticeDay: String? = {
            guard ratedSessions.count >= 5 else { return nil }
            var dayStats: [Int: (total: Int, count: Int)] = [:]
            for s in ratedSessions {
                let wd = cal.component(.weekday, from: s.date)
                dayStats[wd, default: (0, 0)].total += s.quality
                dayStats[wd, default: (0, 0)].count += 1
            }
            let validDays = dayStats.filter { $0.value.count >= 2 }
            guard let best = validDays.max(by: {
                Double($0.value.total) / Double($0.value.count)
                < Double($1.value.total) / Double($1.value.count)
            }) else { return nil }
            let names = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            return names[safe: best.key]
        }()

        // Optimal session range — duration bucket with highest avg quality
        let optimalSessionRange: String? = {
            guard ratedSessions.count >= 5 else { return nil }
            // Buckets: 0 = <30m, 1 = 30–60m, 2 = 60–90m, 3 = 90m+
            var buckets: [Int: (total: Int, count: Int)] = [:]
            for s in ratedSessions {
                let b: Int
                switch s.minutes {
                case ..<30:  b = 0
                case ..<60:  b = 1
                case ..<90:  b = 2
                default:     b = 3
                }
                buckets[b, default: (0, 0)].total += s.quality
                buckets[b, default: (0, 0)].count += 1
            }
            let valid = buckets.filter { $0.value.count >= 2 }
            guard let best = valid.max(by: {
                Double($0.value.total) / Double($0.value.count)
                < Double($1.value.total) / Double($1.value.count)
            }) else { return nil }
            let labels = ["Under 30 min", "30–60 min", "60–90 min", "Over 90 min"]
            return labels[safe: best.key]
        }()

        // Struggle alert — 3 of last 5 rated sessions scored ≤ 2
        let struggleAlert: Bool = {
            let recent = ratedSessions.suffix(5)
            guard recent.count >= 3 else { return false }
            return recent.filter { $0.quality <= 2 }.count >= 3
        }()

        // Milestone projection — time-based estimate for next milestone
        let milestoneProjection: String? = {
            guard let avgDays = averageDaysBetweenMilestones,
                  let last   = completedMilestones.last,
                  currentMilestone != nil
            else { return nil }
            let daysSince = cal.dateComponents([.day], from: last.date, to: Date()).day ?? 0
            let remaining = avgDays - daysSince
            if remaining <= 7  { return "soon — you may be ready" }
            let weeks = Int(ceil(Double(max(remaining, 1)) / 7.0))
            return "approximately \(weeks) week\(weeks == 1 ? "" : "s")"
        }()

        // NLP sentiment — only run on remarks with ≥ 15 words
        let nlpInsightNote: String? = {
            let longRemarks = allSessions
                .map { $0.entry.remark }
                .filter { $0.split(separator: " ").count >= 15 }
            guard longRemarks.count >= 3 else { return nil }
            guard let avg = SentimentEngine.averageScore(for: longRemarks) else { return nil }
            return SentimentEngine.insightNote(for: avg)
        }()

        // AI recommendations — assembled in priority order
        var recs: [String] = []

        if struggleAlert {
            recs.append("Your recent sessions suggest you've been finding practice difficult. Consider revisiting fundamentals before advancing to the next stage.")
        }

        if let last = lastPracticeDate {
            let daysSince = cal.dateComponents([.day], from: last, to: Date()).day ?? 0
            if daysSince > 6 {
                recs.append("You've been away for \(daysSince) day\(daysSince == 1 ? "" : "s"). A shorter, more focused return session tends to work better than jumping back at full intensity.")
            }
        }

        if let day = bestPracticeDay {
            recs.append("Your strongest sessions consistently fall on \(day)s. Protect this time in your schedule whenever possible.")
        }

        if let range = optimalSessionRange {
            recs.append("\(range) sessions produce your highest-quality practice. Aim for this range when you can.")
        }

        if let proj = milestoneProjection, let current = currentMilestone {
            recs.append("Based on your practice history, you could be ready to mark \(current) in \(proj).")
        }

        if let note = nlpInsightNote {
            recs.append(note)
        }

        // ── Burnout warning ───────────────────────────────────────────────────
        // Signal: ≥5 sessions in any rolling 7-day window AND avg quality of
        // those sessions ≤ 2.5, OR ≥4 sessions in last 5 days.
        let burnoutWarning: String? = {
            let sevenDaysAgo = cal.date(byAdding: .day, value: -7, to: now) ?? now
            let fiveDaysAgo  = cal.date(byAdding: .day, value: -5, to: now) ?? now

            let recentWeek = ratedSessions.filter { $0.date >= sevenDaysAgo }
            let recentFiveCount = allSessions.filter { pair in
                guard let d = fmt.date(from: pair.dateKey) else { return false }
                return d >= fiveDaysAgo
            }.count

            if recentFiveCount >= 4 {
                return "You've logged \(recentFiveCount) sessions in the last 5 days. Even dedicated dancers need rest — overtraining can slow progress and increase injury risk."
            }
            if recentWeek.count >= 5 {
                let weekAvg = Double(recentWeek.reduce(0) { $0 + $1.quality }) / Double(recentWeek.count)
                if weekAvg <= 2.5 {
                    return "You've practised intensively this week but your quality scores are dipping. This is a classic early-burnout pattern — a rest day may do more for you than another session."
                }
            }
            return nil
        }()

        // ── Goal feasibility ──────────────────────────────────────────────────
        // For each upcoming goal, estimate required daily sessions based on
        // historical practice frequency and advise.
        let goalFeasibility: [(goal: String, deadline: Date, verdict: String, detail: String)] = {
            guard !upcomingGoals.isEmpty, totalSessions > 0 else { return [] }

            // Average sessions per day over the entire history
            let firstDate: Date? = practiceDateKeys.sorted().first.flatMap { fmt.date(from: $0) }
            guard let start = firstDate else { return [] }
            let totalDays = max(1, cal.dateComponents([.day], from: start, to: now).day ?? 1)
            let avgSessionsPerDay = Double(totalSessions) / Double(totalDays)

            return upcomingGoals.map { g in
                let daysLeft = max(0, cal.dateComponents([.day], from: now, to: g.deadline).day ?? 0)
                if daysLeft == 0 {
                    return (g.text, g.deadline, "Deadline passed", "This goal's deadline has already passed.")
                }
                let projectedSessions = Int(avgSessionsPerDay * Double(daysLeft))
                if projectedSessions >= 5 {
                    return (g.text, g.deadline, "On track", "At your current pace you could fit in ~\(projectedSessions) sessions before this deadline — more than enough to make meaningful progress.")
                } else if projectedSessions >= 2 {
                    return (g.text, g.deadline, "Tight but possible", "You have \(daysLeft) days left. At your current practice frequency that's roughly \(projectedSessions) sessions — achievable, but you'll need consistency.")
                } else {
                    return (g.text, g.deadline, "At risk", "With \(daysLeft) day\(daysLeft == 1 ? "" : "s") remaining and your current practice frequency, this goal may be difficult to reach. Consider adjusting the deadline or increasing your practice days.")
                }
            }
        }()

        // ── Cross-pattern insights ─────────────────────────────────────────────
        // Connect multiple signals to surface observations a calculator wouldn't.
        var crossPatterns: [String] = []

        // Pattern: best day + struggle alert — poor days pulling down a strong day
        if let best = bestPracticeDay, struggleAlert {
            crossPatterns.append("Your \(best) sessions are your strongest, yet your recent quality is slipping. Try anchoring your most demanding repertoire to \(best)s and use other days for lighter review.")
        }

        // Pattern: long sessions not yielding quality
        if let range = optimalSessionRange, range == "Under 30 min",
           let avg = avgQuality, avg < 3.0 {
            crossPatterns.append("Your shorter sessions produce better quality than longer ones, but your average rating is still below 3. This suggests the issue may be focus or energy level, not duration — consider what time of day you practise.")
        }

        // Pattern: strong streak but declining quality
        if currentStreak >= 5, qualityTrend == .declining {
            crossPatterns.append("You've maintained a \(currentStreak)-day streak — impressive commitment — but your session quality is trending downward. A planned rest day within a streak is not failure; it's strategy.")
        }

        // Pattern: milestone pace slowdown
        if let avgDays = averageDaysBetweenMilestones, avgDays > 0 {
            let completedCount = completedMilestones.count
            if completedCount >= 2 {
                let lastTwo = completedMilestones.suffix(2)
                let arr = Array(lastTwo)
                if let gap = cal.dateComponents([.day], from: arr[0].date, to: arr[1].date).day,
                   gap > avgDays + 14 {
                    crossPatterns.append("Your last milestone took notably longer than your average. This can mean you're working on harder material — or that practice frequency has dipped. Check whether your session count has changed recently.")
                }
            }
        }

        // Pattern: goals set but low practice frequency
        if !upcomingGoals.isEmpty, totalSessions < 5 {
            crossPatterns.append("You've set \(upcomingGoals.count) goal\(upcomingGoals.count == 1 ? "" : "s") but have fewer than 5 logged sessions. Goals are most useful when paired with consistent practice — even short daily sessions compound quickly.")
        }

        let crossPatternInsights = crossPatterns

        // ── Composition quality arcs ─────────────────────────────────────────
        // For compositions with ≥5 rated sessions, compare first-third avg to last-third avg.
        let compositionArcs: [(comp: String, firstAvg: Double, recentAvg: Double, count: Int)] = {
            var byComp: [String: [(Date, Int)]] = [:]
            for pair in allSessions where pair.entry.hasContent && pair.entry.quality > 0 {
                let t = pair.entry.workTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !t.isEmpty, let d = fmt.date(from: pair.dateKey) else { continue }
                byComp[t, default: []].append((d, pair.entry.quality))
            }
            return byComp.compactMap { comp, sessions -> (String, Double, Double, Int)? in
                guard sessions.count >= 5 else { return nil }
                let sorted  = sessions.sorted { $0.0 < $1.0 }
                let chunk   = max(2, sorted.count / 3)
                let early   = Array(sorted.prefix(chunk))
                let recent  = Array(sorted.suffix(chunk))
                let eAvg    = Double(early.reduce(0)  { $0 + $1.1 }) / Double(early.count)
                let rAvg    = Double(recent.reduce(0) { $0 + $1.1 }) / Double(recent.count)
                guard abs(rAvg - eAvg) >= 0.6 else { return nil }   // only report meaningful change
                return (comp, eAvg, rAvg, sorted.count)
            }.sorted { abs($1.2 - $1.1) < abs($0.2 - $0.1) }        // largest change first
        }()

        // ── Personal patterns (gap length & duration vs quality) ─────────────
        var personalPatterns: [String] = []

        if ratedSessions.count >= 8 {
            // Gap-length pattern
            var gapData: [(gap: Int, quality: Int)] = []
            let sortedR = ratedSessions  // already sorted by date
            for i in 1..<sortedR.count {
                let gap = cal.dateComponents([.day], from: sortedR[i-1].date, to: sortedR[i].date).day ?? 0
                gapData.append((gap, sortedR[i].quality))
            }
            let shortGapQ = gapData.filter { $0.gap <= 2 }.map { $0.quality }
            let longGapQ  = gapData.filter { $0.gap >= 3 }.map { $0.quality }
            if shortGapQ.count >= 3 && longGapQ.count >= 3 {
                let sAvg = Double(shortGapQ.reduce(0,+)) / Double(shortGapQ.count)
                let lAvg = Double(longGapQ.reduce(0,+))  / Double(longGapQ.count)
                if sAvg - lAvg >= 0.8 {
                    personalPatterns.append(
                        String(format: "Sessions after 1–2 day gaps average %.1f★ — noticeably higher than after longer breaks (%.1f★). Shorter rest periods seem to suit your rhythm.", sAvg, lAvg)
                    )
                } else if lAvg - sAvg >= 0.8 {
                    personalPatterns.append(
                        String(format: "Sessions after 3+ day breaks average %.1f★ vs %.1f★ after shorter gaps — you tend to return with more focus after a longer rest.", lAvg, sAvg)
                    )
                }
            }
            // Duration pattern
            let shortQ  = ratedSessions.filter { $0.minutes > 0 && $0.minutes < 30 }.map { $0.quality }
            let mediumQ = ratedSessions.filter { $0.minutes >= 30 && $0.minutes < 60 }.map { $0.quality }
            let longQ   = ratedSessions.filter { $0.minutes >= 60 }.map { $0.quality }
            var buckets: [(label: String, avg: Double, count: Int)] = []
            if shortQ.count  >= 3 { buckets.append(("under 30 min",  Double(shortQ.reduce(0,+))  / Double(shortQ.count),  shortQ.count))  }
            if mediumQ.count >= 3 { buckets.append(("30–60 min",     Double(mediumQ.reduce(0,+)) / Double(mediumQ.count), mediumQ.count)) }
            if longQ.count   >= 3 { buckets.append(("over 60 min",   Double(longQ.reduce(0,+))   / Double(longQ.count),   longQ.count))   }
            if buckets.count >= 2,
               let best  = buckets.max(by: { $0.avg < $1.avg }),
               let worst = buckets.min(by: { $0.avg < $1.avg }),
               best.avg - worst.avg >= 0.8 {
                personalPatterns.append(
                    String(format: "Your %@ sessions average %.1f★ — your highest-rated duration. %@ sessions average %.1f★.", best.label, best.avg, worst.label, worst.avg)
                )
            }
        }

        // ── Session milestone ─────────────────────────────────────────────────
        let sessionMilestone: String? = {
            let totalMilestones = [10, 25, 50, 100, 200, 500]
            for m in totalMilestones where totalSessions == m {
                switch m {
                case 10:  return "10 sessions logged — the foundation of any practice is built in these early repetitions."
                case 25:  return "25 sessions. Consistency at this level is where habits start to become instinct."
                case 50:  return "50 sessions. That is a meaningful commitment to your craft."
                case 100: return "100 sessions. You have crossed a threshold very few reach."
                case 200: return "200 sessions. This is the dedication that separates serious practitioners."
                default:  return "\(m) sessions logged. A genuine milestone."
                }
            }
            // Composition milestones
            var compCounts: [String: Int] = [:]
            for pair in allSessions where !pair.entry.workTitle.isEmpty {
                compCounts[pair.entry.workTitle, default: 0] += 1
            }
            for (comp, count) in compCounts {
                if count == 10 { return "You have completed 10 \(comp) sessions. Repetition at this level is where muscle memory genuinely builds." }
                if count == 20 { return "20 \(comp) sessions logged. Sustained focus on one piece is how deep understanding develops." }
                if count == 30 { return "30 \(comp) sessions. You have spent real time inside this composition." }
            }
            // Hour milestones
            let totalH = totalMinutes / 60
            for h in [10, 25, 50, 100] where totalH == h {
                return "\(h) hours of practice logged. Time on the mat is the one thing that cannot be shortcut."
            }
            return nil
        }()

        // ── Weekly narrative ──────────────────────────────────────────────────
        let weeklyNarrative: String? = {
            let daysFromMon = (cal.component(.weekday, from: now) + 5) % 7
            guard let lastMon = cal.date(byAdding: .day, value: -daysFromMon - 7, to: now),
                  let lastSun = cal.date(byAdding: .day, value:  6, to: lastMon) else { return nil }
            let wkSessions = allSessions.filter { pair in
                guard let d = fmt.date(from: pair.dateKey) else { return false }
                return d >= lastMon && d <= lastSun && pair.entry.hasContent
            }
            guard !wkSessions.isEmpty else { return nil }
            let wkMins  = wkSessions.reduce(0) { $0 + $1.entry.hours * 60 + $1.entry.minutes }
            let wkComps = Array(Set(wkSessions.compactMap { e -> String? in
                let t = e.entry.workTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                return t.isEmpty ? nil : t
            }))
            let best = wkSessions.filter { $0.entry.quality > 0 }.max(by: { $0.entry.quality < $1.entry.quality })
            let wFmt = DateFormatter(); wFmt.dateFormat = "d MMM"
            var s = "Last week (\(wFmt.string(from: lastMon))–\(wFmt.string(from: lastSun))): \(wkSessions.count) session\(wkSessions.count == 1 ? "" : "s")"
            if wkMins > 0 {
                let h = wkMins / 60; let m = wkMins % 60
                if h > 0 && m > 0 { s += ", \(h)h \(m)m" }
                else if h > 0      { s += ", \(h)h" }
                else               { s += ", \(m)m" }
            }
            if wkComps.count == 1      { s += " of \(wkComps[0])" }
            else if wkComps.count > 1  { s += " across \(wkComps.count) compositions" }
            if let b = best {
                let c = b.entry.workTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                s += c.isEmpty ? ". Highest rated: \(b.entry.quality)★." : ". Highest rated: \(c) at \(b.entry.quality)★."
            } else { s += "." }
            return s
        }()

        // ── Upcoming deadline reminders (simple — no advice) ──────────────────
        let upcomingDeadlineReminders: [(goal: String, daysLeft: Int)] = upcomingGoals
            .compactMap { g in
                let days = cal.dateComponents([.day], from: now, to: g.deadline).day ?? 0
                guard days >= 0 && days <= 21 else { return nil }
                return (g.text, days)
            }

        // ── Summary line ──────────────────────────────────────────────────────
        let summaryLine: String = {
            let h = totalMinutes / 60
            let m = totalMinutes % 60
            var timePart: String
            if h > 0 && m > 0 { timePart = "\(h) hour\(h == 1 ? "" : "s") and \(m) minutes" }
            else if h > 0      { timePart = "\(h) hour\(h == 1 ? "" : "s")" }
            else if m > 0      { timePart = "\(m) minutes" }
            else               { timePart = "your very first steps" }

            let sessionPart = "\(totalSessions) session\(totalSessions == 1 ? "" : "s")"
            let nextPart    = currentMilestone
                .map { "Keep going — \($0) awaits." }
                ?? "You have completed your entire journey. Remarkable."

            return "You have dedicated \(timePart) to your practice across \(sessionPart). \(nextPart)"
        }()

        return ProgressReport(
            totalMilestones:              milestoneCount,
            milestonesCompleted:          completedMilestones.count,
            completedMilestones:          completedMilestones,
            currentMilestone:             currentMilestone,
            averageDaysBetweenMilestones: averageDaysBetweenMilestones,
            totalSessions:                totalSessions,
            totalPracticeMinutes:         totalMinutes,
            mostPracticedItem:            mostPracticedItem,
            currentStreak:                currentStreak,
            longestStreak:                longestStreak,
            lastPracticeDate:             lastPracticeDate,
            averageSessionMinutes:        avgSession,
            totalGoalsSet:                totalGoals,
            upcomingGoals:                upcomingGoals,
            avgQualityRating:             avgQuality,
            qualityTrend:                 qualityTrend,
            bestPracticeDay:              bestPracticeDay,
            optimalSessionRange:          optimalSessionRange,
            struggleAlert:                struggleAlert,
            milestoneProjection:          milestoneProjection,
            nlpInsightNote:               nlpInsightNote,
            aiRecommendations:            recs,
            burnoutWarning:               burnoutWarning,
            goalFeasibility:              goalFeasibility,
            crossPatternInsights:         crossPatternInsights,
            compositionArcs:              compositionArcs,
            personalPatterns:             personalPatterns,
            sessionMilestone:             sessionMilestone,
            weeklyNarrative:              weeklyNarrative,
            upcomingDeadlineReminders:    upcomingDeadlineReminders,
            summaryLine:                  summaryLine
        )
    }

    // MARK: - Private helpers

    private static func dateFmt() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
