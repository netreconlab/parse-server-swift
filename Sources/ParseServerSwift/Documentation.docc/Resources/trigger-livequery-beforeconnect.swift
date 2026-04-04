app.post(
    "connect",
    "before",
    object: .liveQueryConnect,
    trigger: .beforeConnect
) { req async throws -> ParseHookResponse<Bool> in
    if let error: ParseHookResponse<Bool> = checkHeaders(req) {
        return error
    }
    
    let parseRequest = try req.content
        .decode(ParseHookTriggerRequest<User>.self)
    
    req.logger.info("A LiveQuery connection is being made: \(parseRequest)")
    
    // Return true to allow connection
    return ParseHookResponse(success: true)
}
