app.post(
    "version",
    name: "version"
) { req async throws -> ParseHookResponse<String> in
    if let error: ParseHookResponse<String> = checkHeaders(req) {
        return error
    }
    var parseRequest = try req.content
        .decode(ParseHookFunctionRequest<User, FooParameters>.self)
    
    // Require user to be signed in
    guard parseRequest.user != nil else {
        let error = ParseError(code: .invalidSessionToken,
                               message: "User must be signed in to access server version")
        return ParseHookResponse<String>(error: error)
    }
    
    return ParseHookResponse(success: "1.0.0")
}
