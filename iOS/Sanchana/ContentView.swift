import SwiftUI
import Combine

enum AppScreen { case entry, welcome, dashboard }

final class AppState: ObservableObject {
    @Published var screen:   AppScreen
    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "sanchana_user_name") }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "sanchana_user_name") ?? ""
        let trimmed = saved.trimmingCharacters(in: .whitespaces)
        self.userName = trimmed
        self.screen   = trimmed.isEmpty ? .entry : .welcome
    }
}

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            switch appState.screen {
            case .entry:
                EntryView()
                    .environmentObject(appState)
                    .transition(.opacity)
            case .welcome:
                WelcomeView()
                    .environmentObject(appState)
                    .transition(.opacity)
            case .dashboard:
                DashboardView()
                    .environmentObject(appState)
                    .transition(.opacity)
            }
        }
        // Fix: constrain ZStack to screen size so BackgroundView's 700×700 MandalaShape
        // doesn't inflate geo.size.width reported to child GeometryReaders.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.45), value: appState.screen)
    }
}
