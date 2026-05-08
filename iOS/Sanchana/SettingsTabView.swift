import SwiftUI
import UserNotifications

struct SettingsTabView: View {
    @EnvironmentObject var appState: AppState

    @State private var editingName        = false
    @State private var draftName          = ""
    @FocusState private var nameFocused:  Bool
    @AppStorage("notifications_enabled")  private var notificationsEnabled = false
    @AppStorage("reminder_time_seconds")  private var reminderTimeSeconds: Double = 9 * 3600  // 9:00 AM default
    @AppStorage("week_starts_monday")     private var weekStartsMonday = false
    @AppStorage("font_size_preset")       private var fontSizePreset: Int = 0

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                let midnight = Calendar.current.startOfDay(for: Date())
                return midnight.addingTimeInterval(reminderTimeSeconds)
            },
            set: { newDate in
                let midnight = Calendar.current.startOfDay(for: newDate)
                reminderTimeSeconds = newDate.timeIntervalSince(midnight)
                if notificationsEnabled { scheduleReminder() }
            }
        )
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: geo.size.height * 0.06)

                    OmSymbol(size: 28)
                        .padding(.bottom, 10)

                    Text("Settings")
                        .font(.cinzel(20, weight: .bold))
                        .foregroundStyle(LinearGradient.goldGradient)

                    GoldRule()
                        .padding(.horizontal, 60)
                        .padding(.vertical, 18)

                    // ── Dancer Name row ───────────────────────────────────
                    if editingName {
                        nameEditRow(geo: geo)
                    } else {
                        nameDisplayRow
                    }

                    divider()

                    // ── Notifications section header ───────────────────────
                    sectionLabel(icon: "bell", title: "Notifications")

                    // Enable toggle
                    HStack {
                        Text("Enable Reminders to Practise")
                            .font(.cormorant(16, italic: true))
                            .foregroundColor(.ivory)
                        Spacer()
                        Toggle("", isOn: $notificationsEnabled)
                            .labelsHidden()
                            .tint(.gold)
                            .onChange(of: notificationsEnabled) { enabled in
                                if enabled {
                                    UNUserNotificationCenter.current()
                                        .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                                            DispatchQueue.main.async {
                                                notificationsEnabled = granted
                                                if granted { scheduleReminder() }
                                            }
                                        }
                                } else {
                                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_practice_reminder"])
                                }
                            }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)

                    // Time picker — only shown when notifications are on
                    if notificationsEnabled {
                        HStack {
                            Text("Reminder Time")
                                .font(.cormorant(16, italic: true))
                                .foregroundColor(.ivory)
                            Spacer()
                            DatePicker("", selection: reminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(.gold)
                                .colorScheme(.dark)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .animation(.easeInOut(duration: 0.2), value: notificationsEnabled)
                    }

                    divider()

                    // ── Calendar section ───────────────────────────────────
                    sectionLabel(icon: "calendar", title: "Calendar")

                    HStack {
                        Text("Week Starts On")
                            .font(.cormorant(16, italic: true))
                            .foregroundColor(.ivory)
                        Spacer()
                        Picker("", selection: $weekStartsMonday) {
                            Text("Sunday").tag(false)
                            Text("Monday").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                        .colorScheme(.dark)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)

                    divider()

                    // ── Appearance section ─────────────────────────────────
                    sectionLabel(icon: "textformat.size", title: "Appearance")

                    HStack {
                        Text("Font Size")
                            .font(.cormorant(16, italic: true))
                            .foregroundColor(.ivory)
                        Spacer()
                        Menu {
                            ForEach(FontSizePreset.allCases, id: \.rawValue) { preset in
                                Button {
                                    fontSizePreset = preset.rawValue
                                } label: {
                                    HStack {
                                        Text(preset.label)
                                        if fontSizePreset == preset.rawValue {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(FontSizePreset(rawValue: fontSizePreset)?.label ?? "Standard")
                                    .font(.cormorant(15))
                                    .foregroundColor(.ivory)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 9, weight: .light))
                                    .foregroundColor(.gold.opacity(0.6))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color(hex: "1c0400").cornerRadius(4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gold.opacity(0.22), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)

                    divider()

                    // App info
                    VStack(spacing: 6) {
                        Text("Sanchana")
                            .font(.cinzel(11))
                            .tracking(3)
                            .foregroundColor(.gold)
                        Text("An Offering of Art & Rhythm")
                            .font(.cormorant(13, italic: true))
                            .foregroundColor(.ivoryDim.opacity(0.5))
                    }
                    .padding(.top, 36)
                    .padding(.bottom, geo.size.height * 0.06)
                }
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Name display (tap to edit)

    private var nameDisplayRow: some View {
        Button {
            draftName   = appState.userName
            editingName = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { nameFocused = true }
        } label: {
            HStack {
                Image(systemName: "person.circle")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.gold)
                    .frame(width: 28)
                Text("Dancer Name")
                    .font(.cinzel(10))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(.ivoryDim)
                Spacer()
                Text(appState.userName)
                    .font(.cormorant(16, italic: true))
                    .foregroundColor(.ivory)
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.gold.opacity(0.5))
                    .padding(.leading, 6)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Name edit field

    private func nameEditRow(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "person.circle")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.gold)
                    .frame(width: 28)
                Text("Dancer Name")
                    .font(.cinzel(10))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(.ivoryDim)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)

            TextField("", text: $draftName,
                      prompt: Text("Your name…")
                          .foregroundColor(Color.ivoryDim.opacity(0.33))
                          .italic())
                .font(.cormorant(20))
                .foregroundColor(.silk)
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .focused($nameFocused)
                .onSubmit { commitName() }
                .frame(width: geo.size.width * 0.65)
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(nameFocused ? Color.saffron : Color.gold)
                .frame(width: geo.size.width * 0.65, height: 1)
                .padding(.top, 4)
                .animation(.easeInOut(duration: 0.25), value: nameFocused)

            HStack(spacing: 0) {
                Button {
                    editingName = false
                    nameFocused = false
                } label: {
                    Text("Cancel")
                        .font(.cinzel(9)).tracking(2).textCase(.uppercase)
                        .foregroundColor(.ivoryDim.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                Color.gold.opacity(0.2).frame(width: 1, height: 38)
                Button { commitName() } label: {
                    Text("Save")
                        .font(.cinzel(9)).tracking(2).textCase(.uppercase)
                        .foregroundColor(.gold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .disabled(draftName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(draftName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
            }
            .padding(.top, 12)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Helpers

    private func commitName() {
        let t = draftName.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        appState.userName = t      // didSet in AppState persists to UserDefaults
        editingName       = false
        nameFocused       = false
    }

    private func divider() -> some View {
        Color.gold.opacity(0.15).frame(height: 1)
            .padding(.horizontal, 24)
    }

    private func sectionLabel(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.gold)
                .frame(width: 28)
            Text(title)
                .font(.cinzel(10))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(.ivoryDim)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }

    private func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily_practice_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Sanchana"
        content.body  = "Time to practise. Your art grows one session at a time."
        content.sound = .default

        let midnight = Calendar.current.startOfDay(for: Date())
        let fireDate = midnight.addingTimeInterval(reminderTimeSeconds)
        let comps    = Calendar.current.dateComponents([.hour, .minute], from: fireDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_practice_reminder",
                                            content: content, trigger: trigger)
        center.add(request)
    }
}
