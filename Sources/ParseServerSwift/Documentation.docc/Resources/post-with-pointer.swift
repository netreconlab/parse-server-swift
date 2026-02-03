struct Post: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    var title: String?
    var content: String?
    var author: User?  // Pointer to User
    
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.title, original: object) {
            updated.title = object.title
        }
        if updated.shouldRestoreKey(\.content, original: object) {
            updated.content = object.content
        }
        if updated.shouldRestoreKey(\.author, original: object) {
            updated.author = object.author
        }
        return updated
    }
}
