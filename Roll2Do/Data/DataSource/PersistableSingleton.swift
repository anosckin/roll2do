import CoreData
import Foundation

/// Singleton entities — exactly one row, identified by a fixed UUID.
/// Use this when the entity represents a single value (config, current viewer)
/// rather than a collection. The fixed UUID makes the row deterministic across
/// devices (CloudKit dedups on it) and removes the "which row is first?" ambiguity.
protocol PersistableSingleton: Sendable {
    associatedtype CDEntity: NSManagedObject
    static var entityName: String { get }
    static var defaultValue: Self { get }
    static func map(_ cd: CDEntity) -> Self
    static func apply(_ value: Self, to cd: CDEntity)
}

extension PersistableSingleton {
    /// Fixed across all singletons — each lives in its own table, so the id is
    /// scoped per-entity. Single source of truth: no per-model boilerplate, no
    /// chance of two singletons drifting onto different ids.
    static var singletonId: UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    }
}
