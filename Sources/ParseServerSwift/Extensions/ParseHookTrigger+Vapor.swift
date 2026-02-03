//
//  ParseHookTrigger+Vapor.swift
//  
//
//  Created by Corey Baker on 6/23/22.
//

import Foundation
import ParseSwift
import Vapor

// MARK: HookTrigger - Internal
extension ParseHookTrigger {

	@discardableResult
	static func method<V: ParseObject>(
		_ method: HTTPMethod,
		_ path: [PathComponent],
		object: V.Type,
		trigger: ParseHookTriggerType,
		parseServerURLStrings: [String]
	) async throws -> [String: Self] {
		let url = try buildServerPathname(path)
		_ = try Self(
			object: ParseHookTriggerObject.objectType(object),
			trigger: trigger,
			url: url
		)
		return try await Self.method(
			method,
			path,
			className: object.className,
			trigger: trigger,
			parseServerURLStrings: parseServerURLStrings
		)
	}

	@discardableResult
	static func method(
		_ method: HTTPMethod,
		_ path: [PathComponent],
		object: ParseHookTriggerObject,
		trigger: ParseHookTriggerType,
		parseServerURLStrings: [String]
	) async throws -> [String: Self] {
		let url = try buildServerPathname(path)
		_ = try Self(
			object: object,
			trigger: trigger,
			url: url
		)
		return try await Self.method(
			method,
			path,
			className: object.className,
			trigger: trigger,
			parseServerURLStrings: parseServerURLStrings
		)
	}

    @discardableResult
    static func method( // swiftlint:disable:this function_body_length
        _ method: HTTPMethod,
        _ path: [PathComponent],
        className: String,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String]
    ) async throws -> [String: Self] {
        let url = try buildServerPathname(path)
		let hookTrigger = Self(
			className: className,
			trigger: trigger,
			url: url
		)
		var hookTriggers = [String: Self]()

        for parseServerURLString in parseServerURLStrings {
            do {
                switch method {
                case .GET:
                    hookTriggers[parseServerURLString] = try await hookTrigger
                        .fetch(
							options: [.serverURL(parseServerURLString)]
						)
                case .POST:
                    hookTriggers[parseServerURLString] = try await hookTrigger
						.create(
							options: [
								.serverURL(parseServerURLString)
							]
						)
                case .PUT:
                    hookTriggers[parseServerURLString] = try await hookTrigger
                        .update(
							options: [.serverURL(parseServerURLString)]
						)
                case .DELETE:
                    try await hookTrigger
                        .delete(
							options: [.serverURL(parseServerURLString)]
						)
                default:
                    throw ParseError(
						code: .otherCause,
						message: "Method \(method) is not supported for Hook Trigger: \"\(String(describing: hookTrigger))\""
					)
                }
                configuration.logger.notice(
					"Successful \(method); Hook Trigger: \"\(String(describing: hookTrigger))\" on server: \(parseServerURLString)"
				)
            } catch {
                if error.containedIn([.webhookError]) && method == .POST {
                    configuration.logger.warning(
						"Hook Trigger: \"\(String(describing: hookTrigger))\"; warning: \(error); on server: \(parseServerURLString)"
					)
					do {
						try await Self.method(
							.DELETE,
							path,
							className: className,
							trigger: trigger,
							parseServerURLStrings: [parseServerURLString]
						)
					} catch {
						configuration.logger.warning(
							"Hook Trigger: \"\(String(describing: hookTrigger))\"; warning: \(error); on server: \(parseServerURLString)"
						)
					}
                    return try await Self.method(
						method,
						path,
						className: className,
						trigger: trigger,
						parseServerURLStrings: [parseServerURLString]
					)
                } else {
                    configuration.logger.error(
						// swiftlint:disable:next line_length
						"Could not \(method) Hook Trigger: \"\(String(describing: hookTrigger))\"; error: \(error); on server: \(parseServerURLString)"
					)
                }
            }
        }
        return hookTriggers
    }
}

