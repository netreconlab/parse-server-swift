app.post(
    "score",
    "find",
    "before",
    object: GameScore.self,
    trigger: .beforeFind
) { req async throws -> ParseHookResponse<[GameScore]> in
    if let error: ParseHookResponse<[GameScore]> = checkHeaders(req) {
        return error
    }
    
    let parseRequest = try req.content
        .decode(ParseHookTriggerObjectRequest<User, GameScore>.self)
    
    req.logger.info("A query is being made: \(parseRequest)")
    
    // Return empty array to let query proceed normally
    return ParseHookResponse(success: [])
}
