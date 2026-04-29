import Foundation

protocol HistoryRepositoryProtocol: Sendable {
    func fetchAll() async -> [RollHistoryEntry]
    func append(_ entry: RollHistoryEntry) async throws
    func delete(id: UUID) async throws
    func clear() async throws
    func historyStream() async -> AsyncStream<[RollHistoryEntry]>
}

struct HistoryRepository: HistoryRepositoryProtocol {
    private let local: LocalDataSourceProtocol
    private let remote: RemoteDataSourceProtocol

    init() {
        local = DataSourceContainer.shared.local
        remote = DataSourceContainer.shared.remote
    }

    func fetchAll() async -> [RollHistoryEntry] {
        await local.fetchAll(RollHistoryEntry.self, sortedBy: "timestamp", ascending: false)
    }

    func append(_ entry: RollHistoryEntry) async throws {
        try await local.upsert(entry)
    }

    func delete(id: UUID) async throws {
        try await local.delete(RollHistoryEntry.self, id: id)
    }

    func clear() async throws {
        try await local.deleteAll(RollHistoryEntry.self)
    }

    func historyStream() async -> AsyncStream<[RollHistoryEntry]> {
        await local.observeAll(RollHistoryEntry.self, sortedBy: "timestamp", ascending: false)
    }
}
