import Foundation
import ParseSwift

// Every ParseObject must have these required properties
struct GameScore: ParseObject {
    // Required by ParseObject protocol
    var objectId: String?       // Unique identifier
    var createdAt: Date?         // Creation timestamp
    var updatedAt: Date?         // Last update timestamp
    var ACL: ParseACL?           // Access Control List
    var originalData: Data?      // Raw data from server
    
    // Your custom properties
    var points: Int?
    
    // Required merge method
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points, original: object) {
            updated.points = object.points
        }
        return updated
    }
}
