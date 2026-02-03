// Bool return type - indicates success (true) or failure (false)

// afterLogin trigger
app.post("user", "login", "after", object: User.self, trigger: .afterLogin) {
    req async throws -> ParseHookResponse<Bool> in
    return ParseHookResponse(success: true)
}

// afterSave trigger
app.post("score", "save", "after", object: GameScore.self, trigger: .afterSave) {
    req async throws -> ParseHookResponse<Bool> in
    return ParseHookResponse(success: true)
}

// afterDelete trigger
app.post("score", "delete", "after", object: GameScore.self, trigger: .afterDelete) {
    req async throws -> ParseHookResponse<Bool> in
    return ParseHookResponse(success: true)
}

// beforeConnect LiveQuery trigger
app.post("connect", "before", object: .liveQueryConnect, trigger: .beforeConnect) {
    req async throws -> ParseHookResponse<Bool> in
    return ParseHookResponse(success: true)
}

// beforeSubscribe LiveQuery trigger
app.post("score", "subscribe", "before", object: GameScore.self, trigger: .beforeSubscribe) {
    req async throws -> ParseHookResponse<Bool> in
    return ParseHookResponse(success: true)
}

// afterEvent LiveQuery trigger
app.post("score", "event", "after", object: GameScore.self, trigger: .afterEvent) {
    req async throws -> ParseHookResponse<Bool> in
    return ParseHookResponse(success: true)
}
