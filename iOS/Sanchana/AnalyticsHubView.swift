import SwiftUI
import Charts

// MARK: - Period picker enum

enum AnalyticsPeriod: String, CaseIterable {
    case week   = "Week"
    case month  = "Month"
    case months = "3 Months"
    case all    = "All Time"

    func startDate(from now: Date = Date()) -> Date? {
        let cal = Calendar.current
        switch self {
        case .week:   return cal.date(byAdding: .day,   value: -7,  to: now)
        case .month:  return cal.date(byAdding: .month, value: -1,  to: now)
        case .months: return cal.date(byAdding: .month, value: -3,  to: now)
        case .all:    return nil
        }
    }
}

// MARK: - Analytics Hub (main screen)

struct AnalyticsHubView: View {
    @ObservedObject private var progressStore  = ProgressStore.shared
    @ObservedObject private var goalStore      = GoalStore.shared
    @ObservedObject private var milestoneStore = MilestoneStore.shared

    private var report: ProgressReport {
        ReportEngine.generate(
            progressStore:  progressStore,
            goalStore:      goalStore,
            milestoneStore: milestoneStore
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Header ────────────────────────────────────────────
                        VStack(spacing: 6) {
                            Spacer().frame(height: 18)
                            Text("Analytics")
                                .font(.cinzel(30, weight: .black))
                                .foregroundStyle(LinearGradient.goldGradient)
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)

                            HStack(spacing: 10) {
                                GoldRule()
                                OmSymbol(size: 11)
                                GoldRule()
                            }
                            .padding(.horizontal, 48)
                            .padding(.vertical, 4)

                            Text("Your practice, illuminated")
                                .font(.cormorant(14, italic: true))
                                .tracking(2)
                                .foregroundColor(.ivoryDim)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                        Color.gold.opacity(0.22).frame(height: 1).padding(.horizontal, 24)

                        // ── Card grid (2 columns) ─────────────────────────────
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            NavigationLink(destination: PracticeVolumeDetailView()) {
                                AnalyticsCard(
                                    title:    "Practice Volume",
                                    value:    monthlyHoursDisplay,
                                    subtitle: "this month",
                                    icon:     "clock.fill",
                                    trend:    nil
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: QualityDetailView()) {
                                AnalyticsCard(
                                    title:    "Quality Score",
                                    value:    report.avgQualityDisplay,
                                    subtitle: "avg rating",
                                    icon:     "star.fill",
                                    trend:    report.qualityTrend
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: ConsistencyDetailView()) {
                                AnalyticsCard(
                                    title:    "Consistency",
                                    value:    "\(report.currentStreak)",
                                    subtitle: "day streak",
                                    icon:     "flame.fill",
                                    trend:    nil
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: CompositionSplitDetailView()) {
                                AnalyticsCard(
                                    title:    "Composition Split",
                                    value:    report.mostPracticedItem?.title ?? "—",
                                    subtitle: "most practised",
                                    icon:     "music.note",
                                    trend:    nil
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                        Spacer().frame(height: 32)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var monthlyHoursDisplay: String {
        let cal      = Calendar.current
        let now      = Date()
        let monthAgo = cal.date(byAdding: .month, value: -1, to: now) ?? now
        let fmt      = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let total    = progressStore.allSessionsList
            .filter { pair in
                guard let d = fmt.date(from: pair.dateKey) else { return false }
                return d >= monthAgo && pair.entry.hasContent
            }
            .reduce(0) { $0 + $1.entry.hours * 60 + $1.entry.minutes }
        let h = total / 60; let m = total % 60
        if h == 0 && m == 0 { return "0m" }
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }
}

// MARK: - Analytics summary card

struct AnalyticsCard: View {
    let title:    String
    let value:    String
    let subtitle: String
    let icon:     String
    let trend:    QualityTrend?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // ── Card title (prominent, at the top) ──────────────
            HStack {
                Text(title)
                    .font(.cinzel(11, weight: .bold)).tracking(1.2).textCase(.uppercase)
                    .foregroundColor(.ivory)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.gold.opacity(0.55))
            }

            Color.gold.opacity(0.22).frame(height: 1)

            // ── Icon ────────────────────────────────────────────
            Image(systemName: icon)
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.gold)
                .padding(.top, 4)

            Spacer()

            // ── Value + subtitle ────────────────────────────────
            Text(value)
                .font(.cinzel(14, weight: .bold))
                .foregroundColor(.ivory)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.cormorant(13, italic: true))
                .foregroundColor(.ivoryDim)

            if let trend = trend, trend != .insufficient {
                trendLabel(trend)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 155, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gold.opacity(0.22), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func trendLabel(_ trend: QualityTrend) -> some View {
        let (label, color): (String, Color) = {
            switch trend {
            case .improving: return ("↑ Improving", Color(red: 0.3, green: 0.75, blue: 0.4))
            case .declining: return ("↓ Declining", Color(red: 0.8, green: 0.35, blue: 0.2))
            case .stable:    return ("→ Stable",    .gold)
            default:         return ("",            .clear)
            }
        }()
        Text(label)
            .font(.cinzel(7)).tracking(1.2)
            .foregroundColor(color)
    }
}

// MARK: - Viveka hub card (full width)

struct VivekaHubCard: View {
    let report: ProgressReport

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("V I V E K A")
                        .font(.cinzel(13, weight: .bold))
                        .tracking(4)
                        .foregroundStyle(LinearGradient.goldGradient)
                    Text("Your intelligent practice companion")
                        .font(.cormorant(14, italic: true))
                        .foregroundColor(.ivory.opacity(0.85))
                }
                Spacer()
            }

            // Divider
            LinearGradient(colors: [.clear, .gold, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(height: 1)
                .opacity(0.35)
                .padding(.vertical, 12)

            // Bottom row
            HStack(spacing: 0) {
                HStack(spacing: 12) {
                    if report.burnoutWarning != nil {
                        Label("1 alert", systemImage: "exclamationmark.triangle.fill")
                            .font(.cinzel(8)).tracking(1)
                            .foregroundColor(.saffron)
                    }
                    Label(
                        "\(report.aiRecommendations.count) insight\(report.aiRecommendations.count == 1 ? "" : "s")",
                        systemImage: "sparkle"
                    )
                    .font(.cinzel(8)).tracking(1)
                    .foregroundColor(.gold)
                }
                Spacer()
                HStack(spacing: 5) {
                    Text("Reflect")
                        .font(.cinzel(9, weight: .bold)).tracking(2)
                        .foregroundStyle(LinearGradient.goldGradient)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gold)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "3d0f0f").opacity(0.85), Color(hex: "1c0400").opacity(0.92)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .cornerRadius(12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LinearGradient.goldGradient, lineWidth: 1.5)
        )
        .shadow(color: Color.gold.opacity(0.18), radius: 10, x: 0, y: 3)
    }
}

// MARK: - Shared detail header

struct DetailHeader: View {
    let title:    String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.cinzel(20, weight: .bold))
                .foregroundStyle(LinearGradient.goldGradient)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(subtitle)
                .font(.cormorant(13, italic: true))
                .tracking(1.5)
                .foregroundColor(.ivoryDim)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .padding(.horizontal, 24)
    }
}

// MARK: - Shared insight card

private func analyticsInsightCard(text: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
        Image(systemName: "lightbulb")
            .font(.system(size: 14, weight: .light))
            .foregroundColor(.gold)
        Text(text)
            .font(.cormorant(14, italic: true))
            .foregroundColor(.ivoryDim)
            .fixedSize(horizontal: false, vertical: true)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(hex: "1c0400").opacity(0.7))
    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gold.opacity(0.25), lineWidth: 1))
    .cornerRadius(6)
    .padding(.horizontal, 20)
}

