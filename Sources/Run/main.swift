import ParseServerSwift
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer {
    Task {
        await deleteHooks(app)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        app.shutdown()
    }
}
try configure(app)

// Need to start RunLoop.main, https://github.com/vapor/template/pull/78
// try app.run()
let appThread = Thread {
     do {
         try app.run()
         exit(0)
     } catch {
         exit(1)
     }
 }

 appThread.name = "ParseServerSwift"
 appThread.start()

 dispatchMain()
