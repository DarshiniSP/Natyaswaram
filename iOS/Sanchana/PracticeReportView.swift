import SwiftUI
import Charts

// MARK: - Period Report Model

struct PeriodReport {
    let startDate:            Date
    let endDate:              Date
    let totalSessions:        Int
    let totalMinutes:         Int
    let practiceDays:         Int          // unique calendar days with any session
    let avgQuality:           Double?      // nil if < 3 rated sessions
    let qualityTrend:         QualityTrend
    let compositionBreakdown: [(name: String, sessions: Int, minutes: Int)]
    let weeklyData:           [(weekLabel: String, sessions: Int, minutes: Int)]
    let topComposition:       String?
    let bestRatedSession:     (comp: String, quality: Int, date: Date)?
    let longestDay:           (minutes: Int, date: Date)?   // single-day peak
    let vivekasSummary:       String       // the intelligent narrative paragraph
    let highlights:           [String]     // bullet-point highlights for the report

    var totalHoursDisplay: String  { minutesToDisplay(totalMinutes) }
    var avgQualityDisplay: String  {
        guard let q = avgQuality else { return "—" }
        return String(format: "%.1f / 5", q)
    }
    var practiceDaysDisplay: String { "\(practiceDays)" }
    var totalSessionsDisplay: String { "\(totalSessions)" }
}

// MARK: - Period Report Engine

struct PeriodReportEngine {

