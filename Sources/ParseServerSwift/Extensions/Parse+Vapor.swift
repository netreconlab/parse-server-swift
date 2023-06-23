//
//  Parse+Vapor.swift
//  
//
//  Created by Corey E. Baker on 6/20/22.
//

import Vapor
import ParseSwift

extension ParseHookFunctionRequest: Content {}
extension ParseHookTriggerRequest: Content {}
extension ParseHookResponse: Content {}
public extension ParseHookRequestable {
    /**
     Produce the set of options that should be used for subsequent `ParseHook` requests.
     - parameter request: The HTTP request of the application.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s.
     to check the `URI` against. Defaults to the set of servers added during configuration.
     - returns: The set of options produced by the current request.
     - throws: An error of `ParseError` type.
     - note: This options method should be used in a multi Parse Server environment.
     In a single Parse Server environment, use options().
     */
    func options(_ request: Request,
                 // swiftlint:disable:next line_length
                 parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) throws -> API.Options {
        var options = self.options()
        options.insert(.serverURL(try serverURLString(request.url,
                                                      parseServerURLStrings: parseServerURLStrings)))
        return options
    }

    /**
     Fetches the complete `ParseUser` *aynchronously*  from the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter request: The HTTP request of the application.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s.
     Defaults to the set of servers added during configuration.
     - returns: Returns the `ParseHookRequestable` with the hydrated `ParseCloudUser`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     */
     func hydrateUser(options: API.Options = [],
                      request: Request,
                      // swiftlint:disable:next line_length
                      parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> Self {
         var updatedOptions = try self.options(request, parseServerURLStrings: parseServerURLStrings)
         updatedOptions = options.union(updatedOptions)
         return try await withCheckedThrowingContinuation { continuation in
             self.hydrateUser(options: updatedOptions,
                              completion: continuation.resume)
         }
     }
}
