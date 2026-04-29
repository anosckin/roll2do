import CoreData
import Foundation

struct Settings: Sendable, Equatable {
    var rollSpeedMultiplier: Double

    static let `default` = Settings(rollSpeedMultiplier: 1.0)
    static let minSpeedMultiplier: Double = 0.0
    static let maxSpeedMultiplier: Double = 2.0

    var speedDescription: String {
        switch rollSpeedMultiplier {
        case 0:
            "Instant"
        case 0.01 ..< 0.5:
            "Very Fast"
        case 0.5 ..< 0.8:
            "Fast"
        case 0.8 ..< 1.2:
            "Normal"
        case 1.2 ..< 1.6:
            "Slow"
        default:
            "Very Slow"
        }
    }
}

extension Settings: PersistableSingleton {
    static let entityName = "CDSettings"
    static let singletonId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let defaultValue = Settings.default

    static func map(_ cd: CDSettings) -> Settings {
        Settings(rollSpeedMultiplier: cd.rollSpeedMultiplier)
    }

    static func apply(_ value: Settings, to cd: CDSettings) {
        cd.id = Settings.singletonId
        cd.rollSpeedMultiplier = value.rollSpeedMultiplier
    }
}
