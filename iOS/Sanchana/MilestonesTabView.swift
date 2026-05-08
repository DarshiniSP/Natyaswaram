import SwiftUI
import Combine

// MARK: - Achievement model + store

struct MilestoneAchievement: Codable {
    var timestamp: Double   // timeIntervalSince1970
    var title:     String
    var date: Date { Date(timeIntervalSince1970: timestamp) }
}

final class MilestoneStore: ObservableObject {
    static let shared = MilestoneStore()

    @Published private(set) var achievements: [Int: MilestoneAchievement] = [:]

    private static let udKey = "milestone_achieved_v2"
    private let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    private init() { load() }

    // MARK: - Write

    func setAchieved(index: Int, date: Date, title: String) {
        achievements[index] = MilestoneAchievement(
            timestamp: date.timeIntervalSince1970,
            title:     title
        )
        persist()
    }

    func removeAchievement(index: Int) {
        achievements.removeValue(forKey: index)
        persist()
    }

    // MARK: - Read (by index)

    func achievedDate(for index: Int) -> Date? { achievements[index]?.date }

    // MARK: - Read (by calendar date — for CalendarTabView)

    func hasMilestone(on date: Date) -> Bool {
        let key = fmt.string(from: date)
        return achievements.values.contains { fmt.string(from: $0.date) == key }
    }

    func milestones(on date: Date) -> [MilestoneAchievement] {
        let key = fmt.string(from: date)
        return achievements.values.filter { fmt.string(from: $0.date) == key }
    }

    // MARK: - Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: Self.udKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.udKey),
              let decoded = try? JSONDecoder().decode([String: MilestoneAchievement].self, from: data)
        else { return }
        achievements = Dictionary(uniqueKeysWithValues: decoded.compactMap { k, v in
            guard let i = Int(k) else { return nil }
            return (i, v)
        })
    }
}

// MARK: - Data model

struct Milestone {
    let title: String
    let sub:   String
    let xPct:  CGFloat   // 0–100, fraction of container width
}

enum MilestoneStatus { case done, current, upcoming }

// MARK: - Sheet wrapper

private struct SelectedMilestone: Identifiable {
    let id:        Int
    let milestone: Milestone
}

// MARK: - Main view

struct MilestonesTabView: View {
    let items: [Milestone] = [
        Milestone(title: "Adavu Basics",     sub: "Foundation steps",        xPct: 50),
        Milestone(title: "Asamyutha Hastas", sub: "28 single-hand gestures", xPct: 68),
        Milestone(title: "Samyutha Hastas",  sub: "24 combined gestures",    xPct: 52),
        Milestone(title: "Alaripu",          sub: "First margam item",       xPct: 30),
        Milestone(title: "Jathiswaram",      sub: "Pure rhythmic piece",     xPct: 65),
        Milestone(title: "Shabdam",          sub: "Expressive composition",  xPct: 25),
        Milestone(title: "Varnam",           sub: "Centrepiece of recital",  xPct: 55),
    ]

    @ObservedObject private var milestoneStore = MilestoneStore.shared
    @State private var tappedMilestone: SelectedMilestone? = nil

    private let nodeR: CGFloat = 26
    private let padT:  CGFloat = 44   // top padding inside canvas

