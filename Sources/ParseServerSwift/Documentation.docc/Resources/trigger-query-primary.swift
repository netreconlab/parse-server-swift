// Query using primary key
let scores = try await GameScore.query.findAll(options: [.usePrimaryKey])
req.logger.info("All scores (bypassing ACLs): \(scores)")
