//
//  ParseServer.swift
//  
//
//  Created by Corey Baker on 1/25/23.
//

import Vapor
import ParseSwift

// MARK: Internal

internal struct Parse {
	nonisolated(unsafe) static var configuration: ParseServerConfiguration!
}

/// The current `ParseServerConfiguration` for ParseServerSwift.
public var configuration: ParseServerConfiguration {
    Parse.configuration
}

/**
 Configure `ParseServerSwift`. This should only be called once when starting your
 Vapor app. Typically in the `parseServerSwiftConfigure(_ app: Application)`.
 - parameter configuration: The ParseServer configuration.
 - parameter app: Core type representing a Vapor application.
 - throws: An error of `ParseError` type.
 - important: All custom configurations to your Vapor `app` server should occur before
 calling this method as it will modify and use the current configuration to understand the local
 server URL.
 - warning: Be sure to call this method before calling `try routes(app)`.
 */
public func initialize(
    _ configuration: ParseServerConfiguration,
    app: Application
) async throws {
    try await initializeServer(configuration, app: app)
}

func initialize(
    _ configuration: ParseServerConfiguration,
    app: Application,
    testing: Bool
) async throws {
    var configuration = configuration
    configuration.isTesting = testing
    try await initialize(configuration, app: app)
}

func initializeServer(
    _ configuration: ParseServerConfiguration,
    app: Application
) async throws {

    // Parse uses tailored encoders/decoders. These can be retrieved from any ParseObject
    ContentConfiguration.global.use(encoder: User.getEncoder(), for: .json)
    ContentConfiguration.global.use(decoder: User.getDecoder(), for: .json)

    guard let parseServerURL = URL(string: configuration.primaryParseServerURLString) else {
        let error = ParseError(
            code: .otherCause,
            message: "Could not make a URL from the Parse Server string"
        )
        throw error
    }

    if !configuration.isTesting {
        try setConfiguration(configuration)
        do {
            // Initialize the Parse-Swift SDK. Add any additional parameters you need
            try await ParseSwift.initialize(
                applicationId: configuration.applicationId,
                primaryKey: configuration.primaryKey,
                maintenanceKey: configuration.maintenanceKey,
                serverURL: parseServerURL,
                // POST all queries instead of using GET.
                usingPostForQuery: true,
                // Do not use cache for anything.
                requestCachePolicy: .reloadIgnoringLocalCacheData
            ) { _, completionHandler in
                // Setup to use default certificate pinning. See Parse-Swift docs for more info
                completionHandler(.performDefaultHandling, nil)
            }
            // Check the health of all Parse-Server
            try await checkServerHealth()
        } catch {
            await deleteHooks(app)
            try await app.asyncShutdown()
        }
    } else {
        Parse.configuration = configuration
    }
}
