import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var signedInEmail: String?

    var body: some View {
        Form {
            if let email = signedInEmail {
                Section {
                    HStack {
                        Text("Signed in as")
                        Spacer()
                        Text(email)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Account")
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Roll Speed")
                        Spacer()
                        Text(viewModel.speedDescription)
                            .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { viewModel.rollSpeedMultiplier },
                            set: { viewModel.rollSpeedMultiplier = $0 }
                        ),
                        in: SettingsViewModel.minSpeedMultiplier ... SettingsViewModel.maxSpeedMultiplier,
                        step: 0.1
                    )
                    .disabled(!viewModel.isReady)

                    HStack {
                        Text("Instant")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Very Slow")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Animation")
            } footer: {
                Text(
                    "Adjust how fast the dice animation plays. \"Instant\" shows the result immediately, while \"Very Slow\" takes about 2x longer than normal."
                )
            }

            Section {
                Button {
                    viewModel.resetToDefaults()
                } label: {
                    HStack {
                        Spacer()
                        Text("Reset to Defaults")
                        Spacer()
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    Task { await DependencyContainer.shared.auth.signOut() }
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.setup()
            signedInEmail = await DependencyContainer.shared.auth.currentUser()?.email
        }
    }
}
