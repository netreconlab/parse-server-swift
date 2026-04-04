//
//  ParseHookFunction+Vapor.swift
//  
//
//  Created by Corey Baker on 6/23/22.
//

import Foundation
import ParseSwift
import Vapor

// MARK: HookFunction - Internal
extension ParseHookFunction {

    @discardableResult
    static func method(_ method: HTTPMethod,
                       _ path: [PathComponent],
                       name: String,
                       parseServerURLStrings: [String]) async throws -> [String: Self] {
        let url = try buildServerPathname(path)
        let hookFunction = Self(name: name,
                                url: url)
        var hookFunctions = [String: Self]()

        for parseServerURLString in parseServerURLStrings {
            do {
                switch method {
                case .GET:
                    hookFunctions[parseServerURLString] = try await hookFunction
                        .fetch(options: [.serverURL(parseServerURLString)])
                case .POST:
                    hookFunctions[parseServerURLString] = try await hookFunction
                        .create(options: [.serverURL(parseServerURLString)])
                case .PUT:
                    hookFunctions[parseServerURLString] = try await hookFunction
                        .update(options: [.serverURL(parseServerURLString)])
                case .DELETE:
                    try await hookFunction
                        .delete(options: [.serverURL(parseServerURLString)])
                default:
                    throw ParseError(code: .otherCause,
                                     // swiftlint:disable:next line_length
                                     message: "Method \(method) is not supported for Hook Function: \"\(String(describing: hookFunction))\"")
                }
                // swiftlint:disable:next line_length
                configuration.logger.notice("Successful \(method); Hook Function: \"\(String(describing: hookFunction))\" on server: \(parseServerURLString)")
            } catch {
                if error.containedIn([.webhookError]) && method == .POST {
                    // swiftlint:disable:next line_length
                    configuration.logger.warning("Hook Function: \"\(String(describing: hookFunction))\"; warning: \(error); on server: \(parseServerURLString)")
                    try await Self.method(.DELETE,
                                          path,
                                          name: name,
                                          parseServerURLStrings: parseServerURLStrings)
                    return try await Self.method(method,
                                                 path,
                                                 name: name,
                                                 parseServerURLStrings: parseServerURLStrings)
                } else {
                    // swiftlint:disable:next line_length
                    configuration.logger.error("Could not \(method) Hook Function: \"\(String(describing: hookFunction))\"; error: \(error); on server: \(parseServerURLString)")
                }
            }
        }
        return hookFunctions
    }

}

// MARK: HookFunction - Fetch
public extension ParseHookFunction {

