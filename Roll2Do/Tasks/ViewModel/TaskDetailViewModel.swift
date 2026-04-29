import Foundation
import Observation

enum RollResult: Sendable, Equatable {
    case none
    case success
    case failure
}

@MainActor @Observable
final class TaskDetailViewModel {
    enum ViewState {
        case idle
        case loading
        case loaded(TaskDetailData)
        case error(String)
        case notFound
    }

    private(set) var viewState: ViewState = .idle

    private let taskId: UUID
    private let taskRepository: TaskRepositoryProtocol
    private let historyRepository: HistoryRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol

    private var taskWatcher: Task<Void, Never>?
    private var settingsWatcher: Task<Void, Never>?

    init(
        taskId: UUID,
        taskRepository: TaskRepositoryProtocol = TaskRepository(),
        historyRepository: HistoryRepositoryProtocol = HistoryRepository(),
        settingsRepository: SettingsRepositoryProtocol = SettingsRepository()
    ) {
        self.taskId = taskId
        self.taskRepository = taskRepository
        self.historyRepository = historyRepository
        self.settingsRepository = settingsRepository
    }

    func setup() async {
        guard case .idle = viewState else { return }
        viewState = .loading

        guard let task = await taskRepository.fetch(id: taskId) else {
            viewState = .notFound
            return
        }
        let settings = await settingsRepository.get()
        let diceVM = DiceViewModel(initialSpeed: settings.rollSpeedMultiplier)

        let data = TaskDetailData(diceVM: diceVM, task: task)
        viewState = .loaded(data)
        startWatchingTask()
        startWatchingSettings(diceVM: diceVM)
    }

    func handleRollStart() {
        guard case var .loaded(data) = viewState else { return }
        data.lastResult = .none
        data.dcAtRoll = data.task.currentDC
        viewState = .loaded(data)
    }

    func handleRollComplete(_ finalRoll: Int) {
        guard case var .loaded(data) = viewState else { return }
        data.lastRoll = finalRoll
        let dcAtRoll = data.dcAtRoll
        let taskName = data.task.name

        if finalRoll >= dcAtRoll {
            data.lastResult = .success
        } else {
            data.lastResult = .failure
        }
        viewState = .loaded(data)

        Task { [taskRepository, historyRepository, taskId] in
            let updated: TaskItem? = if finalRoll >= dcAtRoll {
                try? await taskRepository.resetDC(for: taskId)
            } else {
                try? await taskRepository.applyMiss(to: taskId)
            }
            _ = updated
            let entry = RollHistoryEntry(
                rollValue: finalRoll,
                targetDC: dcAtRoll,
                taskName: taskName
            )
            try? await historyRepository.append(entry)
        }
    }

    private func startWatchingTask() {
        taskWatcher?.cancel()
        taskWatcher = Task { [weak self, taskRepository, taskId] in
            let stream = await taskRepository.taskStream(id: taskId)
            for await item in stream {
                await MainActor.run {
                    self?.updateTask(item)
                }
            }
            await MainActor.run { self?.handleTaskDeleted() }
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

    private func updateTask(_ item: TaskItem) {
        guard case var .loaded(data) = viewState else { return }
        data.task = item
        viewState = .loaded(data)
    }

    private func handleTaskDeleted() {
        viewState = .notFound
    }

    isolated deinit {
        taskWatcher?.cancel()
        settingsWatcher?.cancel()
    }
}

struct TaskDetailData {
    let diceVM: DiceViewModel
    var task: TaskItem
    var lastResult: RollResult = .none
    var lastRoll: Int = 0
    var dcAtRoll: Int = 0
}
