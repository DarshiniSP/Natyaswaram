import SwiftUI

struct EntryView: View {
    @EnvironmentObject var appState: AppState
    @State private var name: String = ""
    @State private var appeared = false
    @FocusState private var focused: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            VStack(spacing: 0) {

                // ── Top half: identity + tagline ──────────────────────────
                ZStack {
                    VStack(spacing: h * 0.021) {
                        // App name
                        VStack(spacing: h * 0.009) {
                            Text("An Offering of Art & Rhythm")
                                .font(.cormorant(12, italic: true))
                                .tracking(4)
                                .textCase(.uppercase)
                                .foregroundColor(.saffron)
                                .animateIn(appeared, delay: 0.20)

                            Text("Sanchana")
                                .font(.cinzel(38, weight: .black))
                                .foregroundStyle(LinearGradient.goldGradient)
                                .minimumScaleFactor(0.65)
                                .lineLimit(1)
                                .animateIn(appeared, delay: 0.40)
                        }
                        .multilineTextAlignment(.center)

                        // Tagline sits directly below title
                        HStack(spacing: w * 0.025) {
                            OmSymbol(size: 16)
                            Text("Where every gesture speaks a thousand words")
                                .font(.cormorant(14, italic: true))
                                .foregroundColor(.ivoryDim)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, w * 0.082)
                        .animateIn(appeared, delay: 0.60)
                    }
                }
                .frame(width: w, height: h * 0.48)

                // ── Bottom half: entry (no box, just below centre) ────────
                VStack(spacing: 0) {
                    // Small gap from the midpoint
                    Spacer().frame(height: h * 0.04)

                    // Entry content — no card background or border
                    VStack(spacing: 0) {
                        Text("Enter your name to begin")
                            .font(.cinzel(10))
                            .tracking(4)
                            .textCase(.uppercase)
                            .foregroundColor(.gold)
                            .padding(.bottom, h * 0.019)

                        TextField("", text: $name,
                                  prompt: Text("Your name…")
                                      .foregroundColor(Color.ivoryDim.opacity(0.33))
                                      .italic())
                            .font(.cormorant(24))
                            .foregroundColor(.silk)
                            .multilineTextAlignment(.center)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .focused($focused)
                            .onSubmit { submit() }
                            .frame(width: w * 0.75)

                        Rectangle()
                            .fill(focused ? Color.saffron : Color.gold)
                            .frame(width: w * 0.75, height: 1)
                            .padding(.top, 4)
                            .animation(.easeInOut(duration: 0.3), value: focused)

                        GoldRule().padding(.vertical, h * 0.023)

                        Button(action: submit) {
                            HStack(spacing: w * 0.025) {
                                Text("Enter the Sanctum")
                                    .font(.cinzel(10))
                                    .tracking(3)
                                    .textCase(.uppercase)
                                Text("›").font(.system(size: 16))
                            }
                            .foregroundColor(.goldLight)
                            .padding(.horizontal, w * 0.055)
                            .padding(.vertical, h * 0.014)
                            .background(
                                LinearGradient(colors: [.maroon, Color(hex: "4a0e0e")],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .overlay(Rectangle().stroke(Color.gold, lineWidth: 1))
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1.0)
                        .animation(.easeInOut(duration: 0.25), value: name.isEmpty)
                    }
                    .padding(.horizontal, w * 0.082)
                    .animateIn(appeared, delay: 0.80)

                    Spacer()
                }
                .frame(width: w, height: h * 0.52)
            }
            .frame(width: w, height: h)
        }
        .onAppear {
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { focused = true }
        }
    }

    private func submit() {
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        appState.userName = t
        appState.screen   = .welcome
    }
}

// MARK: - Fade-up animation helper
private extension View {
    func animateIn(_ appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(.easeOut(duration: 0.85).delay(delay), value: appeared)
    }
}
