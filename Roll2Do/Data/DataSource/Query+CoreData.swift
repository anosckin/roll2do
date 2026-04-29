import CoreData
import Foundation

/// Core Data adapter for the storage-agnostic `Query`. A different backend
/// (Realm, SQLite, ...) would provide its own translation in a parallel file.
extension Query {
    func toNSPredicate() -> NSPredicate? {
        QueryCondition.and(conditions).toNSPredicate()
    }
}

extension QueryCondition {
    func toNSPredicate() -> NSPredicate? {
        switch self {
        case let .equal(field, value):
            NSPredicate(format: "%K == %@", field, value.cvarArg)
        case let .notEqual(field, value):
            NSPredicate(format: "%K != %@", field, value.cvarArg)
        case let .equalIgnoringCase(field, str):
            NSPredicate(format: "%K ==[c] %@", field, str)
        case let .and(children):
            compound(children, type: .and)
        case let .or(children):
            compound(children, type: .or)
        }
    }

    private func compound(_ children: [QueryCondition], type: NSCompoundPredicate.LogicalType) -> NSPredicate? {
        let subs = children.compactMap { $0.toNSPredicate() }
        switch subs.count {
        case 0: return nil
        case 1: return subs[0]
        default: return NSCompoundPredicate(type: type, subpredicates: subs)
        }
    }
}

private extension QueryValue {
    var cvarArg: CVarArg {
        switch self {
        case let .string(s): s
        case let .uuid(u): u as CVarArg
        case let .bool(b): NSNumber(value: b)
        }
    }
}
