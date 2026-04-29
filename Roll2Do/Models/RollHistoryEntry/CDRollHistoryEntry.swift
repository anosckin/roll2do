import CoreData
import Foundation

@objc(CDRollHistoryEntry)
final class CDRollHistoryEntry: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var timestamp: Date
    @NSManaged var rollValue: Int32
    @NSManaged var targetDC: NSNumber?
    @NSManaged var taskName: String?

    static func fetchRequest() -> NSFetchRequest<CDRollHistoryEntry> {
        NSFetchRequest<CDRollHistoryEntry>(entityName: "CDRollHistoryEntry")
    }
}
