import SwiftUI

// Identifiable wrapper so .sheet(item:) can present a specific day
private struct SelectedDay: Identifiable {
    let id   = UUID()
    let date: Date
}

private enum CalCover: String, Identifiable {
    case progressTracker, goalTracker
    var id: String { rawValue }
}

struct CalendarTabView: View {
    private let today = Date()
    @State private var viewDate:    Date
    @State private var activeCover: CalCover?    = nil
    @State private var selectedDay: SelectedDay? = nil
    @ObservedObject private var store          = ProgressStore.shared
    @ObservedObject private var goalStore      = GoalStore.shared
    @ObservedObject private var milestoneStore = MilestoneStore.shared
    @AppStorage("week_starts_monday") private var weekStartsMonday = false

    init() {
        let cal = Calendar.current
        _viewDate = State(initialValue: cal.date(from: cal.dateComponents([.year, .month], from: Date()))!)
    }

    private var cal: Calendar { .current }
    private var year:  Int    { cal.component(.year,  from: viewDate) }
    private var month: Int    { cal.component(.month, from: viewDate) }

    private let monthNames = ["January","February","March","April","May","June",
                               "July","August","September","October","November","December"]

    private var dayNames: [String] {
        weekStartsMonday
            ? ["Mo","Tu","We","Th","Fr","Sa","Su"]
            : ["Su","Mo","Tu","We","Th","Fr","Sa"]
    }

    private var cells: [Int?] {
        let first    = cal.date(from: DateComponents(year: year, month: month, day: 1))!
        let rawWeekday = cal.component(.weekday, from: first) - 1  // 0=Sun…6=Sat
        let offset   = weekStartsMonday ? (rawWeekday + 6) % 7 : rawWeekday
        let daysInMo = cal.range(of: .day, in: .month, for: first)!.count
        var arr: [Int?] = Array(repeating: nil, count: offset)
        arr += (1...daysInMo).map { Optional($0) }
        while arr.count % 7 != 0 { arr.append(nil) }
        return arr
    }

    private func isToday(_ d: Int) -> Bool {
        let dc = cal.dateComponents([.year, .month, .day], from: today)
        return dc.year == year && dc.month == month && dc.day == d
    }

    private func fullDate(for day: Int) -> Date {
        cal.date(from: DateComponents(year: year, month: month, day: day))!
    }

