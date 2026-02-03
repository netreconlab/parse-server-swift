// Query using the primary key to bypass ACLs
let allScores = try await GameScore.query.findAll(options: [.usePrimaryKey])
req.logger.info("All scores (bypassing ACLs): \(allScores)")