// MARK: - Shared stat cell

private func analyticsStatCell(label: String, value: String) -> some View {
    VStack(spacing: 4) {
        Text(value)
            .font(.cinzel(15, weight: .bold))
            .foregroundColor(.ivory)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
        Text(label)
            .font(.cormorant(11, italic: true))
            .foregroundColor(.ivoryDim.opacity(0.7))
            .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
}

// MARK: - Practice Volume Detail

struct PracticeVolumeDetailView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @State private var period: AnalyticsPeriod = .month

    private let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    private struct DayVolume: Identifiable {
        let id          = UUID()
        let date:         Date
        let minutes:      Int     // actual logged time (may be 0)
        let composition:  String  // workTitle of the session
        // Chart uses at least 2 min height so 0-minute sessions are visible as a thin bar
        var chartMinutes: Int { max(minutes, 2) }
    }

    private var filtered: [DayVolume] {
        let now   = Date()
        let start = period.startDate(from: now)
        return progressStore.allSessionsList
            .compactMap { pair -> DayVolume? in
                guard pair.entry.hasContent, let d = fmt.date(from: pair.dateKey) else { return nil }
                if let s = start, d < s { return nil }
                let comp = pair.entry.workTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                return DayVolume(date: d,
                                 minutes: pair.entry.hours * 60 + pair.entry.minutes,
                                 composition: comp.isEmpty ? "Practice" : comp)
            }
            .sorted { $0.date < $1.date }
    }

    private var totalMins:  Int { filtered.reduce(0) { $0 + $1.minutes } }
    private var avgMins:    Int { filtered.isEmpty ? 0 : totalMins / filtered.count }
    private var maxMins:    Int { filtered.map(\.minutes).max() ?? 0 }

    private var strideCount: Int {
        switch period {
        case .week:   return 1
        case .month:  return 5
        case .months: return 14
        case .all:    return 30
        }
    }

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    DetailHeader(title: "Practice Volume", subtitle: "Time logged per session")

                    Picker("Period", selection: $period) {
                        ForEach(AnalyticsPeriod.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)

                    if filtered.isEmpty {
                        volumeEmpty
                    } else {
                        Chart(filtered) { day in
                            BarMark(
                                x: .value("Date",    day.date, unit: .day),
                                y: .value("Minutes", day.chartMinutes)
                            )
                            .foregroundStyle(day.minutes == 0
                                ? AnyShapeStyle(Color.gold.opacity(0.35))
                                : AnyShapeStyle(LinearGradient.goldGradient))
                            .cornerRadius(3)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: strideCount)) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                                    .foregroundStyle(Color.ivoryDim.opacity(0.18))
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                    .foregroundStyle(Color.ivoryDim.opacity(0.55))
                                    .font(.cinzel(7))
                            }
                        }
                        .chartYAxis {
                            AxisMarks { v in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                                    .foregroundStyle(Color.ivoryDim.opacity(0.18))
                                AxisValueLabel {
                                    if let m = v.as(Int.self) {
                                        Text(m >= 60 ? "\(m/60)h" : "\(m)m")
                                            .font(.cinzel(7))
                                            .foregroundColor(.ivoryDim.opacity(0.55))
                                    }
                                }
                            }
                        }
                        .frame(height: 220)
                        .padding(.horizontal, 20)

                        // Stats row
                        HStack(spacing: 0) {
                            analyticsStatCell(label: "Total",       value: minDisplay(totalMins))
                            Divider().frame(height: 40).background(Color.gold.opacity(0.2))
                            analyticsStatCell(label: "Avg Session", value: minDisplay(avgMins))
                            Divider().frame(height: 40).background(Color.gold.opacity(0.2))
                            analyticsStatCell(label: "Longest",     value: minDisplay(maxMins))
                        }
                        .padding(.vertical, 16)
                        .background(Color(hex: "1c0400").opacity(0.6))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.18), lineWidth: 1))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)

                        if let best = bestDay {
                            analyticsInsightCard(text: "Your most productive sessions tend to fall on \(best)s. Protecting this slot each week compounds your progress faster than adding extra sessions on other days.")
                        }

                        recentSessionsList
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var volumeEmpty: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(.gold.opacity(0.4))
            Text("No sessions in this period")
                .font(.cormorant(15, italic: true))
                .foregroundColor(.ivoryDim)
        }
        .frame(height: 160)
    }

    private var recentSessionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.cinzel(10)).tracking(2)
                .foregroundStyle(LinearGradient.goldGradient)
                .padding(.horizontal, 24)

            ForEach(Array(filtered.suffix(5).reversed()), id: \.id) { day in
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(day.composition)
                                .font(.cormorant(14))
                                .foregroundColor(.ivory)
                            Text(day.date, format: .dateTime.day().month(.abbreviated).year())
                                .font(.cormorant(12, italic: true))
                                .foregroundColor(.ivoryDim.opacity(0.6))
                        }
                        Spacer()
                        Text(minDisplay(day.minutes))
                            .font(.cormorant(14)).fontWeight(.bold)
                            .foregroundColor(day.minutes == 0 ? .ivoryDim.opacity(0.45) : .gold)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    Color.gold.opacity(0.1).frame(height: 1).padding(.horizontal, 24)
                }
            }
        }
    }

    private var bestDay: String? {
        guard filtered.count >= 4 else { return nil }
        let cal   = Calendar.current
        let names = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var totals: [Int: Int] = [:]
        var counts: [Int: Int] = [:]
        for d in filtered {
            let wd = cal.component(.weekday, from: d.date)
            totals[wd, default: 0] += d.minutes
            counts[wd, default: 0] += 1
        }
        guard let best = totals.max(by: { a, b in
            let avgA = Double(a.value) / Double(max(counts[a.key] ?? 1, 1))
            let avgB = Double(b.value) / Double(max(counts[b.key] ?? 1, 1))
            return avgA < avgB
        }) else { return nil }
        guard (counts[best.key] ?? 0) >= 2 else { return nil }
        return names[analyticsAt: best.key]
    }

    private func minDisplay(_ m: Int) -> String {
        if m == 0 { return "0m" }
        let h = m / 60; let min = m % 60
        if h == 0 { return "\(min)m" }
        if min == 0 { return "\(h)h" }
        return "\(h)h \(min)m"
    }
}

