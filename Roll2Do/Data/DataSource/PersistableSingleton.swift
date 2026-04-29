import CoreData
import Foundation

/// Singleton entities — exactly one row, identified by a fixed UUID.
/// Use this when the entity represents a single value (config, current viewer)
/// rather than a collection. The fixed UUID makes the row deterministic across
/// devices (CloudKit dedups on it) and removes the "which row is first?" ambiguity.
protocol PersistableSingleton: Sendable {
    associatedtype CDEntity: NSManagedObject
    static var entityName: String { get }
    static var singletonId: UUID { get }
    static var defaultValue: Self { get }
    static func map(_ cd: CDEntity) -> Self
    static func apply(_ value: Self, to cd: CDEntity)
}
