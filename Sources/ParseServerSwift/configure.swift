import Vapor

public func configure(_ app: Application) async throws {
    // Initialize ParseServerSwift
    let configuration = try ParseServerConfiguration(app: app)
    try await ParseServerSwift.initialize(configuration, app: app)

    // register routes
    try routes(app)
}
