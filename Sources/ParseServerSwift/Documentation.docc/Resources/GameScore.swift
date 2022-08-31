//
//  GameScore.swift
//  
//
//  Created by Corey Baker on 8/31/22.
//

import Foundation
import ParseSwift

/**
 An example `ParseObject`. This is for testing. You can
 remove when creating your application.
 */
struct GameScore: ParseObject {
    // These are required by ParseObject.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Your own properties.
    var points: Int?

    // Implement your own version of merge.
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points,
                                     original: object) {
            updated.points = object.points
        }
        return updated
    }
}
