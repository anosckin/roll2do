import SwiftUI

struct NavigationDestinationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationDestination(for: Router.Destination.self) { destination in
            switch destination {
            case let .taskDetail(taskId):
                TaskDetailView(taskId: taskId)
            }
        }
    }
}

extension View {
    func registerNavigationDestinations() -> some View {
        modifier(NavigationDestinationModifier())
    }
}
