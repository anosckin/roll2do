import SwiftUI

struct RollDiceButton: View {
    var viewModel: DiceViewModel
    var style: Style = .compact
    var onStart: (() -> Void)?
    var onComplete: ((Int) -> Void)?

    var body: some View {
        Button(action: roll) {
            Text(viewModel.isRolling ? "Rolling..." : "Roll Dice")
                .font(style.font)
                .padding(style.padding)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isRolling)
    }

    private func roll() {
        Task {
            onStart?()
            let result = await viewModel.roll()
            onComplete?(result)
        }
    }
}

extension RollDiceButton {
    enum Style {
        case compact
        case large

        var font: Font {
            switch self {
            case .compact: .headline
            case .large: .title2.bold()
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .compact: EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            case .large: EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
            }
        }
    }
}
