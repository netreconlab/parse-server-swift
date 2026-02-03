struct GameScore: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    // Add as many custom properties as you need
    var points: Int?
    var playerName: String?
    var cheatMode: Bool?
    var level: Int?
    var score: Double?
    var achievements: [String]?
    
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points, original: object) {
            updated.points = object.points
        }
        if updated.shouldRestoreKey(\.playerName, original: object) {
            updated.playerName = object.playerName
        }
        if updated.shouldRestoreKey(\.cheatMode, original: object) {
            updated.cheatMode = object.cheatMode
        }
        if updated.shouldRestoreKey(\.level, original: object) {
            updated.level = object.level
        }
        if updated.shouldRestoreKey(\.score, original: object) {
            updated.score = object.score
        }
        if updated.shouldRestoreKey(\.achievements, original: object) {
            updated.achievements = object.achievements
        }
        return updated
    }
}
