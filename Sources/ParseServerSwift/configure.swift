import Leaf
import ParseSwift
import Vapor

/// The key used to authenticate incoming webhook calls from a Parse Server
public var webhookKey: String? = "webhookKey" // Change to match your Parse Server's webhookKey or comment out.

/// The current Hook Functions and Triggers.
public var hooks = Hooks()

/// All Parse Server URL strings to connect to.
public var parseServerURLStrings = [String]()

/// The current address of ParseServerSwift.
var serverPathname: String!

var isTesting = false

let logger = Logger(label: "edu.parseserverswift")

/// Configures your application
public func configure(_ app: Application) throws {
    try configure(app, testing: false)
}

func configure(_ app: Application, testing: Bool) throws {
    isTesting = testing
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.views.use(.leaf)
    // Change to your specific hostname or comment out to use default.
    // app.http.server.configuration.hostname = "4threconbn.cs.uky.edu"
    app.http.server.configuration.port = 8081
    app.http.server.configuration.tlsConfiguration = .none
    // Increases the streaming body collection limit to 500kb
    app.routes.defaultMaxBodySize = "500kb"
    serverPathname = app.http.server.configuration.buildServerURL()

    // Parse uses tailored encoders/decoders. These can be retreived from any ParseObject.
    ContentConfiguration.global.use(encoder: User.getJSONEncoder(), for: .json)
    ContentConfiguration.global.use(decoder: User.getDecoder(), for: .json)

    // Required: Change to your Parse Server serverURL.
    guard let parseServerURL = URL(string: "http://localhost:1337/1") else {
        throw ParseError(code: .otherCause,
                         message: "Could not make Parse Server URL")
    }

    // Initialize the Parse-Swift SDK
    try ParseSwift.initialize(applicationId: "applicationId", // Required: Change to your applicationId.
                              clientKey: "clientKey", // Required: Change to your clientKey.
                              primaryKey: "primaryKey", // Required: Change to your primaryKey.
                              serverURL: parseServerURL,
                              usingPostForQuery: true) { _, completionHandler in
        completionHandler(.performDefaultHandling, nil)
    }
    
    parseServerURLStrings.append(parseServerURL.absoluteString)
    // Append all other Parse Servers
    // parseServerURLStrings.append("http://parse:1337/1")
    
    if !isTesting {
        Task {
            await checkServerHealth(app)
        }
    }

    // register routes
    try routes(app)
}
