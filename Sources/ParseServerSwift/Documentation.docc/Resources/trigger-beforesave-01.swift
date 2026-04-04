app.post(
    "score",
    "save",
    "before",
    object: GameScore.self,
    trigger: .beforeSave
) { req async throws -> ParseHookResponse<GameScore> in
    if let error: ParseHookResponse<GameScore> = checkHeaders(req) {
        return error
    }
    var parseRequest = try req.content
        .decode(ParseHookTriggerObjectRequest<User, GameScore>.self)
    
    guard let object = parseRequest.object else {
        return ParseHookResponse(error: .init(code: .missingObjectId,
                                              message: "Object not sent in request."))
    }
    return ParseHookResponse(success: object)
}
