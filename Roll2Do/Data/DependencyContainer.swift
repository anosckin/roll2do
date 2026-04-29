import Foundation

/// Holds services — components that manage shared state across screens.
/// Services exist when logic belongs to the app rather than to a single screen:
/// cross-screen state (auth), business logic not tied to UI (payments),
/// long-running operations that outlive screens (uploads), or coordination
/// between multiple repositories (checkout).
final class DependencyContainer: Sendable {
    static let shared = DependencyContainer()

    let auth: AuthManagerProtocol

    init(auth: AuthManagerProtocol = AuthManager()) {
        self.auth = auth
    }
}
