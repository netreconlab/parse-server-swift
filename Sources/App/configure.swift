import Leaf
import ParseSwift
import Vapor

var webhookKey: String? = "webhookKey" // Change to your Parse Server's webhookKey or comment out.
var serverPathname: String? // The current address of ParseServerSwift.

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.views.use(.leaf)
    // Change to your specific hostname or comment out to use default.
    // app.http.server.configuration.hostname = "4threconbn.cs.uky.edu"
    app.http.server.configuration.port = 8081
    serverPathname = app.http.server.configuration.buildServerURL()
    ContentConfiguration.global.use(encoder: User.getJSONEncoder(), for: .json)
    ContentConfiguration.global.use(decoder: User.getDecoder(), for: .json)

    // Initialize the Parse-Swift SDK
    ParseSwift.initialize(applicationId: "applicationId", // Change to your applicationId
                          clientKey: "clientKey", // Change to your clientKey
                          masterKey: "masterKey", // Change to your masterKey
                          serverURL: URL(string: "http://localhost:1337/1")!, // Change to your serverURL
                          allowingCustomObjectIds: false,
                          usingEqualQueryConstraint: false) { _, completionHandler in
        completionHandler(.performDefaultHandling, nil)
    }

    Task {
        do {
            print("Parse Server health is \"\(try await ParseHealth.check())\"")
        } catch {
            print("Could not connect to Parse Server: \(error)")
        }
    }

    // register routes
    try routes(app)
}
