import ParseSwift

struct User: ParseCloudUser {
    // ... required properties
    
    var friends: ParseRelation<User>?  // Many-to-many
    var followers: ParseRelation<User>?
}
