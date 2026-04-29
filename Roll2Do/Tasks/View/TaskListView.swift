import SwiftUI

struct TaskListView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = TaskListViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        Group {
            switch viewModel.viewState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                if viewModel.tasks.isEmpty {
                    ContentUnavailableView(
                        "No Tasks Yet",
                        systemImage: "checklist",
                        description: Text("Tap the + button to add your first task.")
                    )
                } else {
                    taskList
                }
            case let .error(message):
                ContentUnavailableView(
                    "Something Went Wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.presentNewTask()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Task")
            }
        }
        .sheet(isPresented: $viewModel.isPresentingEditor) {
            TaskEditorView(taskId: viewModel.editingTaskId)
        }
        .task { await viewModel.setup() }
    }

    private var taskList: some View {
        List {
            ForEach(viewModel.tasks) { task in
                Button {
                    router.navigate(to: .taskDetail(taskId: task.id))
                } label: {
                    TaskRowView(task: task)
                }
                .buttonStyle(.plain)
                .contentShape(.rect)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.delete(id: task.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        viewModel.presentEdit(id: task.id)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
        }
    }
}

private struct TaskRowView: View {
    let task: TaskItem

    var body: some View {
        HStack {
            if let icon = task.icon {
                Image(systemName: icon)
                    .foregroundStyle(.accent)
            }
            VStack(alignment: .leading) {
                Text(task.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text("DC \(task.currentDC)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(.rect)
    }
}