    /**
     Fetches a Parse Cloud Code hook function.
     - parameter path: A variadic list of paths.
     - parameter name: The name of the function.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create hook functions for.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookFunction`.
     - throws: An error of `ParseError` type.
     - note: WIll attempt to create functions on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetch(_ path: PathComponent...,
                      name: String,
                      parseServerURLStrings: [String]) async throws -> [String: Self] {
        try await fetch(path, name: name, parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Fetches a Parse Cloud Code hook function.
     - parameter path: An array of paths.
     - parameter name: The name of the function.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create hook functions for.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookFunction`.
     - throws: An error of `ParseError` type.
     - note: WIll attempt to create functions on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetch(_ path: [PathComponent],
                      name: String,
                      parseServerURLStrings: [String]) async throws -> [String: Self] {
        try await method(.PUT, path, name: name, parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Fetches all Parse Cloud Code hook function.
     - parameter path: A variadic list of paths.
     - parameter name: The name of the function.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create hook functions for.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookFunction`'s.
     - throws: An error of `ParseError` type.
     - note: WIll attempt to create functions on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetchAll(_ path: PathComponent...,
                         name: String,
                         parseServerURLStrings: [String]) async throws -> [String: [Self]] {
        try await fetchAll(path, name: name, parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Fetches all Parse Cloud Code hook function.
     - parameter path: An array of paths.
     - parameter name: The name of the function.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create hook functions for.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookFunction`'s.
     - throws: An error of `ParseError` type.
     - note: WIll attempt to create functions on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetchAll(_ path: [PathComponent],
                         name: String,
                         parseServerURLStrings: [String]) async throws -> [String: [Self]] {
        let url = try buildServerPathname(path)
        let hookFunction = Self(name: name,
                                        url: url)
        var hookFunctions = [String: [Self]]()

        for parseServerURLString in parseServerURLStrings {
            do {
                hookFunctions[parseServerURLString] = try await hookFunction
                    .fetchAll(options: [.serverURL(parseServerURLString)])
            } catch {
                // swiftlint:disable:next line_length
                configuration.logger.error("Could not fetchAll function: \"\(String(describing: hookFunction))\"; error: \(error); on server: \(parseServerURLString)")
            }
        }
        return hookFunctions
    }
}

// MARK: HookFunction - Create
public extension ParseHookFunction {

    /**
     Creates a Parse Cloud Code hook function.
     - parameter path: A variadic list of paths.
     - parameter name: The name of the function.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create hook functions for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookFunction`.
     - throws: An error of `ParseError` type.
     - note: WIll attempt to create functions on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func create(_ path: PathComponent...,
                       name: String,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await create(path, name: name, parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Creates a Parse Cloud Code hook function.
     - parameter path: An array of paths.
     - parameter name: The name of the function.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create hook functions for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookFunction`.
     - throws: An error of `ParseError` type.
     - note: WIll attempt to create functions on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func create(_ path: [PathComponent],
                       name: String,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await method(.POST, path, name: name, parseServerURLStrings: parseServerURLStrings)
    }
}

// MARK: HookFunction - Update
public extension ParseHookFunction {

    /**
     Updates a Parse Cloud Code hook function.
     - parameter path: A variadic list of paths.
     - parameter name: The name of the function.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create hook functions for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookFunction`.
     - throws: An error of `ParseError` type.
     - note: WIll attempt to create functions on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func update(_ path: PathComponent...,
                       name: String,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await update(path, name: name, parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Updates a Parse Cloud Code hook function.
     - parameter path: An array of paths.
     - parameter name: The name of the function.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create hook functions for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookFunction`.
     - throws: An error of `ParseError` type.
     - note: WIll attempt to create functions on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func update(_ path: [PathComponent],
                       name: String,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await method(.PUT, path, name: name, parseServerURLStrings: parseServerURLStrings)
    }
}

// MARK: HookFunction - Delete
public extension ParseHookFunction {

    /**
     Removes a Parse Cloud Code hook function.
     - parameter path: A variadic list of paths.
     - parameter name: The name of the function.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create hook functions for.
     Defaults to the set of servers added during configuration.
     - throws: An error of `ParseError` type.
     - note: WIll attempt to create functions on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func delete(_ path: PathComponent...,
                       name: String,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws {
        try await delete(path, name: name, parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Removes a Parse Cloud Code hook function.
     - parameter path: An array of paths.
     - parameter name: The name of the function.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create hook functions for.
     - throws: An error of `ParseError` type.
     Defaults to the set of servers added during configuration.
     - note: WIll attempt to create functions on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func delete(_ path: [PathComponent],
                       name: String,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws {
        try await method(.DELETE, path, name: name, parseServerURLStrings: parseServerURLStrings)
    }
}

// MARK: RoutesBuilder
public extension RoutesBuilder {
    /**
     Creates a new route for a Parse Cloud Code hook function.
     - parameter path: A variadic list of paths.
     - parameter name: The name of the function.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create hook functions for.
     - parameter hooks: An actor containing all of the current Hooks.
     - note: WIll attempt to create functions on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    func post<Response>(_ path: PathComponent...,
                        name: String,
                        use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable {
        self.on(path,
                name: name,
                use: closure)
    }

    /**
     Creates a new route for a Parse Cloud Code hook function.
     - parameter path: An array of paths.
     - parameter name: The name of the function.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create hook functions for.
     - parameter hooks: An actor containing all of the current Hooks.
     - note: WIll attempt to create functions on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    func post<Response>(_ path: [PathComponent],
                        name: String,
                        use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable {
        self.on(path,
                name: name,
                use: closure)
    }

    /**
     Creates a new route for a Parse Cloud Code hook function.
     - parameter path: A variadic list of paths.
     - parameter body: Determines how an incoming HTTP request’s body is collected.
     - parameter name: The name of the function.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create hook functions for.
     - parameter hooks: An actor containing all of the current Hooks.
     - note: WIll attempt to create functions on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    func on<Response>(_ path: PathComponent...,
                      body: HTTPBodyStreamStrategy = .collect,
                      name: String,
                      use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable {
        self.on(path,
                body: body,
                name: name,
                use: closure)
    }

    /**
     Creates a new route for a Parse Cloud Code hook function.
     - parameter path: An array of paths.
     - parameter body: Determines how an incoming HTTP request’s body is collected.
     - parameter name: The name of the function.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create hook functions for.
     - parameter hooks: An actor containing all of the current Hooks.
     - note: WIll attempt to create functions on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    func on<Response>(_ path: [PathComponent],
                      body: HTTPBodyStreamStrategy = .collect,
                      name: String,
                      use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable {
        let route = self.on(.POST, path, body: body, use: closure)
        Task {
            do {
                await configuration.hooks.updateFunctions(try await ParseHookFunction.create(route.path,
                                                                                             name: name))
            } catch {
                // swiftlint:disable:next line_length
                configuration.logger.error("Could not create HookFunction route for path: \(path); name: \(name) on servers: \(configuration.parseServerURLStrings) because of error: \(error)")
            }
        }
        return route
    }
}
