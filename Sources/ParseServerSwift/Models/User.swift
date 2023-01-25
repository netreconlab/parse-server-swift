//
//  User.swift
//
//
//  Created by Corey E. Baker on 6/20/22.
//

import Foundation
import ParseSwift

/**
 An example `ParseUser`. You will want to add custom
 properties to reflect the `ParseUser` on your Parse Server.
 */
struct User: ParseCloudUser {

    var authData: [String: [String: String]?]?
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    var sessionToken: String?
    var _failed_login_count: Int?
    var _account_lockout_expires_at: Date?
}
