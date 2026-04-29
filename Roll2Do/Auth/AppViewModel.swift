import Foundation
import Observation

@MainActor @Observable
final class AppViewModel {
    enum ViewState {
        case loading
        case signedOut
        case signedIn
    }

    private(set) var viewState: ViewState = .loading

    private let auth = DependencyContainer.shared.auth

    func start() async {
        Task { await auth.restoreSession() }
        for await event in await auth.subscribe() {
            viewState = event.user != nil ? .signedIn : .signedOut
        }
    }
}
