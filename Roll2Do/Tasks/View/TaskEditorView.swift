import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TaskEditorViewModel

    init(taskId: UUID?) {
        _viewModel = State(wrappedValue: TaskEditorViewModel(taskId: taskId))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section {
                    TextField("Task name", text: $viewModel.name)
                        .autocapitalization(.words)
                } footer: {
                    if viewModel.isNameDuplicate, !viewModel.trimmedName.isEmpty {
                        Text("A task with this name already exists.")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Picker("", selection: $viewModel.editorMode) {
                        ForEach(TaskEditorViewModel.EditorMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if viewModel.editorMode == .simple {
                    simpleSettings
                } else {
                    advancedSettings
                }
            }
            .navigationTitle(viewModel.editorTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await viewModel.save() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.saveState == .saving)
                }
            }
            .alert(
                "Save Failed",
                isPresented: Binding(
                    get: {
                        if case .error = viewModel.saveState { return true }
                        return false
                    },
                    set: { newValue in
                        if !newValue { viewModel.dismissError() }
                    }
                )
            ) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                if case let .error(message) = viewModel.saveState {
                    Text(message)
                }
            }
            .task { await viewModel.setup() }
        }
    }

    private var simpleSettings: some View {
        @Bindable var viewModel = viewModel
        return Section {
            Picker("Frequency", selection: $viewModel.selectedPreset) {
                ForEach(TaskPreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } header: {
            Text("How often do you want to do this?")
        } footer: {
            Text(viewModel.selectedPreset.description)
        }
    }

    @ViewBuilder private var advancedSettings: some View {
        @Bindable var viewModel = viewModel

        Section {
            Stepper("Initial DC: \(viewModel.initialDC)", value: $viewModel.initialDC, in: 1 ... 20)
        } footer: {
            Text("The difficulty class to beat on a d20 roll.")
        }

        Section {
            Stepper("DC drop per miss: \(viewModel.dcDropPerMiss)", value: $viewModel.dcDropPerMiss, in: 0 ... 10)
        } footer: {
            Text("How much the DC decreases each time you skip the task, making it easier next time.")
        }

        Section {
            Stepper("Minimum DC: \(viewModel.minDC)", value: $viewModel.minDC, in: 1 ... viewModel.initialDC)
        } footer: {
            Text("The lowest the DC can drop to after repeated misses.")
        }
    }
}
