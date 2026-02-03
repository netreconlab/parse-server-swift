do {
    // Validate session by hydrating user
    parseRequest = try await parseRequest.hydrateUser(request: req)
} catch {
    guard let parseError = error as? ParseError else {
        let error = ParseError(code: .otherCause, swift: error)
        return ParseHookResponse<String>(error: error)
    }
    return ParseHookResponse<String>(error: parseError)
}
