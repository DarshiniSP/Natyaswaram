import SwiftUI

// MARK: - Padma (Lotus) — for Nritta
/// 8-petal lotus built with bezier-curve petals, matching the web version.
struct PadmaIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let cx = size.width  / 2
            let cy = size.height / 2

            func petalPath(n: Int, R: CGFloat, offset: CGFloat, delta: CGFloat) -> Path {
                var p = Path()
                for i in 0..<n {
                    let a  = CGFloat(i) * 2 * .pi / CGFloat(n) + offset
                    let tx = cx + R * cos(a)
                    let ty = cy + R * sin(a)
                    let c1x = cx + R * 0.42 * cos(a - delta)
                    let c1y = cy + R * 0.42 * sin(a - delta)
                    let c2x = cx + R * 0.42 * cos(a + delta)
                    let c2y = cy + R * 0.42 * sin(a + delta)
                    p.move(to: CGPoint(x: cx, y: cy))
                    p.addQuadCurve(to: CGPoint(x: tx, y: ty),
                                   control: CGPoint(x: c1x, y: c1y))
                    p.addQuadCurve(to: CGPoint(x: cx, y: cy),
                                   control: CGPoint(x: c2x, y: c2y))
                }
                return p
            }

            let outer = petalPath(n: 8, R: 11, offset: -.pi/2, delta: .pi/9)
            let inner = petalPath(n: 8, R:  6.5, offset: -.pi/2 + .pi/8, delta: .pi/10)

            ctx.stroke(outer, with: .color(Color.gold),      lineWidth: 1.3)
            ctx.stroke(inner, with: .color(Color.goldLight), lineWidth: 0.9)

            // Centre dot
            var dot = Path()
            dot.addEllipse(in: CGRect(x: cx-2.2, y: cy-2.2, width: 4.4, height: 4.4))
            ctx.fill(dot, with: .color(Color.gold))

            // Dashed outer ring
            var ring = Path()
            ring.addEllipse(in: CGRect(x: cx-12.5, y: cy-12.5, width: 25, height: 25))
            ctx.stroke(ring, with: .color(Color.gold.opacity(0.5)), style:
                StrokeStyle(lineWidth: 0.45, dash: [2, 3]))
        }
        .frame(width: 30, height: 30)
    }
}

// MARK: - Damaru — for Swaram
/// Shiva's hourglass drum with two drum heads, curved sides, and knot beads.
struct DamaruIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let cx = size.width  / 2
            let cy = size.height / 2
            let gc = Color.gold

            // Top & bottom drum-head ellipses
            for ey in [cy - 8, cy + 8] {
                var head = Path()
                head.addEllipse(in: CGRect(x: cx-7, y: ey-2.5, width: 14, height: 5))
                ctx.fill(head, with: .color(gc.opacity(0.1)))
                ctx.stroke(head, with: .color(gc), lineWidth: 1.3)
            }

            // Left & right hourglass curves
            var left = Path()
            left.move(to:    CGPoint(x: cx-7, y: cy-8))
            left.addQuadCurve(to:    CGPoint(x: cx-3.5, y: cy+8),
                              control: CGPoint(x: cx-3.5, y: cy))
            ctx.stroke(left, with: .color(gc), lineWidth: 1.3)

            var right = Path()
            right.move(to:    CGPoint(x: cx+7, y: cy-8))
            right.addQuadCurve(to:    CGPoint(x: cx+3.5, y: cy+8),
                               control: CGPoint(x: cx+3.5, y: cy))
            ctx.stroke(right, with: .color(gc), lineWidth: 1.3)

            // Knot beads at waist
            for bx in [cx-4, cx+4] {
                var bead = Path()
                bead.addEllipse(in: CGRect(x: bx-2, y: cy-2, width: 4, height: 4))
                ctx.fill(bead, with: .color(gc))
            }

            // Bead strings to drum-head edges
            for (bx, ex) in [(cx-4, cx-6.0), (cx+4, cx+6.0)] {
                for ey in [cy - 7.5, cy + 7.5] {
                    var line = Path()
                    line.move(to:    CGPoint(x: bx, y: cy))
                    line.addLine(to: CGPoint(x: ex, y: ey))
                    ctx.stroke(line, with: .color(gc.opacity(0.7)), lineWidth: 0.7)
                }
            }
        }
        .frame(width: 30, height: 30)
    }
}

// MARK: - Diya (oil lamp) — for Bhava
/// Clay oil lamp with shallow bowl, wick, and teardrop flame.
struct DiyaIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let cx = size.width  / 2
            let cy = size.height / 2
            let gc = Color.gold

            // Bowl (shallow ellipse-like shape)
            var bowl = Path()
            bowl.move(to:    CGPoint(x: cx-9, y: cy+4))
            bowl.addQuadCurve(to:    CGPoint(x: cx, y: cy+8),
                              control: CGPoint(x: cx-9, y: cy+8))
            bowl.addQuadCurve(to:    CGPoint(x: cx+9, y: cy+4),
                              control: CGPoint(x: cx+9, y: cy+8))
            bowl.addLine(to: CGPoint(x: cx+7, y: cy+2))
            bowl.addQuadCurve(to:    CGPoint(x: cx-7, y: cy+2),
                              control: CGPoint(x: cx, y: cy))
            bowl.closeSubpath()
            ctx.fill(bowl, with: .color(gc.opacity(0.1)))
            ctx.stroke(bowl, with: .color(gc), lineWidth: 1.3)

            // Wick
            var wick = Path()
            wick.move(to:    CGPoint(x: cx, y: cy+2))
            wick.addLine(to: CGPoint(x: cx, y: cy-2))
            ctx.stroke(wick, with: .color(gc), lineWidth: 1.1)

            // Outer flame (teardrop)
            var flame = Path()
            flame.move(to:    CGPoint(x: cx, y: cy-2))
            flame.addQuadCurve(to:    CGPoint(x: cx, y: cy-12),
                               control: CGPoint(x: cx-3.5, y: cy-7))
            flame.addQuadCurve(to:    CGPoint(x: cx, y: cy-2),
                               control: CGPoint(x: cx+3.5, y: cy-7))
            ctx.fill(flame, with: .color(gc.opacity(0.12)))
            ctx.stroke(flame, with: .color(Color.goldLight), lineWidth: 1.0)

            // Inner flame core
            var core = Path()
            core.move(to:    CGPoint(x: cx, y: cy-3))
            core.addQuadCurve(to:    CGPoint(x: cx, y: cy-10),
                              control: CGPoint(x: cx-2, y: cy-7))
            core.addQuadCurve(to:    CGPoint(x: cx, y: cy-3),
                              control: CGPoint(x: cx+2, y: cy-7))
            ctx.fill(core, with: .color(gc))
        }
        .frame(width: 30, height: 30)
    }
}
