//
//  entrypoint.swift
//  
//
//  Created by Corey Baker on 5/11/23.
//

import Vapor
import Dispatch
import Logging
import ParseServerSwift

/// This extension is temporary and can be removed once Vapor gets this support.
private extension Vapor.Application {
    static let baseExecutionQueue = DispatchQueue(label: "vapor.codes.entrypoint")

    func runFromAsyncMainEntrypoint() async throws {
        try await withCheckedThrowingContinuation { continuation in
            Vapor.Application.baseExecutionQueue.async { [self] in
                do {
                    try self.run()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = Application(env)

        defer {
            Task {
                // This may not delete all because it's async
                // Be sure to delete manually in dashboard
                await deleteHooks(app)
            }
            app.shutdown()
        }

        try await parseServerSwiftConfigure(app)
        try await app.runFromAsyncMainEntrypoint()
    }
}
