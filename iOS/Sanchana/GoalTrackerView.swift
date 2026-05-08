import SwiftUI

struct GoalTrackerView: View {

    @Environment(\.dismiss)    private var dismiss
    @ObservedObject private var store = GoalStore.shared

    @State private var selectedDate: Date
    @State private var goalText:     String = ""
    @State private var showSaved:    Bool   = false

    init(initialDate: Date = Date()) {
        _selectedDate = State(initialValue: initialDate)
    }

    // ── Formatting ────────────────────────────────────────────────────────────
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d MMMM yyyy"
        return f.string(from: date)
    }

    // ── Persistence ───────────────────────────────────────────────────────────
    private func loadGoal(for date: Date) {
        let e = store.goal(for: date)
        goalText = e.goalText
    }

    private func saveGoal() {
        store.save(date: selectedDate, entry: GoalEntry(goalText: goalText))
        showSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { showSaved = false }
    }

    // ── Body ──────────────────────────────────────────────────────────────────
    var body: some View {
        ZStack {
            Color(hex: "0d0200").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Nav bar ───────────────────────────────────────────
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
                        Button {
                            saveGoal()
                        } label: {
                            Text(showSaved ? "Saved ✓" : "Save")
                                .font(.cinzel(10)).tracking(2).textCase(.uppercase)
                                .foregroundColor(showSaved ? Color.green.opacity(0.8) : .gold)
                        }
                        .animation(.easeInOut(duration: 0.3), value: showSaved)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 6)

                    // ── Title ─────────────────────────────────────────────
                    Text("Goals")
                        .font(.cinzel(22)).tracking(6).textCase(.uppercase)
                        .foregroundColor(.gold)
                        .padding(.top, 4)

                    Text("Set a goal · choose your deadline")
                        .font(.cormorant(14, italic: true))
                        .foregroundColor(.ivoryDim.opacity(0.6))
                        .padding(.top, 4)
                        .padding(.bottom, 10)

                    // ── Calendar (deadline picker) ────────────────────────
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(.gold)
                        .colorScheme(.dark)
                        .padding(.horizontal, 28)
                        .onChange(of: selectedDate) { _, newDate in
                            loadGoal(for: newDate)
                        }
                        .onAppear { loadGoal(for: selectedDate) }

                    // ── Goal input card ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {

                        Text("My Goal")
                            .font(.cinzel(13)).tracking(2).textCase(.uppercase)
                            .foregroundColor(.gold)

                        ZStack(alignment: .topLeading) {
                            if goalText.isEmpty {
                                Text("What do you want to achieve?")
                                    .font(.cormorant(15, italic: true))
                                    .foregroundColor(.ivoryDim.opacity(0.4))
                                    .padding(.top, 10)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $goalText)
                                .font(.cormorant(16))
                                .foregroundColor(.ivory)
                                .tint(.gold)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .frame(minHeight: 120)
                        }
                        .padding(12)
                        .background(Color(hex: "140200"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gold.opacity(0.22), lineWidth: 1)
                        )
                        .cornerRadius(6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    // ── Date label divider ────────────────────────────────
                    HStack(spacing: 12) {
                        Color.gold.opacity(0.22).frame(height: 1)
                        Text("Deadline: \(formattedDate(selectedDate))")
                            .font(.cinzel(11)).tracking(2).textCase(.uppercase)
                            .foregroundColor(.gold)
                            .fixedSize()
                        Color.gold.opacity(0.22).frame(height: 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    Spacer(minLength: 40)
                }
            }
        }
    }
}
