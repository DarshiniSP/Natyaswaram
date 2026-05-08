import SwiftUI

// MARK: - Root background (mandala + corners + particles)
struct BackgroundView: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Color.deep

            // Layered radial glows
            RadialGradient(colors: [Color(hex: "5a0e0e").opacity(0.34), .clear],
                           center: .top, startRadius: 0, endRadius: 420)
            RadialGradient(colors: [Color(hex: "7a3a00").opacity(0.20), .clear],
                           center: .bottomLeading, startRadius: 0, endRadius: 360)
            RadialGradient(colors: [Color(hex: "3a0a0a").opacity(0.27), .clear],
                           center: .bottomTrailing, startRadius: 0, endRadius: 360)

            // Spinning mandala — frame(maxWidth/maxHeight:.infinity) prevents the
            // fixed 700×700 canvas inside MandalaShape from inflating the ZStack's
            // reported layout size, which would otherwise corrupt geo.size.width in
            // child GeometryReaders throughout the app.
            MandalaShape()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .rotationEffect(.degrees(rotation))
                .opacity(0.07)
                .onAppear {
                    withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }

            // Corner ornaments
            GeometryReader { geo in
                let size = CGSize(width: 90, height: 90)
                Group {
                    CornerOrnament().frame(width: size.width, height: size.height)
                        .position(x: size.width/2, y: size.height/2)
                    CornerOrnament().scaleEffect(x: -1, y: 1)
                        .frame(width: size.width, height: size.height)
                        .position(x: geo.size.width - size.width/2, y: size.height/2)
                    CornerOrnament().scaleEffect(x: 1, y: -1)
                        .frame(width: size.width, height: size.height)
                        .position(x: size.width/2, y: geo.size.height - size.height/2)
                    CornerOrnament().scaleEffect(x: -1, y: -1)
                        .frame(width: size.width, height: size.height)
                        .position(x: geo.size.width - size.width/2, y: geo.size.height - size.height/2)
                }
                .opacity(0.18)
            }

            // Twinkling particles
            TwinklingDotsView()
        }
    }
}

// MARK: - Mandala
struct MandalaShape: View {
    var body: some View {
        Canvas { ctx, size in
            // Size is dynamic — fills whatever container BackgroundView provides.
            // No fixed frame so the ZStack's layout width stays at screen width.
            let cx = size.width  / 2
            let cy = size.height / 2
            let R  = min(cx, cy) * 0.96
            let gc = Color.gold

            // Concentric rings
            for (r, w) in [(R, 0.8), (R*0.95, 0.4), (R*0.84, 0.8),
                           (R*0.74, 0.4), (R*0.63, 0.8), (R*0.42, 0.8), (R*0.21, 1.2)] {
                var p = Path(); p.addEllipse(in: CGRect(x: cx-r, y: cy-r, width: r*2, height: r*2))
                ctx.stroke(p, with: .color(gc), lineWidth: w)
            }

            // 16 spokes (every 22.5°)
            for i in 0..<16 {
                let a = Double(i) * .pi / 8
                var p = Path()
                p.move(to:    CGPoint(x: cx + R * cos(a), y: cy + R * sin(a)))
                p.addLine(to: CGPoint(x: cx - R * cos(a), y: cy - R * sin(a)))
                ctx.stroke(p, with: .color(gc.opacity(0.5)), lineWidth: 0.5)
            }

            // 8 outer petals (ellipses rotated around centre)
            for i in 0..<8 {
                let a = CGFloat(i) * .pi / 4
                var petal = Path()
                petal.addEllipse(in: CGRect(x: -11, y: -(R * 0.74 + 30), width: 22, height: 60))
                let t = CGAffineTransform(translationX: cx, y: cy).rotated(by: a)
                ctx.fill(petal.applying(t), with: .color(gc.opacity(0.4)))
            }

            // 8 inner petals (offset 22.5°)
            for i in 0..<8 {
                let a = CGFloat(i) * .pi / 4 + .pi / 8
                var petal = Path()
                petal.addEllipse(in: CGRect(x: -7, y: -(R * 0.42 + 19), width: 14, height: 38))
                let t = CGAffineTransform(translationX: cx, y: cy).rotated(by: a)
                ctx.fill(petal.applying(t), with: .color(gc.opacity(0.6)))
            }

            // Centre dots
            var c1 = Path(); c1.addEllipse(in: CGRect(x: cx-10, y: cy-10, width: 20, height: 20))
            ctx.fill(c1, with: .color(gc.opacity(0.8)))
            var c2 = Path(); c2.addEllipse(in: CGRect(x: cx-4, y: cy-4, width: 8, height: 8))
            ctx.fill(c2, with: .color(Color.goldLight))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Corner ornament
struct CornerOrnament: View {
    var body: some View {
        Canvas { ctx, size in
            let gc = Color.gold
            // Outer L bracket
            var outer = Path()
            outer.move(to:    CGPoint(x: 8,  y: 8))
            outer.addLine(to: CGPoint(x: 52, y: 8))
            outer.addQuadCurve(to: CGPoint(x: 58, y: 52),
                               control: CGPoint(x: 58, y: 8))
            ctx.stroke(outer, with: .color(gc), lineWidth: 1.5)

            var inner = Path()
            inner.move(to:    CGPoint(x: 8,  y: 8))
            inner.addLine(to: CGPoint(x: 8,  y: 52))
            inner.addQuadCurve(to: CGPoint(x: 52, y: 58),
                               control: CGPoint(x: 8, y: 58))
            ctx.stroke(inner, with: .color(gc), lineWidth: 1.5)

            // Corner dot
            var d1 = Path(); d1.addEllipse(in: CGRect(x: 5, y: 5, width: 6, height: 6))
            ctx.fill(d1, with: .color(gc))
            // Inner dot
            var d2 = Path(); d2.addEllipse(in: CGRect(x: 55, y: 55, width: 4, height: 4))
            ctx.fill(d2, with: .color(Color.goldLight))

            // Small arch
            var arch = Path()
            arch.move(to:    CGPoint(x: 22, y: 8))
            arch.addLine(to: CGPoint(x: 22, y: 20))
            arch.addQuadCurve(to: CGPoint(x: 44, y: 20),
                              control: CGPoint(x: 33, y: 26))
            arch.addLine(to: CGPoint(x: 44, y: 8))
            ctx.stroke(arch, with: .color(gc.opacity(0.55)), lineWidth: 0.8)
        }
    }
}

// MARK: - Twinkling particle dots
struct TwinklingDotsView: View {
    struct Particle: Identifiable {
        let id: Int; let x, y, dur, delay: Double
    }
    let particles: [Particle] = (0..<55).map {
        Particle(id: $0,
                 x: Double.random(in: 0...1), y: Double.random(in: 0...1),
                 dur: Double.random(in: 3...8), delay: Double.random(in: 0...6))
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                TwinkleDot(duration: p.dur, delay: p.delay)
                    .position(x: p.x * geo.size.width, y: p.y * geo.size.height)
            }
        }
        .allowsHitTesting(false)
    }
}

struct TwinkleDot: View {
    let duration, delay: Double
    @State private var visible = false

    var body: some View {
        Circle()
            .fill(Color.goldLight)
            .frame(width: 2, height: 2)
            .opacity(visible ? 0.7 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: duration)
                    .repeatForever(autoreverses: true).delay(delay)) {
                    visible = true
                }
            }
    }
}
