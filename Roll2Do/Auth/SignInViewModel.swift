import Foundation
import Observation

@MainActor @Observable
final class SignInViewModel {
    var emailInput: String = ""
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    private let auth = DependencyContainer.shared.auth

    var canSubmit: Bool {
        !isSubmitting && isValidEmail(trimmedEmail)
    }

    func observeAuth() async {
        for await event in await auth.subscribe() {
            isSubmitting = event.isLoggingIn
        }
    }

    func signIn() async {
        let email = trimmedEmail
        guard isValidEmail(email) else {
            errorMessage = "Enter a valid email"
            return
        }
        errorMessage = nil
        await auth.signIn(email: email)
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
