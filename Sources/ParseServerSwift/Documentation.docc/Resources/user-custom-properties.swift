struct User: ParseCloudUser {
    // Required properties...
    
    // Custom properties
    var displayName: String?
    var profilePicture: ParseFile?
    var level: Int?
    var lastLogin: Date?
}
