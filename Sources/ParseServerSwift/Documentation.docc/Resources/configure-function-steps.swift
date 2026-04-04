// The parseServerSwiftConfigure function automates the setup process

// Step 1: Reads environment variables
// - PARSE_SERVER_SWIFT_URLS
// - PARSE_SERVER_SWIFT_APPLICATION_ID
// - PARSE_SERVER_SWIFT_PRIMARY_KEY
// - PARSE_SERVER_SWIFT_WEBHOOK_KEY
// - PARSE_SERVER_SWIFT_HOST_NAME (optional)
// - PARSE_SERVER_SWIFT_PORT (optional)

// Step 2: Initializes the Parse Swift SDK
ParseSwift.initialize(
    applicationId: "appId",
    clientKey: nil,
    primaryKey: "primaryKey",
    serverURL: URL(string: "http://parse:1337/parse")!,
    usingPostForQuery: true
)

// Step 3: Configures the Vapor application
app.http.server.configuration.hostname = "cloud-code"
app.http.server.configuration.port = 8080

// Step 4: Registers your routes (passed via the 'using' parameter)
try exampleRoutes(app)

// Step 5: Sets up webhook endpoints for Parse Server
// All Cloud Code Functions and Triggers are automatically registered
