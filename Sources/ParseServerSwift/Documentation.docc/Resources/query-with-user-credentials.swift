// Get query options with user's credentials
let options = try parseRequest.options(req)

// Query using the user's permissions
let scores = try await GameScore.query.findAll(options: options)
req.logger.info("Scores this user can access: \(scores)")