    private static let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    static func generate(
        from start: Date,
        to   end:   Date,
        progressStore: ProgressStore,
        userName: String = ""
    ) -> PeriodReport {

        let cal    = Calendar.current
        let fmt    = self.fmt

        // Normalise range to day boundaries
        let startDay = cal.startOfDay(for: start)
        let endDay   = cal.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end

        // Filter sessions within range
        let sessions = progressStore.allSessionsList.filter { pair in
            guard pair.entry.hasContent,
                  let d = fmt.date(from: pair.dateKey) else { return false }
            return d >= startDay && d <= endDay
        }

        let totalSessions = sessions.count
        let totalMinutes  = sessions.reduce(0) { $0 + $1.entry.hours * 60 + $1.entry.minutes }
        let practiceDays  = Set(sessions.map { $0.dateKey }).count

        // Composition breakdown
        var compSessions: [String: Int]     = [:]
        var compMinutes:  [String: Int]     = [:]
        for pair in sessions {
            let t = pair.entry.workTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { continue }
            compSessions[t, default: 0] += 1
            compMinutes[t, default: 0]  += pair.entry.hours * 60 + pair.entry.minutes
        }
        let compositionBreakdown: [(name: String, sessions: Int, minutes: Int)] = compSessions
            .map { (name: $0.key, sessions: $0.value, minutes: compMinutes[$0.key] ?? 0) }
            .sorted { $0.sessions > $1.sessions }

        let topComposition = compositionBreakdown.first?.name

        // Rated sessions
        typealias Rated = (date: Date, quality: Int, comp: String, minutes: Int)
        let ratedSessions: [Rated] = sessions.compactMap { pair -> Rated? in
            guard pair.entry.quality > 0,
                  let d = fmt.date(from: pair.dateKey) else { return nil }
            return (d, pair.entry.quality,
                    pair.entry.workTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    pair.entry.hours * 60 + pair.entry.minutes)
        }.sorted { $0.date < $1.date }

        let avgQuality: Double? = ratedSessions.count >= 3
            ? Double(ratedSessions.reduce(0) { $0 + $1.quality }) / Double(ratedSessions.count)
            : nil

        // Quality trend
        let qualityTrend: QualityTrend = {
            guard ratedSessions.count >= 6 else { return .insufficient }
            let recent   = Array(ratedSessions.suffix(min(7, ratedSessions.count / 2)))
            let previous = Array(ratedSessions.dropLast(recent.count).suffix(recent.count))
            guard !previous.isEmpty else { return .insufficient }
            let ra = Double(recent.reduce(0)   { $0 + $1.quality }) / Double(recent.count)
            let pa = Double(previous.reduce(0) { $0 + $1.quality }) / Double(previous.count)
            if ra - pa > 0.4 { return .improving }
            if pa - ra > 0.4 { return .declining }
            return .stable
        }()

        // Best rated session
        let bestRatedSession = ratedSessions.max(by: { $0.quality < $1.quality })
            .map { (comp: $0.comp, quality: $0.quality, date: $0.date) }

        // Longest single-day practice
        var dayMinutes: [String: Int] = [:]
        for pair in sessions {
            dayMinutes[pair.dateKey, default: 0] += pair.entry.hours * 60 + pair.entry.minutes
        }
        let longestDay: (minutes: Int, date: Date)? = dayMinutes
            .max(by: { $0.value < $1.value })
            .flatMap { k, v -> (Int, Date)? in
                guard let d = fmt.date(from: k) else { return nil }
                return (v, d)
            }

        // Weekly data — group sessions by Monday-start week
        var weekBuckets: [String: (sessions: Int, minutes: Int)] = [:]
        for pair in sessions {
            guard let d = fmt.date(from: pair.dateKey) else { continue }
            let mon = cal.date(from: cal.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: d)) ?? d
            let key = fmt.string(from: mon)
            weekBuckets[key, default: (0, 0)].sessions += 1
            weekBuckets[key, default: (0, 0)].minutes  += pair.entry.hours * 60 + pair.entry.minutes
        }
        let weekLabelFmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "d MMM"; return f }()
        let weeklyData: [(weekLabel: String, sessions: Int, minutes: Int)] = weekBuckets
            .sorted { $0.key < $1.key }
            .map { k, v in
                let label = fmt.date(from: k).map { weekLabelFmt.string(from: $0) } ?? k
                return (weekLabel: label, sessions: v.sessions, minutes: v.minutes)
            }

        // Highlights
        var highlights: [String] = []

        if totalSessions >= 1 {
            highlights.append("\(totalSessions) session\(totalSessions == 1 ? "" : "s") logged across \(practiceDays) day\(practiceDays == 1 ? "" : "s").")
        }
        if let top = topComposition {
            let topSess = compSessions[top] ?? 0
            highlights.append("\(top) was the most practised with \(topSess) session\(topSess == 1 ? "" : "s").")
        }
        if let q = avgQuality {
            highlights.append("Average session quality: \(String(format: "%.1f", q)) out of 5.")
        }
        if let best = bestRatedSession, best.quality == 5 {
            let df = DateFormatter(); df.dateFormat = "d MMM"
            highlights.append("Excellent (\(best.quality)★) session in \(best.comp) on \(df.string(from: best.date)).")
        }
        if qualityTrend == .improving {
            highlights.append("Quality trended upward over this period.")
        } else if qualityTrend == .declining {
            highlights.append("Quality dipped toward the end of this period.")
        }

        // Viveka's narrative
        let narrative = generateNarrative(
            sessions: sessions,
            totalMinutes: totalMinutes,
            practiceDays: practiceDays,
            avgQuality: avgQuality,
            qualityTrend: qualityTrend,
            compositionBreakdown: compositionBreakdown,
            ratedSessions: ratedSessions,
            bestRatedSession: bestRatedSession,
            longestDay: longestDay,
            weeklyData: weeklyData,
            start: startDay,
            end: endDay,
            userName: userName
        )

        return PeriodReport(
            startDate:            startDay,
            endDate:              endDay,
            totalSessions:        totalSessions,
            totalMinutes:         totalMinutes,
            practiceDays:         practiceDays,
            avgQuality:           avgQuality,
            qualityTrend:         qualityTrend,
            compositionBreakdown: compositionBreakdown,
            weeklyData:           weeklyData,
            topComposition:       topComposition,
            bestRatedSession:     bestRatedSession,
            longestDay:           longestDay,
            vivekasSummary:       narrative,
            highlights:           highlights
        )
    }

    // MARK: - Narrative generator

    private static func generateNarrative(
        sessions:             [(dateKey: String, entry: PracticeEntry)],
        totalMinutes:         Int,
        practiceDays:         Int,
        avgQuality:           Double?,
        qualityTrend:         QualityTrend,
        compositionBreakdown: [(name: String, sessions: Int, minutes: Int)],
        ratedSessions:        [(date: Date, quality: Int, comp: String, minutes: Int)],
        bestRatedSession:     (comp: String, quality: Int, date: Date)?,
        longestDay:           (minutes: Int, date: Date)?,
        weeklyData:           [(weekLabel: String, sessions: Int, minutes: Int)],
        start:                Date,
        end:                  Date,
        userName:             String
    ) -> String {

        let totalSessions = sessions.count
        let periodFmt = DateFormatter(); periodFmt.dateFormat = "d MMMM yyyy"
        let dayFmt    = DateFormatter(); periodFmt.dateFormat = "d MMMM"

        // Empty data guard
        guard totalSessions > 0 else {
            return "No sessions were recorded during this period. Every practice begins with a single step — when you are ready, the mat will be there."
        }

        var parts: [String] = []

        // Opening: period overview
        let h = totalMinutes / 60, m = totalMinutes % 60
        let timeStr = h > 0 ? (m > 0 ? "\(h)h \(m)m" : "\(h)h") : "\(m)m"
        parts.append("Over this period, \(totalSessions) session\(totalSessions == 1 ? "" : "s") were logged across \(practiceDays) day\(practiceDays == 1 ? "" : "s"), totalling \(timeStr) of practice.")

        // Composition focus
        if let top = compositionBreakdown.first {
            let topTime = minutesToDisplay(top.minutes)
            if compositionBreakdown.count == 1 {
                parts.append("The focus was entirely on \(top.name), with \(top.sessions) session\(top.sessions == 1 ? "" : "s") dedicated to it.")
            } else {
                let second = compositionBreakdown.dropFirst().first
                if let s = second {
                    parts.append("\(top.name) received the most attention (\(top.sessions) session\(top.sessions == 1 ? "" : "s"), \(topTime)), followed by \(s.name) with \(s.sessions) session\(s.sessions == 1 ? "" : "s").")
                } else {
                    parts.append("\(top.name) received the most attention at \(top.sessions) session\(top.sessions == 1 ? "" : "s") (\(topTime)).")
                }
            }
        }

        // Quality read
        if let q = avgQuality {
            let qDesc: String
            switch q {
            case 4.5...: qDesc = "consistently strong — a mark of a focused period"
            case 3.5..<4.5: qDesc = "solid and steady"
            case 2.5..<3.5: qDesc = "mixed — some days pushed through, others held back"
            default: qDesc = "challenging, which is often where the most learning happens"
            }
            parts.append("Session quality averaged \(String(format: "%.1f", q)) out of 5 — \(qDesc).")

            // Trend
            switch qualityTrend {
            case .improving:
                parts.append("Quality trended upward as the period progressed, suggesting the body and mind were finding their rhythm.")
            case .declining:
                parts.append("Quality dipped toward the latter part of the period — rest, reflection, or a change of approach may help going forward.")
            case .stable:
                parts.append("Quality remained consistent throughout, showing a stable practice foundation.")
            case .insufficient:
                break
            }
        }

        // Best session callout
        if let best = bestRatedSession, best.quality >= 4 {
            let df = DateFormatter(); df.dateFormat = "d MMMM"
            let label = best.quality == 5 ? "Excellent" : "Strong"
            parts.append("\(label) session in \(best.comp) on \(df.string(from: best.date)) — rated \(best.quality)★.")
        }

        // Longest single day
        if let peak = longestDay, peak.minutes >= 60 {
            let df = DateFormatter(); df.dateFormat = "d MMMM"
            parts.append("The longest single-day practice was \(minutesToDisplay(peak.minutes)) on \(df.string(from: peak.date)).")
        }

        // Weekly rhythm
        if weeklyData.count >= 2 {
            let maxWeek = weeklyData.max(by: { $0.sessions < $1.sessions })
            let minWeek = weeklyData.min(by: { $0.sessions < $1.sessions })
            if let mx = maxWeek, let mn = minWeek, mx.weekLabel != mn.weekLabel {
                parts.append("Practice was most active during the week of \(mx.weekLabel) (\(mx.sessions) session\(mx.sessions == 1 ? "" : "s")).")
            }
        }

        // Diversity note
        if compositionBreakdown.count >= 4 {
            parts.append("With \(compositionBreakdown.count) different compositions in the log, this was a varied and rounded period of study.")
        } else if compositionBreakdown.count == 1 {
            parts.append("A focused period — single-composition dedication can build depth when that is the intention.")
        }

        // Closing reflection
        let closings = [
            "The log doesn't capture everything, but what's here reflects real time spent on the art.",
            "Every session recorded is a step held in memory — the body remembers even what the mind forgets.",
            "The practice speaks for itself."
        ]
        parts.append(closings[totalSessions % closings.count])

        return parts.joined(separator: " ")
    }
}

