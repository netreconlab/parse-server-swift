app.post(
    "file",
    "delete",
    "before",
    object: .file,
    trigger: .beforeDelete
) { req async throws -> ParseHookResponse<Bool> in
    if let error: ParseHookResponse<Bool> = checkHeaders(req) {
        return error
    }
    
    let parseRequest = try req.content
        .decode(ParseHookTriggerRequest<User>.self)
    
    req.logger.info("A ParseFile is being deleted: \(parseRequest)")
    return ParseHookResponse(success: true)
}