// MARK: - Quality Detail

struct QualityDetailView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @State private var period: AnalyticsPeriod = .month
    @State private var selectedComposition: String = "All"   // "All" or a specific name

    private let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    // Composition → colour (used when "All" is selected)
    private let compColors: [String: Color] = [
        "Alarippu":          Color(hex: "e8b84b"),
        "Jathiswaram":       Color(hex: "e07b20"),
        "Shabdam":           Color(hex: "c9922a"),
        "Varnam":            Color(hex: "9c2626"),
        "Adavu Basics":      Color(hex: "c9b99a"),
        "Asamyutha Hastas":  Color(hex: "6b3a1a"),
        "Samyutha Hastas":   Color(hex: "d4c5a9"),
    ]

    // X-axis is the actual session date
    private struct QualityPoint: Identifiable {
        let id          = UUID()
        let date:        Date
        let quality:     Double
        let composition: String
    }


    // Known compositions (matches sessionCompositions in HomeTabView)
    private let knownCompositions = ["Alarippu", "Jathiswaram", "Shabdam", "Varnam",
                                     "Adavu Basics", "Asamyutha Hastas", "Samyutha Hastas"]

    // All rated points in the selected period, sorted chronologically
    private var allPoints: [QualityPoint] {
        let now   = Date()
        let start = period.startDate(from: now)
        return progressStore.allSessionsList
            .compactMap { pair -> QualityPoint? in
                guard pair.entry.hasContent, pair.entry.quality > 0,
                      let d = fmt.date(from: pair.dateKey) else { return nil }
                if let s = start, d < s { return nil }
                let comp = pair.entry.workTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                return QualityPoint(
                    date:        d,
                    quality:     Double(pair.entry.quality),
                    composition: comp.isEmpty ? "Other" : comp
                )
            }
            .sorted { $0.date < $1.date }
    }

    // Filtered by dropdown selection
    private var displayedPoints: [QualityPoint] {
        selectedComposition == "All"
            ? allPoints
            : allPoints.filter { $0.composition == selectedComposition }
    }

    // All known compositions shown in dropdown — not just ones with ratings yet
    private var uniqueCompositions: [String] {
        // Start with known list, then add any "Other" compositions that appear in data
        var result = knownCompositions
        let dataComps = Set(allPoints.map(\.composition))
        let extras = dataComps.subtracting(Set(knownCompositions)).sorted()
        result.append(contentsOf: extras)
        return result
    }

    // No rolling average — line connects dots directly in date order

    private var avgQ: Double? {
        guard displayedPoints.count >= 2 else { return nil }
        return displayedPoints.reduce(0.0) { $0 + $1.quality } / Double(displayedPoints.count)
    }
    private var maxQ: Double { displayedPoints.map(\.quality).max() ?? 0 }
    private var minQ: Double { displayedPoints.map(\.quality).min() ?? 0 }

    // Date domain — pad ±1 day so edge dots aren't clipped
    private var xDomain: ClosedRange<Date> {
        let cal = Calendar.current
        guard let first = displayedPoints.first?.date,
              let last  = displayedPoints.last?.date else {
            let now = Date()
            return (cal.date(byAdding: .day, value: -7, to: now) ?? now)...now
        }
        let lo = cal.date(byAdding: .day, value: -1, to: first) ?? first
        let hi = cal.date(byAdding: .day, value:  1, to: last)  ?? last
        return lo...hi
    }

    // Adaptive stride for X-axis labels based on date range
    private var xAxisStride: Calendar.Component {
        guard let first = displayedPoints.first?.date,
              let last  = displayedPoints.last?.date else { return .day }
        let days = Calendar.current.dateComponents([.day], from: first, to: last).day ?? 0
        if days <= 14  { return .day }
        if days <= 60  { return .weekOfYear }
        return .month
    }

    private var xAxisStrideCount: Int {
        guard let first = displayedPoints.first?.date,
              let last  = displayedPoints.last?.date else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: first, to: last).day ?? 0
        if days <= 14  { return 2 }
        if days <= 60  { return 1 }
        return 1
    }

    private func pointColor(_ pt: QualityPoint) -> Color {
        selectedComposition == "All"
            ? (compColors[pt.composition] ?? Color.gold)
            : Color.gold
    }

    private func shortDateLabel(_ date: Date) -> String {
        let cal  = Calendar.current
        let days = cal.dateComponents([.day], from: (displayedPoints.first?.date ?? date), to: date).day ?? 0
        let fmt  = DateFormatter()
        // For short ranges show day+month, for longer ranges show month only
        let span = cal.dateComponents([.day],
            from: displayedPoints.first?.date ?? date,
            to:   displayedPoints.last?.date  ?? date).day ?? 0
        fmt.dateFormat = span > 45 ? "MMM" : "d MMM"
        return fmt.string(from: date)
    }

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    DetailHeader(title: "Quality Score", subtitle: "Rating progression per session")

                    // ── Period picker ────────────────────────────────────────
                    Picker("Period", selection: $period) {
                        ForEach(AnalyticsPeriod.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .onChange(of: period) { _, _ in selectedComposition = "All" }

                    // ── Composition dropdown ─────────────────────────────────
                    Menu {
                        Button("All Sessions") { selectedComposition = "All" }
                        if !uniqueCompositions.isEmpty {
                            Divider()
                            ForEach(uniqueCompositions, id: \.self) { comp in
                                Button(comp) { selectedComposition = comp }
                            }
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("COMPOSITION")
                                    .font(.cinzel(8)).tracking(2)
                                    .foregroundColor(.ivoryDim.opacity(0.55))
                                Text(selectedComposition == "All" ? "All Sessions" : selectedComposition)
                                    .font(.cormorant(16))
                                    .foregroundColor(.ivory)
                            }
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11, weight: .light))
                                .foregroundColor(.gold.opacity(0.6))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(hex: "2c1208").opacity(0.9).cornerRadius(8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.3), lineWidth: 1))
                    }
                    .padding(.horizontal, 24)

                    // ── Chart ────────────────────────────────────────────────
                    ZStack {
                        Chart {
                            ForEach(displayedPoints) { pt in
                                LineMark(
                                    x: .value("Date",    pt.date),
                                    y: .value("Quality", pt.quality)
                                )
                                .foregroundStyle(Color.saffron.opacity(0.85))
                                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                .interpolationMethod(.linear)
                            }
                            ForEach(displayedPoints) { pt in
                                PointMark(
                                    x: .value("Date",    pt.date),
                                    y: .value("Quality", pt.quality)
                                )
                                .foregroundStyle(pointColor(pt))
                                .symbolSize(65)
                            }
                            if let a = avgQ {
                                RuleMark(y: .value("Average", a))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                    .foregroundStyle(Color.gold.opacity(0.4))
                                    .annotation(position: .trailing, alignment: .leading) {
                                        Text("avg").font(.cinzel(7)).foregroundColor(.gold.opacity(0.55))
                                    }
                            }
                        }
                        .chartYScale(domain: 0.5...5.5)
                        .chartXScale(domain: xDomain)
                        .chartYAxis {
                            AxisMarks(values: [1.0, 2.0, 3.0, 4.0, 5.0]) { v in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                                    .foregroundStyle(Color.ivoryDim.opacity(0.15))
                                AxisValueLabel {
                                    if let d = v.as(Double.self) {
                                        Text("\(Int(d))★").font(.cinzel(7))
                                            .foregroundColor(.ivoryDim.opacity(0.55))
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: xAxisStride, count: xAxisStrideCount)) { v in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                                    .foregroundStyle(Color.ivoryDim.opacity(0.15))
                                AxisValueLabel {
                                    if let d = v.as(Date.self) {
                                        Text(shortDateLabel(d)).font(.cinzel(7))
                                            .foregroundColor(.ivoryDim.opacity(0.55))
                                    }
                                }
                            }
                        }
                        .chartLegend(.hidden)
                        .frame(height: 210)
                        .padding(.horizontal, 20)

                        if displayedPoints.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 30, weight: .ultraLight))
                                    .foregroundColor(.gold.opacity(0.4))
                                Text("No rated sessions yet\nfor this selection")
                                    .font(.cormorant(14, italic: true))
                                    .foregroundColor(.ivoryDim)
                                    .multilineTextAlignment(.center)
                                Text("Rate sessions after practice to populate the chart")
                                    .font(.cinzel(7)).tracking(1.5)
                                    .foregroundColor(.ivoryDim.opacity(0.4))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 40)
                            .frame(height: 210)
                        }
                    }

                    // Axis labels
                    HStack {
                        Text("Quality ↑")
                            .font(.cinzel(11, weight: .bold)).tracking(1)
                            .foregroundColor(.ivoryDim.opacity(0.7))
                        Spacer()
                        Text("Date →")
                            .font(.cinzel(11, weight: .bold)).tracking(1)
                            .foregroundColor(.ivoryDim.opacity(0.7))
                    }
                    .padding(.horizontal, 28)

                    // Colour legend when "All" is selected
                    if selectedComposition == "All" && uniqueCompositions.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(uniqueCompositions, id: \.self) { comp in
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(compColors[comp] ?? .gold)
                                            .frame(width: 8, height: 8)
                                        Text(comp)
                                            .font(.cormorant(11, italic: true))
                                            .foregroundColor(.ivoryDim.opacity(0.7))
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    // Trend line + avg legend + stats row
                    if !displayedPoints.isEmpty {
                        HStack(spacing: 18) {
                            HStack(spacing: 5) {
                                RoundedRectangle(cornerRadius: 1).fill(Color.saffron)
                                    .frame(width: 18, height: 2.5)
                                Text("Session quality").font(.cormorant(11, italic: true))
                                    .foregroundColor(.ivoryDim.opacity(0.6))
                            }
                            HStack(spacing: 5) {
                                RoundedRectangle(cornerRadius: 1).fill(Color.gold.opacity(0.4))
                                    .frame(width: 18, height: 1)
                                Text("Overall avg").font(.cormorant(11, italic: true))
                                    .foregroundColor(.ivoryDim.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 24)

                        HStack(spacing: 0) {
                            analyticsStatCell(label: "Average",
                                              value: avgQ.map { String(format: "%.1f ★", $0) } ?? "—")
                            Divider().frame(height: 40).background(Color.gold.opacity(0.2))
                            analyticsStatCell(label: "Best",   value: maxQ > 0 ? "\(Int(maxQ)) ★" : "—")
                            Divider().frame(height: 40).background(Color.gold.opacity(0.2))
                            analyticsStatCell(label: "Lowest", value: minQ > 0 ? "\(Int(minQ)) ★" : "—")
                        }
                        .padding(.vertical, 16)
                        .background(Color(hex: "1c0400").opacity(0.6))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.18), lineWidth: 1))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)

                        if let a = avgQ {
                            analyticsInsightCard(text: a >= 4.0
                                ? "Your sessions are consistently strong — a high average reflects focused, intentional practice."
                                : a >= 3.0
                                ? "Your quality is solid. Consider what your best sessions have in common — time of day, warm-up routine, or which compositions you practised."
                                : "Your quality average suggests sessions may be feeling harder than usual. Short, focused sessions often outperform long, fatigued ones."
                            )
                        }
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

}

