do {
    let result = try await somethingThatMightFail()
    return ParseHookResponse(success: result)
} catch {
    guard let parseError = error as? ParseError else {
        let error = ParseError(code: .otherCause, swift: error)
        return ParseHookResponse<String>(error: error)
    }
    return ParseHookResponse<String>(error: parseError)
}