    var body: some View {
        GeometryReader { geo in
            let w       = geo.size.width
            let h       = geo.size.height
            let calH    = h * 0.75
            let botH    = h - calH - 1
            let headerH = calH * 0.12
            let namesH  = calH * 0.09
            let gridH   = calH - headerH - namesH
            let numRows = CGFloat(cells.count / 7)
            let rowH    = gridH / numRows
            let colW    = w / 7

            VStack(spacing: 0) {

                // ── Calendar area (top 75%) ───────────────────────────────
                VStack(spacing: 0) {

                    // Month / year header
                    HStack {
                        navButton("‹") { stepMonth(by: -1) }
                        Spacer()
                        Text("\(monthNames[month-1]) \(String(year))")
                            .font(.cinzel(14))
                            .tracking(3)
                            .textCase(.uppercase)
                            .foregroundColor(.gold)
                        Spacer()
                        navButton("›") { stepMonth(by: +1) }
                    }
                    .frame(width: w, height: headerH)

                    // Day-name row
                    HStack(spacing: 0) {
                        ForEach(dayNames, id: \.self) { d in
                            Text(d)
                                .font(.cinzel(9))
                                .tracking(1)
                                .textCase(.uppercase)
                                .foregroundColor(.gold)
                                .multilineTextAlignment(.center)
                                .frame(width: colW, height: namesH)
                        }
                    }

                    // Day grid — each cell fills exactly colW × rowH
                    let rows = cells.count / 7
                    VStack(spacing: 0) {
                        ForEach(0..<rows, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<7, id: \.self) { col in
                                    let idx = row * 7 + col
                                    if idx < cells.count, let d = cells[idx] {
                                        Button {
                                            selectedDay = SelectedDay(date: fullDate(for: d))
                                        } label: {
                                            dayCell(d, colW: colW, rowH: rowH)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        Color.clear.frame(width: colW, height: rowH)
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: w, height: gridH)
                }
                .frame(width: w, height: calH)

                // ── Divider ───────────────────────────────────────────────
                Color.gold.opacity(0.33).frame(height: 1)

                // ── Bottom cards (bottom 25%) ─────────────────────────────
                HStack(spacing: 0) {
                    calBottomCard(icon: progressIcon, title: "Progress Tracker",
                                  action: { activeCover = .progressTracker })
                    Color.gold.opacity(0.2).frame(width: 1)
                    calBottomCard(icon: goalsIcon, title: "Goals",
                                  action: { activeCover = .goalTracker })
                }
                .frame(width: w, height: botH)
                .fullScreenCover(item: $activeCover) { cover in
                    switch cover {
                    case .progressTracker: ProgressTrackerView()
                    case .goalTracker:     GoalTrackerView()
                    }
                }
                .sheet(item: $selectedDay) { day in
                    DayRemarkSheet(date: day.date)
                        .presentationDetents([.fraction(0.60)])
                        .presentationBackground(Color(hex: "1c0400"))
                        .presentationDragIndicator(.visible)
                }
            }
            .frame(width: w, height: h)
        }
    }

    // MARK: - Day cell (explicit size — fills the calculated rowH × colW)
    private func dayCell(_ d: Int, colW: CGFloat, rowH: CGFloat) -> some View {
        let isTodayCell    = isToday(d)
        let date           = fullDate(for: d)
        let hasNote        = store.hasEntry(for: date)
        let hasGoal        = goalStore.hasGoal(for: date)
        let hasMilestone   = milestoneStore.hasMilestone(on: date)
        let circleSize     = min(colW, rowH) * 0.70
        return ZStack {
            if isTodayCell {
                Circle()
                    .fill(Color.gold)
                    .frame(width: circleSize, height: circleSize)
            }
            VStack(spacing: 2) {
                Text("\(d)")
                    .font(.cormorant(17))
                    .foregroundColor(isTodayCell ? Color.ink : Color.ivoryDim)
                    .fontWeight(isTodayCell ? .bold : .regular)
                // Three dots: white=practice  gold=goal  goldLight=milestone
                HStack(spacing: 3) {
                    Circle()
                        .fill(isTodayCell ? Color.ink.opacity(0.7) : Color.white.opacity(0.9))
                        .frame(width: 4, height: 4)
                        .opacity(hasNote ? 1 : 0)
                    Circle()
                        .fill(isTodayCell ? Color.ink.opacity(0.7) : Color.gold)
                        .frame(width: 4, height: 4)
                        .opacity(hasGoal ? 1 : 0)
                    Image(systemName: "star.fill")
                        .font(.system(size: 6))
                        .foregroundColor(isTodayCell ? Color.ink.opacity(0.7) : Color.goldLight)
                        .opacity(hasMilestone ? 1 : 0)
                }
            }
        }
        .frame(width: colW, height: rowH)
    }

    // MARK: - Nav button
    private func navButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.gold)
                .padding(.horizontal, 12)
        }
    }

    // MARK: - Bottom card
    private func calBottomCard(icon: AnyView, title: String, action: (() -> Void)? = nil) -> some View {
        Button { action?() } label: {
            VStack(spacing: 8) {
                icon.frame(width: 28, height: 28)
                Text(title)
                    .font(.cinzel(9))
                    .tracking(2.5)
                    .textCase(.uppercase)
                    .foregroundColor(.gold)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LinearGradient.cardBackground)
        }
        .buttonStyle(.plain)
    }

    private func stepMonth(by delta: Int) {
        viewDate = cal.date(byAdding: .month, value: delta, to: viewDate)!
    }

