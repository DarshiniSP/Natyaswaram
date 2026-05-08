import SwiftUI

private let minuteOptions = Array(stride(from: 0, through: 55, by: 5))

// Items listed here will appear in the "What I worked on" dropdown.
// Add or remove entries as your repertoire grows.
private let practiceItems: [String] = [
    "Alarippu",
    "Jathiswaram",
    "Shabdam",
    "Varnam",
    "Adavu Basics",
    "Asamyutha Hastas",
    "Samyutha Hastas",
    "Others",
]

struct ProgressTrackerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = ProgressStore.shared

    @State private var selectedDate:    Date
    @State private var workTitle:       String = ""
    @State private var isOthers:        Bool   = false  // true when "Others" is selected
    @State private var practiceHours:   Int    = 0
    @State private var practiceMinutes: Int    = 0
    @State private var remarkText:      String = ""
    @State private var sessionQuality:  Int    = 0   // 0 = unrated, 1–5
    @State private var showSaved:       Bool   = false

    // Display label for the dropdown button
    private var dropdownLabel: String {
        if isOthers { return "Others" }
        return workTitle.isEmpty ? "Select item…" : workTitle
    }

    init(initialDate: Date = Date()) {
        _selectedDate = State(initialValue: initialDate)
    }

    var body: some View {
        ZStack {
            Color(red: 16/255, green: 2/255, blue: 0/255).ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Nav bar ───────────────────────────────────────────────
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .light))
                            Text("Back")
                                .font(.cormorant(16, italic: true))
                        }
                        .foregroundColor(.gold)
                    }
                    Spacer()
                    Button { saveEntry() } label: {
                        Text(showSaved ? "Saved ✓" : "Save")
                            .font(.cinzel(10)).tracking(2).textCase(.uppercase)
                            .foregroundColor(showSaved ? Color(red: 0.4, green: 0.8, blue: 0.5) : .gold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Title ─────────────────────────────────────────
                        Text("Progress Tracker")
                            .font(.cinzel(13)).tracking(5).textCase(.uppercase)
                            .foregroundColor(.gold)
                            .padding(.bottom, 4)
                        Text("Select a date · log your practice")
                            .font(.cormorant(13, italic: true))
                            .foregroundColor(.ivoryDim)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 14)

                        // ── Date picker ───────────────────────────────────
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(.gold)
                            .colorScheme(.dark)
                            .padding(.horizontal, 28)
                            .onChange(of: selectedDate) { _, newDate in
                                loadEntry(for: newDate)
                            }

                        // ── Work title + Practice time row ────────────────
                        HStack(alignment: .center, spacing: 0) {

                            // LEFT: what they worked on
                            VStack(alignment: .leading, spacing: 6) {
                                Text("What I worked on")
                                    .font(.cinzel(13)).tracking(2).textCase(.uppercase)
                                    .foregroundColor(.gold)

                                VStack(spacing: 8) {
                                    Menu {
                                        ForEach(practiceItems, id: \.self) { item in
                                            Button(item) {
                                                if item == "Others" {
                                                    isOthers  = true
                                                    workTitle = ""
                                                } else {
                                                    isOthers  = false
                                                    workTitle = item
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(dropdownLabel)
                                                .font(.cormorant(14))
                                                .foregroundColor(workTitle.isEmpty && !isOthers
                                                                 ? .ivoryDim.opacity(0.45) : .ivory)
                                            Spacer()
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 9, weight: .light))
                                                .foregroundColor(.gold.opacity(0.6))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 9)
                                        .background(Color(hex: "140200").cornerRadius(4))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.gold.opacity(0.18), lineWidth: 1)
                                        )
                                    }

                                    // Custom name field shown only when "Others" is picked
                                    if isOthers {
                                        TextField("", text: $workTitle,
                                                  prompt: Text("Enter composition name…")
                                                      .foregroundColor(Color.ivoryDim.opacity(0.38))
                                                      .italic())
                                            .font(.cormorant(14))
                                            .foregroundColor(.ivory)
                                            .autocorrectionDisabled()
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 9)
                                            .background(Color(hex: "140200").cornerRadius(4))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(Color.gold.opacity(0.18), lineWidth: 1)
                                            )
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                                .animation(.easeInOut(duration: 0.18), value: isOthers)
                            }
                            .padding(.leading, 16)
                            .padding(.trailing, 10)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)

                            // Vertical divider
                            Color.gold.opacity(0.22)
                                .frame(width: 1, height: 90)

                            // RIGHT: practice time wheel pickers
                            VStack(alignment: .center, spacing: 4) {
                                Text("Practice Time")
                                    .font(.cinzel(13)).tracking(1).textCase(.uppercase)
                                    .foregroundColor(.gold)

                                HStack(spacing: 0) {
                                    VStack(spacing: 2) {
                                        Text("h")
                                            .font(.cinzel(13)).tracking(1).textCase(.uppercase)
                                            .foregroundColor(.gold.opacity(0.7))
                                        Picker("", selection: $practiceHours) {
                                            ForEach(0..<9) { h in Text("\(h)").tag(h) }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 52, height: 88)
                                        .clipped()
                                    }
                                    VStack(spacing: 2) {
                                        Text("min")
                                            .font(.cinzel(13)).tracking(1).textCase(.uppercase)
                                            .foregroundColor(.gold.opacity(0.7))
                                        Picker("", selection: $practiceMinutes) {
                                            ForEach(minuteOptions, id: \.self) { m in
                                                Text(String(format: "%02d", m)).tag(m)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 60, height: 88)
                                        .clipped()
                                    }
                                }
                                .colorScheme(.dark)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 10)
                            .frame(width: 132)
                        }
                        .background(Color(hex: "1c0400"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gold.opacity(0.22), lineWidth: 1)
                        )
                        .cornerRadius(5)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                        // ── Date label divider ────────────────────────────
                        HStack(spacing: 12) {
                            Color.gold.opacity(0.22).frame(height: 1)
                            Text(formattedDate(selectedDate))
                                .font(.cinzel(13)).tracking(3).textCase(.uppercase)
                                .foregroundColor(.gold)
                                .fixedSize()
                            Color.gold.opacity(0.22).frame(height: 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)

                        // ── Session quality rating ────────────────────────
                        VStack(spacing: 10) {
                            HStack {
                                Text("Session Quality")
                                    .font(.cinzel(11)).tracking(2).textCase(.uppercase)
                                    .foregroundColor(.gold)
                                Spacer()
                                if sessionQuality > 0 {
                                    Text(qualityLabel(sessionQuality))
                                        .font(.cormorant(13, italic: true))
                                        .foregroundColor(.ivoryDim)
                                        .transition(.opacity)
                                }
                            }
                            .padding(.horizontal, 20)

                            HStack(spacing: 18) {
                                ForEach(1...5, id: \.self) { star in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            sessionQuality = (sessionQuality == star) ? 0 : star
                                        }
                                    } label: {
                                        Image(systemName: star <= sessionQuality ? "star.fill" : "star")
                                            .font(.system(size: 26))
                                            .foregroundColor(
                                                star <= sessionQuality
                                                ? .gold
                                                : Color.ivoryDim.opacity(0.25)
                                            )
                                            .scaleEffect(star <= sessionQuality ? 1.08 : 1.0)
                                            .animation(.spring(response: 0.2), value: sessionQuality)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.bottom, 18)

                        // ── Remarks text box ──────────────────────────────
                        ZStack(alignment: .topLeading) {
                            if remarkText.isEmpty {
                                Text("Describe your practice for this day…")
                                    .font(.cormorant(14, italic: true))
                                    .foregroundColor(.ivoryDim.opacity(0.45))
                                    .padding(.horizontal, 14)
                                    .padding(.top, 14)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $remarkText)
                                .font(.cormorant(15))
                                .foregroundColor(.ivory)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .frame(minHeight: 180)
                        }
                        .background(Color(hex: "1c0400").cornerRadius(5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gold.opacity(0.22), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 48)
                    }
                }
            }
        }
        .onAppear { loadEntry(for: selectedDate) }
    }

    // MARK: - Helpers

    private func saveEntry() {
        store.save(date: selectedDate, entry: PracticeEntry(
            workTitle: workTitle,
            hours:     practiceHours,
            minutes:   practiceMinutes,
            remark:    remarkText,
            quality:   sessionQuality
        ))
        withAnimation(.easeInOut(duration: 0.25)) { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { showSaved = false }
        }
    }

    private func loadEntry(for date: Date) {
        let e           = store.entry(for: date)
        practiceHours   = e.hours
        practiceMinutes = e.minutes
        remarkText      = e.remark
        sessionQuality  = e.quality
        // If the saved workTitle isn't in the known list it was a custom "Others" entry
        let knownItems  = practiceItems.filter { $0 != "Others" }
        if e.workTitle.isEmpty || knownItems.contains(e.workTitle) {
            isOthers  = false
            workTitle = e.workTitle
        } else {
            isOthers  = true
            workTitle = e.workTitle   // populate the custom text field with the saved name
        }
    }

    private func qualityLabel(_ q: Int) -> String {
        switch q {
        case 1: return "Difficult"
        case 2: return "Challenging"
        case 3: return "Steady"
        case 4: return "Strong"
        case 5: return "Excellent"
        default: return ""
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d MMMM yyyy"
        return f.string(from: date)
    }
}
