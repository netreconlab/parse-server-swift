import Vapor

public func configure(_ app: Application) throws {
    // Initialize ParseServerSwift
    let configuration = try ParseServerConfiguration(app: app)
    try ParseServerSwift.initialize(configuration, app: app)
    
    // register routes
    try routes(app)
}
