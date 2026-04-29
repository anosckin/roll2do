import Foundation

protocol AuthRepositoryProtocol {
    func signIn(email: String) async throws -> User
    func restoreSession() async throws -> User
    func signOut() async
}

struct AuthRepository: AuthRepositoryProtocol {
    private let local: LocalDataSourceProtocol

    init() {
        local = DataSourceContainer.shared.local
    }

    func signIn(email: String) async throws -> User {
        // TODO: hit backend auth endpoint here once it exists. For now the
        // local store is the source of truth — we just persist a User row
        // so kill/relaunch can restore the session.
        let user = User(id: UUID(), email: email)
        try await local.upsert(user)
        return user
    }

    func restoreSession() async throws -> User {
        guard let user = await local.fetchFirst(User.self) else {
            throw AuthError.noSession
        }
        return user
    }

    func signOut() async {
        // TODO: once a backend exists, also wipe Tasks/History/Settings on
        // sign-out so a new account doesn't see the previous user's local
        // data — for now the local store is the only source of truth, so
        // we keep it and only clear the User row.
        try? await local.deleteAll(User.self)
    }
}

enum AuthError: Error {
    case noSession
}
