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
        let error = ParseError(code: .otherCause,
                               message: "WebHook keys don't match")
        return ParseHookResponse<T>(error: error)
    }
    return nil
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

/**
 Construct the full server pathname with route.
 - returns: The server path with scheme, hostname, port, and route.
 */
func buildServerPathname(_ path: [PathComponent]) throws -> URL {
    let pathString = "/" + path.map { "\($0)" }.joined(separator: "/")
    guard let serverPathname = serverPathname,
          let url = URL(string: serverPathname)?.appendingPathComponent(pathString) else {
        throw ParseError(code: .otherCause,
                         message: "Cannot create a pathname for the server")
    }
    return url
}
