import SwiftUI
import Combine

// Shared composition list used by both the session sheet and ProgressTrackerView.
// "Others" is always the last item — triggers a custom text field in the UI.
private let sessionCompositions: [String] = [
    "Alarippu",
    "Jathiswaram",
    "Shabdam",
    "Varnam",
    "Adavu Basics",
    "Asamyutha Hastas",
    "Samyutha Hastas",
    "Others",
]

// MARK: - Home tab

struct HomeTabView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var progressStore  = ProgressStore.shared
    @ObservedObject private var goalStore      = GoalStore.shared
    @ObservedObject private var milestoneStore = MilestoneStore.shared
    @State private var showSessionStart    = false
    @State private var showProgressTracker = false

    private var report: ProgressReport {
        ReportEngine.generate(
            progressStore:  progressStore,
            goalStore:      goalStore,
            milestoneStore: milestoneStore
        )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            BackgroundView().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    greetingSection
                    sectionDivider()
                    weeklyDotsSection
                    sectionDivider()
                    atAGlanceSection
                    sectionDivider()
                    lastSessionSection
                    sectionDivider()
                    suggestedCompositionSection
                    sectionDivider()
                    vivekaNudgeSection
                    sectionDivider()
                    quickLogSection
                    Spacer().frame(height: 90)
                }
            }

            // Floating start session button
            Button { showSessionStart = true } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.goldLight, .saffron],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 56, height: 56)
                        .shadow(color: .gold.opacity(0.5), radius: 10, x: 0, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color(hex: "120800"))
                }
            }
            .padding(.trailing, 24)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showSessionStart)    { SessionStartSheet() }
        .sheet(isPresented: $showProgressTracker) { ProgressTrackerView() }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(spacing: 6) {
            Spacer().frame(height: 28)
            Text(greeting)
                .font(.cinzel(21, weight: .bold))
                .foregroundStyle(LinearGradient.goldGradient)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
            Text(formattedDate)
                .font(.cormorant(14, italic: true))
                .tracking(1.5)
                .foregroundColor(.ivoryDim)
            Spacer().frame(height: 22)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let time: String
        switch hour {
        case 5..<12:  time = "Good morning"
        case 12..<17: time = "Good afternoon"
        default:      time = "Good evening"
        }
        let name = appState.userName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? time : "\(time), \(name)"
    }

    private var formattedDate: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, d MMMM yyyy"
        return f.string(from: Date())
    }

    // MARK: - At a glance

    private var atAGlanceSection: some View {
        HStack(spacing: 12) {
            glancePill(icon: "flame.fill",
                       value: "\(report.currentStreak)",
                       label: report.currentStreak == 1 ? "day streak" : "days streak")
            if let goal = report.upcomingGoals.first {
                glancePill(icon: "target", value: goal.text, label: "next goal")
            } else {
                glancePill(icon: "target", value: "No goal set", label: "next goal")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    @ViewBuilder
    private func glancePill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(LinearGradient.goldGradient)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.cinzel(13, weight: .bold))
                    .foregroundColor(.ivory)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text(label)
                    .font(.cormorant(14, italic: true))
                    .foregroundColor(.ivoryDim)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.2), lineWidth: 1))
        .cornerRadius(8)
    }

    // MARK: - Viveka nudge

    private var vivekaNudgeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VIVEKA")
                .font(.cinzel(10, weight: .bold))
                .tracking(2)
                .foregroundStyle(LinearGradient.goldGradient)
            Text(vivekaInsight)
                .font(.cormorant(14, italic: true))
                .foregroundColor(.ivory)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .padding(16)
        .background(LinearGradient.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(LinearGradient.goldGradient, lineWidth: 1))
        .cornerRadius(8)
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private var vivekaInsight: String {
        let fmt      = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let todayKey = fmt.string(from: Date())
        let cal      = Calendar.current
        let todayLogged  = progressStore.entryArrays[todayKey]?.contains(where: { $0.hasContent }) ?? false
        let streak       = report.currentStreak
        let longestStreak = report.longestStreak
        let allSessions  = progressStore.allSessionsList.filter { $0.entry.hasContent }

        let daysSinceLast: Int = {
            let last = allSessions.compactMap { fmt.date(from: $0.dateKey) }.max()
            guard let l = last else { return 999 }
            return max(0, cal.dateComponents([.day], from: l, to: Date()).day ?? 0)
        }()

        // Last seen date per composition (using all sessions)
        let neglected: (name: String, days: Int)? = {
            var lastSeen: [String: Date] = [:]
            for pair in allSessions where !pair.entry.workTitle.isEmpty {
                if let d = fmt.date(from: pair.dateKey) {
                    let t = pair.entry.workTitle
                    if lastSeen[t] == nil || d > lastSeen[t]! { lastSeen[t] = d }
                }
            }
            guard !lastSeen.isEmpty else { return nil }
            let oldest = lastSeen.min { $0.value < $1.value }
            guard let o = oldest,
                  let days = cal.dateComponents([.day], from: o.value, to: Date()).day,
                  days >= 5 else { return nil }
            return (name: o.key, days: days)
        }()

        let recentRatings: [Int] = allSessions
            .filter { $0.entry.quality > 0 }
            .sorted { $0.dateKey > $1.dateKey }
            .prefix(3)
            .map { $0.entry.quality }

        // Today's sessions
        let todayCount = progressStore.entryArrays[todayKey]?.filter({ $0.hasContent }).count ?? 0

        // Quality pattern for today's composition
        let lastSessionQuality = allSessions.last?.entry.quality ?? 0
        let lastSessionComp    = allSessions.last?.entry.workTitle ?? ""

        if streak > 0 && streak == longestStreak && streak >= 5 {
            return "A new personal best — \(streak) days in a row. This is your longest streak yet."
        }
        if streak >= 7 { return "Seven days in a row. That kind of consistency is rare. Keep it going." }
        if streak >= 4 { return "\(streak) days in a row. Momentum is building — don't let it break now." }
        if daysSinceLast >= 5 && !todayLogged {
            return "\(daysSinceLast) days without a session. Come back gently — the practice is still yours."
        }
        if daysSinceLast >= 3 && !todayLogged {
            return "It's been \(daysSinceLast) days since your last session. Even 20 minutes today matters."
        }
        // Reflect on today's session quality — no directive, just acknowledgement
        if todayLogged && lastSessionQuality > 0 && lastSessionQuality <= 2 && !lastSessionComp.isEmpty {
            return "Your \(lastSessionComp) session was rated \(lastSessionQuality)★ today. Every session leaves something behind."
        }
        if todayCount >= 2 {
            let comps = progressStore.entryArrays[todayKey]?
                .filter({ $0.hasContent && !$0.workTitle.isEmpty })
                .map { $0.workTitle } ?? []
            let unique = Array(Set(comps))
            if unique.count > 1 {
                return "You've logged \(todayCount) sessions today — \(unique.joined(separator: " and "))."
            }
            return "You've logged \(todayCount) sessions today."
        }
        if recentRatings.count >= 3 && recentRatings.allSatisfy({ $0 >= 4 }) {
            return "Your last three sessions were all rated \(recentRatings.min() ?? 4)★ or above. You've been in strong form."
        }
        if recentRatings.count >= 2 && recentRatings.prefix(2).allSatisfy({ $0 <= 2 }) {
            return "Your last two sessions were rated \(recentRatings[0])★ and \(recentRatings[1])★. That's part of the process."
        }
        if let n = neglected {
            return "\(n.name) was last logged \(n.days) day\(n.days == 1 ? "" : "s") ago."
        }
        if todayLogged { return "Session logged for today. Every practice, however small, is an offering." }
        return "You haven't logged a session yet today. The mat is waiting."
    }

    private func sectionDivider() -> some View {
        Color.gold.opacity(0.15).frame(height: 1).padding(.horizontal, 24)
    }

    // MARK: - Weekly practice dots

    private struct WeekDayDot: Identifiable {
        let id        = UUID()
        let date:      Date
        let label:     String
        let practiced: Bool
        let isToday:   Bool
    }

    private var weekDays: [WeekDayDot] {
        let cal     = Calendar.current
        let today   = Date()
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        // (weekday: 1=Sun … 7=Sat) → (weekday+5)%7 gives 0=Mon
        let daysFromMon = (cal.component(.weekday, from: today) + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysFromMon, to: today) else { return [] }
        return (0..<7).map { offset in
            let date      = cal.date(byAdding: .day, value: offset, to: monday) ?? today
            let practiced = progressStore.hasEntry(for: date)
            let isToday   = cal.isDate(date, inSameDayAs: today)
            return WeekDayDot(date: date, label: letters[offset],
                              practiced: practiced, isToday: isToday)
        }
    }

    private var weeklyMinutesDisplay: String {
        let cal = Calendar.current; let today = Date()
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let daysFromMon = (cal.component(.weekday, from: today) + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysFromMon, to: today) else { return "0m" }
        // Build the set of date keys for Mon–Sun this week
        let weekKeys: Set<String> = Set((0..<7).compactMap { off -> String? in
            guard let d = cal.date(byAdding: .day, value: off, to: monday) else { return nil }
            return fmt.string(from: d)
        })
        // Sum minutes from ALL sessions this week (supports multiple sessions per day)
        let total = progressStore.allSessionsList
            .filter { weekKeys.contains($0.dateKey) && $0.entry.hasContent }
            .reduce(0) { $0 + $1.entry.hours * 60 + $1.entry.minutes }
        // Count distinct days with any session
        let practicedDays = weekKeys.filter { progressStore.entryArrays[$0]?.contains(where: { $0.hasContent }) ?? false }.count
        if practicedDays == 0 { return "No sessions yet" }
        let h = total / 60; let m = total % 60
        if h == 0 && m == 0 {
            return "\(practicedDays) session\(practicedDays == 1 ? "" : "s") this week"
        }
        if h == 0 { return "\(m)m this week" }
        if m == 0 { return "\(h)h this week" }
        return "\(h)h \(m)m this week"
    }

    private var weeklyDotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("THIS WEEK")
                    .font(.cinzel(10, weight: .bold)).tracking(2)
                    .foregroundColor(.ivory.opacity(0.75))
                Spacer()
                Text(weeklyMinutesDisplay)
                    .font(.cormorant(15, italic: true))
                    .foregroundColor(.gold)
            }

            HStack(spacing: 0) {
                ForEach(weekDays) { day in
                    VStack(spacing: 6) {
                        Text(day.label)
                            .font(.cinzel(9)).tracking(1)
                            .foregroundColor(day.isToday ? .gold : .ivoryDim.opacity(0.5))
                        ZStack {
                            // Filled gold for practiced days; subtle ring for empty days
                            Circle()
                                .fill(day.practiced
                                      ? Color.gold
                                      : Color(hex: "1a0802"))
                                .frame(width: 30, height: 30)
                            Circle()
                                .stroke(
                                    day.practiced
                                        ? Color.gold
                                        : (day.isToday ? Color.gold : Color.gold.opacity(0.22)),
                                    lineWidth: day.isToday && !day.practiced ? 1.5 : (day.practiced ? 0 : 1)
                                )
                                .frame(width: 30, height: 30)
                            if day.practiced {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(hex: "120800"))
                            } else if day.isToday {
                                Circle()
                                    .fill(Color.gold.opacity(0.15))
                                    .frame(width: 30, height: 30)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    // MARK: - Last session card

    private struct LastSessionInfo {
        let entry:     PracticeEntry
        let dateLabel: String
    }

    private var lastSession: LastSessionInfo? {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        // allSessionsList is sorted oldest→newest, so last is the most recent session overall
        guard let last = progressStore.allSessionsList
            .filter({ $0.entry.hasContent })
            .last,
              let date = fmt.date(from: last.dateKey)
        else { return nil }

        let cal = Calendar.current
        let label: String
        if      cal.isDateInToday(date)     { label = "Today" }
        else if cal.isDateInYesterday(date) { label = "Yesterday" }
        else {
            let df = DateFormatter(); df.dateFormat = "d MMM"
            label = df.string(from: date)
        }
        return LastSessionInfo(entry: last.entry, dateLabel: label)
    }

    private var lastSessionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LAST SESSION")
                .font(.cinzel(10, weight: .bold)).tracking(2)
                .foregroundColor(.ivory.opacity(0.75))

            if let last = lastSession {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(last.entry.workTitle.isEmpty ? "Practice" : last.entry.workTitle)
                            .font(.cinzel(14, weight: .bold))
                            .foregroundColor(.ivory)
                            .lineLimit(1)
                        Text(last.dateLabel)
                            .font(.cormorant(14, italic: true))
                            .foregroundColor(.ivoryDim)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        if last.entry.hours > 0 || last.entry.minutes > 0 {
                            Text(last.entry.practiceTimeString)
                                .font(.cinzel(13, weight: .bold))
                                .foregroundStyle(LinearGradient.goldGradient)
                        }
                        if last.entry.quality > 0 {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { s in
                                    Image(systemName: s <= last.entry.quality ? "star.fill" : "star")
                                        .font(.system(size: 11))
                                        .foregroundColor(s <= last.entry.quality
                                                         ? .gold : .ivoryDim.opacity(0.22))
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .background(LinearGradient.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.2), lineWidth: 1))
                .cornerRadius(8)
            } else {
                Text("No sessions yet — tap + to start your first practice.")
                    .font(.cormorant(15, italic: true))
                    .foregroundColor(.ivoryDim.opacity(0.6))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    // MARK: - Viveka suggested composition

    private struct CompositionSuggestion {
        let name:   String
        let reason: String
    }

    private var suggestedComposition: CompositionSuggestion? {
        let known = ["Alarippu", "Jathiswaram", "Shabdam", "Varnam",
                     "Adavu Basics", "Asamyutha Hastas", "Samyutha Hastas"]
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let cal = Calendar.current; let today = Date()
        let allSessions = progressStore.allSessionsList.filter { $0.entry.hasContent }

        // Build per-composition stats from ALL sessions
        var lastSeen:     [String: Date] = [:]
        var sessionCount: [String: Int]  = [:]
        var lastQuality:  [String: Int]  = [:]

        for pair in allSessions where !pair.entry.workTitle.isEmpty {
            guard let d = fmt.date(from: pair.dateKey) else { continue }
            let raw = pair.entry.workTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            // Map to known bucket
            let bucket = known.first { raw.localizedCaseInsensitiveContains($0) } ?? raw
            sessionCount[bucket, default: 0] += 1
            if lastSeen[bucket] == nil || d > lastSeen[bucket]! {
                lastSeen[bucket] = d
                if pair.entry.quality > 0 { lastQuality[bucket] = pair.entry.quality }
            }
        }

        // ── Priority 1: last session for a composition was rated ≤2★ ──
        // Just state the fact — user decides what to do with it
        if let weak = known
            .compactMap({ n -> (String, Int, Date)? in
                guard let q = lastQuality[n], q <= 2, let d = lastSeen[n] else { return nil }
                return (n, q, d)
            })
            .sorted(by: { $0.1 < $1.1 })
            .first {
            let days = cal.dateComponents([.day], from: weak.2, to: today).day ?? 0
            let when = days == 0 ? "today" : days == 1 ? "yesterday" : "\(days) days ago"
            return CompositionSuggestion(
                name: weak.0,
                reason: "Last session was \(weak.1)★ · practised \(when)"
            )
        }

        // ── Priority 2: composition practised before but not for 5+ days ──
        // Reminder of what hasn't been visited recently — no instruction
        if let stale = known
            .compactMap({ n -> (String, Date)? in lastSeen[n].map { (n, $0) } })
            .filter({ cal.dateComponents([.day], from: $0.1, to: today).day ?? 0 >= 5 })
            .min(by: { $0.1 < $1.1 }),
           let days = cal.dateComponents([.day], from: stale.1, to: today).day {
            return CompositionSuggestion(
                name: stale.0,
                reason: "Last practised \(days) day\(days == 1 ? "" : "s") ago"
            )
        }

        // ── Priority 3: composition never logged yet ──
        // Only show if user already has at least 2 compositions in their log
        if let fresh = known.first(where: { lastSeen[$0] == nil }),
           lastSeen.count >= 2 {
            return CompositionSuggestion(name: fresh, reason: "Not yet in your practice log")
        }

        return nil
    }

    private var suggestedCompositionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VIVEKA SUGGESTS")
                .font(.cinzel(10, weight: .bold)).tracking(2)
                .foregroundColor(.ivory.opacity(0.75))

            if let s = suggestedComposition {
                HStack(spacing: 14) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 20))
                        .foregroundStyle(LinearGradient.goldGradient)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(s.name)
                            .font(.cinzel(14, weight: .bold))
                            .foregroundColor(.ivory)
                        Text(s.reason)
                            .font(.cormorant(15, italic: true))
                            .foregroundColor(.ivoryDim)
                    }
                    Spacer()
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "3d0f0f").opacity(0.7), Color(hex: "1c0400").opacity(0.8)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(LinearGradient.goldGradient, lineWidth: 1))
                .cornerRadius(8)
            } else {
                Text("Practise consistently to unlock personalised suggestions.")
                    .font(.cormorant(15, italic: true))
                    .foregroundColor(.ivoryDim.opacity(0.55))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    // MARK: - Quick log

    private var quickLogSection: some View {
        Button { showProgressTracker = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Log")
                        .font(.cinzel(11, weight: .bold)).tracking(2)
                        .foregroundColor(.ivory)
                    Text("Log a session without a timer")
                        .font(.cormorant(14, italic: true))
                        .foregroundColor(.ivoryDim)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(.ivoryDim.opacity(0.4))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(LinearGradient.cardBackground)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.2), lineWidth: 1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

// MARK: - Section card (kept for future composition pages)
struct SectionCard: View {
    let title:  String
    let sub:    String
    var action: (() -> Void)? = nil
    @State private var pressed = false

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: 0) {
                Color.gold.frame(width: 3)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.cinzel(10)).tracking(2.6).textCase(.uppercase).foregroundColor(.ivory)
                    Text(sub).font(.cormorant(13, italic: true)).foregroundColor(.ivoryDim)
                }
                .padding(.horizontal, 14).padding(.vertical, 13)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(Color.gold.opacity(0.5))
                    .padding(.trailing, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LinearGradient(
                colors: [Color(hex: "2c1208").opacity(pressed ? 0.53 : 0.27), Color(hex: "1a0802").opacity(0.14)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Rectangle().stroke(Color.gold.opacity(pressed ? 0.53 : 0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { p in pressed = p }, perform: {})
    }
}

// MARK: - Session start sheet

struct SessionStartSheet: View {
    @Environment(\.dismiss)    private var dismiss
    @State private var selectedComposition = ""
    @State private var customComposition   = ""   // used when "Others" is picked
    @State private var focusIntention      = ""
    @State private var checklistTexts      = ["", "", ""]
    @State private var navigateToTimer     = false

    // The composition name that actually gets saved / passed to the timer
    private var resolvedComposition: String {
        selectedComposition == "Others"
            ? customComposition.trimmingCharacters(in: .whitespacesAndNewlines)
            : selectedComposition
    }

    private var canStart: Bool {
        if selectedComposition.isEmpty { return false }
        if selectedComposition == "Others" { return !resolvedComposition.isEmpty }
        return true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Close button row
                        HStack {
                            Spacer()
                            Button { dismiss() } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.ivoryDim.opacity(0.7))
                                    .padding(10)
                                    .background(Color(hex: "2c1208").opacity(0.85))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gold.opacity(0.25), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                        OmSymbol(size: 22).padding(.bottom, 10)

                        Text("Begin Practice")
                            .font(.cinzel(18, weight: .bold))
                            .foregroundStyle(LinearGradient.goldGradient)
                            .padding(.bottom, 5)

                        Text("Set your intention before you begin")
                            .font(.cormorant(14, italic: true))
                            .foregroundColor(.ivoryDim)
                            .padding(.bottom, 28)

                        // ── Composition picker ─────────────────────────────
                        sheetSection(label: "Composition") {
                            VStack(spacing: 10) {
                                Menu {
                                    ForEach(sessionCompositions, id: \.self) { item in
                                        Button(item) {
                                            selectedComposition = item
                                            if item != "Others" { customComposition = "" }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedComposition.isEmpty
                                             ? "Select composition…"
                                             : selectedComposition)
                                            .font(.cormorant(16))
                                            .foregroundColor(selectedComposition.isEmpty
                                                             ? .ivoryDim.opacity(0.5) : .ivory)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 10, weight: .light))
                                            .foregroundColor(.gold.opacity(0.6))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 13)
                                    .background(Color(hex: "2c1208").opacity(0.85).cornerRadius(6))
                                    .overlay(RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gold.opacity(0.3), lineWidth: 1))
                                }

                                // Custom name field — only shown when "Others" is selected
                                if selectedComposition == "Others" {
                                    TextField("", text: $customComposition,
                                              prompt: Text("Enter composition name…")
                                                  .foregroundColor(Color.ivoryDim.opacity(0.4))
                                                  .italic())
                                        .font(.cormorant(16))
                                        .foregroundColor(.ivory)
                                        .autocorrectionDisabled()
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 13)
                                        .background(Color(hex: "2c1208").opacity(0.85).cornerRadius(6))
                                        .overlay(RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gold.opacity(0.3), lineWidth: 1))
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .animation(.easeInOut(duration: 0.18), value: selectedComposition)
                        }
                        .padding(.bottom, 18)

                        // ── Focus intention ────────────────────────────────
                        sheetSection(label: "Focus intention") {
                            TextField("", text: $focusIntention,
                                      prompt: Text("What will you focus on today?")
                                          .foregroundColor(Color.ivoryDim.opacity(0.4))
                                          .italic())
                                .font(.cormorant(16))
                                .foregroundColor(.ivory)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .background(Color(hex: "2c1208").opacity(0.85).cornerRadius(6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gold.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.bottom, 18)

                        // ── Session goals checklist ────────────────────────
                        sheetSection(label: "Session goals  (tick off mid-session)") {
                            VStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { i in
                                    HStack(spacing: 10) {
                                        Image(systemName: "circle")
                                            .font(.system(size: 9))
                                            .foregroundColor(.gold.opacity(0.4))
                                        TextField("", text: $checklistTexts[i],
                                                  prompt: Text("Goal \(i + 1)…")
                                                      .foregroundColor(Color.ivoryDim.opacity(0.35))
                                                      .italic())
                                            .font(.cormorant(15))
                                            .foregroundColor(.ivory)
                                            .autocorrectionDisabled()
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: "2c1208").opacity(0.85).cornerRadius(6))
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gold.opacity(0.25), lineWidth: 1))
                                }
                            }
                        }
                        .padding(.bottom, 32)

                        // ── Start button ───────────────────────────────────
                        Button { navigateToTimer = true } label: {
                            Text("Start Session")
                                .font(.cinzel(11, weight: .bold))
                                .tracking(3)
                                .textCase(.uppercase)
                                .foregroundColor(Color(hex: "120800"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: canStart
                                            ? [.goldLight, .saffron]
                                            : [Color.gold.opacity(0.3), Color.gold.opacity(0.3)],
                                        startPoint: .leading, endPoint: .trailing
                                    ).cornerRadius(8)
                                )
                        }
                        .disabled(!canStart)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToTimer) {
                SessionTimerView(
                    composition:    resolvedComposition,
                    focusIntention: focusIntention,
                    checklistItems: checklistTexts.map { $0.trimmingCharacters(in: .whitespaces) }
                                                  .filter { !$0.isEmpty },
                    onDone:         { dismiss() }
                )
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder
    private func sheetSection<Content: View>(label: String,
                                             @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.cinzel(9))
                .tracking(2)
                .foregroundColor(.ivoryDim.opacity(0.7))
            content()
        }
    }
}