// MARK: - Shared helper

private func minutesToDisplay(_ m: Int) -> String {
    let h = m / 60, mn = m % 60
    if h == 0 && mn == 0 { return "0m" }
    if h == 0 { return "\(mn)m" }
    if mn == 0 { return "\(h)h" }
    return "\(h)h \(mn)m"
}

// MARK: - Main Report View

struct PracticeReportView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var progressStore = ProgressStore.shared

    // Date range state
    @State private var startDate: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
    }()
    @State private var endDate: Date = Date()
    @State private var report: PeriodReport?
    @State private var showingRangePicker = true   // start on picker
    @State private var isGenerating = false

    // Palette
    private let deepBg   = Color(red: 16/255, green: 2/255,  blue: 0/255)
    private let cardBg   = Color(hex: "1c0400")
    private let cardBg2  = Color(hex: "200500")

    var body: some View {
        ZStack {
            deepBg.ignoresSafeArea()

            if showingRangePicker {
                rangePicker
                    .transition(.opacity)
            } else if let rep = report {
                reportScroll(rep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingRangePicker)
    }

    // MARK: - Range Picker Screen

    private var rangePicker: some View {
        VStack(spacing: 0) {

            // Nav bar
            HStack {
                Button { dismiss() } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .light))
                        Text("Back")
                            .font(.cormorant(16, italic: true))
                    }
                    .foregroundColor(.gold)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {

                    // Header
                    VStack(spacing: 6) {
                        Text("Practice Report")
                            .font(.cinzel(18, weight: .bold))
                            .tracking(4)
                            .foregroundStyle(LinearGradient.goldGradient)
                        HStack(spacing: 10) {
                            Color.gold.opacity(0.3).frame(height: 1)
                            OmSymbol(size: 10)
                            Color.gold.opacity(0.3).frame(height: 1)
                        }
                        .padding(.horizontal, 40)
                        Text("Choose a period and Viveka will\nread the data and compose your report.")
                            .font(.cormorant(14, italic: true))
                            .foregroundColor(.ivoryDim)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    // Date pickers
                    VStack(spacing: 16) {
                        pickerCard(label: "From", date: $startDate, maxDate: endDate)
                        pickerCard(label: "To",   date: $endDate,   minDate: startDate)
                    }
                    .padding(.horizontal, 24)

                    // Range summary
                    let days = max(0, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1
                    let sessionCount = sessionsInRange()
                    VStack(spacing: 4) {
                        Text("\(days) day\(days == 1 ? "" : "s")  ·  \(sessionCount) session\(sessionCount == 1 ? "" : "s") logged")
                            .font(.cormorant(14, italic: true))
                            .foregroundColor(.ivoryDim)
                    }
                    .padding(.horizontal, 24)

                    // Generate button
                    Button(action: generateReport) {
                        HStack(spacing: 10) {
                            if isGenerating {
                                ProgressView()
                                    .tint(Color(red: 16/255, green: 2/255, blue: 0/255))
                                    .scaleEffect(0.8)
                            }
                            Text(isGenerating ? "Generating…" : "Generate Report")
                                .font(.cinzel(12, weight: .bold))
                                .tracking(3)
                                .textCase(.uppercase)
                        }
                        .foregroundColor(Color(red: 16/255, green: 2/255, blue: 0/255))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "e8b84b"), Color(hex: "c9922a")],
                                startPoint: .leading,
                                endPoint:   .trailing
                            )
                        )
                        .cornerRadius(6)
                    }
                    .disabled(isGenerating || sessionCount == 0)
                    .opacity(sessionCount == 0 ? 0.45 : 1)
                    .padding(.horizontal, 24)

                    if sessionCount == 0 {
                        Text("No sessions found in this range.")
                            .font(.cormorant(13, italic: true))
                            .foregroundColor(.ivoryDim.opacity(0.6))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private func pickerCard(label: String, date: Binding<Date>,
                             minDate: Date? = nil, maxDate: Date? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.cinzel(9)).tracking(2)
                .foregroundColor(.gold.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.top, 10)

            DatePicker(
                "",
                selection: date,
                in: (minDate ?? Date.distantPast)...(maxDate ?? Date()),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(.gold)
            .colorScheme(.dark)
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
        }
        .background(cardBg.cornerRadius(8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gold.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Report Scroll

    @ViewBuilder
    private func reportScroll(_ rep: PeriodReport) -> some View {
        VStack(spacing: 0) {

            // Nav bar
            HStack {
                Button {
                    withAnimation { showingRangePicker = true }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .light))
                        Text("Change Period")
                            .font(.cormorant(16, italic: true))
                    }
                    .foregroundColor(.gold)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    reportContent(rep)
                        .padding(.bottom, 48)
                }
            }
        }
    }

    @ViewBuilder
    private func reportContent(_ rep: PeriodReport) -> some View {
        VStack(spacing: 0) {

            // ── Report Header ──────────────────────────────────────────────────
            VStack(spacing: 8) {
                Text("SANCHANA")
                    .font(.cinzel(11, weight: .bold))
                    .tracking(6)
                    .foregroundColor(.gold.opacity(0.6))

                Text("Practice Report")
                    .font(.cinzel(22, weight: .black))
                    .tracking(3)
                    .foregroundStyle(LinearGradient.goldGradient)

                HStack(spacing: 10) {
                    Color.gold.opacity(0.25).frame(height: 1)
                    OmSymbol(size: 12)
                    Color.gold.opacity(0.25).frame(height: 1)
                }
                .padding(.horizontal, 30)

                Text(periodLabel(rep))
                    .font(.cormorant(14, italic: true))
                    .foregroundColor(.ivoryDim)
                    .tracking(1)
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .padding(.bottom, 24)

            // ── Stat Strip ─────────────────────────────────────────────────────
            HStack(spacing: 10) {
                statBox(value: rep.totalSessionsDisplay, label: "Sessions")
                statBox(value: rep.totalHoursDisplay,   label: "Total Time")
                statBox(value: rep.practiceDaysDisplay, label: "Days")
                statBox(value: rep.avgQualityDisplay,   label: "Avg Quality")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            sectionRule()

            // ── Composition Breakdown ──────────────────────────────────────────
            if !rep.compositionBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    sectionTitle("Composition Breakdown")

                    let maxSessions = rep.compositionBreakdown.first?.sessions ?? 1

                    ForEach(rep.compositionBreakdown, id: \.name) { item in
                        VStack(spacing: 5) {
                            HStack {
                                Text(item.name)
                                    .font(.cormorant(14))
                                    .foregroundColor(.ivory)
                                Spacer()
                                Text("\(item.sessions) session\(item.sessions == 1 ? "" : "s")")
                                    .font(.cormorant(13, italic: true))
                                    .foregroundColor(.ivoryDim)
                                Text("·")
                                    .foregroundColor(.ivoryDim.opacity(0.4))
                                Text(minutesToDisplay(item.minutes))
                                    .font(.cormorant(13, italic: true))
                                    .foregroundColor(.ivoryDim)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.gold.opacity(0.08))
                                        .frame(height: 6)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "e8b84b"), Color(hex: "9c2626")],
                                                startPoint: .leading,
                                                endPoint:   .trailing
                                            )
                                        )
                                        .frame(
                                            width: geo.size.width * CGFloat(item.sessions) / CGFloat(max(maxSessions, 1)),
                                            height: 6
                                        )
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                sectionRule()
            }

            // ── Quality Summary ────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Quality Summary")

                HStack(spacing: 14) {
                    // Avg quality dial
                    VStack(spacing: 4) {
                        Text(rep.avgQualityDisplay)
                            .font(.cinzel(22, weight: .bold))
                            .foregroundStyle(LinearGradient.goldGradient)
                        Text("Average")
                            .font(.cormorant(12, italic: true))
                            .foregroundColor(.ivoryDim)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(cardBg.cornerRadius(8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.18), lineWidth: 1))

                    // Trend box
                    VStack(spacing: 4) {
                        Image(systemName: trendIcon(rep.qualityTrend))
                            .font(.system(size: 22))
                            .foregroundColor(trendColor(rep.qualityTrend))
                        Text(trendLabel(rep.qualityTrend))
                            .font(.cormorant(12, italic: true))
                            .foregroundColor(.ivoryDim)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(cardBg.cornerRadius(8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.18), lineWidth: 1))

                    // Best session
                    if let best = rep.bestRatedSession {
                        VStack(spacing: 4) {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { s in
                                    Image(systemName: s <= best.quality ? "star.fill" : "star")
                                        .font(.system(size: 9))
                                        .foregroundColor(s <= best.quality ? .gold : Color.ivoryDim.opacity(0.2))
                                }
                            }
                            Text(best.comp.count > 10 ? String(best.comp.prefix(10)) + "…" : best.comp)
                                .font(.cormorant(12, italic: true))
                                .foregroundColor(.ivoryDim)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(cardBg.cornerRadius(8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.18), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            sectionRule()

            // ── Weekly Chart ───────────────────────────────────────────────────
            if rep.weeklyData.count >= 2 {
                VStack(alignment: .leading, spacing: 14) {
                    sectionTitle("Sessions by Week")

                    Chart(rep.weeklyData, id: \.weekLabel) { week in
                        BarMark(
                            x: .value("Week beginning", week.weekLabel),
                            y: .value("Sessions", week.sessions)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "e8b84b"), Color(hex: "c9922a")],
                                startPoint: .bottom,
                                endPoint:   .top
                            )
                        )
                        .cornerRadius(3)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel()
                                .font(.cormorant(10))
                                .foregroundStyle(Color.ivoryDim)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { v in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                                .foregroundStyle(Color.gold.opacity(0.15))
                            AxisValueLabel()
                                .font(.cormorant(10))
                                .foregroundStyle(Color.ivoryDim)
                        }
                    }
                    .frame(height: 160)
                    .padding(.top, 4)

                    // Axis labels
                    HStack {
                        Text("Sessions ↑")
                            .font(.cinzel(11, weight: .bold)).tracking(1)
                            .foregroundColor(.ivoryDim.opacity(0.7))
                        Spacer()
                        Text("Week beginning →")
                            .font(.cinzel(11, weight: .bold)).tracking(1)
                            .foregroundColor(.ivoryDim.opacity(0.7))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                sectionRule()
            }

            // ── Highlights ─────────────────────────────────────────────────────
            if !rep.highlights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Highlights")
                    ForEach(rep.highlights, id: \.self) { h in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.gold)
                                .padding(.top, 6)
                            Text(h)
                                .font(.cormorant(14))
                                .foregroundColor(.ivory)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                sectionRule()
            }

            // ── Viveka's Reading ───────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundColor(.gold)
                    Text("Viveka's Reading")
                        .font(.cinzel(11, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(LinearGradient.goldGradient)
                }

                Text(rep.vivekasSummary)
                    .font(.cormorant(15, italic: true))
                    .foregroundColor(.ivory)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .background(
                ZStack {
                    cardBg2.cornerRadius(10)
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: [Color.gold.opacity(0.35), Color.gold.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint:   .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            // ── Footer ─────────────────────────────────────────────────────────
            VStack(spacing: 6) {
                Color.gold.opacity(0.15).frame(height: 1)
                    .padding(.horizontal, 24)
                Text("SANCHANA  ·  \(periodLabel(rep))")
                    .font(.cinzel(8)).tracking(3)
                    .foregroundColor(.ivoryDim.opacity(0.4))
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.cinzel(14, weight: .bold))
                .foregroundStyle(LinearGradient.goldGradient)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.cormorant(10, italic: true))
                .foregroundColor(.ivoryDim)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(cardBg.cornerRadius(8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.18), lineWidth: 1))
    }

    @ViewBuilder
    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.cinzel(10, weight: .bold))
            .tracking(3)
            .foregroundStyle(LinearGradient.goldGradient)
    }

    @ViewBuilder
    private func sectionRule() -> some View {
        Color.gold.opacity(0.12).frame(height: 1)
            .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func generateReport() {
        isGenerating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            report = PeriodReportEngine.generate(
                from: startDate,
                to:   endDate,
                progressStore: progressStore
            )
            isGenerating = false
            withAnimation { showingRangePicker = false }
        }
    }

    private func sessionsInRange() -> Int {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let cal = Calendar.current
        let s   = cal.startOfDay(for: startDate)
        let e   = cal.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        return progressStore.allSessionsList.filter { pair in
            guard pair.entry.hasContent,
                  let d = fmt.date(from: pair.dateKey) else { return false }
            return d >= s && d <= e
        }.count
    }

    private func periodLabel(_ rep: PeriodReport) -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "d MMM yyyy"
        if Calendar.current.isDate(rep.startDate, equalTo: rep.endDate, toGranularity: .day) {
            return fmt.string(from: rep.startDate)
        }
        return "\(fmt.string(from: rep.startDate)) – \(fmt.string(from: rep.endDate))"
    }

    private func trendIcon(_ t: QualityTrend) -> String {
        switch t {
        case .improving:    return "arrow.up.right"
        case .declining:    return "arrow.down.right"
        case .stable:       return "minus"
        case .insufficient: return "questionmark"
        }
    }

    private func trendColor(_ t: QualityTrend) -> Color {
        switch t {
        case .improving:    return Color(red: 0.4, green: 0.8, blue: 0.5)
        case .declining:    return Color(red: 0.9, green: 0.4, blue: 0.3)
        case .stable:       return .ivoryDim
        case .insufficient: return .ivoryDim.opacity(0.5)
        }
    }

    private func trendLabel(_ t: QualityTrend) -> String {
        switch t {
        case .improving:    return "Improving"
        case .declining:    return "Declining"
        case .stable:       return "Stable"
        case .insufficient: return "Not enough data"
        }
    }
}
