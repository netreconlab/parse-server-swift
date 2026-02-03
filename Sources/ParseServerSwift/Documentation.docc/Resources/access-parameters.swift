app.post(
    "hello",
    name: "hello"
) { req async throws -> ParseHookResponse<String> in
    if let error: ParseHookResponse<String> = checkHeaders(req) {
        return error
    }
    var parseRequest = try req.content
        .decode(ParseHookFunctionRequest<User, FooParameters>.self)
    
    // Access parameters
    if let foo = parseRequest.params?.foo {
        req.logger.info("Received foo parameter: \(foo)")
    }
    
    return ParseHookResponse(success: "Hello world!")
}
