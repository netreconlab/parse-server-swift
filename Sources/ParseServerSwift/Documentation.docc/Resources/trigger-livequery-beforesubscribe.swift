app.post(
    "score",
    "subscribe",
    "before",
    object: GameScore.self,
    trigger: .beforeSubscribe
) { req async throws -> ParseHookResponse<Bool> in
    if let error: ParseHookResponse<Bool> = checkHeaders(req) {
        return error
    }
    
    let parseRequest = try req.content
        .decode(ParseHookTriggerObjectRequest<User, GameScore>.self)
    
    req.logger.info("A LiveQuery subscription is being made: \(parseRequest)")
    return ParseHookResponse(success: true)
}
