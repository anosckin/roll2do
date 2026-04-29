import SwiftUI

struct DiceView: View {
    var viewModel: DiceViewModel
    var config: DiceConfig = .default

    var body: some View {
        ZStack {
            D20Shape()
                .fill(
                    LinearGradient(
                        colors: config.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: config.size, height: config.size)
                .shadow(
                    color: config.colors.first?.opacity(0.4) ?? .accentColor.opacity(0.4),
                    radius: viewModel.isRolling ? 20 : 10,
                    y: 5
                )

            Text("\(viewModel.displayedNumber)")
                .font(.system(size: config.fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(viewModel.displayedNumber)))
                .animation(.spring(response: 0.15, dampingFraction: 0.5), value: viewModel.displayedNumber)
        }
        .scaleEffect(viewModel.scale)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.scale)
    }
}
