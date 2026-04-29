import CoreData
import Foundation

@objc(CDUser)
final class CDUser: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var email: String

    static func fetchRequest() -> NSFetchRequest<CDUser> {
        NSFetchRequest<CDUser>(entityName: "CDUser")
    }
}
