import Foundation

/// Storage-agnostic query. Each `LocalDataSource` translates this into its
/// native filter form (NSPredicate, Realm query, SQL WHERE, ...). Conditions
/// in the array are AND-ed; OR / nested groups can be added when first needed.
struct Query<T: PersistableModel>: Sendable {
    let conditions: [QueryCondition]

    init(_ conditions: [QueryCondition] = []) {
        self.conditions = conditions
    }
}

enum QueryCondition: Sendable {
    case equal(field: String, value: QueryValue)
    case notEqual(field: String, value: QueryValue)
    case equalIgnoringCase(field: String, value: String)
    indirect case and([QueryCondition])
    indirect case or([QueryCondition])
}

enum QueryValue: Sendable {
    case string(String)
    case uuid(UUID)
    case bool(Bool)
}
