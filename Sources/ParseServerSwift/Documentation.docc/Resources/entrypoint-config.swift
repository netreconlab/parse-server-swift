import Vapor
import Dispatch
import Logging
import NIOCore
import NIOPosix
import ParseServerSwift

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = try await Application.make(env)

        // Install NIO as global executor (optional)
        let executorTakeoverSuccess = NIOSingletons
            .unsafeTryInstallSingletonPosixEventLoopGroupAsConcurrencyGlobalExecutor()
        app.logger.debug(
            "Tried to install SwiftNIO's EventLoopGroup",
            metadata: ["success": .stringConvertible(executorTakeoverSuccess)]
        )

        do {
            try await parseServerSwiftConfigure(
                app,
                using: exampleRoutes
            )
            try await app.execute()
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}
