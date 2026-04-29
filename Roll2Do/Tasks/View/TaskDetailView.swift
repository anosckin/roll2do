import SwiftUI

struct TaskDetailView: View {
    @Environment(Router.self) private var router
    @State private var viewModel: TaskDetailViewModel
    @State private var isPresentingEditor = false

    init(taskId: UUID) {
        _viewModel = State(wrappedValue: TaskDetailViewModel(taskId: taskId))
    }

    var body: some View {
        Group {
            switch viewModel.viewState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .loaded(data):
                loadedContent(data)
            case .notFound:
                ContentUnavailableView(
                    "Task Not Found",
                    systemImage: "questionmark.folder",
                    description: Text("This task may have been deleted.")
                )
                .onAppear { router.navigateBack() }
            case let .error(message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .toolbar {
            if case let .loaded(data) = viewModel.viewState {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        isPresentingEditor = true
                    }
                    .disabled(data.diceVM.isRolling)
                }
            }
        }
        .sheet(isPresented: $isPresentingEditor) {
            if case let .loaded(data) = viewModel.viewState {
                TaskEditorView(taskId: data.task.id)
            }
        }
        .task { await viewModel.setup() }
    }

    private func loadedContent(_ data: TaskDetailData) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection(data.task)
                diceSection(data)
                statsSection(data.task)
            }
            .padding()
        }
    }

    private func headerSection(_ task: TaskItem) -> some View {
        VStack(spacing: 12) {
            if let icon = task.icon {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.accent)
            }

            Text(task.name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func diceSection(_ data: TaskDetailData) -> some View {
        VStack(spacing: 16) {
            Text("Roll to beat DC \(data.task.currentDC)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TaskDiceView(
                diceVM: data.diceVM,
                lastResult: data.lastResult,
                lastRoll: data.lastRoll,
                dcAtRoll: data.dcAtRoll,
                onRollStart: viewModel.handleRollStart,
                onRollComplete: viewModel.handleRollComplete
            )
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statsSection(_ task: TaskItem) -> some View {
        VStack(spacing: 16) {
            if !task.usesAdvancedSettings,
               let preset = TaskPreset.matching(
                   initialDC: task.initialDC,
                   dcDrop: task.dcDecreasePerMiss,
                   minDC: task.minDC
               )
            {
                presetDisplay(preset)
            } else {
                advancedStatsDisplay(task)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func presetDisplay(_ preset: TaskPreset) -> some View {
        VStack(spacing: 8) {
            Text(preset.title)
                .font(.headline)
            Text(preset.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func advancedStatsDisplay(_ task: TaskItem) -> some View {
        VStack(spacing: 16) {
            StatRow(label: "Current DC", value: "\(task.currentDC)")
            StatRow(label: "Initial DC", value: "\(task.initialDC)")
            StatRow(label: "DC Drop per Miss", value: "\(task.dcDecreasePerMiss)")
            StatRow(label: "Minimum DC", value: "\(task.minDC)")
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}
