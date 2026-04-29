import Foundation
import Observation

@MainActor @Observable
final class TaskEditorViewModel {
    enum EditorMode: String, CaseIterable, Identifiable {
        case simple
        case advanced
        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .simple: "Simple"
            case .advanced: "Advanced"
            }
        }
    }

    enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case error(String)
    }

    var name: String = "" {
        didSet { scheduleDuplicateCheck() }
    }

    var editorMode: EditorMode = .simple
    var selectedPreset: TaskPreset = .regular {
        didSet { applyPreset(selectedPreset) }
    }

    var initialDC: Int = 10 {
        didSet { minDC = min(minDC, initialDC) }
    }

    var dcDropPerMiss: Int = 2
    var minDC: Int = 1

    private(set) var isNameDuplicate: Bool = false
    private(set) var saveState: SaveState = .idle

    func dismissError() {
        if case .error = saveState {
            saveState = .idle
        }
    }

    let taskId: UUID?
    private let repository: TaskRepositoryProtocol
    private var duplicateCheckTask: Task<Void, Never>?

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isFormValid: Bool {
        !trimmedName.isEmpty && !isNameDuplicate
    }

    var editorTitle: String {
        taskId == nil ? "Add Task" : "Edit Task"
    }

    init(
        taskId: UUID? = nil,
        repository: TaskRepositoryProtocol = TaskRepository()
    ) {
        self.taskId = taskId
        self.repository = repository
    }

    func setup() async {
        guard let taskId else {
            applyPreset(selectedPreset)
            return
        }
        guard let item = await repository.fetch(id: taskId) else { return }
        _name = item.name
        _initialDC = item.initialDC
        _dcDropPerMiss = item.dcDecreasePerMiss
        _minDC = item.minDC
        _editorMode = item.usesAdvancedSettings ? .advanced : .simple
        if let preset = TaskPreset.matching(
            initialDC: item.initialDC,
            dcDrop: item.dcDecreasePerMiss,
            minDC: item.minDC
        ) {
            _selectedPreset = preset
        }
    }

    func save() async -> Bool {
        let finalName = trimmedName
        guard !finalName.isEmpty else { return false }

        if await repository.isNameTaken(finalName, excluding: taskId) {
            isNameDuplicate = true
            saveState = .error("A task with this name already exists.")
            return false
        }

        saveState = .saving

        let usesAdvanced = editorMode == .advanced
        let effectiveInitial = initialDC
        let effectiveDrop = usesAdvanced ? dcDropPerMiss : selectedPreset.dcDrop
        let effectiveMin = usesAdvanced ? minDC : selectedPreset.minDC

        let item: TaskItem
        if let taskId, let existing = await repository.fetch(id: taskId) {
            item = TaskItem(
                id: existing.id,
                name: finalName,
                icon: existing.icon,
                initialDC: usesAdvanced ? effectiveInitial : selectedPreset.initialDC,
                currentDC: usesAdvanced ? effectiveInitial : selectedPreset.initialDC,
                dcDecreasePerMiss: effectiveDrop,
                minDC: effectiveMin,
                usesAdvancedSettings: usesAdvanced
            )
        } else {
            let nextInitial = usesAdvanced ? effectiveInitial : selectedPreset.initialDC
            item = TaskItem(
                name: finalName,
                icon: nil,
                initialDC: nextInitial,
                currentDC: nextInitial,
                dcDecreasePerMiss: effectiveDrop,
                minDC: effectiveMin,
                usesAdvancedSettings: usesAdvanced
            )
        }

        do {
            try await repository.save(item)
            saveState = .saved
            return true
        } catch {
            saveState = .error(error.localizedDescription)
            return false
        }
    }

    private func applyPreset(_ preset: TaskPreset) {
        _initialDC = preset.initialDC
        _dcDropPerMiss = preset.dcDrop
        _minDC = preset.minDC
    }

    private func scheduleDuplicateCheck() {
        duplicateCheckTask?.cancel()
        let currentName = trimmedName
        guard !currentName.isEmpty else {
            isNameDuplicate = false
            return
        }
        duplicateCheckTask = Task { [weak self, repository, taskId] in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            let duplicate = await repository.isNameTaken(currentName, excluding: taskId)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.isNameDuplicate = duplicate
            }
        }
    }

    isolated deinit {
        duplicateCheckTask?.cancel()
    }
}
