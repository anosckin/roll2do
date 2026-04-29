import CoreData
import Foundation

@objc(CDSettings)
final class CDSettings: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var rollSpeedMultiplier: Double

    static func fetchRequest() -> NSFetchRequest<CDSettings> {
        NSFetchRequest<CDSettings>(entityName: "CDSettings")
    }
}
