import Foundation
import Observation

@MainActor @Observable
final class SettingsViewModel {
    var rollSpeedMultiplier: Double {
        didSet {
            guard oldValue != rollSpeedMultiplier, !isApplyingRemoteUpdate else { return }
            persist()
        }
    }

    private(set) var isReady: Bool = false

    var speedDescription: String {
        Settings(rollSpeedMultiplier: rollSpeedMultiplier).speedDescription
    }

    static let minSpeedMultiplier = Settings.minSpeedMultiplier
    static let maxSpeedMultiplier = Settings.maxSpeedMultiplier

    private let repository: SettingsRepositoryProtocol
    private var watcherTask: Task<Void, Never>?
    private var isApplyingRemoteUpdate = false

    init(repository: SettingsRepositoryProtocol = SettingsRepository()) {
        self.repository = repository
        _rollSpeedMultiplier = Settings.default.rollSpeedMultiplier
    }

    func setup() async {
        let settings = await repository.get()
        isApplyingRemoteUpdate = true
        rollSpeedMultiplier = settings.rollSpeedMultiplier
        isApplyingRemoteUpdate = false
        isReady = true
        startWatching()
    }

    func resetToDefaults() {
        rollSpeedMultiplier = Settings.default.rollSpeedMultiplier
    }

    private func persist() {
        let value = rollSpeedMultiplier
        Task { [repository] in
            try? await repository.update(Settings(rollSpeedMultiplier: value))
        }
    }

    private func startWatching() {
        watcherTask?.cancel()
        watcherTask = Task { [weak self, repository] in
            let stream = await repository.settingsStream()
            for await settings in stream {
                await MainActor.run {
                    guard let self else { return }
                    guard self.rollSpeedMultiplier != settings.rollSpeedMultiplier else { return }
                    self.isApplyingRemoteUpdate = true
                    self.rollSpeedMultiplier = settings.rollSpeedMultiplier
                    self.isApplyingRemoteUpdate = false
                }
            }
        }
    }

    isolated deinit {
        watcherTask?.cancel()
    }
}
