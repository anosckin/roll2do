import Foundation

final class DataSourceContainer: Sendable {
    static let shared = DataSourceContainer()

    let local: LocalDataSourceProtocol
    let remote: RemoteDataSourceProtocol

    init(
        local: LocalDataSourceProtocol = LocalDataSource(stack: .shared),
        remote: RemoteDataSourceProtocol = RemoteDataSource()
    ) {
        self.local = local
        self.remote = remote
    }
}
