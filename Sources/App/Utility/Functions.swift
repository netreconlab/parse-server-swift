//
//  Functions.swift
//  
//
//  Created by Corey E. Baker on 6/21/22.
//

import ParseSwift
import Vapor

/**
 Checks headers for matching webhookKey to prove authenticity.
 - parameter req: The incoming request.
 - returns: **nil** if the webhookKeys match or a `ParseHookResponse`
 with an error that should be sent back to the Parse Server immediately.
 */
func checkHeaders<T>(_ req: Request) -> ParseHookResponse<T>? {
    guard req.headers.first(name: Headers.webhook) == webhookKey else {
        let error = ParseError(code: .unknownError,
                               message: "WebHook keys don't match")
        return ParseHookResponse<T>(error: error)
    }
    return nil
}

/**
 Register all Parse Hooks.
 */
func registerHooks() async {
    await registerFunctions()
    await registerTriggers()
}

/**
 Register all Parse Hook Functions.
 - note: Add all of your Parse Hook Functions in this method.
 */
func registerFunctions() async {
    do {
        let url = try buildServerPathname(["foo"])
        let hookFunction = HookFunction(name: "foo",
                                        url: url)
        do {
            _ = try await hookFunction.create()
        } catch {
            print("Could not create \"\(hookFunction)\" function: \(error)")
        }
    } catch {
        print("Could not create server path: \(error)")
    }
}

/**
 Register all Parse Hook Triggers.
 - note: Add all of your Parse Hook Triggers in this method.
 */
func registerTriggers() async {
    do {
        let url = try buildServerPathname(["bar"])
        let hookTrigger = HookTrigger(className: "GameScore",
                                      triggerName: .afterSave,
                                      url: url)
        do {
            _ = try await hookTrigger.create()
        } catch {
            print("Could not create \"\(hookTrigger)\" trigger: \(error)")
        }
    } catch {
        print("Could not create server path: \(error)")
    }
}

extension HTTPServer.Configuration {
    func buildServerURL() -> String {
        let scheme = tlsConfiguration == nil ? "http" : "https"
        let addressDescription: String
        switch address {
        case .hostname(let hostname, let port):
            addressDescription = "\(scheme)://\(hostname ?? self.hostname):\(port ?? self.port)"
        case .unixDomainSocket(let socketPath):
            addressDescription = "\(scheme)+unix: \(socketPath)"
        }
        return addressDescription
    }
}

func buildServerPathname(_ path: [PathComponent]) throws -> URL {
    let pathString = path.map { "\($0)" }.joined(separator: "/")
    guard let serverPathname = serverPathname,
          let url = URL(string: serverPathname)?.appendingPathComponent("/"+pathString) else {
        throw ParseError(code: .unknownError,
                         message: "Cannot create a pathname for the server")
    }
    return url
}
