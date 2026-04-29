import Foundation

protocol RemoteDataSourceProtocol: Sendable {
    // Intentionally empty for v1. Methods will appear here when the app
    // gains a backend (preset sharing, cloud sync, etc.).
}

struct RemoteDataSource: RemoteDataSourceProtocol {}
