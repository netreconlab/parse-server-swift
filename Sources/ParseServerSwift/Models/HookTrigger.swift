//
//  HookTrigger.swift
//  
//
//  Created by Corey Baker on 6/23/22.
//

import Foundation
import ParseSwift
import Vapor

/**
 Parse Hook Triggers can be created by conforming to
 `ParseHookTriggerable`.
 */
public struct HookTrigger: ParseHookTriggerable {
    public var className: String?
    public var triggerName: ParseHookTriggerType?
    public var url: URL?

    public init() {}
}

// MARK: HookTrigger - Internal
extension HookTrigger {

    @discardableResult
    static func method(_ method: HTTPMethod,
                       _ path: [PathComponent],
                       className: String? = nil,
                       trigger: ParseHookTriggerType,
                       parseServerURLStrings: [String]) async throws -> [String: Self] {
        let url = try buildServerPathname(path)
        let hookTrigger: HookTrigger!
        var hookTriggers = [String: Self]()

        if let className = className {
            hookTrigger = HookTrigger(className: className,
                                      triggerName: trigger,
                                      url: url)
        } else {
            hookTrigger = try HookTrigger(triggerName: trigger,
                                          url: url)
        }

        for parseServerURLString in parseServerURLStrings {
            do {
                switch method {
                case .GET:
                    hookTriggers[parseServerURLString] = try await hookTrigger
                        .fetch(options: [.serverURL(parseServerURLString)])
                case .POST:
                    // swiftlint:disable:next line_length
                    hookTriggers[parseServerURLString] = try await hookTrigger.create(options: [.serverURL(parseServerURLString)])
                case .PUT:
                    hookTriggers[parseServerURLString] = try await hookTrigger
                        .update(options: [.serverURL(parseServerURLString)])
                case .DELETE:
                    try await hookTrigger
                        .delete(options: [.serverURL(parseServerURLString)])
                default:
                    throw ParseError(code: .otherCause,
                                     // swiftlint:disable:next line_length
                                     message: "Method \(method) is not supported for Hook Trigger: \"\(String(describing: hookTrigger))\"")
                }
                // swiftlint:disable:next line_length
                configuration.logger.notice("Successful \(method); Hook Trigger: \"\(String(describing: hookTrigger))\" on server: \(parseServerURLString)")
            } catch {
                if error.containedIn([.webhookError]) && method == .POST {
                    // swiftlint:disable:next line_length
                    configuration.logger.warning("Hook Trigger: \"\(String(describing: hookTrigger))\"; warning: \(error); on server: \(parseServerURLString)")
                    try await Self.method(.DELETE,
                                          path,
                                          className: className,
                                          trigger: trigger,
                                          parseServerURLStrings: parseServerURLStrings)
                    return try await Self.method(method,
                                                 path,
                                                 className: className,
                                                 trigger: trigger,
                                                 parseServerURLStrings: parseServerURLStrings)
                } else {
                    // swiftlint:disable:next line_length
                    configuration.logger.error("Could not \(method) Hook Trigger: \"\(String(describing: hookTrigger))\"; error: \(error); on server: \(parseServerURLString)")
                }
            }
        }
        return hookTriggers
    }
}

// MARK: HookTrigger - Fetch
public extension HookTrigger {

