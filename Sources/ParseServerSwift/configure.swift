import Vapor

/**
 A helper method for configuring your `ParseServerSwift`. This should only be called once when starting your
 Vapor app.
 - parameter app: Core type representing a Vapor application.
 */
public func parseServerSwiftConfigure(_ app: Application) async throws {
    // Initialize ParseServerSwift
    let configuration = try ParseServerConfiguration(app: app)
    try await ParseServerSwift.initialize(configuration, app: app)

    // register routes
    try routes(app)
}
