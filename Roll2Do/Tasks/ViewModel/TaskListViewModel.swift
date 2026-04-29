import Foundation
import Observation

@MainActor @Observable
final class TaskListViewModel {
    enum ViewState {
        case idle
        case loading
        case loaded
        case error(String)
    }

    private(set) var viewState: ViewState = .idle
    private(set) var tasks: [TaskItem] = []

    var isPresentingEditor: Bool = false
    var editingTaskId: UUID?

    private let repository: TaskRepositoryProtocol
    private var watcherTask: Task<Void, Never>?

    init(repository: TaskRepositoryProtocol = TaskRepository()) {
        self.repository = repository
    }

    func setup() async {
        guard case .idle = viewState else { return }
        viewState = .loading
        tasks = await repository.fetchAll()
        viewState = .loaded
        startWatching()
    }

    func delete(id: UUID) {
        Task { [repository] in
            try? await repository.delete(id: id)
        }
    }

    func presentNewTask() {
        editingTaskId = nil
        isPresentingEditor = true
    }

    func presentEdit(id: UUID) {
        editingTaskId = id
        isPresentingEditor = true
    }

    private func startWatching() {
        watcherTask?.cancel()
        watcherTask = Task { [weak self, repository] in
            let stream = await repository.tasksStream()
            for await items in stream {
                await MainActor.run {
                    self?.tasks = items
                }
            }
        }
    }

    isolated deinit {
        watcherTask?.cancel()
    }
}
