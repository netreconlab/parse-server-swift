import ParseSwift
import Vapor

/// The key used to authenticate incoming webhook calls from a Parse Server
var webhookKey: String?

/// The current Hook Functions and Triggers.
var hooks = Hooks()

/// All Parse Server URL strings to connect to.
var parseServerURLStrings = [String]()

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

    // Setup current host
    app.http.server.configuration.hostname = Environment.process.PARSE_SERVER_SWIFT_HOST_NAME ?? "localhost"
    app.http.server.configuration.port = Int(Environment.process.PARSE_SERVER_SWIFT_PORT ?? 8081)
    app.http.server.configuration.tlsConfiguration = .none
    serverPathname = buildServerURL(from: app.http.server.configuration)
    webhookKey = Environment.process.PARSE_SERVER_SWIFT_WEBHOOK_KEY

    // Increases the streaming body collection limit to 500kb
    app.routes.defaultMaxBodySize = ByteCount(stringLiteral: Environment.process.PARSE_SERVER_SWIFT_DEFAULT_MAX_BODY_SIZE ?? "500kb")

    // Parse uses tailored encoders/decoders. These can be retrieved from any ParseObject
    ContentConfiguration.global.use(encoder: User.getJSONEncoder(), for: .json)
    ContentConfiguration.global.use(decoder: User.getDecoder(), for: .json)

    // Required: Change to your Parse Server serverURL.
    let serverURLStrings = try getParseServerURLs()
    parseServerURLStrings.append(serverURLStrings.0)
    // Append all additional Parse Servers
    parseServerURLStrings.append(contentsOf: serverURLStrings.1)
    
    guard let parseServerURL = URL(string: serverURLStrings.0) else {
        throw ParseError(code: .otherCause,
                         message: "Could not make a URL from the Parse Server string")
    }

    // Initialize the Parse-Swift SDK. Add any additional parameters you need
    try ParseSwift.initialize(applicationId: Environment.process.PARSE_SERVER_SWIFT_APPLICATION_ID ?? "applicationId",
                              primaryKey: Environment.process.PARSE_SERVER_SWIFT_PRIMARY_KEY ?? "primaryKey",
                              serverURL: parseServerURL,
                              usingPostForQuery: true) { _, completionHandler in
        // Setup to use default certificate pinning. See Parse-Swift docs for more info
        completionHandler(.performDefaultHandling, nil)
    }
    
    if !isTesting {
        Task {
            do {
                // Check the health of all Parse-Server
                try await checkServerHealth(app)
            } catch {
                app.shutdown()
            }
        }
    }
    
    // register routes
    try routes(app)
}
