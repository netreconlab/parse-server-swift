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
struct HookTrigger: ParseHookTriggerable {
    var className: String?
    var triggerName: ParseHookTriggerType?
    var url: URL?
}

// MARK: RoutesBuilder
extension RoutesBuilder {
    @discardableResult
    public func post<Response>(
        _ path: PathComponent...,
        className: String,
        triggerName: ParseHookTriggerType,
        use closure: @escaping (Request) async throws -> Response
    ) -> Route
        where Response: AsyncResponseEncodable
    {
        do {
            let url = try buildServerPathname(path)
            let hookTrigger = HookTrigger(className: className,
                                          triggerName: triggerName,
                                          url: url)
            Task {
                do {
                    _ = try await hookTrigger.create()
                } catch {
                    if !error.equalsTo(.invalidImageData) {
                        print("Could not create \"\(hookTrigger)\" trigger: \(error)")
                    }
                }
            }
        } catch {
            print(error)
        }
        return self.post(path, use: closure)
    }

    @discardableResult
    public func post<Response>(
        _ path: [PathComponent],
        className: String,
        triggerName: ParseHookTriggerType,
        use closure: @escaping (Request) async throws -> Response
    ) -> Route
        where Response: AsyncResponseEncodable
    {
        do {
            let url = try buildServerPathname(path)
            let hookTrigger = HookTrigger(className: className,
                                          triggerName: .afterSave,
                                          url: url)
            Task {
                do {
                    _ = try await hookTrigger.create()
                } catch {
                    if !error.equalsTo(.invalidImageData) {
                        print("Could not create \"\(hookTrigger)\" trigger: \(error)")
                    }
                }
            }
        } catch {
            print(error)
        }
        return self.post(path, use: closure)
    }
}
