//
//  ParseServer.swift
//  
//
//  Created by Corey Baker on 1/25/23.
//

import Vapor
import ParseSwift

// MARK: Internal

internal struct ParseServer {
    static var configuration: ParseServerConfiguration!
}

/// The current `ParseServerConfiguration` for ParseServerSwift.
public var configuration: ParseServerConfiguration {
    ParseServer.configuration
}

/**
 Configure `ParseServerSwift`. This should only be called once when starting your
 Vapor app. Typically in the `configure(_ app: Application)`.
 - parameter configuration: The ParseServer configuration.
 - parameter app: Core type representing a Vapor application.
 - throws: An error of `ParseError` type.
 - important: All custom configurations to your Vapor `app` server should occur before
 calling this method as it will modify and use the current configuration to understand the local
 server URL.
 - warning: Be sure to call this method before calling `try routes(app)`.
 */
public func initialize(_ configuration: ParseServerConfiguration,
                       app: Application) throws {
    try initializeServer(configuration, app: app)
}

func initialize(_ configuration: ParseServerConfiguration,
                       app: Application,
                       testing: Bool) throws {
    var configuration = configuration
    configuration.isTesting = testing
    try initialize(configuration, app: app)
}

func initializeServer(_ configuration: ParseServerConfiguration,
                      app: Application) throws {

    // Parse uses tailored encoders/decoders. These can be retrieved from any ParseObject
    ContentConfiguration.global.use(encoder: User.getJSONEncoder(), for: .json)
    ContentConfiguration.global.use(decoder: User.getDecoder(), for: .json)
    
    guard let parseServerURL = URL(string: configuration.primaryParseServerURLString) else {
        throw ParseError(code: .otherCause,
                         message: "Could not make a URL from the Parse Server string")
    }
    
    if !configuration.isTesting {
        try setConfiguration(configuration)
        Task {
            do {
                // Initialize the Parse-Swift SDK. Add any additional parameters you need
                try await ParseSwift.initialize(applicationId: configuration.applicationId,
                                                primaryKey: configuration.primaryKey,
                                                serverURL: parseServerURL,
                                                // POST all queries instead of using GET.
                                                usingPostForQuery: true,
                                                // Do not use cache for anything.
                                                requestCachePolicy: .reloadIgnoringLocalCacheData) { _, completionHandler in
                    // Setup to use default certificate pinning. See Parse-Swift docs for more info
                    completionHandler(.performDefaultHandling, nil)
                }
                // Check the health of all Parse-Server
                try await checkServerHealth()
            } catch {
                app.shutdown()
            }
        }
    } else {
        ParseServer.configuration = configuration
    }
}