// MARK: - Consistency Detail (with heatmap)

struct ConsistencyDetailView: View {
    @ObservedObject private var progressStore = ProgressStore.shared

    private let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    private var report: ProgressReport {
        ReportEngine.generate(
            progressStore:  progressStore,
            goalStore:      GoalStore.shared,
            milestoneStore: MilestoneStore.shared
        )
    }

    // 105 days = 15 weeks, oldest → newest
    private var heatmapData: [(date: Date, minutes: Int)] {
        let cal = Calendar.current
        let now = Date()
        return (0..<105).reversed().compactMap { offset -> (Date, Int)? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: now) else { return nil }
            let key   = fmt.string(from: date)
            let entry = progressStore.entries[key]
            let mins  = entry.map { $0.hours * 60 + $0.minutes } ?? 0
            return (date, mins)
        }
    }

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    DetailHeader(title: "Consistency", subtitle: "Your practice rhythm over time")

                    HStack(spacing: 0) {
                        analyticsStatCell(label: "Current Streak", value: "\(report.currentStreak)d")
                        Divider().frame(height: 40).background(Color.gold.opacity(0.2))
                        analyticsStatCell(label: "Longest Streak", value: "\(report.longestStreak)d")
                        Divider().frame(height: 40).background(Color.gold.opacity(0.2))
                        analyticsStatCell(label: "Total Sessions", value: "\(report.totalSessions)")
                    }
                    .padding(.vertical, 16)
                    .background(Color(hex: "1c0400").opacity(0.6))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.18), lineWidth: 1))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("15 weeks of practice")
                            .font(.cinzel(9)).tracking(2)
                            .foregroundColor(.ivoryDim.opacity(0.55))
                            .padding(.horizontal, 24)

                        HeatmapView(data: heatmapData)
                            .frame(height: 112)
                            .padding(.horizontal, 20)

                        HStack(spacing: 6) {
                            Text("Less")
                                .font(.cormorant(11, italic: true))
                                .foregroundColor(.ivoryDim.opacity(0.45))
                            ForEach(0..<5, id: \.self) { level in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(HeatmapView.heatColor(level: level))
                                    .frame(width: 12, height: 12)
                            }
                            Text("More")
                                .font(.cormorant(11, italic: true))
                                .foregroundColor(.ivoryDim.opacity(0.45))
                        }
                        .padding(.horizontal, 24)
                    }

                    if let best = report.bestPracticeDay {
                        analyticsInsightCard(text: "Your strongest sessions consistently fall on \(best)s. Protecting this slot in your schedule each week compounds progress faster than adding random extra sessions.")
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Heatmap canvas view

struct HeatmapView: View {
    let data: [(date: Date, minutes: Int)]

    private let cols = 15
    private let rows = 7
    private let gap: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            let cellW = (geo.size.width  - gap * CGFloat(cols - 1)) / CGFloat(cols)
            let cellH = (geo.size.height - gap * CGFloat(rows - 1)) / CGFloat(rows)

            Canvas { ctx, _ in
                let weeks = stride(from: 0, to: data.count, by: rows).map {
                    Array(data[$0..<min($0 + rows, data.count)])
                }
                for (col, week) in weeks.enumerated() {
                    for (row, day) in week.enumerated() {
                        let x    = CGFloat(col) * (cellW + gap)
                        let y    = CGFloat(row) * (cellH + gap)
                        let rect = CGRect(x: x, y: y, width: cellW, height: cellH)
                        let path = Path(roundedRect: rect, cornerRadius: 2)
                        ctx.fill(path, with: .color(Self.heatColor(level: intensityLevel(minutes: day.minutes))))
                    }
                }
            }
        }
    }

    private func intensityLevel(minutes: Int) -> Int {
        switch minutes {
        case 0:       return 0
        case 1..<30:  return 1
        case 30..<60: return 2
        case 60..<90: return 3
        default:      return 4
        }
    }

    static func heatColor(level: Int) -> Color {
        switch level {
        case 0:  return Color(hex: "1c0a04")
        case 1:  return Color.gold.opacity(0.18)
        case 2:  return Color.gold.opacity(0.42)
        case 3:  return Color.gold.opacity(0.70)
        default: return Color.goldLight
        }
    }
}

