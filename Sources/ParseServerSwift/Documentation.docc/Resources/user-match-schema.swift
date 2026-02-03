import Foundation
import ParseSwift

// Server-side User model must match database schema exactly
struct User: ParseCloudUser {
    // Required by ParseCloudUser
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
    
    // Add ALL custom properties from your Parse Server _User class
    var displayName: String?
    var profilePicture: ParseFile?
    var phoneNumber: String?
    var dateOfBirth: Date?
    var location: String?
    var preferences: [String: String]?
    
    // If your _User has a "level" column, add it here:
    var level: Int?
    
    // If your _User has a "subscription" column, add it here:
    var subscription: String?
}
