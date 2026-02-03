app.on(
    "file",
    "save",
    "before",
    object: .file,
    trigger: .beforeSave
) { req async throws -> ParseHookResponse<Bool> in
    if let error: ParseHookResponse<Bool> = checkHeaders(req) {
        return error
    }
    
    let parseRequest = try req.content
        .decode(ParseHookTriggerRequest<User>.self)
    
    req.logger.info("A ParseFile is being saved: \(parseRequest)")
    
    // Return true to allow save, false to reject
    return ParseHookResponse(success: true)
}
