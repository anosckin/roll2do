import CoreData
import Foundation

struct TaskItem: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var icon: String?
    var initialDC: Int
    var currentDC: Int
    var dcDecreasePerMiss: Int
    var minDC: Int
    var usesAdvancedSettings: Bool

    init(
        id: UUID = UUID(),
        name: String,
        icon: String? = nil,
        initialDC: Int,
        currentDC: Int? = nil,
        dcDecreasePerMiss: Int,
        minDC: Int = 1,
        usesAdvancedSettings: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.initialDC = initialDC
        self.currentDC = currentDC ?? initialDC
        self.dcDecreasePerMiss = dcDecreasePerMiss
        self.minDC = minDC
        self.usesAdvancedSettings = usesAdvancedSettings
    }
}

extension TaskItem: PersistableModel {
    static let entityName = "CDTaskItem"

    static func map(_ cd: CDTaskItem) -> TaskItem {
        TaskItem(
            id: cd.id,
            name: cd.name,
            icon: cd.icon,
            initialDC: Int(cd.initialDC),
            currentDC: Int(cd.currentDC),
            dcDecreasePerMiss: Int(cd.dcDecreasePerMiss),
            minDC: Int(cd.minDC),
            usesAdvancedSettings: cd.usesAdvancedSettings
        )
    }

    static func apply(_ item: TaskItem, to cd: CDTaskItem) {
        cd.id = item.id
        cd.name = item.name
        cd.icon = item.icon
        cd.initialDC = Int32(item.initialDC)
        cd.currentDC = Int32(item.currentDC)
        cd.dcDecreasePerMiss = Int32(item.dcDecreasePerMiss)
        cd.minDC = Int32(item.minDC)
        cd.usesAdvancedSettings = item.usesAdvancedSettings
    }
}
