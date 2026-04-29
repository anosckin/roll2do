import CoreData
import Foundation

@objc(CDTaskItem)
final class CDTaskItem: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var icon: String?
    @NSManaged var initialDC: Int32
    @NSManaged var currentDC: Int32
    @NSManaged var dcDecreasePerMiss: Int32
    @NSManaged var minDC: Int32
    @NSManaged var usesAdvancedSettings: Bool

    static func fetchRequest() -> NSFetchRequest<CDTaskItem> {
        NSFetchRequest<CDTaskItem>(entityName: "CDTaskItem")
    }
}
