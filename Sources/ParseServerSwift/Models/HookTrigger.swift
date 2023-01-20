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
 `ParseHookFunctionable`.
 */
public struct HookTrigger: ParseHookTriggerable {
    public var className: String?
    public var triggerName: ParseHookTriggerType?
    public var url: URL?

    public init() {}
}

// MARK: RoutesBuilder
public extension RoutesBuilder {
    /**
     Creates a new route and for a Parse Cloud Code hook trigger.
     - parameter path: A variadic list of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter url: The endpoint of the hook.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for. Defaults to
     the set of servers added during configuration.
     - warning: `className` should only be **nil** when creating `ParseFile` and `.beforeConnect` triggers.
     */
    @discardableResult
    func post<Response>(
        _ path: PathComponent...,
        className: String? = nil,
        triggerName: ParseHookTriggerType,
        parseServerURLStrings: [String] = parseServerURLStrings,
        use closure: @escaping (Request) async throws -> Response
    ) -> Route
        where Response: AsyncResponseEncodable
    {
        do {
            let url = try buildServerPathname(path)
            let hookTrigger: HookTrigger!
            
            if let className = className {
                hookTrigger = HookTrigger(className: className,
                                          triggerName: triggerName,
                                          url: url)
            } else {
                hookTrigger = try HookTrigger(triggerName: triggerName,
                                              url: url)
            }
            
            Task {
                for parseServerURLString in parseServerURLStrings {
                    do {
                        _ = try await hookTrigger.create(options: [.serverURL(parseServerURLString)])
                    } catch {
                        if !error.equalsTo(.webhookError) {
                            logger.error("Could not create \"\(String(describing: hookTrigger))\" trigger: \(error)")
                        }
                    }
                }
            }
        } catch {
            logger.error("\(error)")
        }
        return self.post(path, use: closure)
    }

    /**
     Creates a new route and for a Parse Cloud Code hook trigger.
     - parameter path: An array of paths.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter triggerName: The `ParseHookTriggerType` type.
     - parameter url: The endpoint of the hook.
     - parameter parseServerURLStrings: A set of Parse Server `URL`'s to create triggers for. Defaults to
     the set of servers added during configuration.
     - warning: `className` should only be **nil** when creating `ParseFile` and `.beforeConnect` triggers.
     */
    @discardableResult
    func post<Response>(
        _ path: [PathComponent],
        className: String? = nil,
        triggerName: ParseHookTriggerType,
        parseServerURLStrings: [String] = parseServerURLStrings,
        use closure: @escaping (Request) async throws -> Response
    ) -> Route
        where Response: AsyncResponseEncodable
    {
        do {
            let url = try buildServerPathname(path)
            let hookTrigger: HookTrigger!
            
            if let className = className {
                hookTrigger = HookTrigger(className: className,
                                          triggerName: triggerName,
                                          url: url)
            } else {
                hookTrigger = try HookTrigger(triggerName: triggerName,
                                              url: url)
            }
            Task {
                for parseServerURLString in parseServerURLStrings {
                    do {
                        _ = try await hookTrigger.create(options: [.serverURL(parseServerURLString)])
                    } catch {
                        if !error.equalsTo(.webhookError) {
                            logger.error("Could not create \"\(String(describing: hookTrigger))\" trigger: \(error)")
                        }
                    }
                }
            }
        } catch {
            logger.error("\(error)")
        }
        return self.post(path, use: closure)
    }
}
