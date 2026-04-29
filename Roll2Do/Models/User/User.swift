import CoreData
import Foundation

struct User: Identifiable, Hashable, Sendable {
    let id: UUID
    let email: String

    init(id: UUID = UUID(), email: String) {
        self.id = id
        self.email = email
    }
}

extension User: PersistableModel {
    static let entityName = "CDUser"

    static func map(_ cd: CDUser) -> User {
        User(id: cd.id, email: cd.email)
    }

    static func apply(_ user: User, to cd: CDUser) {
        cd.id = user.id
        cd.email = user.email
    }
}
