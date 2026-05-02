import Foundation
import Observation

@MainActor @Observable
final class SignInViewModel {
    enum Mode {
        case signIn
        case signUp
    }

    var emailInput: String = ""
    var passwordInput: String = ""
    private(set) var mode: Mode = .signIn
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    private let auth = DependencyContainer.shared.auth

    var canSubmit: Bool {
        !isSubmitting && isValidEmail(trimmedEmail) && passwordInput.count >= 6
    }

    var primaryButtonTitle: String {
        mode == .signIn ? "Sign In" : "Sign Up"
    }

    var toggleButtonTitle: String {
        mode == .signIn
            ? "Don't have an account? Sign Up"
            : "Already have an account? Sign In"
    }

    func toggleMode() {
        mode = mode == .signIn ? .signUp : .signIn
        errorMessage = nil
    }

    func observeAuth() async {
        for await event in await auth.subscribe() {
            isSubmitting = event.isLoggingIn
        }
    }

    func submit() async {
        let email = trimmedEmail

        guard isValidEmail(email) else {
            errorMessage = "Enter a valid email"
            return
        }

        guard passwordInput.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }

        errorMessage = nil

        do {
            switch mode {
            case .signIn:
                try await auth.signIn(email: email, password: passwordInput)
            case .signUp:
                try await auth.signUp(email: email, password: passwordInput)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var trimmedEmail: String {
        emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isValidEmail(_ s: String) -> Bool {
        guard let at = s.firstIndex(of: "@"), at != s.startIndex else { return false }
        let domain = s[s.index(after: at)...]
        return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
    }
}
