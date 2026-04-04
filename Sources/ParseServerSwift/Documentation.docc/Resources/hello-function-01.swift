app.post(
    "hello",
    name: "hello"
) { req async throws -> ParseHookResponse<String> in
    // Check webhook key for security
    if let error: ParseHookResponse<String> = checkHeaders(req) {
        return error
    }
    
    // Decode the function request
    var parseRequest = try req.content
        .decode(ParseHookFunctionRequest<User, FooParameters>.self)
    
    // Return success response
    return ParseHookResponse(success: "Hello world!")
}
