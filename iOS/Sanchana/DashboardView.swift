import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var activeTab: DashTab = .items
    // Observing this triggers a re-render whenever the font scale changes in Settings,
    // which causes all child views to rebuild with the updated font size.
    @AppStorage("font_size_preset") private var fontSizePreset: Int = 0

    enum DashTab { case calendar, insights, items, settings }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch activeTab {
                case .calendar: CalendarTabView()
                case .insights: InsightsView()
                case .items:    HomeTabView()
                case .settings: SettingsTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.25), value: activeTab)

            BottomNavBar(active: $activeTab)
        }
    }
}

// MARK: - Bottom nav bar
struct BottomNavBar: View {
    @Binding var active: DashboardView.DashTab

    var body: some View {
        HStack(spacing: 0) {
            NavTabButton(tab: .items,    label: "Home",     icon: homeIcon,      active: $active)
            NavTabButton(tab: .calendar, label: "Calendar", icon: calendarIcon,  active: $active)
            NavTabButton(tab: .insights, label: "Insights", icon: insightsIcon,  active: $active)
            NavTabButton(tab: .settings, label: "Settings", icon: settingsIcon,  active: $active)
        }
        .frame(height: 68)
        .background {
            // Background extends below home indicator visually while
            // buttons stay within the safe area touch target
            LinearGradient(colors: [Color(hex: "1a0802").opacity(0.93), Color.ink],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .top) {
                Color.gold.opacity(0.33).frame(height: 1)
            }
        }
    }
}

struct NavTabButton: View {
    let tab:   DashboardView.DashTab
    let label: String
    let icon:  AnyView
    @Binding var active: DashboardView.DashTab

    var isActive: Bool { active == tab }

    var body: some View {
        Button { active = tab } label: {
            VStack(spacing: 4) {
                icon
                    .frame(width: 24, height: 24)
                Text(label)
                    .font(.cormorant(10))
                    .tracking(1.2)
                    .textCase(.uppercase)
            }
            .foregroundColor(isActive ? .gold : Color.ivoryDim.opacity(0.67))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                if isActive {
                    Color.gold.frame(height: 2).padding(.horizontal, 20)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

// MARK: - Nav icon paths (computed inside BottomNavBar to avoid file-scope Sendable issues)
private extension BottomNavBar {

    var calendarIcon: AnyView {
        AnyView(Canvas { ctx, _ in
            let gc = Color(white: 1)
            var body = Path()
            body.addRoundedRect(in: CGRect(x: 3, y: 4, width: 18, height: 18), cornerSize: CGSize(width: 2, height: 2))
            ctx.stroke(body, with: .color(gc), lineWidth: 1.6)
            for x in [8, 16] as [CGFloat] {
                var pin = Path()
                pin.move(to:    CGPoint(x: x, y: 2))
                pin.addLine(to: CGPoint(x: x, y: 6))
                ctx.stroke(pin, with: .color(gc), lineWidth: 1.6)
            }
            var line = Path()
            line.move(to:    CGPoint(x: 3, y: 9))
            line.addLine(to: CGPoint(x: 21, y: 9))
            ctx.stroke(line, with: .color(gc), lineWidth: 1.6)
        })
    }

    // ♫ double eighth note
    var musicIcon: AnyView {
        AnyView(Canvas { ctx, _ in
            let gc = Color(white: 1)
            // Noteheads (filled ellipses)
            var head1 = Path()
            head1.addEllipse(in: CGRect(x: 2.5, y: 16.5, width: 7, height: 5))
            ctx.fill(head1, with: .color(gc))
            var head2 = Path()
            head2.addEllipse(in: CGRect(x: 13, y: 14.5, width: 7, height: 5))
            ctx.fill(head2, with: .color(gc))
            // Stems
            var stem1 = Path()
            stem1.move(to:    CGPoint(x: 9,   y: 19))
            stem1.addLine(to: CGPoint(x: 9,   y: 5))
            ctx.stroke(stem1, with: .color(gc), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            var stem2 = Path()
            stem2.move(to:    CGPoint(x: 19.5, y: 17))
            stem2.addLine(to: CGPoint(x: 19.5, y: 5))
            ctx.stroke(stem2, with: .color(gc), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            // Beam connecting the tops
            var beam = Path()
            beam.move(to:    CGPoint(x: 9,    y: 5))
            beam.addLine(to: CGPoint(x: 19.5, y: 5))
            ctx.stroke(beam, with: .color(gc), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        })
    }

    var insightsIcon: AnyView {
        AnyView(Canvas { ctx, _ in
            let gc = Color(white: 1)
            // Base line
            var base = Path()
            base.move(to:    CGPoint(x: 2, y: 22))
            base.addLine(to: CGPoint(x: 22, y: 22))
            ctx.stroke(base, with: .color(gc), lineWidth: 1.2)
            // Bar 1 — short (left)
            var b1 = Path(); b1.addRect(CGRect(x: 3,  y: 14, width: 5, height: 8))
            ctx.fill(b1, with: .color(gc))
            // Bar 2 — tall (middle)
            var b2 = Path(); b2.addRect(CGRect(x: 10, y: 5,  width: 5, height: 17))
            ctx.fill(b2, with: .color(gc))
            // Bar 3 — medium (right)
            var b3 = Path(); b3.addRect(CGRect(x: 17, y: 10, width: 5, height: 12))
            ctx.fill(b3, with: .color(gc))
        })
    }

    var homeIcon: AnyView {
        AnyView(Canvas { ctx, _ in
            let gc = Color(white: 1)
            // Roof
            var roof = Path()
            roof.move(to:    CGPoint(x: 12, y: 3))
            roof.addLine(to: CGPoint(x: 21, y: 11))
            roof.addLine(to: CGPoint(x: 3,  y: 11))
            roof.closeSubpath()
            ctx.stroke(roof, with: .color(gc), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            // Walls
            var walls = Path()
            walls.addRect(CGRect(x: 5, y: 11, width: 14, height: 10))
            ctx.stroke(walls, with: .color(gc), lineWidth: 1.6)
            // Door
            var door = Path()
            door.addRect(CGRect(x: 9.5, y: 15, width: 5, height: 6))
            ctx.stroke(door, with: .color(gc), lineWidth: 1.2)
        })
    }

    var settingsIcon: AnyView {
        AnyView(Canvas { ctx, _ in
            let gc = Color(white: 1)
            var gear = Path()
            gear.addEllipse(in: CGRect(x: 9, y: 9, width: 6, height: 6))
            ctx.stroke(gear, with: .color(gc), lineWidth: 1.6)
            let outerAngles: [CGFloat] = [0, 45, 90, 135, 180, 225, 270, 315]
            for a in outerAngles {
                let rad = a * .pi / 180
                let x1 = 12 + cos(rad) * 7, y1 = 12 + sin(rad) * 7
                let x2 = 12 + cos(rad) * 9.5, y2 = 12 + sin(rad) * 9.5
                var spoke = Path()
                spoke.move(to:    CGPoint(x: x1, y: y1))
                spoke.addLine(to: CGPoint(x: x2, y: y2))
                ctx.stroke(spoke, with: .color(gc), lineWidth: 1.6)
            }
        })
    }
}