    var body: some View {
        GeometryReader { geo in
            let cw      = geo.size.width
            let h       = geo.size.height
            // heading strip ≈ 47 pt (text + padding + divider)
            let pathH   = h - 47
            // row spacing that fills pathH exactly
            let rowH    = (pathH - padT - 26) / CGFloat(items.count)
            let totalH  = pathH

            let pts      = items.enumerated().map { (i, m) in
                CGPoint(x: cw * m.xPct / 100, y: padT + CGFloat(i) * rowH)
            }
            let statuses = items.indices.map { computedStatus(for: $0) }

            VStack(spacing: 0) {
                // ── Fixed heading strip ───────────────────────────────────
                Text("Every step brings you closer to the stage.")
                    .font(.cormorant(15, italic: true))
                    .foregroundColor(.ivoryDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)

                Color.gold.opacity(0.18).frame(height: 1)

                // ── Milestone path (fills remaining height) ───────────────
                ZStack(alignment: .topLeading) {
                    Canvas { ctx, _ in
                        drawDecorations(ctx: &ctx, cw: cw, rowH: rowH)
                        drawPaths(ctx: &ctx, pts: pts, statuses: statuses)
                    }
                    .frame(width: cw, height: totalH)

                    ForEach(items.indices, id: \.self) { i in
                        MilestoneNode(item: items[i], index: i, pt: pts[i], status: statuses[i])
                            .onTapGesture {
                                tappedMilestone = SelectedMilestone(id: i, milestone: items[i])
                            }
                    }
                }
                .frame(width: cw, height: totalH)
                .clipped()
            }
            .frame(width: cw, height: h)
            .sheet(item: $tappedMilestone) { sel in
                MilestoneConfirmSheet(
                    milestone:    sel.milestone,
                    index:        sel.id,
                    existingDate: milestoneStore.achievedDate(for: sel.id),
                    onAchieved: { date in
                        milestoneStore.setAchieved(
                            index: sel.id,
                            date:  date,
                            title: sel.milestone.title
                        )
                    },
                    onRemoved: {
                        milestoneStore.removeAchievement(index: sel.id)
                    }
                )
                .presentationDetents([.large])
                .presentationBackground(Color(hex: "1c0400"))
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Status computation

    private func computedStatus(for index: Int) -> MilestoneStatus {
        if milestoneStore.achievedDate(for: index) != nil { return .done }
        let firstUnachieved = (0..<items.count).first {
            milestoneStore.achievedDate(for: $0) == nil
        } ?? index
        return index == firstUnachieved ? .current : .upcoming
    }

    // MARK: - Connecting paths

    private func drawPaths(ctx: inout GraphicsContext, pts: [CGPoint], statuses: [MilestoneStatus]) {
        for i in 0..<pts.count-1 {
            let a  = pts[i]
            let b  = pts[i+1]
            let my = (a.y + b.y) / 2
            var p  = Path()
            p.move(to:    CGPoint(x: a.x, y: a.y + nodeR))
            p.addCurve(to: CGPoint(x: b.x, y: b.y - nodeR),
                       control1: CGPoint(x: a.x, y: my),
                       control2: CGPoint(x: b.x, y: my))
            let done = statuses[i] == .done
            ctx.stroke(p, with: .color(done ? Color.gold : Color.ivoryDim.opacity(0.16)),
                       style: StrokeStyle(lineWidth: done ? 3 : 2.5,
                                          lineCap: .round,
                                          dash: done ? [] : [7, 5]))
        }
    }

    // MARK: - Decorative motifs (rowH passed in so they scale with the layout)

    private func drawDecorations(ctx: inout GraphicsContext, cw: CGFloat, rowH: CGFloat) {

        func petalPath(n: Int, R: CGFloat, offset: CGFloat, delta: CGFloat) -> Path {
            var p = Path()
            for i in 0..<n {
                let a   = CGFloat(i) * 2 * .pi / CGFloat(n) + offset
                let tx  = R * cos(a);  let ty  = R * sin(a)
                let c1x = R * 0.46 * cos(a - delta); let c1y = R * 0.46 * sin(a - delta)
                let c2x = R * 0.46 * cos(a + delta); let c2y = R * 0.46 * sin(a + delta)
                p.move(to: .zero)
                p.addQuadCurve(to: CGPoint(x: tx, y: ty), control: CGPoint(x: c1x, y: c1y))
                p.addQuadCurve(to: .zero, control: CGPoint(x: c2x, y: c2y))
            }
            return p
        }

        func translated(_ p: Path, dx: CGFloat, dy: CGFloat) -> Path {
            p.applying(CGAffineTransform(translationX: dx, y: dy))
        }

        let gc  = Color.gold
        let bud = petalPath(n: 6, R: 32, offset: 0, delta: .pi/7)

        // ── Small lotus bud (upper-left) ──────────────────────────────────
        let bx = cw * 0.11, by = padT + 0.75 * rowH
        ctx.opacity = 0.34
        ctx.stroke(translated(bud, dx: bx, dy: by), with: .color(gc),
                   style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
        var bRing = Path(); bRing.addEllipse(in: CGRect(x: bx-7, y: by-7, width: 14, height: 14))
        ctx.stroke(bRing, with: .color(gc), lineWidth: 0.7)
        var bDot = Path(); bDot.addEllipse(in: CGRect(x: bx-4, y: by-4, width: 8, height: 8))
        ctx.fill(bDot, with: .color(gc))
        ctx.opacity = 1.0

        // ── Small lotus bud (lower-right) ─────────────────────────────────
        let sx = cw * 0.89, sy = padT + 3.4 * rowH
        ctx.opacity = 0.34
        ctx.stroke(translated(bud, dx: sx, dy: sy), with: .color(gc),
                   style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
        var sRing = Path(); sRing.addEllipse(in: CGRect(x: sx-7, y: sy-7, width: 14, height: 14))
        ctx.stroke(sRing, with: .color(gc), lineWidth: 0.7)
        var sDot = Path(); sDot.addEllipse(in: CGRect(x: sx-4, y: sy-4, width: 8, height: 8))
        ctx.fill(sDot, with: .color(gc))
        ctx.opacity = 1.0
    }
}

// MARK: - Milestone confirmation + date picker sheet

struct MilestoneConfirmSheet: View {
    let milestone:    Milestone
    let index:        Int
    let existingDate: Date?
    let onAchieved:   (Date) -> Void
    let onRemoved:    () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var phase:           Phase = .confirm
    @State private var pickedDate:      Date
    @State private var confirmingUnmark = false

    enum Phase { case confirm, datePick }

    init(milestone: Milestone, index: Int,
         existingDate: Date?,
         onAchieved: @escaping (Date) -> Void,
         onRemoved:  @escaping () -> Void) {
        self.milestone    = milestone
        self.index        = index
        self.existingDate = existingDate
        self.onAchieved   = onAchieved
        self.onRemoved    = onRemoved
        _pickedDate = State(initialValue: existingDate ?? Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(milestone.title)
                .font(.cinzel(15)).tracking(4).textCase(.uppercase)
                .foregroundColor(.gold)
                .padding(.top, 30)
                .padding(.bottom, 4)

            Text(milestone.sub)
                .font(.cormorant(13, italic: true))
                .foregroundColor(.ivoryDim.opacity(0.6))
                .padding(.bottom, 20)

            Color.gold.opacity(0.22).frame(height: 1).padding(.horizontal, 24)

            if phase == .confirm { confirmPhase } else { datePickPhase }
        }
    }

    private var confirmPhase: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("Have you reached this milestone?")
                .font(.cormorant(18, italic: true))
                .foregroundColor(.ivory)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let d = existingDate {
                Text("Previously marked · \(formattedDate(d))")
                    .font(.cinzel(8)).tracking(1.5).textCase(.uppercase)
                    .foregroundColor(.gold.opacity(0.5))
                    .padding(.top, 10)
            }
            Spacer()

            // ── Unmark row (only shown when already logged) ───────────────
            if existingDate != nil {
                if confirmingUnmark {
                    VStack(spacing: 0) {
                        Text("Remove this achievement?")
                            .font(.cormorant(15, italic: true))
                            .foregroundColor(.ivoryDim)
                            .padding(.bottom, 12)
                        HStack(spacing: 0) {
                            Button {
                                confirmingUnmark = false
                            } label: {
                                Text("Keep it")
                                    .font(.cinzel(9)).tracking(2).textCase(.uppercase)
                                    .foregroundColor(.ivoryDim.opacity(0.5))
                                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                            }
                            Color.gold.opacity(0.2).frame(width: 1, height: 38)
                            Button {
                                onRemoved()
                                dismiss()
                            } label: {
                                Text("Yes, remove")
                                    .font(.cinzel(9)).tracking(2).textCase(.uppercase)
                                    .foregroundColor(.saffron)
                                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .overlay(alignment: .top) { Color.gold.opacity(0.15).frame(height: 1) }
                    .padding(.bottom, 6)
                } else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { confirmingUnmark = true }
                    } label: {
                        Text("Unmark this milestone")
                            .font(.cinzel(8)).tracking(2).textCase(.uppercase)
                            .foregroundColor(.saffron.opacity(0.7))
                            .padding(.vertical, 12)
                    }
                    .overlay(alignment: .top) { Color.gold.opacity(0.15).frame(height: 1) }
                }
            }

            // ── Main action row ───────────────────────────────────────────
            HStack(spacing: 0) {
                Button { dismiss() } label: {
                    Text("Not yet")
                        .font(.cinzel(10)).tracking(2).textCase(.uppercase)
                        .foregroundColor(.ivoryDim.opacity(0.5))
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                }
                Color.gold.opacity(0.2).frame(width: 1, height: 48)
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { phase = .datePick }
                } label: {
                    Text(existingDate != nil ? "Change date" : "Yes, I did!")
                        .font(.cinzel(10)).tracking(2).textCase(.uppercase)
                        .foregroundColor(.gold)
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                }
            }
            .overlay(alignment: .top) { Color.gold.opacity(0.2).frame(height: 1) }
            .padding(.bottom, 10)
        }
    }

    private var datePickPhase: some View {
        VStack(spacing: 0) {
            Text("When did you achieve this?")
                .font(.cormorant(16, italic: true))
                .foregroundColor(.ivory)
                .padding(.top, 20).padding(.bottom, 2)
            DatePicker("", selection: $pickedDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(.gold)
                .colorScheme(.dark)
                .padding(.horizontal, 16)
            Spacer()
            HStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { phase = .confirm }
                } label: {
                    Text("Back")
                        .font(.cinzel(10)).tracking(2).textCase(.uppercase)
                        .foregroundColor(.ivoryDim.opacity(0.5))
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                }
                Color.gold.opacity(0.2).frame(width: 1, height: 48)
                Button {
                    onAchieved(pickedDate)
                    dismiss()
                } label: {
                    Text("Save")
                        .font(.cinzel(10)).tracking(2).textCase(.uppercase)
                        .foregroundColor(.gold)
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                }
            }
            .overlay(alignment: .top) { Color.gold.opacity(0.2).frame(height: 1) }
            .padding(.bottom, 10)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d MMMM yyyy"
        return f.string(from: date)
    }
}

// MARK: - Individual milestone node

struct MilestoneNode: View {
    let item:   Milestone
    let index:  Int
    let pt:     CGPoint
    let status: MilestoneStatus

    @State private var pulse = false

    var nodeR: CGFloat { 26 }

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                switch status {
                case .done:
                    Circle()
                        .fill(LinearGradient(colors: [.goldLight, .gold],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(Circle().stroke(Color.goldLight, lineWidth: 2))
                    Text("✓")
                        .font(.cinzel(13, weight: .bold))
                        .foregroundColor(.ink)

                case .current:
                    Circle()
                        .fill(LinearGradient(colors: [.maroon, Color(hex: "4a0e0e")],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(Circle().stroke(Color.gold, lineWidth: 2))
                        .shadow(color: Color.gold.opacity(pulse ? 0.55 : 0.22), radius: pulse ? 18 : 8)
                    Text("\(index+1)")
                        .font(.cinzel(13, weight: .bold))
                        .foregroundColor(.goldLight)

                case .upcoming:
                    Circle()
                        .fill(Color(hex: "1e0d05").opacity(0.54))
                        .overlay(Circle().stroke(Color.ivoryDim.opacity(0.14), lineWidth: 2))
                    Text("\(index+1)")
                        .font(.cinzel(13))
                        .foregroundColor(Color.ivoryDim.opacity(0.34))
                }
            }
            .frame(width: nodeR*2, height: nodeR*2)
            .onAppear {
                if status == .current {
                    withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }
            }

            Text(item.title)
                .font(.cinzel(7)).tracking(1.5).textCase(.uppercase)
                .foregroundColor(status == .upcoming ? Color.ivoryDim.opacity(0.28) : .ivory)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(width: 80)
        }
        .frame(width: 88)
        .position(x: pt.x, y: pt.y)
    }
}
