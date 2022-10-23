import Leaf
import ParseSwift
import Vapor

/// The key used to authenticate incoming webhook calls from a Parse Server
let webhookKey: String? = "webhookKey" // Change to match your Parse Server's webhookKey or comment out.

/// The current address of ParseServerSwift.
var serverPathname: String!

let logger = Logger(label: "edu.parseserverswift")

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.views.use(.leaf)
    // Change to your specific hostname or comment out to use default.
    // app.http.server.configuration.hostname = "4threconbn.cs.uky.edu"
    app.http.server.configuration.port = 8081
    app.http.server.configuration.tlsConfiguration = .none
    serverPathname = app.http.server.configuration.buildServerURL()

    // Parse uses tailored encoders/decoders. These can be retreived from any ParseObject.
    ContentConfiguration.global.use(encoder: User.getJSONEncoder(), for: .json)
    ContentConfiguration.global.use(decoder: User.getDecoder(), for: .json)

    // Required: Change to your Parse Server serverURL.
    guard let parseServerUrl = URL(string: "http://localhost:1337/1") else {
        throw ParseError(code: .unknownError,
                         message: "Could not make Parse Server URL")
    }

    // Initialize the Parse-Swift SDK
    ParseSwift.initialize(applicationId: "applicationId", // Required: Change to your applicationId.
                          clientKey: "clientKey", // Required: Change to your clientKey.
                          primaryKey: "primaryKey", // Required: Change to your primaryKey.
                          serverURL: parseServerUrl,
                          usingPostForQuery: true) { _, completionHandler in
        completionHandler(.performDefaultHandling, nil)
    }

    Task {
        do {
            let parseHealth = try await ParseHealth.check()
            app.logger.notice("Parse Server (\(parseServerUrl.absoluteString)) health is \"\(parseHealth)\"")
        } catch {
            app.logger.error("Could not connect to Parse Server (\(parseServerUrl)): \(error)")
        }
    }

    // register routes
    try routes(app)
}
