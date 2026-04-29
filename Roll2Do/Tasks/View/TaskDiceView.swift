import SwiftUI

struct TaskDiceView: View {
    let diceVM: DiceViewModel
    let lastResult: RollResult
    let lastRoll: Int
    let dcAtRoll: Int
    let onRollStart: () -> Void
    let onRollComplete: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            DiceView(viewModel: diceVM, config: diceConfig)
                .padding(.top, 8)

            VStack(spacing: 4) {
                if lastResult != .none {
                    resultMessage
                        .transition(.opacity)
                }
            }
            .frame(minHeight: 80)
            .animation(.easeInOut(duration: 0.2), value: lastResult)

            Spacer(minLength: 8)

            RollDiceButton(
                viewModel: diceVM,
                onStart: onRollStart,
                onComplete: onRollComplete
            )
            .padding(.bottom, 8)
        }
        .frame(minHeight: 280)
    }

    private var diceConfig: DiceConfig {
        switch lastResult {
        case .none:
            .default
        case .success:
            .default.with(colors: [Color.green, Color.green.opacity(0.7)])
        case .failure:
            .default.with(colors: [Color.orange, Color.orange.opacity(0.7)])
        }
    }

    private var resultMessage: some View {
        VStack(spacing: 4) {
            switch lastResult {
            case .success:
                Text("Success!")
                    .font(.title2.bold())
                    .foregroundStyle(.green)
                Text("You rolled \(lastRoll) vs DC \(dcAtRoll)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Time to do the task!")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.green)
            case .failure:
                Text("Not this time")
                    .font(.title2.bold())
                    .foregroundStyle(.orange)
                Text("You rolled \(lastRoll) vs DC \(dcAtRoll)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("DC decreased - easier next time!")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
            case .none:
                EmptyView()
            }
        }
        .multilineTextAlignment(.center)
    }
}
