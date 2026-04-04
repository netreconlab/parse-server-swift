import Vapor
import ParseServerSwift

public func configure(_ app: Application) async throws {
    // Initialize ParseServerSwift
    let configuration = try ParseServerConfiguration(
        app: app,
        hostName: "localhost",
        port: 8081,
        applicationId: "applicationId",
        primaryKey: "primaryKey",
        webhookKey: "webhookKey",
        parseServerURLString: "http://localhost:1337/parse"
    )
    try await ParseServerSwift.initialize(configuration, app: app)
    
    // Add any additional server configuration here...
    
    // Register routes
    try routes(app)
}
