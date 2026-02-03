// Check if a score with these points already exists
let existingScores = try await GameScore.query
    .where("points" == object.points)
    .findAll(options: [.usePrimaryKey])

if !existingScores.isEmpty {
    let error = ParseError(code: .duplicateValue,
                           message: "A score with these points already exists")
    return ParseHookResponse<GameScore>(error: error)
}
