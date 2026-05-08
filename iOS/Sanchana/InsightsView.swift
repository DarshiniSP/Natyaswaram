import SwiftUI
import Charts

struct InsightsView: View {
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

    private let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    @State private var showViveka  = false
    @State private var showReport  = false

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView().ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── Header ────────────────────────────────────────────────
                    VStack(spacing: 6) {
                        Spacer().frame(height: 18)
                        Text("Your Progress")
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

                        Text("A reflection of your journey")
                            .font(.cormorant(14, italic: true))
                            .tracking(2)
                            .foregroundColor(.ivoryDim)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                    Color.gold.opacity(0.22).frame(height: 1).padding(.horizontal, 24)

                    // ── Scrollable content ────────────────────────────────────
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {

                            // ══════════════════════════════════════════════════
                            // VIVEKA — compact card
                            // ══════════════════════════════════════════════════
                            Button(action: { showViveka = true }) {
                                VivekaHubCard(report: report)
                            }
                            .buttonStyle(.plain)
                            .sheet(isPresented: $showViveka) {
                                VivekaView()
                            }

                            sectionDivider()

                            // ══════════════════════════════════════════════════
                            // ANALYTICS CARDS
                            // ══════════════════════════════════════════════════
                            Text("Analytics")
                                .font(.cinzel(12, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(LinearGradient.goldGradient)

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
                                        subtitle: "avg · tap for graph",
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
                                        subtitle: "tap for breakdown",
                                        icon:     "music.note",
                                        trend:    nil
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            sectionDivider()

                            // ══════════════════════════════════════════════════
                            // PRACTICE SUMMARY
                            // ══════════════════════════════════════════════════
                            sectionHeader("Practice Summary")

                            statRow(label: "Total Sessions",       value: "\(report.totalSessions)")
                            statRow(label: "Total Time Practised", value: report.totalHoursDisplay)
                            statRow(label: "Average Session",      value: report.averageSessionDisplay)

                            if let top = report.mostPracticedItem {
                                statRow(
                                    label: "Most Practised Item",
                                    value: "\(top.title) (\(top.sessions) session\(top.sessions == 1 ? "" : "s"))"
                                )
                            }

                            statRow(
                                label: "Current Streak",
                                value: "\(report.currentStreak) day\(report.currentStreak == 1 ? "" : "s")"
                            )
                            statRow(
                                label: "Longest Streak",
                                value: "\(report.longestStreak) day\(report.longestStreak == 1 ? "" : "s")"
                            )

                            if let last = report.lastPracticeDate {
                                statRow(label: "Last Session", value: dateFmt.string(from: last))
                            }

                            sectionDivider()

                            // ══════════════════════════════════════════════════
                            // GOALS
                            // ══════════════════════════════════════════════════
                            sectionHeader("Goals")

                            statRow(label: "Total Goals Set", value: "\(report.totalGoalsSet)")

                            if report.upcomingGoals.isEmpty {
                                Text("No upcoming goals set.")
                                    .font(.cormorant(15, italic: true))
                                    .foregroundColor(.ivoryDim)
                            } else {
                                goalList(report.upcomingGoals)
                            }

                            sectionDivider()

                            // ══════════════════════════════════════════════════
                            // GENERATE REPORT
                            // ══════════════════════════════════════════════════
                            Button(action: { showReport = true }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 14))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Generate Practice Report")
                                            .font(.cinzel(11, weight: .bold))
                                            .tracking(2)
                                        Text("Choose a period · Viveka reads your data")
                                            .font(.cormorant(13, italic: true))
                                            .foregroundColor(.ivoryDim)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .light))
                                        .foregroundColor(.gold.opacity(0.5))
                                }
                                .foregroundColor(.gold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(hex: "1c0400").cornerRadius(8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.gold.opacity(0.35), Color.gold.opacity(0.12)],
                                                startPoint: .topLeading,
                                                endPoint:   .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .sheet(isPresented: $showReport) {
                                PracticeReportView()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Monthly hours helper

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

    // MARK: - Sub-views

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.cinzel(12, weight: .bold))
            .tracking(2)
            .foregroundStyle(LinearGradient.goldGradient)
    }

    @ViewBuilder
    private func statRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.cormorant(15))
                .foregroundColor(.ivoryDim)
            Spacer()
            Text(value)
                .font(.cormorant(15)).fontWeight(.bold)
                .foregroundColor(.ivory)
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder
    private func goalList(_ list: [(text: String, deadline: Date)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upcoming")
                .font(.cinzel(9))
                .tracking(2)
                .foregroundColor(.ivoryDim)

            ForEach(Array(list.enumerated()), id: \.offset) { _, g in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle")
                        .font(.system(size: 7))
                        .foregroundColor(.gold)
                        .padding(.top, 5)
                    Text(g.text)
                        .font(.cormorant(15))
                        .foregroundColor(.ivory)
                    Spacer()
                    Text(dateFmt.string(from: g.deadline))
                        .font(.cormorant(13, italic: true))
                        .foregroundColor(.ivoryDim)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionDivider() -> some View {
        Color.gold.opacity(0.15).frame(height: 1)
    }
}
