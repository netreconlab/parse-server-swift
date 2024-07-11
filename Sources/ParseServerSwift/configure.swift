import Vapor

/**
 A helper method for configuring your `ParseServerSwift`. This should only be called once when starting your
 Vapor app.
 - parameter app: Core type representing a Vapor application.
 - parameter configuration: A `ParseServerConfiguration`. If `nil`, the vapor
 environment variables will be used for configuration.
 */
public func parseServerSwiftConfigure(
    _ app: Application,
    configuration: ParseServerConfiguration? = nil
) async throws {
    // Initialize ParseServerSwift
    let configuration = try configuration ?? ParseServerConfiguration(app: app)
    try await ParseServerSwift.initialize(configuration, app: app)

    // register routes
    try routes(app)
}
