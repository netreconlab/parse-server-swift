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
extension ParseHookRequestable {
    /**
     Produce the set of options that should be used for subsequent `ParseHook` requests.
     - parameter request: The HTTP request of the application.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s
     to check the `URI` against. Defaults to the set of servers added during configuration.
     - returns: The set of options produced by the current request.
     - throws: An error of `ParseError` type.
     - note: This options method should be used in a multi Parse Server environment.
     In a single Parse Server environment, use options().
     */
    public func options(_ request: Request,
                        parseServerURLStrings: [String] = parseServerURLStrings) throws -> API.Options {
        var options = self.options()
        options.insert(.serverURL(try serverURLString(request.url,
                                                      parseServerURLStrings: parseServerURLStrings)))
        return options
    }
}
