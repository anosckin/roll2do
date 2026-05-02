import SwiftUI

@main
struct Roll2DoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @State private var viewModel = AppViewModel()

    var body: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                ProgressView()
            case .signedOut:
                SignInView()
            case .signedIn:
                MainTabView()
            }
        }
        .task { await viewModel.start() }
    }
}

struct MainTabView: View {
    @State private var tasksRouter = Router()

    var body: some View {
        TabView {
            NavigationStack {
                D20RollerView()
            }
            .tabItem { Label("Roll", systemImage: "dice.fill") }

            NavigationStack(path: $tasksRouter.path) {
                TaskListView()
                    .registerNavigationDestinations()
            }
            .environment(tasksRouter)
            .tabItem { Label("Tasks", systemImage: "list.bullet") }

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
