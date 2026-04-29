import Foundation

protocol TaskRepositoryProtocol: Sendable {
    func fetchAll() async -> [TaskItem]
    func fetch(id: UUID) async -> TaskItem?
    func isNameTaken(_ name: String, excluding id: UUID?) async -> Bool
    func save(_ item: TaskItem) async throws
    func delete(id: UUID) async throws
    func applyMiss(to id: UUID) async throws -> TaskItem?
    func resetDC(for id: UUID) async throws -> TaskItem?
    func tasksStream() async -> AsyncStream<[TaskItem]>
    func taskStream(id: UUID) async -> AsyncStream<TaskItem>
}

struct TaskRepository: TaskRepositoryProtocol {
    private let local: LocalDataSourceProtocol
    private let remote: RemoteDataSourceProtocol

    init() {
        local = DataSourceContainer.shared.local
        remote = DataSourceContainer.shared.remote
    }

    func fetchAll() async -> [TaskItem] {
        await local.fetchAll(TaskItem.self, sortedBy: "name", ascending: true)
    }

    func fetch(id: UUID) async -> TaskItem? {
        await local.fetchOne(TaskItem.self, id: id)
    }

    func isNameTaken(_ name: String, excluding id: UUID?) async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var conditions: [QueryCondition] = [.equalIgnoringCase(field: "name", value: trimmed)]
        if let id {
            conditions.append(.notEqual(field: "id", value: .uuid(id)))
        }
        return await local.exists(TaskItem.self, matching: Query(conditions))
    }

    func save(_ item: TaskItem) async throws {
        try await local.upsert(item)
    }

    func delete(id: UUID) async throws {
        try await local.delete(TaskItem.self, id: id)
    }

    func applyMiss(to id: UUID) async throws -> TaskItem? {
        guard var item = await local.fetchOne(TaskItem.self, id: id) else { return nil }
        item.currentDC = max(item.minDC, item.currentDC - item.dcDecreasePerMiss)
        try await local.upsert(item)
        return item
    }

    func resetDC(for id: UUID) async throws -> TaskItem? {
        guard var item = await local.fetchOne(TaskItem.self, id: id) else { return nil }
        item.currentDC = item.initialDC
        try await local.upsert(item)
        return item
    }

    func tasksStream() async -> AsyncStream<[TaskItem]> {
        await local.observeAll(TaskItem.self, sortedBy: "name", ascending: true)
    }

    func taskStream(id: UUID) async -> AsyncStream<TaskItem> {
        await local.observe(TaskItem.self, id: id)
    }
}
