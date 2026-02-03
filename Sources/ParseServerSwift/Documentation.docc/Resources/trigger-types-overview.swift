// afterSave trigger - runs after an object is saved
app.post("score", "save", "after", object: GameScore.self, trigger: .afterSave) {
    req async throws -> ParseHookResponse<Bool> in
    // Log or perform post-save actions
    return ParseHookResponse(success: true)
}

// beforeDelete trigger - runs before an object is deleted
app.post("score", "delete", "before", object: GameScore.self, trigger: .beforeDelete) {
    req async throws -> ParseHookResponse<Bool> in
    // Validate deletion is allowed
    return ParseHookResponse(success: true)
}

// afterDelete trigger - runs after an object is deleted
app.post("score", "delete", "after", object: GameScore.self, trigger: .afterDelete) {
    req async throws -> ParseHookResponse<Bool> in
    // Clean up related data
    return ParseHookResponse(success: true)
}

// beforeFind trigger - can modify queries before execution
app.post("score", "find", "before", object: GameScore.self, trigger: .beforeFind) {
    req async throws -> ParseHookResponse<[GameScore]> in
    // Modify query or return custom results
    return ParseHookResponse(success: [])
}

// afterFind trigger - can modify results after execution
app.post("score", "find", "after", object: GameScore.self, trigger: .afterFind) {
    req async throws -> ParseHookResponse<[GameScore]> in
    // Transform results before sending to client
    return ParseHookResponse(success: [])
}
