import Foundation

struct User: Identifiable, Hashable, Sendable {
    let id: String
    let email: String
}
