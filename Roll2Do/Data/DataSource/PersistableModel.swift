import CoreData
import Foundation

protocol PersistableModel: Sendable {
    associatedtype CDEntity: NSManagedObject
    static var entityName: String { get }
    static func map(_ cd: CDEntity) -> Self
    static func apply(_ value: Self, to cd: CDEntity)
    var id: UUID { get }
}
