import FirebaseAuth
import Foundation

protocol AuthRepositoryProtocol: Sendable {
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String) async throws -> User
    func restoreSession() async throws -> User
    func signOut() async throws
}

struct AuthRepository: AuthRepositoryProtocol {
    func signIn(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return User(from: result.user)
    }

    func signUp(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return User(from: result.user)
    }

    func restoreSession() async throws -> User {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw AuthError.noSession
        }
        return User(from: firebaseUser)
    }

    func signOut() async throws {
        try Auth.auth().signOut()
    }
}

enum AuthError: Error {
    case noSession
}

private extension User {
    init(from firebaseUser: FirebaseAuth.User) {
        self.init(id: firebaseUser.uid, email: firebaseUser.email ?? "")
    }
}
