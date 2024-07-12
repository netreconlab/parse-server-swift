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
    func options(
        _ request: Request,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) throws -> API.Options {
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
     func hydrateUser(
        options: API.Options = [],
        request: Request,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
     ) async throws -> Self {
         var updatedOptions = try self.options(request, parseServerURLStrings: parseServerURLStrings)
         updatedOptions = options.union(updatedOptions)
         return try await self.hydrateUser(options: updatedOptions)
     }
}

extension ParseEncoder: ContentEncoder {

    public func encode<E>(_ encodable: E, to body: inout ByteBuffer, headers: inout HTTPHeaders) throws
        where E: Encodable
    {
        try self.encode(encodable, to: &body, headers: &headers, userInfo: [:])
    }

    public func encode<E>(_ encodable: E, to body: inout ByteBuffer, headers: inout HTTPHeaders, userInfo: [CodingUserInfoKey: Sendable]) throws
        where E: Encodable
    {
        headers.contentType = .json
        let jsonEncoder = User.getJSONEncoder()

        if !userInfo.isEmpty { // Changing a coder's userInfo is a thread-unsafe mutation, operate on a copy
            try body.writeBytes(JSONEncoder.custom(
                dates: jsonEncoder.dateEncodingStrategy,
                data: jsonEncoder.dataEncodingStrategy,
                keys: jsonEncoder.keyEncodingStrategy,
                format: jsonEncoder.outputFormatting,
                floats: jsonEncoder.nonConformingFloatEncodingStrategy,
                userInfo: jsonEncoder.userInfo.merging(userInfo) { $1 }
            ).encode(encodable))
        } else {
            if let parseEncodable = encodable as? ParseCloudTypeable {
                try body.writeBytes(self.encode(parseEncodable, skipKeys: .cloud))
            } else if let parseEncodable = encodable as? ParseEncodable {
                let skipKeys: SkipKeys
                if !ParseSwift.configuration.isRequiringCustomObjectIds {
                    skipKeys = .object
                } else {
                    skipKeys = .customObjectId
                }
                try body.writeBytes(self.encode(parseEncodable, skipKeys: skipKeys))
            } else {
                try body.writeBytes(jsonEncoder.encode(encodable))
            }

        }
    }
}
