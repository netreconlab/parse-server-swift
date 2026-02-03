// String response
func stringFunction() -> ParseHookResponse<String> {
    return ParseHookResponse(success: "Hello world!")
}

// Int response
func numberFunction() -> ParseHookResponse<Int> {
    return ParseHookResponse(success: 42)
}

// Bool response
func boolFunction() -> ParseHookResponse<Bool> {
    return ParseHookResponse(success: true)
}

// ParseObject response
func objectFunction() -> ParseHookResponse<GameScore> {
    let score = GameScore(objectId: "abc123", createdAt: Date(), points: 100)
    return ParseHookResponse(success: score)
}

// Array response
func arrayFunction() -> ParseHookResponse<[GameScore]> {
    let scores = [GameScore(objectId: "abc123", createdAt: Date(), points: 100)]
    return ParseHookResponse(success: scores)
}