    /**
     Fetch a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetch<V: ParseObject>(_ path: PathComponent...,
                                      object: V.Type,
                                      trigger: ParseHookTriggerType,
                                      // swiftlint:disable:next line_length
                                      parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await fetch(path,
                        object: object,
                        trigger: trigger,
                        parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Fetch a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @available(*, deprecated, message: "Change \"triggerName\" to \"trigger\"")
    static func fetch(_ path: PathComponent...,
                      className: String? = nil,
                      triggerName: ParseHookTriggerType,
                      // swiftlint:disable:next line_length
                      parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await fetch(path,
                        className: className,
                        trigger: triggerName,
                        parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Fetch a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetch(_ path: PathComponent...,
                      className: String? = nil,
                      trigger: ParseHookTriggerType,
                      // swiftlint:disable:next line_length
                      parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await fetch(path,
                        className: className,
                        trigger: trigger,
                        parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Fetch a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetch<V: ParseObject>(_ path: [PathComponent],
                                      object: V.Type,
                                      trigger: ParseHookTriggerType,
                                      // swiftlint:disable:next line_length
                                      parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await fetch(path,
                        className: object.className,
                        trigger: trigger,
                        parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Fetch a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @available(*, deprecated, message: "Change \"triggerName\" to \"trigger\"")
    static func fetch(_ path: [PathComponent],
                      className: String? = nil,
                      triggerName: ParseHookTriggerType,
                      // swiftlint:disable:next line_length
                      parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await fetch(path,
                        className: className,
                        trigger: triggerName,
                        parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Fetch a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetch(_ path: [PathComponent],
                      className: String? = nil,
                      trigger: ParseHookTriggerType,
                      // swiftlint:disable:next line_length
                      parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await method(.GET,
                         path,
                         className: className,
                         trigger: trigger,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Fetch all Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`'s.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetchAll<V: ParseObject>(_ path: PathComponent...,
                                         object: V.Type,
                                         trigger: ParseHookTriggerType,
                                         // swiftlint:disable:next line_length
                                         parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: [Self]] {
        try await fetchAll(path,
                           object: object,
                           trigger: trigger,
                           parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Fetch all Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`'s.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @available(*, deprecated, message: "Change \"triggerName\" to \"trigger\"")
    static func fetchAll(_ path: PathComponent...,
                         className: String? = nil,
                         triggerName: ParseHookTriggerType,
                         // swiftlint:disable:next line_length
                         parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: [Self]] {
        try await fetchAll(path,
                           className: className,
                           trigger: triggerName,
                           parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Fetch all Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`'s.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetchAll(_ path: PathComponent...,
                         className: String? = nil,
                         trigger: ParseHookTriggerType,
                         // swiftlint:disable:next line_length
                         parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: [Self]] {
        try await fetchAll(path,
                           className: className,
                           trigger: trigger,
                           parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Fetch all Parse Cloud Code hook triggers.
     - parameter path: An array of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`'s.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetchAll<V: ParseObject>(_ path: [PathComponent],
                                         object: V.Type,
                                         trigger: ParseHookTriggerType,
                                         // swiftlint:disable:next line_length
                                         parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: [Self]] {
        try await fetchAll(path,
                           className: object.className,
                           trigger: trigger,
                           parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Fetch all Parse Cloud Code hook triggers.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`'s.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @available(*, deprecated, message: "Change \"triggerName\" to \"trigger\"")
    static func fetchAll(_ path: [PathComponent],
                         className: String? = nil,
                         triggerName: ParseHookTriggerType,
                         // swiftlint:disable:next line_length
                         parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: [Self]] {
        try await self.fetchAll(path,
                                className: className,
                                trigger: triggerName,
                                parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Fetch all Parse Cloud Code hook triggers.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`'s.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetchAll(_ path: [PathComponent],
                         className: String? = nil,
                         trigger: ParseHookTriggerType,
                         // swiftlint:disable:next line_length
                         parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: [Self]] {
        let url = try buildServerPathname(path)
        let hookTrigger: HookTrigger!
        var hookTriggers = [String: [Self]]()

        if let className = className {
            hookTrigger = Self(className: className,
                               triggerName: trigger,
                               url: url)
        } else {
            hookTrigger = try HookTrigger(triggerName: trigger,
                                          url: url)
        }
        for parseServerURLString in parseServerURLStrings {
            do {
                hookTriggers[parseServerURLString] = try await hookTrigger
                    .fetchAll(options: [.serverURL(parseServerURLString)])
            } catch {
                // swiftlint:disable:next line_length
                configuration.logger.error("Problem fetching all triggers: \"\(String(describing: hookTrigger))\"; error: \(error); on server: \(parseServerURLString)")
            }
        }
        return hookTriggers
    }
}

// MARK: HookTrigger - Create
public extension HookTrigger {

    /**
     Create a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func create<V: ParseObject>(_ path: PathComponent...,
                                       object: V.Type,
                                       trigger: ParseHookTriggerType,
                                       // swiftlint:disable:next line_length
                                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await create(path,
                         object: object,
                         trigger: trigger,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Create a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @available(*, deprecated, message: "Change \"triggerName\" to \"trigger\"")
    static func create(_ path: PathComponent...,
                       className: String? = nil,
                       triggerName: ParseHookTriggerType,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await create(path,
                         className: className,
                         trigger: triggerName,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Create a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func create(_ path: PathComponent...,
                       className: String? = nil,
                       trigger: ParseHookTriggerType,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await create(path,
                         className: className,
                         trigger: trigger,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Create a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func create<V: ParseObject>(_ path: [PathComponent],
                                       object: V.Type,
                                       trigger: ParseHookTriggerType,
                                       // swiftlint:disable:next line_length
                                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await create(path,
                         className: object.className,
                         trigger: trigger,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Create a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @available(*, deprecated, message: "Change \"triggerName\" to \"trigger\"")
    static func create(_ path: [PathComponent],
                       className: String? = nil,
                       triggerName: ParseHookTriggerType,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await self.create(path,
                              className: className,
                              trigger: triggerName,
                              parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Create a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func create(_ path: [PathComponent],
                       className: String? = nil,
                       trigger: ParseHookTriggerType,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await method(.POST,
                         path,
                         className: className,
                         trigger: trigger,
                         parseServerURLStrings: parseServerURLStrings)
    }

}

// MARK: HookTrigger - Update
public extension HookTrigger {

    /**
     Update a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func update<V: ParseObject>(_ path: PathComponent...,
                                       object: V.Type,
                                       trigger: ParseHookTriggerType,
                                       // swiftlint:disable:next line_length
                                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await update(path,
                         object: object,
                         trigger: trigger,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Update a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @available(*, deprecated, message: "Change \"triggerName\" to \"trigger\"")
    static func update(_ path: PathComponent...,
                       className: String? = nil,
                       triggerName: ParseHookTriggerType,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await update(path,
                         className: className,
                         trigger: triggerName,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Update a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func update(_ path: PathComponent...,
                       className: String? = nil,
                       trigger: ParseHookTriggerType,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await update(path,
                         className: className,
                         trigger: trigger,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Update a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func update<V: ParseObject>(_ path: [PathComponent],
                                       object: V.Type,
                                       trigger: ParseHookTriggerType,
                                       // swiftlint:disable:next line_length
                                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await update(path,
                         className: object.className,
                         trigger: trigger,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Update a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @available(*, deprecated, message: "Change \"triggerName\" to \"trigger\"")
    static func update(_ path: [PathComponent],
                       className: String? = nil,
                       triggerName: ParseHookTriggerType,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await update(path,
                         className: className,
                         trigger: triggerName,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Update a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func update(_ path: [PathComponent],
                       className: String? = nil,
                       trigger: ParseHookTriggerType,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws -> [String: Self] {
        try await method(.PUT,
                         path,
                         className: className,
                         trigger: trigger,
                         parseServerURLStrings: parseServerURLStrings)
    }

}

// MARK: HookTrigger - Delete
public extension HookTrigger {

    /**
     Delete a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to delete triggers for.
     Defaults to the set of servers added during configuration.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func delete<V: ParseObject>(_ path: PathComponent...,
                                       object: V.Type,
                                       trigger: ParseHookTriggerType,
                                       // swiftlint:disable:next line_length
                                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws {
        try await delete(path,
                         object: object,
                         trigger: trigger,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Delete a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to delete triggers for.
     Defaults to the set of servers added during configuration.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @available(*, deprecated, message: "Change \"triggerName\" to \"trigger\"")
    static func delete(_ path: PathComponent...,
                       className: String? = nil,
                       triggerName: ParseHookTriggerType,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws {
        try await delete(path,
                         className: className,
                         trigger: triggerName,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Delete a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to delete triggers for.
     Defaults to the set of servers added during configuration.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func delete(_ path: PathComponent...,
                       className: String? = nil,
                       trigger: ParseHookTriggerType,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws {
        try await delete(path,
                         className: className,
                         trigger: trigger,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Delete a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to delete triggers for.
     Defaults to the set of servers added during configuration.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func delete<V: ParseObject>(_ path: [PathComponent],
                                       object: V.Type,
                                       trigger: ParseHookTriggerType,
                                       // swiftlint:disable:next line_length
                                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws {
        try await delete(path,
                         className: object.className,
                         trigger: trigger,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Delete a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to delete triggers for.
     Defaults to the set of servers added during configuration.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @available(*, deprecated, message: "Change \"triggerName\" to \"trigger\"")
    static func delete(_ path: [PathComponent],
                       className: String? = nil,
                       triggerName: ParseHookTriggerType,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws {
        try await delete(path,
                         className: className,
                         trigger: triggerName,
                         parseServerURLStrings: parseServerURLStrings)
    }

    /**
     Delete a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to delete triggers for.
     Defaults to the set of servers added during configuration.
     - throws: An error of `ParseError` type.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func delete(_ path: [PathComponent],
                       className: String? = nil,
                       trigger: ParseHookTriggerType,
                       // swiftlint:disable:next line_length
                       parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings) async throws {
        try await method(.DELETE,
                         path,
                         className: className,
                         trigger: trigger,
                         parseServerURLStrings: parseServerURLStrings)
    }

}

// MARK: RoutesBuilder
public extension RoutesBuilder {

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     - parameter hooks: An actor containing all of the current Hooks.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    func post<Response, V>(_ path: PathComponent...,
                           object: V.Type,
                           trigger: ParseHookTriggerType,
                           use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable, V: ParseObject {
        self.on(path,
                object: object,
                trigger: trigger,
                use: closure)
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     - parameter hooks: An actor containing all of the current Hooks.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    @available(*, deprecated, message: "Change \"triggerName\" to \"trigger\"")
    func post<Response>(_ path: PathComponent...,
                        className: String? = nil,
                        triggerName: ParseHookTriggerType,
                        use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable {
        self.post(path,
                  className: className,
                  trigger: triggerName,
                  use: closure)
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     - parameter hooks: An actor containing all of the current Hooks.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    func post<Response>(_ path: PathComponent...,
                        className: String? = nil,
                        trigger: ParseHookTriggerType,
                        use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable {
        self.on(path,
                className: className,
                trigger: trigger,
                use: closure)
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter method: The method to use for the route.
     - parameter path: An array of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     - parameter hooks: An actor containing all of the current Hooks.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    func post<Response, V>(_ path: [PathComponent],
                           object: V.Type,
                           trigger: ParseHookTriggerType,
                           use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable, V: ParseObject {
        self.on(path,
                object: object,
                trigger: trigger,
                use: closure)
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter method: The method to use for the route.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     - parameter hooks: An actor containing all of the current Hooks.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    @available(*, deprecated, message: "Change \"triggerName\" to \"trigger\"")
    func post<Response>(_ path: [PathComponent],
                        className: String? = nil,
                        triggerName: ParseHookTriggerType,
                        use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable {
        self.post(path,
                  className: className,
                  trigger: triggerName,
                  use: closure)
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter method: The method to use for the route.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     - parameter hooks: An actor containing all of the current Hooks.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    func post<Response>(_ path: [PathComponent],
                        className: String? = nil,
                        trigger: ParseHookTriggerType,
                        use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable {
        self.on(path,
                className: className,
                trigger: trigger,
                use: closure)
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter body: Determines how an incoming HTTP request’s body is collected.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     - parameter hooks: An actor containing all of the current Hooks.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    func on<Response, V>(_ path: PathComponent...,
                         body: HTTPBodyStreamStrategy = .collect,
                         object: V.Type,
                         trigger: ParseHookTriggerType,
                         use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable, V: ParseObject {
        self.on(path,
                body: body,
                object: object,
                trigger: trigger,
                use: closure)
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter body: Determines how an incoming HTTP request’s body is collected.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     - parameter hooks: An actor containing all of the current Hooks.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    @available(*, deprecated, message: "Change \"triggerName\" to \"trigger\"")
    func on<Response>(_ path: PathComponent...,
                      body: HTTPBodyStreamStrategy = .collect,
                      className: String? = nil,
                      triggerName: ParseHookTriggerType,
                      use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable {
        self.on(path,
                body: body,
                className: className,
                trigger: triggerName,
                use: closure)
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter body: Determines how an incoming HTTP request’s body is collected.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     - parameter hooks: An actor containing all of the current Hooks.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    func on<Response>(_ path: PathComponent...,
                      body: HTTPBodyStreamStrategy = .collect,
                      className: String? = nil,
                      trigger: ParseHookTriggerType,
                      use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable {
    self.on(path,
            body: body,
            className: className,
            trigger: trigger,
            use: closure)
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter body: Determines how an incoming HTTP request’s body is collected.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     - parameter hooks: An actor containing all of the current Hooks.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    func on<Response, V>(_ path: [PathComponent],
                         body: HTTPBodyStreamStrategy = .collect,
                         object: V.Type,
                         trigger: ParseHookTriggerType,
                         use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable, V: ParseObject {
        self.on(path,
                body: body,
                className: object.className,
                trigger: trigger,
                use: closure)
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter body: Determines how an incoming HTTP request’s body is collected.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     - parameter hooks: An actor containing all of the current Hooks.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    @available(*, deprecated, message: "Change \"triggerName\" to \"trigger\"")
    func on<Response>(_ path: [PathComponent],
                      body: HTTPBodyStreamStrategy = .collect,
                      className: String? = nil,
                      triggerName: ParseHookTriggerType,
                      use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable {
        self.on(path,
                body: body,
                className: className,
                trigger: triggerName,
                use: closure)
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter body: Determines how an incoming HTTP request’s body is collected.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     - parameter hooks: An actor containing all of the current Hooks.
     - important: `className` should only be **nil** when creating `ParseFile` and
     `.beforeConnect` triggers.
     - note: WIll attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    func on<Response>(_ path: [PathComponent],
                      body: HTTPBodyStreamStrategy = .collect,
                      className: String? = nil,
                      trigger: ParseHookTriggerType,
                      use closure: @escaping (Request) async throws -> Response) -> Route
    where Response: AsyncResponseEncodable {
        let route = self.on(.POST, path, body: body, use: closure)
        Task {
            do {
                await configuration.hooks.updateTriggers(try await HookTrigger.create(path,
                                                                                      className: className,
                                                                                      trigger: trigger))
            } catch {
                if let className = className {
                    // swiftlint:disable:next line_length
                    configuration.logger.error("Could not create HookTrigger route for path: \(path); className: \(className); trigger: \(trigger) on servers: \(configuration.parseServerURLStrings) because of error: \(error)")
                } else {
                    // swiftlint:disable:next line_length
                    configuration.logger.error("Could not create HookTrigger route for path: \(path); trigger: \(trigger) on servers: \(configuration.parseServerURLStrings) because of error: \(error)")
                }
            }
        }
        return route
    }

}
