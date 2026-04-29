import SwiftUI

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        Group {
            switch viewModel.viewState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                if viewModel.filteredEntries.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            case let .error(message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle("History")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterMenu
            }
        }
        .task { await viewModel.setup() }
    }

    private var filterMenu: some View {
        Menu {
            Button {
                viewModel.filter = .all
            } label: {
                HStack {
                    Text("All")
                    if viewModel.filter == .all {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Button {
                viewModel.filter = .freeRolls
            } label: {
                HStack {
                    Text("Free Rolls")
                    if viewModel.filter == .freeRolls {
                        Image(systemName: "checkmark")
                    }
                }
            }

            if !viewModel.uniqueTaskNames.isEmpty {
                Divider()

                ForEach(viewModel.uniqueTaskNames, id: \.self) { taskName in
                    Button {
                        viewModel.filter = .task(taskName)
                    } label: {
                        HStack {
                            Text(taskName)
                            if viewModel.filter == .task(taskName) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            Label(viewModel.filter.title, systemImage: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filter history")
        .accessibilityValue(viewModel.filter.title)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            viewModel.filter.emptyTitle,
            systemImage: "dice",
            description: Text(viewModel.filter.emptyDescription)
        )
    }

    private var historyList: some View {
        List {
            ForEach(viewModel.filteredEntries) { entry in
                HistoryRow(entry: entry)
            }
            .onDelete(perform: viewModel.deleteEntries)
        }
    }
}

private struct HistoryRow: View {
    let entry: RollHistoryEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let taskName = entry.taskName {
                    Text(taskName)
                        .font(.headline)
                } else {
                    Text("Free Roll")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Text(entry.timestamp, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    +
                    Text(" at ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    +
                    Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.rollValue)")
                    .font(.title2.bold())
                    .foregroundStyle(rollColor)

                if let dc = entry.targetDC {
                    Text("vs DC \(dc)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var rollColor: Color {
        guard let success = entry.wasSuccess else {
            return .primary
        }
        return success ? .green : .orange
    }
}
