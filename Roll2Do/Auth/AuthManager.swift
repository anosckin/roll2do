import Foundation

/// AsyncStream is used over Combine to keep a single concurrency paradigm
/// (async/await + actors) throughout the codebase, with no framework dependency.
struct AuthEvent: Sendable {
    let user: User?
    let isLoggingIn: Bool
}

protocol AuthManagerProtocol: Actor {
    func subscribe() -> AsyncStream<AuthEvent>
    func currentUser() async -> User?
    func restoreSession() async
    func signIn(email: String) async
    func signOut() async
}

/// Actor (not @MainActor) so work runs off the main thread. ViewModels are
/// @MainActor because they drive UI; services are not, because they may do
/// heavier work (validation, network, encryption) that shouldn't block the
/// UI. State flows back to VMs via AsyncStream.
actor AuthManager: AuthManagerProtocol {
    private let repository: AuthRepositoryProtocol
    private var continuations: [UUID: AsyncStream<AuthEvent>.Continuation] = [:]
    private var user: User?

    init(repository: AuthRepositoryProtocol = AuthRepository()) {
        self.repository = repository
    }

    func subscribe() -> AsyncStream<AuthEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            self.continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id: id) }
            }
        }
    }

    func currentUser() async -> User? {
        user
    }

    func restoreSession() async {
        let restored = try? await repository.restoreSession()
        user = restored
        broadcast(AuthEvent(user: restored, isLoggingIn: false))
    }

    func signIn(email: String) async {
        broadcast(AuthEvent(user: user, isLoggingIn: true))
        let signedIn = try? await repository.signIn(email: email)
        user = signedIn
        broadcast(AuthEvent(user: signedIn, isLoggingIn: false))
    }

    func signOut() async {
        await repository.signOut()
        user = nil
        broadcast(AuthEvent(user: nil, isLoggingIn: false))
    }

    private func broadcast(_ event: AuthEvent) {
        for continuation in continuations.values {
            continuation.yield(event)
        }
    }

    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }
}
