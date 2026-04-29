import Foundation

protocol SettingsRepositoryProtocol: Sendable {
    func get() async -> Settings
    func update(_ settings: Settings) async throws
    func settingsStream() async -> AsyncStream<Settings>
}

struct SettingsRepository: SettingsRepositoryProtocol {
    private let local: LocalDataSourceProtocol
    private let remote: RemoteDataSourceProtocol

    init() {
        local = DataSourceContainer.shared.local
        remote = DataSourceContainer.shared.remote
    }

    func get() async -> Settings {
        await local.getSingleton(Settings.self)
    }

    func update(_ settings: Settings) async throws {
        try await local.setSingleton(settings)
    }

    func settingsStream() async -> AsyncStream<Settings> {
        await local.observeSingleton(Settings.self)
    }
}
