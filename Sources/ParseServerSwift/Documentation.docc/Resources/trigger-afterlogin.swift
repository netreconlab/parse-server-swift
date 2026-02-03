app.post(
    "user",
    "login",
    "after",
    object: User.self,
    trigger: .afterLogin
) { req async throws -> ParseHookResponse<Bool> in
    if let error: ParseHookResponse<Bool> = checkHeaders(req) {
        return error
    }
    
    let parseRequest = try req.content
		// GameScore is used as dummy generic type here,
		// essentially any ParseObject can be used
		// for login related triggers.
        .decode(ParseHookTriggerObjectRequest<User, GameScore>.self)
    
    req.logger.info("A user has logged in: \(parseRequest)")
    
    // Return true to indicate success
    return ParseHookResponse(success: true)
}
