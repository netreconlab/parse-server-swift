app.post(
    "score",
    "save",
    "before",
    object: GameScore.self,
    trigger: .beforeSave
) { req async throws -> ParseHookResponse<GameScore> in
    // Check webhook key
    if let error: ParseHookResponse<GameScore> = checkHeaders(req) {
        return error
    }
    
    // Decode the trigger request
    var parseRequest = try req.content
        .decode(ParseHookTriggerObjectRequest<User, GameScore>.self)
    
    // Get the object being saved
    guard let object = parseRequest.object else {
        return ParseHookResponse(error: .init(code: .missingObjectId,
                                              message: "Object not sent in request."))
    }
    
    // Return the object to allow save
    return ParseHookResponse(success: object)
}