// MARK: - Composition Split Detail

struct CompositionSplitDetailView: View {
    @ObservedObject private var progressStore = ProgressStore.shared

    // Must match sessionCompositions in HomeTabView exactly so workTitle lookups succeed
    private let knownCompositions = ["Alarippu", "Jathiswaram", "Shabdam", "Varnam",
                                     "Adavu Basics", "Asamyutha Hastas", "Samyutha Hastas"]

    // Named colours — same palette as QualityDetailView so legend is consistent
    private let compColors: [String: Color] = [
        "Alarippu":          Color(hex: "e8b84b"),
        "Jathiswaram":       Color(hex: "e07b20"),
        "Shabdam":           Color(hex: "c9922a"),
        "Varnam":            Color(hex: "9c2626"),
        "Adavu Basics":      Color(hex: "c9b99a"),
        "Asamyutha Hastas":  Color(hex: "6b3a1a"),
        "Samyutha Hastas":   Color(hex: "d4c5a9"),
    ]

    // Slices keyed by session COUNT so entries with no time still appear
    private struct CompSlice: Identifiable {
        let id       = UUID()
        let name:     String
        let sessions: Int    // used for pie chart angle
        let minutes:  Int    // shown in list
        let color:    Color
    }

    private var slices: [CompSlice] {
        // Accumulate sessions + minutes per composition bucket using ALL sessions
        var sessionBucket: [String: Int] = [:]
        var minuteBucket:  [String: Int] = [:]

        for pair in progressStore.allSessionsList where pair.entry.hasContent {
            let title = pair.entry.workTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }
            let bucket = knownCompositions.first {
                title.localizedCaseInsensitiveContains($0)
            } ?? "Other"
            sessionBucket[bucket, default: 0] += 1
            minuteBucket[bucket,  default: 0] += pair.entry.hours * 60 + pair.entry.minutes
        }

