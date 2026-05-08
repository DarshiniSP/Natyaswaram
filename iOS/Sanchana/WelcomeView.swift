import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            VStack(spacing: 0) {

                // ── Top 3/4: all content spread out ───────────────────────
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    // Heading
                    Text("Namaskaram  ·  नमस्कारम्")
                        .font(.cormorant(10))
                        .tracking(4)
                        .textCase(.uppercase)
                        .foregroundColor(.saffron)
                        .padding(.bottom, h * 0.010)

                    VStack(spacing: h * 0.004) {
                        Text("Welcome,")
                            .font(.cinzel(26, weight: .bold))
                            .foregroundStyle(LinearGradient.goldGradient)
                        Text("\(appState.userName)!")
                            .font(.cinzel(40, weight: .black))
                            .foregroundStyle(LinearGradient.goldGradient)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .padding(.horizontal, w * 0.065)
                    }
                    .multilineTextAlignment(.center)

                    Spacer(minLength: 0)

                    // OM divider
                    HStack(spacing: w * 0.03) {
                        GoldRule()
                        OmSymbol(size: 14)
                        GoldRule()
                    }
                    .padding(.horizontal, w * 0.082)
                    .padding(.vertical, h * 0.018)

                    // Body text
                    Text("You have entered the sacred space of rhythm and expression — where the nritta of form, the nritya of feeling, and the natya of drama are woven into one eternal song.")
                        .font(.cormorant(12))
                        .foregroundColor(.ivoryDim)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, w * 0.065)

                    Spacer(minLength: 0)

                    // Three pillars — compact, no stretching
                    HStack(alignment: .center, spacing: 0) {
                        PillarCell(icon: AnyView(PadmaIcon()),  name: "Nritta",  desc: "Pure Movement", iconSize: w * 0.048)
                        Color.gold.opacity(0.25).frame(width: 1, height: h * 0.08)
                        PillarCell(icon: AnyView(DamaruIcon()), name: "Swaram",  desc: "Sacred Sound",  iconSize: w * 0.048)
                        Color.gold.opacity(0.25).frame(width: 1, height: h * 0.08)
                        PillarCell(icon: AnyView(DiyaIcon()),   name: "Bhava",   desc: "Deep Emotion",  iconSize: w * 0.048)
                    }
                    .padding(.horizontal, w * 0.055)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .frame(height: h * 0.75)

                // ── Bottom 1/4: navigation ─────────────────────────────────
                Button { appState.screen = .dashboard } label: {
                    Text("Enter the Sanctum  →")
                        .font(.cormorant(18, italic: true))
                        .foregroundColor(.gold)
                        .underline(color: Color.gold.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, w * 0.037)
                .frame(maxWidth: .infinity)
                .frame(height: h * 0.25)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Single pillar cell
struct PillarCell: View {
    let icon: AnyView
    let name: String
    let desc: String
    var iconSize: CGFloat = 24

    var body: some View {
        VStack(spacing: 4) {
            icon.frame(width: iconSize, height: iconSize)
            Text(name)
                .font(.cinzel(8))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(.gold)
            Text(desc)
                .font(.cormorant(11, italic: true))
                .foregroundColor(.ivoryDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }
}