// MARK: - Session timer view

struct SessionTimerView: View {
    let composition:    String
    let focusIntention: String
    let checklistItems: [String]
    let onDone:         () -> Void

    @ObservedObject private var progressStore = ProgressStore.shared
    @State private var startDate          = Date.distantFuture  // reset in onAppear
    @State private var isPaused           = false
    @State private var pauseStart:        Date?    = nil
    @State private var totalPausedSecs:   TimeInterval = 0
    @State private var displaySeconds:    Int      = 0
    @State private var checkedItems:      Set<Int> = []
    @State private var showRecap          = false
    @State private var showVarnamRef      = false
    @State private var recapQuality       = 0
    @State private var milestoneFired:    Set<Int> = []
    @State private var pausedForRecap     = false

    private let ticker = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

    private var elapsedSeconds: Int {
        let paused = isPaused ? (pauseStart.map { Date().timeIntervalSince($0) } ?? 0) : 0
        return max(0, Int(Date().timeIntervalSince(startDate) - totalPausedSecs - paused))
    }

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Spacer().frame(height: 20)
                    Text(composition)
                        .font(.cinzel(16, weight: .bold))
                        .foregroundStyle(LinearGradient.goldGradient)
                        .multilineTextAlignment(.center)
                    if !focusIntention.isEmpty {
                        Text(focusIntention)
                            .font(.cormorant(13, italic: true))
                            .foregroundColor(.ivoryDim)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Timer display
                VStack(spacing: 6) {
                    Text(timeString(displaySeconds))
                        .font(.custom("CinzelDecorative-Bold", size: 50 * appFontScale))
                        .foregroundStyle(LinearGradient.goldGradient)
                        .monospacedDigit()
                    Text(isPaused ? "Paused" : "In practice")
                        .font(.cormorant(13, italic: true))
                        .foregroundColor(.ivoryDim.opacity(0.55))
                }

                // Varnam reference button — centre of page, between timer and checklist
                if composition == "Varnam" {
                    Button { showVarnamRef = true } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "text.book.closed.fill")
                                .font(.system(size: 20, weight: .light))
                                .foregroundStyle(LinearGradient.goldGradient)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("VARNAM REFERENCE")
                                    .font(.cinzel(11, weight: .bold)).tracking(2)
                                    .foregroundColor(.ivory)
                                Text("Lyrics & emotions guide")
                                    .font(.cormorant(12, italic: true))
                                    .foregroundColor(.ivoryDim)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(.gold.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "3d1a04"), Color(hex: "2a1002")],
                                startPoint: .leading, endPoint: .trailing
                            )
                            .cornerRadius(12)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gold.opacity(0.45), lineWidth: 1))
                        .shadow(color: Color.gold.opacity(0.15), radius: 8, x: 0, y: 3)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                }

                Spacer()

                // Checklist
                if !checklistItems.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Session Goals")
                            .font(.cinzel(9)).tracking(2)
                            .foregroundColor(.ivoryDim.opacity(0.55))

                        ForEach(checklistItems.indices, id: \.self) { i in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    if checkedItems.contains(i) { checkedItems.remove(i) }
                                    else { checkedItems.insert(i) }
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: checkedItems.contains(i)
                                          ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 16))
                                        .foregroundColor(checkedItems.contains(i) ? .gold : .ivoryDim.opacity(0.35))
                                    Text(checklistItems[i])
                                        .font(.cormorant(15))
                                        .foregroundColor(checkedItems.contains(i) ? .ivoryDim : .ivory)
                                        .strikethrough(checkedItems.contains(i), color: .ivoryDim.opacity(0.5))
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: checkedItems)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient.cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.2), lineWidth: 1))
                    .cornerRadius(8)
                    .padding(.horizontal, 24)
                }

                Spacer()

                // Pause + End buttons
                HStack(spacing: 14) {
                    Button {
                        if isPaused {
                            if let ps = pauseStart { totalPausedSecs += Date().timeIntervalSince(ps) }
                            pauseStart = nil
                            isPaused   = false
                        } else {
                            pauseStart = Date()
                            isPaused   = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 13))
                            Text(isPaused ? "Resume" : "Pause")
                                .font(.cinzel(10)).tracking(1.5)
                        }
                        .foregroundColor(.ivory)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "1c0400"))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.3), lineWidth: 1))
                        .cornerRadius(8)
                    }

                    Button {
                        // Pause the timer while the recap overlay is visible
                        if !isPaused {
                            pauseStart     = Date()
                            isPaused       = true
                            pausedForRecap = true
                        }
                        showRecap = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 13))
                            Text("End Session")
                                .font(.cinzel(10)).tracking(1.5)
                        }
                        .foregroundColor(Color(hex: "120800"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [.goldLight, .saffron],
                                           startPoint: .leading, endPoint: .trailing)
                            .cornerRadius(8)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { startDate = Date() }
        .onReceive(ticker) { _ in
            guard !isPaused else { return }
            let s = elapsedSeconds
            guard s != displaySeconds else { return }
            displaySeconds = s
            for milestone in [1800, 3600] where s >= milestone && !milestoneFired.contains(milestone) {
                milestoneFired.insert(milestone)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
        .overlay { if showRecap { recapOverlay } }
        .sheet(isPresented: $showVarnamRef) { VarnamView() }
    }

    // MARK: - Recap overlay

    private var recapOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
                .onTapGesture {} // absorb taps behind the card

            VStack(spacing: 20) {
                Text("Session Complete")
                    .font(.cinzel(17, weight: .bold))
                    .foregroundStyle(LinearGradient.goldGradient)

                Text(timeString(displaySeconds))
                    .font(.custom("CinzelDecorative-Bold", size: 38 * appFontScale))
                    .foregroundStyle(LinearGradient.goldGradient)
                    .monospacedDigit()

                Text(composition)
                    .font(.cormorant(15, italic: true))
                    .foregroundColor(.ivoryDim)

                // Quality rating
                VStack(spacing: 10) {
                    Text("How did the session feel?")
                        .font(.cinzel(9)).tracking(2)
                        .foregroundColor(.ivoryDim.opacity(0.7))
                    HStack(spacing: 14) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    recapQuality = (recapQuality == star) ? 0 : star
                                }
                            } label: {
                                Image(systemName: star <= recapQuality ? "star.fill" : "star")
                                    .font(.system(size: 28))
                                    .foregroundColor(star <= recapQuality ? .gold : .ivoryDim.opacity(0.22))
                                    .scaleEffect(star <= recapQuality ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.2), value: recapQuality)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Save button
                Button {
                    saveSession()
                    onDone()
                } label: {
                    Text("Save Session")
                        .font(.cinzel(11, weight: .bold))
                        .tracking(3)
                        .foregroundColor(Color(hex: "120800"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [.goldLight, .saffron],
                                           startPoint: .leading, endPoint: .trailing)
                            .cornerRadius(8)
                        )
                }

                // Keep going — resume timer if it was paused by tapping End Session
                Button {
                    showRecap = false
                    if pausedForRecap {
                        if let ps = pauseStart {
                            totalPausedSecs += Date().timeIntervalSince(ps)
                        }
                        pauseStart     = nil
                        isPaused       = false
                        pausedForRecap = false
                    }
                } label: {
                    Text("Keep going")
                        .font(.cormorant(14, italic: true))
                        .foregroundColor(.ivoryDim.opacity(0.55))
                }
            }
            .padding(26)
            .background(Color(hex: "1a0802"))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gold.opacity(0.3), lineWidth: 1))
            .cornerRadius(14)
            .padding(.horizontal, 28)
        }
    }

    // MARK: - Save

    private func saveSession() {
        let totalMins = displaySeconds / 60
        var parts: [String] = []
        if !focusIntention.isEmpty { parts.append("Focus: \(focusIntention)") }
        let ticked = checklistItems.enumerated()
            .filter { checkedItems.contains($0.offset) }
            .map { "✓ \($0.element)" }
        let unticked = checklistItems.enumerated()
            .filter { !checkedItems.contains($0.offset) }
            .map { "○ \($0.element)" }
        let allGoals = ticked + unticked
        if !allGoals.isEmpty { parts.append(allGoals.joined(separator: "\n")) }

        progressStore.saveSession(date: Date(), entry: PracticeEntry(
            workTitle: composition,
            hours:     totalMins / 60,
            minutes:   totalMins % 60,
            remark:    parts.joined(separator: "\n\n"),
            quality:   recapQuality
        ))
    }

    // MARK: - Helpers

    private func timeString(_ s: Int) -> String {
        let h = s / 3600; let m = (s % 3600) / 60; let sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec)
                     : String(format: "%02d:%02d", m, sec)
    }
}
