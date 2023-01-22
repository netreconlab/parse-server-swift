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
public func checkHeaders<T>(_ req: Request) -> ParseHookResponse<T>? {
    guard req.headers.first(name: Headers.webhook) == webhookKey else {
        let error = ParseError(code: .otherCause,
                               message: "Webhook keys don't match")
        return ParseHookResponse<T>(error: error)
    }
    return nil
}

/**
 Returns the correct Parse Server `URL` string related to a particular `URI`.
 - parameter uri: The `URI` to check against.
 - parameter parseServerURLStrings: A set of Parse Server `URL`'s
 to check the `URI` against. Defaults to the set of servers added during configuration.
 - returns: The the Parse Server `URL` string related to a `URI`.
 - throws: An error of `ParseError` type.
 */
public func serverURLString(_ uri: URI,
                            parseServerURLStrings: [String] = parseServerURLStrings) throws -> String {
    guard let returnURLString = parseServerURLStrings.first else {
        throw ParseError(code: .otherCause,
                         message: "Missing at least one Parse Server URL")
    }
    return parseServerURLStrings.first(where: { uri.string.contains($0) }) ?? returnURLString
}

/**
 Construct the full server pathname with route.
 - returns: The server path with scheme, hostname, port, and route.
 */
public func buildServerPathname(_ path: [PathComponent]) throws -> URL {
    let pathString = "/" + path.map { "\($0)" }.joined(separator: "/")
    guard let serverPathname = serverPathname,
          let url = URL(string: serverPathname)?.appendingPathComponent(pathString) else {
        throw ParseError(code: .otherCause,
                         message: "Cannot create a pathname for the server")
    }
    return url
}

/// Check the Health of all Parse Servers.
/// - parameter app: Core type representing a Vapor application.
public func checkServerHealth(_ app: Application) async {
    for parseServerURLString in parseServerURLStrings {
        do {
            let serverHealth = try await ParseHealth.check(options: [.serverURL(parseServerURLString)])
            app.logger.notice("Parse Server (\(parseServerURLString)) health is \"\(serverHealth)\"")
        } catch {
            app.logger.error("Could not connect to Parse Server (\(parseServerURLString)): \(error)")
        }
    }
}

/// Delete all Parse Hooks from all Parse Servers.
/// - parameter app: Core type representing a Vapor application.
public func deleteHooks(_ app: Application) async {
    let functions = await hooks.getFunctions()
    let triggers = await hooks.getTriggers()
    
    app.logger.notice("Deleting Hooks from all Parse Servers, please wait...")
    
    for (urlString, function) in functions {
        do {
            try await function.delete(options: [.serverURL(urlString)])
            app.logger.notice("Successfully removed Hook Function: \(function); on Parse Server: (\(urlString))")
        } catch {
            app.logger.error("Could not remove Hook Function: \(function); on Parse Server: (\(urlString)); due to error: \(error)")
        }
        await hooks.removeFunctions([urlString])
    }

    for (urlString, trigger) in triggers {
        do {
            try await trigger.delete(options: [.serverURL(urlString)])
            app.logger.notice("Successfully removed Hook Trigger: \(trigger); on Parse Server: (\(urlString))")
        } catch {
            app.logger.error("Could not remove Hook Trigger: \(trigger); on Parse Server: (\(urlString)); due to error: \(error)")
        }
        await hooks.removeTriggers([urlString])
    }
}

extension HTTPServer.Configuration {
    /**
     Construct the full server pathname.
     - returns: The server path with scheme, hostname, and port.
     */
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
