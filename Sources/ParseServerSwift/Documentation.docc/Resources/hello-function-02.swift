app.post(
    "hello",
    name: "hello"
) { req async throws -> ParseHookResponse<String> in
    if let error: ParseHookResponse<String> = checkHeaders(req) {
        return error
    }
    var parseRequest = try req.content
        .decode(ParseHookFunctionRequest<User, FooParameters>.self)
    
    // Hydrate the user if present
    if parseRequest.user != nil {
        parseRequest = try await parseRequest.hydrateUser(request: req)
    }
    
    return ParseHookResponse(success: "Hello world!")
}
