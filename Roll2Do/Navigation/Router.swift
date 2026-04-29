import Foundation
import Observation

@MainActor @Observable
final class Router {
    var path: [Destination] = []

    enum Destination: Hashable {
        case taskDetail(taskId: UUID)
    }

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func navigateToRoot() {
        path.removeAll()
    }
}
