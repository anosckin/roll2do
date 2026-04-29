import CoreData
import Foundation

protocol LocalDataSourceProtocol: Actor {
    // Generic persistence (collections)
    func fetchOne<T: PersistableModel>(_: T.Type, id: UUID) async -> T?
    func fetchAll<T: PersistableModel>(_: T.Type, sortedBy key: String, ascending: Bool) async -> [T]
    func fetchFirst<T: PersistableModel>(_: T.Type) async -> T?
    func upsert(_ value: some PersistableModel) async throws
    func delete(_: (some PersistableModel).Type, id: UUID) async throws
    func deleteAll(_: (some PersistableModel).Type) async throws

    // Generic observation (FRC-backed)
    func observeAll<T: PersistableModel>(_: T.Type, sortedBy key: String, ascending: Bool) -> AsyncStream<[T]>
    func observe<T: PersistableModel>(_: T.Type, id: UUID) -> AsyncStream<T>

    // Generic singleton API (one row, fixed UUID).
    // `getSingleton` / `observeSingleton` coalesce missing rows to `T.defaultValue`.
    // The `IfPresent` variants surface absence as `nil`, for singletons where
    // "absent" is a meaningful state (e.g. no signed-in user).
    func getSingleton<T: PersistableSingleton>(_: T.Type) async -> T
    func getSingletonIfPresent<T: PersistableSingleton>(_: T.Type) async -> T?
    func setSingleton(_ value: some PersistableSingleton) async throws
    func observeSingleton<T: PersistableSingleton>(_: T.Type) -> AsyncStream<T>
    func observeSingletonIfPresent<T: PersistableSingleton>(_: T.Type) -> AsyncStream<T?>

    /// Generic predicate-based existence check
    func exists<T: PersistableModel>(_: T.Type, matching query: Query<T>) async -> Bool
}