        return sessionBucket
            .sorted { $0.value > $1.value }
            .map { pair in
                CompSlice(name:     pair.key,
                          sessions: pair.value,
                          minutes:  minuteBucket[pair.key] ?? 0,
                          color:    compColors[pair.key] ?? Color.goldLight)
            }
    }

    private var totalSessions: Int { slices.reduce(0) { $0 + $1.sessions } }

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    DetailHeader(title: "Composition Split",
                                 subtitle: "Sessions per composition")

                    if slices.isEmpty {
                        splitEmpty
                    } else {
                        // Pie chart — sized by session count, not time
                        Chart(slices) { slice in
                            SectorMark(
                                angle:        .value("Sessions", slice.sessions),
                                innerRadius:  .ratio(0.55),
                                angularInset: 2
                            )
                            .foregroundStyle(slice.color)
                            .cornerRadius(3)
                        }
                        .frame(height: 220)
                        .padding(.horizontal, 40)

                        // Breakdown list
                        VStack(spacing: 0) {
                            ForEach(slices) { slice in
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(slice.color)
                                        .frame(width: 12, height: 12)
                                    Text(slice.name)
                                        .font(.cormorant(15))
                                        .foregroundColor(.ivory)
                                    Spacer()
                                    // Session count badge
                                    Text("\(slice.sessions) session\(slice.sessions == 1 ? "" : "s")")
                                        .font(.cormorant(13)).fontWeight(.semibold)
                                        .foregroundColor(.gold)
                                    // Time (if any logged)
                                    if slice.minutes > 0 {
                                        Text("· \(minDisplay(slice.minutes))")
                                            .font(.cormorant(12, italic: true))
                                            .foregroundColor(.ivoryDim.opacity(0.6))
                                    }
                                    Text(pct(slice.sessions))
                                        .font(.cinzel(8)).tracking(1)
                                        .foregroundColor(.ivoryDim.opacity(0.55))
                                        .frame(width: 38, alignment: .trailing)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                Color.gold.opacity(0.1).frame(height: 1).padding(.horizontal, 16)
                            }
                        }
                        .background(Color(hex: "1c0400").opacity(0.6))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold.opacity(0.18), lineWidth: 1))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)

                        if let top = slices.first {
                            analyticsInsightCard(text: "\(top.name) makes up \(pct(top.sessions)) of your sessions. A balanced spread across compositions builds stronger overall technique for the stage.")
                        }
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var splitEmpty: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(.gold.opacity(0.4))
            Text("Log sessions with a composition selected to see your split")
                .font(.cormorant(15, italic: true))
                .foregroundColor(.ivoryDim)
                .multilineTextAlignment(.center)
        }
        .frame(height: 160)
        .padding(.horizontal, 40)
    }

    private func minDisplay(_ m: Int) -> String {
        let h = m / 60; let min = m % 60
        if h == 0 { return "\(min)m" }
        if min == 0 { return "\(h)h" }
        return "\(h)h \(min)m"
    }

    private func pct(_ sessions: Int) -> String {
        guard totalSessions > 0 else { return "0%" }
        return "\(Int(Double(sessions) / Double(totalSessions) * 100))%"
    }
}

// MARK: - Safe array subscript (file-private)

private extension Array {
    subscript(analyticsAt index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
