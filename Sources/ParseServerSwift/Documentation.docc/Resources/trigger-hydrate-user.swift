// Hydrate user if present
if parseRequest.user != nil {
    parseRequest = try await parseRequest.hydrateUser(request: req)
}

// Log user information
if let user = parseRequest.user {
    req.logger.info("User \(user.objectId ?? "unknown") is saving a score")
}
