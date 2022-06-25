import Vapor
import ParseSwift

func routes(_ app: Application) throws {

    // A typical route in Vapor.
    app.get { req in
        return req.view.render("index", ["title": "Hello Vapor!"])
    }

    // Another typical route in Vapor.
    app.get("hello") { req async throws -> String in
        return "Hello, world!"
    }

    // A Parse Hook Function route.
    app.post("foo",
             name: "foo") { req async throws -> ParseHookResponse<String> in
        if let error: ParseHookResponse<String> = checkHeaders(req) {
            return error
        }
        var parseRequest = try req.content
            .decode(ParseHookFunctionRequest<User, FooParameters>.self)
        
        // If a User called the request, fetch the complete user.
        if parseRequest.user != nil {
            parseRequest = try await parseRequest.hydrateUser()
        }
        
        // To query using the User's credentials who called this function,
        // use the options() method from the request
        let options = parseRequest.options()
        let scores = try await GameScore.query.findAll(options: options)
        req.logger.info("Scores this user can access: \(scores)")
        return ParseHookResponse(success: "Hello, new world!")
    }

    // A Parse Hook Trigger route.
    app.post("bar",
             className: "GameScore",
             triggerName: .afterSave) { req async throws -> ParseHookResponse<Bool> in
        if let error: ParseHookResponse<Bool> = checkHeaders(req) {
            return error
        }
        var parseRequest = try req.content
            .decode(ParseHookTriggerRequest<User, GameScore>.self)

        // If a User called the request, fetch the complete user.
        if parseRequest.user != nil {
            parseRequest = try await parseRequest.hydrateUser()
        }

        // To query using the masterKey pass the `useMasterKey option
        // to ther query.
        let scores = try await GameScore.query.findAll(options: [.useMasterKey])
        req.logger.info("All scores: \(scores)")
        return ParseHookResponse(success: true)
    }
}