    // MARK: - Bottom card icons
    private var progressIcon: AnyView {
        AnyView(Canvas { ctx, _ in
            let gc = Color(white: 1)
            var xAxis = Path(); xAxis.move(to: CGPoint(x: 3, y: 20)); xAxis.addLine(to: CGPoint(x: 21, y: 20))
            var yAxis = Path(); yAxis.move(to: CGPoint(x: 3, y: 4));  yAxis.addLine(to: CGPoint(x: 3,  y: 20))
            ctx.stroke(xAxis, with: .color(gc), lineWidth: 1.5)
            ctx.stroke(yAxis, with: .color(gc), lineWidth: 1.5)
            var trend = Path()
            trend.move(to:    CGPoint(x:  5, y: 17))
            trend.addLine(to: CGPoint(x:  9, y: 13))
            trend.addLine(to: CGPoint(x: 13, y: 15))
            trend.addLine(to: CGPoint(x: 19, y:  7))
            ctx.stroke(trend, with: .color(gc), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            for (x, y, r) in [(19, 7, 1.6), (13, 15, 1.2), (9, 13, 1.2), (5, 17, 1.2)] as [(CGFloat,CGFloat,CGFloat)] {
                var dot = Path(); dot.addEllipse(in: CGRect(x: x-r, y: y-r, width: r*2, height: r*2))
                ctx.fill(dot, with: .color(gc))
            }
        })
    }

    private var goalsIcon: AnyView {
        AnyView(Canvas { ctx, _ in
            let gc = Color(white: 1)
            for r in [9.0, 5.5] as [CGFloat] {
                var ring = Path(); ring.addEllipse(in: CGRect(x: 12-r, y: 12-r, width: r*2, height: r*2))
                ctx.stroke(ring, with: .color(gc), lineWidth: 1.5)
            }
            var centre = Path(); centre.addEllipse(in: CGRect(x: 10, y: 10, width: 4, height: 4))
            ctx.fill(centre, with: .color(gc))
            var arrow = Path()
            arrow.move(to:    CGPoint(x: 20, y: 4))
            arrow.addLine(to: CGPoint(x: 14, y: 10))
            ctx.stroke(arrow, with: .color(gc), lineWidth: 1.5)
            var tip = Path()
            tip.move(to:    CGPoint(x: 15.5, y: 4))
            tip.addLine(to: CGPoint(x: 20, y: 4))
            tip.addLine(to: CGPoint(x: 20, y: 8.5))
            ctx.stroke(tip, with: .color(gc), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        })
    }
}

// MARK: - Day remark sheet (slides up when a calendar day is tapped)

private enum SheetCover: String, Identifiable {
    case practiceEditor, goalEditor
    var id: String { rawValue }
}

struct DayRemarkSheet: View {
    let date: Date
    @ObservedObject private var store          = ProgressStore.shared
    @ObservedObject private var goalStore      = GoalStore.shared
    @ObservedObject private var milestoneStore = MilestoneStore.shared
    @State private var activeCover: SheetCover? = nil

    var body: some View {
        let entry        = store.entry(for: date)
        let goalEntry    = goalStore.goal(for: date)
        let milestones   = milestoneStore.milestones(on: date)
        let hasAny       = entry.hasContent || goalEntry.hasContent || !milestones.isEmpty

        VStack(spacing: 0) {

            // ── Date header ───────────────────────────────────────────
            Text(formattedDate(date))
                .font(.cinzel(12)).tracking(4).textCase(.uppercase)
                .foregroundColor(.gold)
                .padding(.top, 22)
                .padding(.bottom, 10)

            Color.gold.opacity(0.25).frame(height: 1).padding(.horizontal, 24)

            if !hasAny {
                // Empty state
                Spacer()
                Text("Nothing recorded for this day.")
                    .font(.cormorant(14, italic: true))
                    .foregroundColor(.ivoryDim.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Practice section ─────────────────────────
                        if entry.hasContent {

                            // Work title + practice time row
                            if !entry.workTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                || !entry.practiceTimeString.isEmpty {
                                HStack(spacing: 0) {
                                    if !entry.workTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text("Worked on")
                                                .font(.cinzel(7)).tracking(2).textCase(.uppercase)
                                                .foregroundColor(.gold.opacity(0.7))
                                            Text(entry.workTitle)
                                                .font(.cormorant(15))
                                                .foregroundColor(.ivory)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    if !entry.practiceTimeString.isEmpty {
                                        VStack(alignment: .trailing, spacing: 3) {
                                            Text("Practice time")
                                                .font(.cinzel(7)).tracking(2).textCase(.uppercase)
                                                .foregroundColor(.gold.opacity(0.7))
                                            Text(entry.practiceTimeString)
                                                .font(.cinzel(13)).tracking(1)
                                                .foregroundColor(.gold)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 12)
                            }

                            // Remark
                            if !entry.remark.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                if !entry.workTitle.isEmpty || !entry.practiceTimeString.isEmpty {
                                    Color.gold.opacity(0.18).frame(height: 1)
                                        .padding(.horizontal, 24).padding(.top, 10)
                                }
                                Text(entry.remark)
                                    .font(.cormorant(15))
                                    .foregroundColor(.ivory)
                                    .lineSpacing(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                            }
                        }

                        // ── Goal section ─────────────────────────────
                        if goalEntry.hasContent {
                            if entry.hasContent {
                                Color.gold.opacity(0.25).frame(height: 1)
                                    .padding(.horizontal, 24).padding(.top, 4)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Goal")
                                    .font(.cinzel(7)).tracking(2).textCase(.uppercase)
                                    .foregroundColor(.gold.opacity(0.7))
                                Text(goalEntry.goalText)
                                    .font(.cormorant(15))
                                    .foregroundColor(.ivory)
                                    .lineSpacing(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                            .padding(.bottom, 10)
                        }

                        // ── Milestone section ─────────────────────────
                        if !milestones.isEmpty {
                            if entry.hasContent || goalEntry.hasContent {
                                Color.gold.opacity(0.25).frame(height: 1)
                                    .padding(.horizontal, 24).padding(.top, 4)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text(milestones.count == 1 ? "Milestone Achieved" : "Milestones Achieved")
                                    .font(.cinzel(7)).tracking(2).textCase(.uppercase)
                                    .foregroundColor(.goldLight.opacity(0.85))
                                ForEach(milestones, id: \.title) { m in
                                    HStack(spacing: 6) {
                                        Text("✦")
                                            .font(.system(size: 8))
                                            .foregroundColor(.goldLight)
                                        Text(m.title)
                                            .font(.cormorant(15))
                                            .foregroundColor(.ivory)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                            .padding(.bottom, 10)
                        }
                    }
                }
            }

            // ── Add / Edit Note button ────────────────────────────────
            Button { activeCover = .practiceEditor } label: {
                Text(entry.hasContent ? "Edit Note" : "Add Note")
                    .font(.cinzel(9)).tracking(2.5).textCase(.uppercase)
                    .foregroundColor(.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .overlay(alignment: .top) { Color.gold.opacity(0.2).frame(height: 1) }

            // ── Add / Edit Goal button ────────────────────────────────
            Button { activeCover = .goalEditor } label: {
                Text(goalEntry.hasContent ? "Edit Goal" : "Add Goal")
                    .font(.cinzel(9)).tracking(2.5).textCase(.uppercase)
                    .foregroundColor(.gold.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .overlay(alignment: .top) { Color.gold.opacity(0.2).frame(height: 1) }
            .padding(.bottom, 8)
        }
        .fullScreenCover(item: $activeCover) { cover in
            switch cover {
            case .practiceEditor: ProgressTrackerView(initialDate: date)
            case .goalEditor:     GoalTrackerView(initialDate: date)
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d MMMM yyyy"
        return f.string(from: date)
    }
}
