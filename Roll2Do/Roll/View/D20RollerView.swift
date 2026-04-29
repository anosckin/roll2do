import SwiftUI

struct D20RollerView: View {
    @State private var viewModel = RollScreenViewModel()

    var body: some View {
        Group {
            switch viewModel.viewState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .loaded(data):
                loadedContent(data)
            case let .error(message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task { await viewModel.setup() }
    }

    private func loadedContent(_ data: RollScreenData) -> some View {
        VStack(spacing: 40) {
            Text("Roll the Dice")
                .font(.largeTitle.bold())

            DiceView(viewModel: data.diceVM, config: .large)

            RollDiceButton(
                viewModel: data.diceVM,
                style: .large,
                onComplete: viewModel.onRollComplete
            )
        }
    }
}
