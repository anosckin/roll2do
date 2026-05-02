import SwiftUI

struct SignInView: View {
    @State private var viewModel = SignInViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $viewModel.emailInput)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $viewModel.passwordInput)
                        .textContentType(viewModel.mode == .signIn ? .password : .newPassword)
                } footer: {
                    if let message = viewModel.errorMessage {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await viewModel.submit() }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isSubmitting {
                                ProgressView()
                            } else {
                                Text(viewModel.primaryButtonTitle)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .foregroundStyle(.primary)
                    }
                    .disabled(!viewModel.canSubmit)
                }

                Section {
                    Button(viewModel.toggleButtonTitle) {
                        viewModel.toggleMode()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle(viewModel.mode == .signIn ? "Welcome" : "Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.observeAuth() }
        }
    }
}
