import SwiftUI

struct DiceConfig {
    var colors: [Color]
    var size: CGFloat
    var fontSize: CGFloat

    static let `default` = DiceConfig(
        colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
        size: 140,
        fontSize: 50
    )
    static let large = DiceConfig(
        colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
        size: 160,
        fontSize: 50
    )

    func with(colors: [Color]) -> DiceConfig {
        DiceConfig(colors: colors, size: size, fontSize: fontSize)
    }
}
