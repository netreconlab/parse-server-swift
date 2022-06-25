//
//  User.swift
//  
//
//  Created by Corey E. Baker on 6/20/22.
//

import Foundation
import ParseSwift
import Vapor

/**
 An example `ParseUser`. You will want to replace this
 with your version of `ParseUser`.
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
}
