struct Profile: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    var user: User?
    var profilePicture: ParseFile?
    var coverPhoto: ParseFile?
    var documents: [ParseFile]?
    
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.user, original: object) {
            updated.user = object.user
        }
        if updated.shouldRestoreKey(\.profilePicture, original: object) {
            updated.profilePicture = object.profilePicture
        }
        if updated.shouldRestoreKey(\.coverPhoto, original: object) {
            updated.coverPhoto = object.coverPhoto
        }
        if updated.shouldRestoreKey(\.documents, original: object) {
            updated.documents = object.documents
        }
        return updated
    }
}
