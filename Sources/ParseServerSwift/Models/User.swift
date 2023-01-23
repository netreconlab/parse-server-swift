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
public struct User: ParseCloudUser {

    public var authData: [String: [String: String]?]?
    public var username: String?
    public var email: String?
    public var emailVerified: Bool?
    public var password: String?
    public var objectId: String?
    public var createdAt: Date?
    public var updatedAt: Date?
    public var ACL: ParseACL?
    public var originalData: Data?
    public var sessionToken: String?
    public var _failed_login_count: Int?
    public var _account_lockout_expires_at: Date?
    
    public init() { }
}
