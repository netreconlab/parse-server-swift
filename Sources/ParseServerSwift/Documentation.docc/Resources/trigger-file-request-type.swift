// File triggers use ParseHookTriggerRequest<User> instead of ParseHookTriggerObjectRequest
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
    
    // Decode ParseHookTriggerRequest instead of ParseHookTriggerObjectRequest
    let parseRequest = try req.content
        .decode(ParseHookTriggerRequest<User>.self)
    
    // Access user information if available
    if let user = parseRequest.user {
        req.logger.info("File uploaded by user: \(user.objectId ?? "unknown")")
    }
    
    req.logger.info("A ParseFile is being saved: \(parseRequest)")
    return ParseHookResponse(success: true)
}
