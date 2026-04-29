import Foundation
import Observation

@MainActor @Observable
final class DiceViewModel {
    private(set) var isRolling = false
    private(set) var displayedNumber = 20
    private(set) var scale: Double = 1.0
    private(set) var speedMultiplier: Double

    init(initialSpeed: Double = Settings.default.rollSpeedMultiplier) {
        _speedMultiplier = initialSpeed
    }

    func setSpeedMultiplier(_ value: Double) {
        speedMultiplier = value
    }

    func roll() async -> Int {
        guard !isRolling else { return displayedNumber }

        isRolling = true
        defer { isRolling = false }

        let multiplier = speedMultiplier
        let tickCount = max(1, Int(11.0 * multiplier))

        if multiplier > 0 {
            scale = 1.15
        }

        for tick in 0 ..< tickCount {
            let progress = Double(tick) / Double(tickCount)
            let baseInterval = 30.0 + progress * 100.0
            let interval = Int(baseInterval * multiplier)
            if interval > 0 {
                try? await Task.sleep(for: .milliseconds(interval))
            }
            displayedNumber = Int.random(in: 1 ... 20)
        }

        let finalDelay = Int(100.0 * multiplier)
        if finalDelay > 0 {
            try? await Task.sleep(for: .milliseconds(finalDelay))
        }
        scale = 1.0

        return displayedNumber
    }
}
