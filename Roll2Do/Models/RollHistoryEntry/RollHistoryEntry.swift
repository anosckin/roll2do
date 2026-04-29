import CoreData
import Foundation

struct RollHistoryEntry: Identifiable, Hashable, Sendable {
    let id: UUID
    let timestamp: Date
    let rollValue: Int
    let targetDC: Int?
    let taskName: String?

    var wasSuccess: Bool? {
        guard let dc = targetDC else { return nil }
        return rollValue >= dc
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        rollValue: Int,
        targetDC: Int? = nil,
        taskName: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.rollValue = rollValue
        self.targetDC = targetDC
        self.taskName = taskName
    }
}

extension RollHistoryEntry: PersistableModel {
    static let entityName = "CDRollHistoryEntry"

    static func map(_ cd: CDRollHistoryEntry) -> RollHistoryEntry {
        RollHistoryEntry(
            id: cd.id,
            timestamp: cd.timestamp,
            rollValue: Int(cd.rollValue),
            targetDC: cd.targetDC.map { Int(truncating: $0) },
            taskName: cd.taskName
        )
    }

    static func apply(_ entry: RollHistoryEntry, to cd: CDRollHistoryEntry) {
        cd.id = entry.id
        cd.timestamp = entry.timestamp
        cd.rollValue = Int32(entry.rollValue)
        cd.targetDC = entry.targetDC.map { NSNumber(value: $0) }
        cd.taskName = entry.taskName
    }
}
