import SwiftUI

struct VivekaView: View {
    @ObservedObject private var progressStore  = ProgressStore.shared
    @ObservedObject private var goalStore      = GoalStore.shared
    @ObservedObject private var milestoneStore = MilestoneStore.shared
    @Environment(\.dismiss) private var dismiss

    private var report: ProgressReport {
        ReportEngine.generate(
            progressStore:  progressStore,
            goalStore:      goalStore,
            milestoneStore: milestoneStore
        )
    }

    private let deadlineFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ────────────────────────────────────────────────────
                VStack(spacing: 6) {
                    Spacer().frame(height: 18)

                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gold)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)

                    Text("Viveka")
                        .font(.cinzel(32, weight: .black))
                        .foregroundStyle(LinearGradient.goldGradient)

                    HStack(spacing: 10) {
                        GoldRule()
                        OmSymbol(size: 11)
                        GoldRule()
                    }
                    .padding(.horizontal, 48)
                    .padding(.vertical, 4)

                    Text("Your practice intelligence")
                        .font(.cormorant(14, italic: true))
                        .tracking(2)
                        .foregroundColor(.ivoryDim)
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

                Color.gold.opacity(0.22).frame(height: 1).padding(.horizontal, 24)

                // ── Scroll content ────────────────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {

                        // Intro note
                        Text("Viveka observes your practice over time and surfaces patterns you might not notice yourself.")
                            .font(.cormorant(15, italic: true))
                            .foregroundColor(.ivoryDim)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)

                        // ════════════════════════════════════════════════════
                        // MILESTONE — shown first if one was just crossed
                        // ════════════════════════════════════════════════════
                        if let milestone = report.sessionMilestone {
                            vivekaCard(
                                icon:     "seal.fill",
                                headline: "Milestone",
                                body:     milestone,
                                accent:   Color(red: 0.9, green: 0.75, blue: 0.3)
                            )
                            sectionDivider()
                        }

                        // ════════════════════════════════════════════════════
                        // UPCOMING DEADLINES (simple reminder, no advice)
                        // ════════════════════════════════════════════════════
                        if !report.upcomingDeadlineReminders.isEmpty {
                            sectionHeader("Coming Up", icon: "calendar.badge.clock")
                            ForEach(Array(report.upcomingDeadlineReminders.enumerated()), id: \.offset) { _, d in
                                let accent = d.daysLeft <= 3
                                    ? Color(red: 0.85, green: 0.4, blue: 0.1)
                                    : Color.gold
                                vivekaCard(
                                    icon:     d.daysLeft <= 3 ? "exclamationmark.circle" : "calendar",
                                    headline: d.daysLeft == 0 ? "Today" : "In \(d.daysLeft) day\(d.daysLeft == 1 ? "" : "s")",
                                    body:     d.goal,
                                    accent:   accent
                                )
                            }
                            sectionDivider()
                        }

                        // ════════════════════════════════════════════════════
                        // LAST WEEK NARRATIVE
                        // ════════════════════════════════════════════════════
                        if let weekly = report.weeklyNarrative {
                            sectionHeader("Last Week", icon: "calendar")
                            vivekaCard(
                                icon:     "calendar",
                                headline: "Weekly Recap",
                                body:     weekly,
                                accent:   .gold
                            )
                            sectionDivider()
                        }

                        // ════════════════════════════════════════════════════
                        // COMPOSITION QUALITY ARCS
                        // ════════════════════════════════════════════════════
                        if !report.compositionArcs.isEmpty {
                            sectionHeader("Quality Arcs", icon: "chart.line.uptrend.xyaxis")
                            ForEach(Array(report.compositionArcs.enumerated()), id: \.offset) { _, arc in
                                let improved = arc.recentAvg > arc.firstAvg
                                let accent: Color = improved
                                    ? Color(red: 0.3, green: 0.75, blue: 0.4)
                                    : Color(red: 0.8, green: 0.4, blue: 0.1)
                                let arrow = improved ? "↑" : "↓"
                                vivekaCard(
                                    icon:     improved ? "arrow.up.right" : "arrow.down.right",
                                    headline: arc.comp,
                                    body:     String(format: "%@ Average moved from %.1f★ to %.1f★ across %d sessions.", arrow, arc.firstAvg, arc.recentAvg, arc.count),
                                    accent:   accent
                                )
                            }
                            sectionDivider()
                        }

                        // ════════════════════════════════════════════════════
                        // PERSONAL PATTERNS
                        // ════════════════════════════════════════════════════
                        if !report.personalPatterns.isEmpty {
                            sectionHeader("Your Patterns", icon: "waveform.path.ecg")
                            ForEach(Array(report.personalPatterns.enumerated()), id: \.offset) { _, p in
                                vivekaCard(
                                    icon:     "waveform.path.ecg",
                                    headline: "Pattern",
                                    body:     p,
                                    accent:   .gold
                                )
                            }
                            sectionDivider()
                        }

                        // ════════════════════════════════════════════════════
                        // OBSERVATIONS — original Viveka intelligence
                        // ════════════════════════════════════════════════════
                        sectionHeader("Observations", icon: "sparkle")

                        if report.aiRecommendations.isEmpty {
                            emptyCard(
                                icon:    "sparkle",
                                message: "Log a few more sessions with quality ratings and written notes — Viveka's observations will appear here.",
                                accent:  .gold
                            )
                        } else {
                            ForEach(Array(report.aiRecommendations.enumerated()), id: \.offset) { _, rec in
                                vivekaCard(
                                    icon:     obsIcon(rec),
                                    headline: obsHeadline(rec),
                                    body:     rec,
                                    accent:   obsAccent(rec)
                                )
                            }
                        }

                        // Quality summary
                        if let avg = report.avgQualityRating {
                            HStack {
                                Text("Avg. Session Quality")
                                    .font(.cormorant(15))
                                    .foregroundColor(.ivoryDim)
                                Spacer()
                                HStack(spacing: 3) {
                                    ForEach(1...5, id: \.self) { s in
                                        Image(systemName: Double(s) <= avg ? "star.fill" : "star")
                                            .font(.system(size: 10))
                                            .foregroundColor(Double(s) <= avg ? .gold : Color.ivoryDim.opacity(0.3))
                                    }
                                    Text(String(format: "%.1f", avg))
                                        .font(.cormorant(14)).fontWeight(.bold)
                                        .foregroundColor(.ivory)
                                        .padding(.leading, 4)
                                }
                            }

                            if report.qualityTrend != .insufficient {
                                HStack {
                                    Text("Quality Trend")
                                        .font(.cormorant(15))
                                        .foregroundColor(.ivoryDim)
                                    Spacer()
                                    trendBadge(report.qualityTrend)
                                }
                            }
                        }

                        // Sentiment note (from remark NLP analysis)
                        if let sentiment = report.sentimentNote {
                            vivekaCard(
                                icon:     "text.bubble",
                                headline: "Session Sentiment",
                                body:     sentiment,
                                accent:   .gold
                            )
                        }

                        sectionDivider()

                        // ════════════════════════════════════════════════════
                        // BURNOUT WARNING
                        // ════════════════════════════════════════════════════
                        sectionHeader("Burnout Warning", icon: "flame")

                        if let warning = report.burnoutWarning {
                            vivekaCard(
                                icon:     "flame.fill",
                                headline: "Fatigue Detected",
                                body:     warning,
                                accent:   Color(red: 0.85, green: 0.35, blue: 0.15)
                            )
                        } else {
                            emptyCard(
                                icon:    "checkmark.circle",
                                message: "No burnout signals detected. Your practice frequency looks sustainable.",
                                accent:  Color(red: 0.3, green: 0.75, blue: 0.4)
                            )
                        }

                        sectionDivider()

                        // ════════════════════════════════════════════════════
                        // GOAL FEASIBILITY
                        // ════════════════════════════════════════════════════
                        sectionHeader("Goal Feasibility", icon: "target")

                        if report.goalFeasibility.isEmpty {
                            emptyCard(
                                icon:    "circle.dashed",
                                message: "Set goals with deadlines in the Calendar page and Viveka will assess whether you're on track to meet them.",
                                accent:  .gold
                            )
                        } else {
                            ForEach(Array(report.goalFeasibility.enumerated()), id: \.offset) { _, g in
                                feasibilityCard(
                                    goal:     g.goal,
                                    deadline: deadlineFmt.string(from: g.deadline),
                                    verdict:  g.verdict,
                                    detail:   g.detail
                                )
                            }
                        }

                        sectionDivider()

                        // ════════════════════════════════════════════════════
                        // CROSS-PATTERN INSIGHTS
                        // ════════════════════════════════════════════════════
                        sectionHeader("Cross-Pattern Insights", icon: "arrow.triangle.branch")

                        if report.crossPatternInsights.isEmpty {
                            emptyCard(
                                icon:    "waveform.path.ecg",
                                message: "Keep logging sessions — Viveka will connect the dots across your practice patterns once more data is available.",
                                accent:  .gold
                            )
                        } else {
                            ForEach(Array(report.crossPatternInsights.enumerated()), id: \.offset) { _, insight in
                                vivekaCard(
                                    icon:     "arrow.triangle.branch",
                                    headline: "Pattern Observed",
                                    body:     insight,
                                    accent:   .gold
                                )
                            }
                        }

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 24)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Section header

    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(LinearGradient.goldGradient)
            Text(title)
                .font(.cinzel(12, weight: .bold))
                .tracking(2)
                .foregroundStyle(LinearGradient.goldGradient)
        }
    }

    // MARK: - Viveka card

    @ViewBuilder
    private func vivekaCard(icon: String, headline: String, body: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(accent)
                .frame(width: 22)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(headline)
                    .font(.cinzel(10)).tracking(1.5)
                    .foregroundColor(accent)
                Text(body)
                    .font(.cormorant(14, italic: true))
                    .foregroundColor(.ivoryDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "1c0400").opacity(0.7))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(accent.opacity(0.35), lineWidth: 1))
        .cornerRadius(6)
    }

    // MARK: - Empty / positive state card

    @ViewBuilder
    private func emptyCard(icon: String, message: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(accent)
                .frame(width: 22)
                .padding(.top, 2)
            Text(message)
                .font(.cormorant(14, italic: true))
                .foregroundColor(.ivoryDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "1c0400").opacity(0.5))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(accent.opacity(0.2), lineWidth: 1))
        .cornerRadius(6)
    }

    // MARK: - Goal feasibility card

    @ViewBuilder
    private func feasibilityCard(goal: String, deadline: String, verdict: String, detail: String) -> some View {
        let accent: Color = {
            switch verdict {
            case "On track":         return Color(red: 0.3, green: 0.75, blue: 0.4)
            case "Tight but possible": return Color(red: 0.85, green: 0.75, blue: 0.2)
            default:                 return Color(red: 0.85, green: 0.35, blue: 0.15)
            }
        }()
        let icon: String = {
            switch verdict {
            case "On track":         return "checkmark.circle"
            case "Tight but possible": return "exclamationmark.triangle"
            default:                 return "xmark.circle"
            }
        }()

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(accent)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal)
                        .font(.cormorant(15)).fontWeight(.semibold)
                        .foregroundColor(.ivory)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Deadline: \(deadline)")
                        .font(.cormorant(12, italic: true))
                        .foregroundColor(.ivoryDim)
                }
                Spacer()
                Text(verdict)
                    .font(.cinzel(8)).tracking(1)
                    .foregroundColor(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accent.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(accent.opacity(0.4), lineWidth: 1))
                    .cornerRadius(4)
            }
            Text(detail)
                .font(.cormorant(13, italic: true))
                .foregroundColor(.ivoryDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "1c0400").opacity(0.7))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(accent.opacity(0.35), lineWidth: 1))
        .cornerRadius(6)
    }

    // MARK: - Observation helpers (mirroring InsightsView logic)

    private func obsIcon(_ rec: String) -> String {
        if rec.contains("difficult") || rec.contains("struggle") { return "exclamationmark.triangle" }
        if rec.contains("away") || rec.contains("days")          { return "clock.arrow.circlepath" }
        if rec.contains("fall on")                               { return "calendar" }
        if rec.contains("sessions produce")                      { return "timer" }
        if rec.contains("ready to mark")                         { return "flag" }
        if rec.contains("confidence") || rec.contains("notes")   { return "text.bubble" }
        return "sparkle"
    }

    private func obsHeadline(_ rec: String) -> String {
        if rec.contains("difficult") || rec.contains("struggle") { return "Difficulty detected" }
        if rec.contains("away")                                  { return "Practice gap" }
        if rec.contains("fall on")                               { return "Best practice day" }
        if rec.contains("sessions produce")                      { return "Optimal session length" }
        if rec.contains("ready to mark")                         { return "Milestone projection" }
        if rec.contains("confidence") || rec.contains("notes")   { return "Session sentiment" }
        return "Insight"
    }

    private func obsAccent(_ rec: String) -> Color {
        if rec.contains("difficult") || rec.contains("struggle") || rec.contains("away") {
            return Color(red: 0.8, green: 0.4, blue: 0.1)
        }
        return .gold
    }

    // MARK: - Trend badge

    @ViewBuilder
    private func trendBadge(_ trend: QualityTrend) -> some View {
        let (label, color, icon): (String, Color, String) = {
            switch trend {
            case .improving:    return ("Improving", Color(red: 0.3, green: 0.75, blue: 0.4), "arrow.up.right")
            case .declining:    return ("Declining", Color(red: 0.8, green: 0.35, blue: 0.2), "arrow.down.right")
            case .stable:       return ("Stable",    .gold,                                    "minus")
            case .insufficient: return ("—",         .ivoryDim,                                "minus")
            }
        }()
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10, weight: .semibold))
            Text(label).font(.cinzel(9)).tracking(1.5)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(color.opacity(0.12))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.4), lineWidth: 1))
        .cornerRadius(4)
    }

    // MARK: - Divider

    @ViewBuilder
    private func sectionDivider() -> some View {
        Color.gold.opacity(0.15).frame(height: 1)
    }
}
