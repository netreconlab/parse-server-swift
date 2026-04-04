// Fast trigger - quick validation
app.post("score", "save", "before", object: GameScore.self, trigger: .beforeSave) {
    req async throws -> ParseHookResponse<GameScore> in
    if let error: ParseHookResponse<GameScore> = checkHeaders(req) {
        return error
    }
    let parseRequest = try req.content
        .decode(ParseHookTriggerObjectRequest<User, GameScore>.self)
    
    guard let object = parseRequest.object else {
        return ParseHookResponse(error: .init(code: .missingObjectId,
                                              message: "Object not sent"))
    }
    
    // Quick validation - runs synchronously
    guard let points = object.points, points >= 0 else {
        return ParseHookResponse(error: .init(code: .validationError,
                                              message: "Invalid points"))
    }
    
    return ParseHookResponse(success: object)
}

// For long-running tasks, return success quickly
app.post("score", "save", "after", object: GameScore.self, trigger: .afterSave) {
    req async throws -> ParseHookResponse<Bool> in
    if let error: ParseHookResponse<Bool> = checkHeaders(req) {
        return error
    }
    
    // Return success immediately
    Task {
        // Long-running background task
        try? await performSlowAnalytics()
    }
    
    return ParseHookResponse(success: true)
}
