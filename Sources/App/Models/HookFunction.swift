//
//  HookFunction.swift
//  
//
//  Created by Corey Baker on 6/23/22.
//

import Foundation
import ParseSwift
import Vapor

/**
 Parse Hook Functions can be created by conforming to
 `ParseHookFunctionable`.
 */
struct HookFunction: ParseHookFunctionable {
    var functionName: String?
    var url: URL?
}

// MARK: RoutesBuilder
extension RoutesBuilder {
    @discardableResult
    public func post<Response>(
        _ path: PathComponent...,
        name: String,
        use closure: @escaping (Request) async throws -> Response
    ) -> Route
        where Response: AsyncResponseEncodable
    {
        do {
            let url = try buildServerPathname(path)
            let hookFunction = HookFunction(name: name,
                                            url: url)
            Task {
                do {
                    _ = try await hookFunction.create()
                } catch {
                    if !error.equalsTo(.invalidImageData) {
                        print("Could not create \"\(hookFunction)\" function: \(error)")
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
        name: String,
        triggerName: ParseHookTriggerType,
        use closure: @escaping (Request) async throws -> Response
    ) -> Route
        where Response: AsyncResponseEncodable
    {
        do {
            let url = try buildServerPathname(path)
            let hookFunction = HookFunction(name: name,
                                            url: url)
            Task {
                do {
                    _ = try await hookFunction.create()
                } catch {
                    if !error.equalsTo(.invalidImageData) {
                        print("Could not create \"\(hookFunction)\" function: \(error)")
                    }
                }
            }
        } catch {
            print(error)
        }
        return self.post(path, use: closure)
    }
}
