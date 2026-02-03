struct Post: ParseObject {
    // ... other properties
    
    var tags: [Tag]?  // Array of Tag objects
    var relatedPosts: [Post]?  // Array of other Posts
}
