import SwiftUI

struct D20Shape: Shape {
    func path(in rect: CGRect) -> Path {
        let sides = 6
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let angleOffset = -CGFloat.pi / 2

        var path = Path()
        for i in 0 ..< sides {
            let angle = angleOffset + (2 * .pi / CGFloat(sides)) * CGFloat(i)
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