actor LocalDataSource: LocalDataSourceProtocol {
    private let stack: CoreDataStack
    /// Accessed only via context.perform; the queue makes access safe.
    private let context: NSManagedObjectContext

    init(stack: CoreDataStack = .shared) {
        self.stack = stack
        context = stack.newBackgroundContext()
    }

    // MARK: - Generic persistence helpers

    func fetchOne<T: PersistableModel>(_: T.Type, id: UUID) async -> T? {
        await withCheckedContinuation { continuation in
            context.perform { [context] in
                let request = NSFetchRequest<T.CDEntity>(entityName: T.entityName)
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                request.fetchLimit = 1
                let cd = (try? context.fetch(request))?.first
                continuation.resume(returning: cd.map(T.map))
            }
        }
    }

    func fetchAll<T: PersistableModel>(_: T.Type, sortedBy key: String, ascending: Bool) async -> [T] {
        await withCheckedContinuation { continuation in
            context.perform { [context] in
                let request = NSFetchRequest<T.CDEntity>(entityName: T.entityName)
                request.sortDescriptors = [NSSortDescriptor(key: key, ascending: ascending)]
                let cdItems = (try? context.fetch(request)) ?? []
                continuation.resume(returning: cdItems.map(T.map))
            }
        }
    }

    func fetchFirst<T: PersistableModel>(_: T.Type) async -> T? {
        await withCheckedContinuation { continuation in
            context.perform { [context] in
                let request = NSFetchRequest<T.CDEntity>(entityName: T.entityName)
                request.fetchLimit = 1
                let cd = (try? context.fetch(request))?.first
                continuation.resume(returning: cd.map(T.map))
            }
        }
    }

    func upsert<T: PersistableModel>(_ value: T) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform { [context] in
                do {
                    let request = NSFetchRequest<T.CDEntity>(entityName: T.entityName)
                    request.predicate = NSPredicate(format: "id == %@", value.id as CVarArg)
                    request.fetchLimit = 1
                    let existing = try context.fetch(request).first
                    let cd = existing ?? T.CDEntity(context: context)
                    T.apply(value, to: cd)
                    try context.save()
                    continuation.resume()
                } catch {
                    context.rollback()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func delete<T: PersistableModel>(_: T.Type, id: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform { [context] in
                do {
                    let request = NSFetchRequest<T.CDEntity>(entityName: T.entityName)
                    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    request.fetchLimit = 1
                    if let cd = try context.fetch(request).first {
                        context.delete(cd)
                        try context.save()
                    }
                    continuation.resume()
                } catch {
                    context.rollback()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func deleteAll<T: PersistableModel>(_: T.Type) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform { [context] in
                do {
                    let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: T.entityName)
                    let delete = NSBatchDeleteRequest(fetchRequest: request)
                    delete.resultType = .resultTypeObjectIDs
                    let result = try context.execute(delete) as? NSBatchDeleteResult
                    if let ids = result?.result as? [NSManagedObjectID], !ids.isEmpty {
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: [NSDeletedObjectsKey: ids],
                            into: [context]
                        )
                    }
                    try context.save()
                    continuation.resume()
                } catch {
                    context.rollback()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Generic observation (FRC)

    nonisolated func observeAll<T: PersistableModel>(
        _: T.Type,
        sortedBy key: String,
        ascending: Bool
    ) -> AsyncStream<[T]> {
        AsyncStream { continuation in
            let observer = FRCObserver<T>(
                context: context,
                sortKey: key,
                ascending: ascending,
                predicate: nil,
                onUpdate: { items in continuation.yield(items) },
                onEmpty: nil
            )
            observer.start()
            continuation.onTermination = { _ in observer.detach() }
        }
    }

    nonisolated func observe<T: PersistableModel>(_: T.Type, id: UUID) -> AsyncStream<T> {
        AsyncStream { continuation in
            let observer = FRCObserver<T>(
                context: context,
                sortKey: "id",
                ascending: true,
                predicate: NSPredicate(format: "id == %@", id as CVarArg),
                onUpdate: { items in
                    if let item = items.first {
                        continuation.yield(item)
                    }
                },
                onEmpty: { continuation.finish() }
            )
            observer.start()
            continuation.onTermination = { _ in observer.detach() }
        }
    }

    // MARK: - Generic singleton API

    func getSingleton<T: PersistableSingleton>(_: T.Type) async -> T {
        await getSingletonIfPresent(T.self) ?? T.defaultValue
    }

    func getSingletonIfPresent<T: PersistableSingleton>(_: T.Type) async -> T? {
        await withCheckedContinuation { continuation in
            context.perform { [context] in
                let request = NSFetchRequest<T.CDEntity>(entityName: T.entityName)
                request.predicate = NSPredicate(format: "id == %@", T.singletonId as CVarArg)
                request.fetchLimit = 1
                let cd = (try? context.fetch(request))?.first
                continuation.resume(returning: cd.map(T.map))
            }
        }
    }

    func setSingleton<T: PersistableSingleton>(_ value: T) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform { [context] in
                do {
                    let request = NSFetchRequest<T.CDEntity>(entityName: T.entityName)
                    request.predicate = NSPredicate(format: "id == %@", T.singletonId as CVarArg)
                    request.fetchLimit = 1
                    let existing = try context.fetch(request).first
                    let cd = existing ?? T.CDEntity(context: context)
                    T.apply(value, to: cd)
                    try context.save()
                    continuation.resume()
                } catch {
                    context.rollback()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    nonisolated func observeSingleton<T: PersistableSingleton>(_: T.Type) -> AsyncStream<T> {
        AsyncStream { continuation in
            let observer = SingletonObserver<T>(
                context: context,
                onUpdate: { value in continuation.yield(value ?? T.defaultValue) }
            )
            observer.start()
            continuation.onTermination = { _ in observer.detach() }
        }
    }

    nonisolated func observeSingletonIfPresent<T: PersistableSingleton>(_: T.Type) -> AsyncStream<T?> {
        AsyncStream { continuation in
            let observer = SingletonObserver<T>(
                context: context,
                onUpdate: { value in continuation.yield(value) }
            )
            observer.start()
            continuation.onTermination = { _ in observer.detach() }
        }
    }

    // MARK: - Generic predicate-based existence check

    func exists<T: PersistableModel>(_: T.Type, matching query: Query<T>) async -> Bool {
        await withCheckedContinuation { continuation in
            context.perform { [context] in
                let request = NSFetchRequest<T.CDEntity>(entityName: T.entityName)
                request.predicate = query.toNSPredicate()
                request.fetchLimit = 1
                let count = (try? context.count(for: request)) ?? 0
                continuation.resume(returning: count > 0)
            }
        }
    }
}

// MARK: - FRC observer (collections + per-id, generic over PersistableModel)

private final class FRCObserver<T: PersistableModel>: NSObject, NSFetchedResultsControllerDelegate, @unchecked Sendable {
    private let frc: NSFetchedResultsController<T.CDEntity>
    private let onUpdate: @Sendable ([T]) -> Void
    private let onEmpty: (@Sendable () -> Void)?

    init(
        context: NSManagedObjectContext,
        sortKey: String,
        ascending: Bool,
        predicate: NSPredicate?,
        onUpdate: @escaping @Sendable ([T]) -> Void,
        onEmpty: (@Sendable () -> Void)?
    ) {
        let request = NSFetchRequest<T.CDEntity>(entityName: T.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: sortKey, ascending: ascending)]
        request.predicate = predicate
        frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.onUpdate = onUpdate
        self.onEmpty = onEmpty
        super.init()
        frc.delegate = self
    }

    func start() {
        frc.managedObjectContext.perform {
            try? self.frc.performFetch()
            self.emit()
        }
    }

    func detach() {
        frc.managedObjectContext.perform {
            self.frc.delegate = nil
        }
    }

    nonisolated func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        emit()
    }

    private func emit() {
        let items = (frc.fetchedObjects ?? []).map(T.map)
        onUpdate(items)
        if items.isEmpty, let onEmpty {
            onEmpty()
        }
    }
}

// MARK: - Singleton observer (generic over PersistableSingleton)

private final class SingletonObserver<T: PersistableSingleton>: NSObject, NSFetchedResultsControllerDelegate, @unchecked Sendable {
    private let frc: NSFetchedResultsController<T.CDEntity>
    private let context: NSManagedObjectContext
    private let onUpdate: @Sendable (T?) -> Void

    init(context: NSManagedObjectContext, onUpdate: @escaping @Sendable (T?) -> Void) {
        self.context = context
        let request = NSFetchRequest<T.CDEntity>(entityName: T.entityName)
        request.predicate = NSPredicate(format: "id == %@", T.singletonId as CVarArg)
        // FRC requires a sort descriptor; sorting by id is stable and trivial.
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        request.fetchLimit = 1
        frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.onUpdate = onUpdate
        super.init()
        frc.delegate = self
    }

    func start() {
        context.perform {
            try? self.frc.performFetch()
            self.emit()
        }
    }

    func detach() {
        context.perform {
            self.frc.delegate = nil
        }
    }

    nonisolated func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        emit()
    }

    private func emit() {
        onUpdate(frc.fetchedObjects?.first.map(T.map))
    }
}
