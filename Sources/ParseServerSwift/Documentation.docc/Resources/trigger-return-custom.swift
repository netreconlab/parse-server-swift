// Create custom scores to return
let score1 = GameScore(objectId: "yolo",
                       createdAt: Date(),
                       points: 50)
let score2 = GameScore(objectId: "nolo",
                       createdAt: Date(),
                       points: 60)

req.logger.info("""
    Returning custom objects from Cloud Code instead of querying:
    \(score1); \(score2)
""")

return ParseHookResponse(success: [score1, score2])
