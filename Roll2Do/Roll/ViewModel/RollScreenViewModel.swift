import Foundation
import Observation

@MainActor @Observable
final class RollScreenViewModel {
    enum ViewState {
        case idle
        case loading
        case loaded(RollScreenData)
        case error(String)
    }

    private(set) var viewState: ViewState = .idle

    private let historyRepository: HistoryRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol
    private var settingsWatcher: Task<Void, Never>?

    init(
        historyRepository: HistoryRepositoryProtocol = HistoryRepository(),
        settingsRepository: SettingsRepositoryProtocol = SettingsRepository()
    ) {
        self.historyRepository = historyRepository
        self.settingsRepository = settingsRepository
    }

    func setup() async {
        guard case .idle = viewState else { return }
        viewState = .loading

        let settings = await settingsRepository.get()
        let diceVM = DiceViewModel(initialSpeed: settings.rollSpeedMultiplier)
        viewState = .loaded(RollScreenData(diceVM: diceVM))
        startWatchingSettings(diceVM: diceVM)
    }

    func onRollComplete(_ value: Int) {
        Task { [historyRepository] in
            let entry = RollHistoryEntry(rollValue: value)
            try? await historyRepository.append(entry)
        }
    }

    private func startWatchingSettings(diceVM: DiceViewModel) {
        settingsWatcher?.cancel()
        settingsWatcher = Task { [weak diceVM, settingsRepository] in
            let stream = await settingsRepository.settingsStream()
            for await settings in stream {
                diceVM?.setSpeedMultiplier(settings.rollSpeedMultiplier)
            }
        }
    }

    isolated deinit {
        settingsWatcher?.cancel()
    }
}

struct RollScreenData {
    let diceVM: DiceViewModel
}