// MARK: HookTrigger - Fetch
public extension ParseHookTrigger {

    /**
     Fetch a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetch<V: ParseObject>(
		_ path: PathComponent...,
		object: V.Type,
		trigger: ParseHookTriggerType,
		parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
	) async throws -> [String: Self] {
        try await fetch(
			path,
			object: object,
			trigger: trigger,
			parseServerURLStrings: parseServerURLStrings
		)
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
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetch(
		_ path: PathComponent...,
		className: String,
		trigger: ParseHookTriggerType,
		parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
	) async throws -> [String: Self] {
        try await fetch(
			path,
			className: className,
			trigger: trigger,
			parseServerURLStrings: parseServerURLStrings
		)
    }

	/**
	 Fetch a Parse Cloud Code hook trigger.
	 - parameter path: A variadic list of paths.
	 - parameter object: The `ParseHookTriggerObject` the trigger should act on.
	 - parameter trigger: The `ParseHookTriggerType` type.
	 - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
	 Defaults to the set of servers added during configuration.
	 - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
	 - throws: An error of `ParseError` type.
	 - note: Will attempt to create triggers on all `parseServerURLStrings`.
	 Will log an error for each `parseServerURLString` that returns an error.
	 */
	static func fetch(
		_ path: PathComponent...,
		object: ParseHookTriggerObject,
		trigger: ParseHookTriggerType,
		parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
	) async throws -> [String: Self] {
		try await fetch(
			path,
			object: object,
			trigger: trigger,
			parseServerURLStrings: parseServerURLStrings
		)
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
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetch<V: ParseObject>(
        _ path: [PathComponent],
        object: V.Type,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: Self] {
		try await method(
			.GET,
			path,
			object: object,
			trigger: trigger,
			parseServerURLStrings: parseServerURLStrings
		)
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
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetch(
        _ path: [PathComponent],
        className: String,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: Self] {
        try await method(
			.GET,
			path,
			className: className,
			trigger: trigger,
			parseServerURLStrings: parseServerURLStrings
		)
    }

    /**
     Fetch a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter object: The `ParseHookTriggerObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetch(
        _ path: [PathComponent],
        object: ParseHookTriggerObject,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: Self] {
        try await method(
            .GET,
            path,
			object: object,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
    }

    /**
     Fetch all Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter object: The `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`'s.
     - throws: An error of `ParseError` type.
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetchAll<V: ParseObject>(
        _ path: PathComponent...,
        object: V.Type,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: [Self]] {
        try await fetchAll(
            path,
            object: object,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
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
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetchAll(
        _ path: PathComponent...,
        className: String,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: [Self]] {
        try await fetchAll(
            path,
            className: className,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
    }

	/**
	 Fetch all Parse Cloud Code hook trigger.
	 - parameter path: A variadic list of paths.
	 - parameter object: The `ParseHookTriggerObject` the trigger should act on.
	 - parameter trigger: The `ParseHookTriggerType` type.
	 - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
	 Defaults to the set of servers added during configuration.
	 - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`'s.
	 - throws: An error of `ParseError` type.
	 - note: Will attempt to create triggers on all `parseServerURLStrings`.
	 Will log an error for each `parseServerURLString` that returns an error.
	 */
	static func fetchAll(
		_ path: PathComponent...,
		object: ParseHookTriggerObject,
		trigger: ParseHookTriggerType,
		parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
	) async throws -> [String: [Self]] {
		try await fetchAll(
			path,
			object: object,
			trigger: trigger,
			parseServerURLStrings: parseServerURLStrings
		)
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
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetchAll<V: ParseObject>(
        _ path: [PathComponent],
        object: V.Type,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: [Self]] {
        try await fetchAll(
            path,
            className: object.className,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
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
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetchAll(
        _ path: [PathComponent],
        className: String,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: [Self]] {
        let url = try buildServerPathname(path)
		let hookTrigger = Self(
			className: className,
			trigger: trigger,
			url: url
		)
		var hookTriggers = [String: [Self]]()

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

    /**
     Fetch all Parse Cloud Code hook triggers.
     - parameter path: An array of paths.
     - parameter object: The `ParseHookTriggerObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`'s.
     - throws: An error of `ParseError` type.
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func fetchAll(
        _ path: [PathComponent],
        object: ParseHookTriggerObject,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: [Self]] {
        let url = try buildServerPathname(path)
        let hookTrigger = try Self(
			object: object,
            trigger: trigger,
            url: url
        )
        var hookTriggers = [String: [Self]]()

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
public extension ParseHookTrigger {

    /**
     Create a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func create<V: ParseObject>(
        _ path: PathComponent...,
        object: V.Type,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: Self] {
        try await create(
            path,
            object: object,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
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
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func create(
        _ path: PathComponent...,
        className: String,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: Self] {
        try await create(
            path,
            className: className,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
    }

	/**
	 Create a Parse Cloud Code hook trigger.
	 - parameter path: A variadic list of paths.
	 - parameter object: The `ParseHookTriggerObject` the trigger should act on.
	 - parameter trigger: The `ParseHookTriggerType` type.
	 - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
	 Defaults to the set of servers added during configuration.
	 - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
	 - throws: An error of `ParseError` type.
	 - note: Will attempt to create triggers on all `parseServerURLStrings`.
	 Will log an error for each `parseServerURLString` that returns an error.
	 */
	static func create(
		_ path: PathComponent...,
		object: ParseHookTriggerObject,
		trigger: ParseHookTriggerType,
		parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
	) async throws -> [String: Self] {
		try await create(
			path,
			object: object,
			trigger: trigger,
			parseServerURLStrings: parseServerURLStrings
		)
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
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func create<V: ParseObject>(
        _ path: [PathComponent],
        object: V.Type,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: Self] {
		try await method(
			.POST,
			path,
			object: object,
			trigger: trigger,
			parseServerURLStrings: parseServerURLStrings
		)
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
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func create(
        _ path: [PathComponent],
        className: String,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: Self] {
        try await method(
            .POST,
            path,
            className: className,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
    }

    /**
     Create a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter object: The`ParseHookTriggerObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func create(
        _ path: [PathComponent],
        object: ParseHookTriggerObject,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: Self] {
        try await method(
            .POST,
            path,
			object: object,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
    }
}

// MARK: HookTrigger - Update
public extension ParseHookTrigger {

    /**
     Update a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func update<V: ParseObject>(
        _ path: PathComponent...,
        object: V.Type,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: Self] {
        try await update(
            path,
            object: object,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
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
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func update(
        _ path: PathComponent...,
        className: String,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: Self] {
        try await update(
            path,
            className: className,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
    }

	/**
	 Update a Parse Cloud Code hook trigger.
	 - parameter path: A variadic list of paths.
	 - parameter object: The `ParseHookTriggerObject` the trigger should act on.
	 - parameter trigger: The `ParseHookTriggerType` type.
	 - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
	 Defaults to the set of servers added during configuration.
	 - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
	 - throws: An error of `ParseError` type.
	 - note: Will attempt to create triggers on all `parseServerURLStrings`.
	 Will log an error for each `parseServerURLString` that returns an error.
	 */
	static func update(
		_ path: PathComponent...,
		object: ParseHookTriggerObject,
		trigger: ParseHookTriggerType,
		parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
	) async throws -> [String: Self] {
		try await update(
			path,
			object: object,
			trigger: trigger,
			parseServerURLStrings: parseServerURLStrings
		)
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
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func update<V: ParseObject>(
        _ path: [PathComponent],
        object: V.Type,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: Self] {
		try await method(
			.PUT,
			path,
			object: object,
			trigger: trigger,
			parseServerURLStrings: parseServerURLStrings
		)
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
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func update(
        _ path: [PathComponent],
        className: String,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: Self] {
        try await method(
            .PUT,
            path,
            className: className,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
    }

    /**
     Update a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter object: The`ParseHookTriggerObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for.
     Defaults to the set of servers added during configuration.
     - returns: A dictionary where the keys are Parse Server `URL`'s and the respective `HookTrigger`.
     - throws: An error of `ParseError` type.
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func update(
        _ path: [PathComponent],
        object: ParseHookTriggerObject,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws -> [String: Self] {
        try await method(
            .PUT,
            path,
			object: object,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
    }
}

// MARK: HookTrigger - Delete
public extension ParseHookTrigger {

    /**
     Delete a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to delete triggers for.
     Defaults to the set of servers added during configuration.
     - throws: An error of `ParseError` type.
     - note: Will attempt to delete triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func delete<V: ParseObject>(
        _ path: PathComponent...,
        object: V.Type,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws {
        try await delete(
            path,
            object: object,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
    }

    /**
     Delete a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to delete triggers for.
     Defaults to the set of servers added during configuration.
     - throws: An error of `ParseError` type.
     - note: Will attempt to delete triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func delete(
        _ path: PathComponent...,
        className: String,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws {
        try await delete(
            path,
            className: className,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
    }

	/**
	 Delete a Parse Cloud Code hook trigger.
	 - parameter path: A variadic list of paths.
	 - parameter object: The `ParseHookTriggerObject` the trigger should act on.
	 - parameter trigger: The `ParseHookTriggerType` type.
	 - parameter parseServerURLStrings: A set of Parse Server `URL`'s to delete triggers for.
	 Defaults to the set of servers added during configuration.
	 - throws: An error of `ParseError` type.
	 - note: Will attempt to delete triggers on all `parseServerURLStrings`.
	 Will log an error for each `parseServerURLString` that returns an error.
	 */
	static func delete(
		_ path: PathComponent...,
		object: ParseHookTriggerObject,
		trigger: ParseHookTriggerType,
		parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
	) async throws {
		try await delete(
			path,
			object: object,
			trigger: trigger,
			parseServerURLStrings: parseServerURLStrings
		)
	}

    /**
     Delete a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to delete triggers for.
     Defaults to the set of servers added during configuration.
     - throws: An error of `ParseError` type.
     - note: Will attempt to delete triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func delete<V: ParseObject>(
        _ path: [PathComponent],
        object: V.Type,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws {
		try await method(
			.DELETE,
			path,
			object: object,
			trigger: trigger,
			parseServerURLStrings: parseServerURLStrings
		)
    }

    /**
     Delete a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to delete triggers for.
     Defaults to the set of servers added during configuration.
     - throws: An error of `ParseError` type.
     - note: Will attempt to delete triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func delete(
        _ path: [PathComponent],
        className: String,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws {
        try await method(
            .DELETE,
            path,
            className: className,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
    }

    /**
     Delete a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter object: The `ParseHookTriggerObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to delete triggers for.
     Defaults to the set of servers added during configuration.
     - throws: An error of `ParseError` type.
     - note: Will attempt to delete triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    static func delete(
        _ path: [PathComponent],
        object: ParseHookTriggerObject,
        trigger: ParseHookTriggerType,
        parseServerURLStrings: [String] = ParseServerSwift.configuration.parseServerURLStrings
    ) async throws {
        try await method(
            .DELETE,
            path,
			object: object,
            trigger: trigger,
            parseServerURLStrings: parseServerURLStrings
        )
    }
}

// MARK: RoutesBuilder
public extension RoutesBuilder {

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter closure: A closure that takes as input an HTTP `Request` and returns a `Response`.
     */
    @discardableResult
    func post<Response, V>(
        _ path: PathComponent...,
        object: V.Type,
        trigger: ParseHookTriggerType,
        use closure: @escaping @Sendable (Request) async throws -> Response
    ) -> Route
    where Response: AsyncResponseEncodable, V: ParseObject {
        self.on(
            path,
            object: object,
            trigger: trigger,
            use: closure
        )
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter closure: A closure that takes as input an HTTP `Request` and returns a `Response`.
     - note: Will attempt to create triggers on all `parseServerURLStrings`.
     Will log an error for each `parseServerURLString` that returns an error.
     */
    @discardableResult
    func post<Response>(
        _ path: PathComponent...,
        className: String,
        trigger: ParseHookTriggerType,
        use closure: @escaping @Sendable (Request) async throws -> Response
    ) -> Route
    where Response: AsyncResponseEncodable {
        self.on(
            path,
            className: className,
            trigger: trigger,
            use: closure
        )
    }

	/**
	 Creates a new route for a Parse Cloud Code hook trigger.
	 - parameter path: A variadic list of paths.
	 - parameter object: The `ParseHookTriggerObject` the trigger should act on.
	 - parameter trigger: The `ParseHookTriggerType` type.
	 - parameter closure: A closure that takes as input an HTTP `Request` and returns a `Response`.
	 */
	@discardableResult
	func post<Response>(
		_ path: PathComponent...,
		object: ParseHookTriggerObject,
		trigger: ParseHookTriggerType,
		use closure: @escaping @Sendable (Request) async throws -> Response
	) -> Route
	where Response: AsyncResponseEncodable {
		self.on(
			path,
			object: object,
			trigger: trigger,
			use: closure
		)
	}

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter closure: A closure that takes as input an HTTP `Request` and returns a `Response`.
     */
    @discardableResult
    func post<Response, V>(
        _ path: [PathComponent],
        object: V.Type,
        trigger: ParseHookTriggerType,
        use closure: @escaping @Sendable (Request) async throws -> Response
    ) -> Route
    where Response: AsyncResponseEncodable, V: ParseObject {
        self.on(
            path,
            object: object,
            trigger: trigger,
            use: closure
        )
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter closure: A closure that takes as input an HTTP `Request` and returns a `Response`.
     */
    @discardableResult
    func post<Response>(
        _ path: [PathComponent],
        className: String,
        trigger: ParseHookTriggerType,
        use closure: @escaping @Sendable (Request) async throws -> Response
    ) -> Route where Response: AsyncResponseEncodable {
        self.on(
            path,
            className: className,
            trigger: trigger,
            use: closure
        )
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter object: The `ParseHookTriggerObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter closure: A closure that takes as input an HTTP `Request` and returns a `Response`.
     */
    @discardableResult
    func post<Response>(
        _ path: [PathComponent],
        object: ParseHookTriggerObject,
        trigger: ParseHookTriggerType,
        use closure: @escaping @Sendable (Request) async throws -> Response
    ) -> Route where Response: AsyncResponseEncodable {
        self.on(
            path,
			object: object,
            trigger: trigger,
            use: closure
        )
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter body: Determines how an incoming HTTP request’s body is collected.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter closure: A closure that takes as input an HTTP `Request` and returns a `Response`.
     */
    @discardableResult
    func on<Response, V>(
        _ path: PathComponent...,
        body: HTTPBodyStreamStrategy = .collect,
        object: V.Type,
        trigger: ParseHookTriggerType,
        use closure: @escaping @Sendable (Request) async throws -> Response
    ) -> Route
    where Response: AsyncResponseEncodable, V: ParseObject {
        self.on(
            path,
            body: body,
            object: object,
            trigger: trigger,
            use: closure
        )
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter body: Determines how an incoming HTTP request’s body is collected.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter closure: A closure that takes as input an HTTP `Request` and returns a `Response`.
     */
    @discardableResult
    func on<Response>(
        _ path: PathComponent...,
        body: HTTPBodyStreamStrategy = .collect,
        className: String,
        trigger: ParseHookTriggerType,
        use closure: @escaping @Sendable (Request) async throws -> Response
    ) -> Route where Response: AsyncResponseEncodable {
		self.on(
			path,
            body: body,
            className: className,
            trigger: trigger,
            use: closure
		)
    }

	/**
	 Creates a new route for a Parse Cloud Code hook trigger.
	 - parameter path: A variadic list of paths.
	 - parameter body: Determines how an incoming HTTP request’s body is collected.
	 - parameter object: The `ParseHookTriggerObject` the trigger should act on.
	 - parameter trigger: The `ParseHookTriggerType` type.
	 - parameter closure: A closure that takes as input an HTTP `Request` and returns a `Response`.
	 */
	@discardableResult
	func on<Response>(
		_ path: PathComponent...,
		body: HTTPBodyStreamStrategy = .collect,
		object: ParseHookTriggerObject,
		trigger: ParseHookTriggerType,
		use closure: @escaping @Sendable (Request) async throws -> Response
	) -> Route where Response: AsyncResponseEncodable {
		self.on(
			path,
			body: body,
			object: object,
			trigger: trigger,
			use: closure
		)
	}

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter body: Determines how an incoming HTTP request’s body is collected.
     - parameter object: The type of `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter closure: A closure that takes as input an HTTP `Request` and returns a `Response`.
     */
    @discardableResult
    func on<Response, V>(
        _ path: [PathComponent],
        body: HTTPBodyStreamStrategy = .collect,
        object: V.Type,
        trigger: ParseHookTriggerType,
        use closure: @escaping @Sendable (Request) async throws -> Response
    ) -> Route where Response: AsyncResponseEncodable, V: ParseObject {
		let route = self.on(.POST, path, body: body, use: closure)
		Task {
			do {
				await configuration.hooks.updateTriggers(
					try await ParseHookTrigger.create(
						route.path,
						object: object,
						trigger: trigger
					)
				)
			} catch {
				// swiftlint:disable:next line_length
				configuration.logger.error("Could not create HookTrigger route for path: \(path); className: \(object.className); trigger: \(trigger) on servers: \(configuration.parseServerURLStrings) because of error: \(error)")
			}
		}
		return route
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter body: Determines how an incoming HTTP request’s body is collected.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter closure: A closure that takes as input an HTTP `Request` and returns a `Response`.
     */
    @discardableResult
    func on<Response>(
        _ path: [PathComponent],
        body: HTTPBodyStreamStrategy = .collect,
        className: String,
        trigger: ParseHookTriggerType,
        use closure: @escaping @Sendable (Request) async throws -> Response
    ) -> Route where Response: AsyncResponseEncodable {
        let route = self.on(.POST, path, body: body, use: closure)
        Task {
            do {
                await configuration.hooks.updateTriggers(
					try await ParseHookTrigger.create(
						route.path,
						className: className,
						trigger: trigger
					)
				)
            } catch {
				// swiftlint:disable:next line_length
				configuration.logger.error("Could not create HookTrigger route for path: \(path); className: \(className); trigger: \(trigger) on servers: \(configuration.parseServerURLStrings) because of error: \(error)")
            }
        }
        return route
    }

    /**
     Creates a new route for a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter body: Determines how an incoming HTTP request’s body is collected.
     - parameter object: The `ParseHookTriggerObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter closure: A closure that takes as input an HTTP `Request` and returns a `Response`.
     */
    @discardableResult
    func on<Response>(
        _ path: [PathComponent],
        body: HTTPBodyStreamStrategy = .collect,
        object: ParseHookTriggerObject,
        trigger: ParseHookTriggerType,
        use closure: @escaping @Sendable (Request) async throws -> Response
    ) -> Route where Response: AsyncResponseEncodable {
		let route = self.on(.POST, path, body: body, use: closure)
		Task {
			do {
				await configuration.hooks.updateTriggers(
					try await ParseHookTrigger.create(
						route.path,
						object: object,
						trigger: trigger
					)
				)
			} catch {
				// swiftlint:disable:next line_length
				configuration.logger.error("Could not create HookTrigger route for path: \(path); className: \(object.className); trigger: \(trigger) on servers: \(configuration.parseServerURLStrings) because of error: \(error)")
			}
		}
		return route
    }
}
