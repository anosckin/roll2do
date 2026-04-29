import Foundation
import Observation

@MainActor @Observable
final class HistoryViewModel {
    enum ViewState {
        case idle
        case loading
        case loaded
        case error(String)
    }

    enum Filter: Equatable, Hashable {
        case all
        case freeRolls
        case task(String)

        var title: String {
            switch self {
            case .all: "All"
            case .freeRolls: "Free Rolls"
            case let .task(name): name
            }
        }

        var emptyTitle: String {
            switch self {
            case .all: "No Rolls Yet"
            case .freeRolls: "No Free Rolls"
            case .task: "No Rolls for This Task"
            }
        }

        var emptyDescription: String {
            switch self {
            case .all: "Your roll history will appear here."
            case .freeRolls: "Use the Roll tab to make free rolls."
            case .task: "Roll dice on this task to see history here."
            }
        }
    }

    private(set) var viewState: ViewState = .idle
    private(set) var entries: [RollHistoryEntry] = []
    var filter: Filter = .all

    var uniqueTaskNames: [String] {
        Array(Set(entries.compactMap(\.taskName))).sorted()
    }

    var filteredEntries: [RollHistoryEntry] {
        switch filter {
        case .all:
            entries
        case .freeRolls:
            entries.filter { $0.taskName == nil }
        case let .task(name):
            entries.filter { $0.taskName == name }
        }
    }

    private let repository: HistoryRepositoryProtocol
    private var watcherTask: Task<Void, Never>?

    init(repository: HistoryRepositoryProtocol = HistoryRepository()) {
        self.repository = repository
    }

    func setup() async {
        guard case .idle = viewState else { return }
        viewState = .loading
        entries = await repository.fetchAll()
        viewState = .loaded
        startWatching()
    }

    func deleteEntries(at offsets: IndexSet) {
        let toDelete = offsets.map { filteredEntries[$0] }
        Task { [repository] in
            for entry in toDelete {
                try? await repository.delete(id: entry.id)
            }
        }
    }

    private func startWatching() {
        watcherTask?.cancel()
        watcherTask = Task { [weak self, repository] in
            let stream = await repository.historyStream()
            for await items in stream {
                await MainActor.run {
                    self?.entries = items
                }
            }
        }
    }

    isolated deinit {
        watcherTask?.cancel()
    }
}
