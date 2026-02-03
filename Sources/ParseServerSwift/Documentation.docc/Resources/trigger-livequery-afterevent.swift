app.post(
    "score",
    "event",
    "after",
    object: GameScore.self,
    trigger: .afterEvent
) { req async throws -> ParseHookResponse<Bool> in
    if let error: ParseHookResponse<Bool> = checkHeaders(req) {
        return error
    }
    
    let parseRequest = try req.content
        .decode(ParseHookTriggerObjectRequest<User, GameScore>.self)
    
    req.logger.info("A LiveQuery event occurred: \(parseRequest)")
    return ParseHookResponse(success: true)
}
