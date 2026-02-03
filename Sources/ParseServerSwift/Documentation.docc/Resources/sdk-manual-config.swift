// This is done automatically by parseServerSwiftConfigure
guard let parseServerURL = URL(string: "http://localhost:1337/parse") else {
    throw ParseError(code: .unknownError,
                     message: "Could not make Parse Server URL")
}

// Initialize the Parse-Swift SDK
ParseSwift.initialize(
    applicationId: "applicationId",
    clientKey: "clientKey",
    primaryKey: "primaryKey",
    serverURL: parseServerURL,
    usingPostForQuery: true
)
