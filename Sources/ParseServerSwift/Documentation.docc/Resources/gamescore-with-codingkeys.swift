struct GameScore: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    var points: Int?
    var playerName: String?
    
    // Map Swift names to database names
    enum CodingKeys: String, CodingKey {
        case objectId
        case createdAt
        case updatedAt
        case ACL
        case originalData
        case points
        case playerName = "player_name"  // Database uses snake_case
    }
    
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points, original: object) {
            updated.points = object.points
        }
        if updated.shouldRestoreKey(\.playerName, original: object) {
            updated.playerName = object.playerName
        }
        return updated
    }
}
