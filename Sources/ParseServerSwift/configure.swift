import Leaf
import ParseSwift
import Vapor

/// The key used to authenticate incoming webhook calls from a Parse Server
var webhookKey: String? = "webhookKey" // Change to match your Parse Server's webhookKey or comment out.

/// The current address of ParseServerSwift.
var serverPathname: String!

/// The current Hook Functions and Triggers.
public var hooks = Hooks()

/// All Parse Server URL strings to connect to.
public var parseServerURLStrings = [String]()

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

func checkServerHealth(_ app: Application) async {
    for parseServerURLString in parseServerURLStrings {
        do {
            let serverHealth = try await ParseHealth.check(options: [.serverURL(parseServerURLString)])
            app.logger.notice("Parse Server (\(parseServerURLString)) health is \"\(serverHealth)\"")
        } catch {
            app.logger.error("Could not connect to Parse Server (\(parseServerURLString)): \(error)")
        }
    }
}

/// Delete all Parse Hooks from all Parse Servers.
public func deleteHooks(_ app: Application) async {
    let functions = await hooks.getFunctions()
    let triggers = await hooks.getTriggers()
    
    app.logger.notice("Deleting Hooks from all Parse Servers, please wait...")
    
    for (urlString, function) in functions {
        do {
            try await function.delete(options: [.serverURL(urlString)])
            app.logger.notice("Successfully removed Hook Function: \(function); on Parse Server: (\(urlString))")
        } catch {
            app.logger.error("Could not remove Hook Function: \(function); on Parse Server: (\(urlString)); due to error: \(error)")
        }
        await hooks.removeFunctions([urlString])
    }

    for (urlString, trigger) in triggers {
        do {
            try await trigger.delete(options: [.serverURL(urlString)])
            app.logger.notice("Successfully removed Hook Trigger: \(trigger); on Parse Server: (\(urlString))")
        } catch {
            app.logger.error("Could not remove Hook Trigger: \(trigger); on Parse Server: (\(urlString)); due to error: \(error)")
        }
        await hooks.removeTriggers([urlString])
    }
}
