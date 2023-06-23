import Vapor
import ParseSwift

// swiftlint:disable:next cyclomatic_complexity function_body_length
func routes(_ app: Application) throws {

    // A typical route in Vapor.
    app.get { req in
        return req.view.render("index", ["title": "Hello Vapor!"])
    }

    // Another typical route in Vapor.
    app.get("foo") { _ async throws -> String in
        return "foo bar"
    }

    // A simple Parse Hook Function route that returns "Hello World".
    app.post("hello",
             name: "hello") { req async throws -> ParseHookResponse<String> in
        // Note that `ParseHookResponse<String>` means a "successfull"
        // response will return a "String" type.
        if let error: ParseHookResponse<String> = checkHeaders(req) {
            return error
        }
        var parseRequest = try req.content
            .decode(ParseHookFunctionRequest<User, FooParameters>.self)

        // If a User made the request, fetch the complete user.
        if parseRequest.user != nil {
            parseRequest = try await parseRequest.hydrateUser(request: req)
        }

        // To query using the User's credentials who called this function,
        // use the options() method from the parseRequest
        let options = try parseRequest.options(req)
        let scores = try await GameScore.query.findAll(options: options)
        req.logger.info("Scores this user can access: \(scores)")
        return ParseHookResponse(success: "Hello world!")
    }

    // Another simple Parse Hook Function route that returns the version of the server.
    app.post("version",
             name: "version") { req async throws -> ParseHookResponse<String> in
        // Note that `ParseHookResponse<String>` means a "successfull"
        // response will return a "String" type.
        if let error: ParseHookResponse<String> = checkHeaders(req) {
            return error
        }
        var parseRequest = try req.content
            .decode(ParseHookFunctionRequest<User, FooParameters>.self)

        // If a non-User made the request, they cannot see the version.
        guard parseRequest.user != nil else {
            let error = ParseError(code: .invalidSessionToken,
                                   message: "User must be signed in to access server version")
            return ParseHookResponse<String>(error: error)
        }

        do {
            // If a User made the request, fetch the complete user to ensure
            // their sessionToken is valid.
            parseRequest = try await parseRequest.hydrateUser(request: req)
        } catch {
            guard let parseError = error as? ParseError else {
                let error = ParseError(code: .otherCause,
                                       swift: error)
                return ParseHookResponse<String>(error: error)
            }
            return ParseHookResponse<String>(error: parseError)
        }

        do {
            // Attempt to get version of the server.
            guard let version = try await ParseServer.information().version else {
                let error = ParseError(code: .otherCause,
                                       message: "Could not retrieve any information from the Server")
                return ParseHookResponse<String>(error: error)
            }
            req.logger.info("Server version is: \(version)")
            return ParseHookResponse(success: "\(version)")
        } catch {
            guard let parseError = error as? ParseError else {
                let error = ParseError(code: .otherCause,
                                       swift: error)
                return ParseHookResponse<String>(error: error)
            }
            return ParseHookResponse<String>(error: parseError)
        }
    }

    // A Parse Hook Trigger route.
    app.post("score", "save", "before",
             object: GameScore.self,
             trigger: .beforeSave) { req async throws -> ParseHookResponse<GameScore> in
        // Note that `ParseHookResponse<GameScore>` means a "successfull"
        // response will return a "GameScore" type.
        if let error: ParseHookResponse<GameScore> = checkHeaders(req) {
            return error
        }
        var parseRequest = try req.content
            .decode(ParseHookTriggerObjectRequest<User, GameScore>.self)

        // If a User made the request, fetch the complete user.
        if parseRequest.user != nil {
            parseRequest = try await parseRequest.hydrateUser(request: req)
        }

        guard let object = parseRequest.object else {
            return ParseHookResponse(error: .init(code: .missingObjectId,
                                                  message: "Object not sent in request."))
        }
        // To query using the primaryKey pass the `usePrimaryKey` option
        // to ther query.
        let scores = try await GameScore.query.findAll(options: [.usePrimaryKey])
        req.logger.info("Before save is being made. Showing all scores before saving new ones: \(scores)")
        return ParseHookResponse(success: object)
    }

    // Another Parse Hook Trigger route.
    app.post("score", "find", "before",
             object: GameScore.self,
             trigger: .beforeFind) { req async throws -> ParseHookResponse<[GameScore]> in
        // Note that `ParseHookResponse<[GameScore]>` means a "successfull"
        // response will return a "[GameScore]" type.
        if let error: ParseHookResponse<[GameScore]> = checkHeaders(req) {
            return error
        }
        let parseRequest = try req.content
            .decode(ParseHookTriggerObjectRequest<User, GameScore>.self)
        req.logger.info("A query is being made: \(parseRequest)")

        // Return two custom scores instead.
        let score1 = GameScore(objectId: "yolo",
                               createdAt: Date(),
                               points: 50)
        let score2 = GameScore(objectId: "nolo",
                               createdAt: Date(),
                               points: 60)
        req.logger.info("""
            Returning custom objects to the user from Cloud Code instead of querying:
            \(score1); \(score2)
        """)
        return ParseHookResponse(success: [score1, score2])
    }

    // Another Parse Hook Trigger route.
    app.post("user", "login", "after",
             object: User.self,
             trigger: .afterLogin) { req async throws -> ParseHookResponse<Bool> in
        // Note that `ParseHookResponse<Bool>` means a "successfull"
        // response will return a "Bool" type. Bool is the standard response with
        // a "true" response meaning everything is okay or continue.
        if let error: ParseHookResponse<Bool> = checkHeaders(req) {
            return error
        }
        let parseRequest = try req.content
            .decode(ParseHookTriggerObjectRequest<User, GameScore>.self)

        req.logger.info("A user has logged in: \(parseRequest)")
        return ParseHookResponse(success: true)
    }

    // A Parse Hook Trigger route for `ParseFile`.
    app.on("file", "save", "before",
           trigger: .beforeSave) { req async throws -> ParseHookResponse<Bool> in
        // Note that `ParseHookResponse<Bool>` means a "successfull"
        // response will return a "Bool" type. Bool is the standard response with
        // a "true" response meaning everything is okay or continue. Sending "false"
        // in this case will reject saving the file.
        if let error: ParseHookResponse<Bool> = checkHeaders(req) {
            return error
        }
        let parseRequest = try req.content
            .decode(ParseHookTriggerRequest<User>.self)

        req.logger.info("A ParseFile is being saved: \(parseRequest)")
        return ParseHookResponse(success: true)
    }

    // Another Parse Hook Trigger route for `ParseFile`.
    app.post("file", "delete", "before",
             trigger: .beforeDelete) { req async throws -> ParseHookResponse<Bool> in
        // Note that `ParseHookResponse<Bool>` means a "successfull"
        // response will return a "Bool" type. Bool is the standard response with
        // a "true" response meaning everything is okay or continue.
        if let error: ParseHookResponse<Bool> = checkHeaders(req) {
            return error
        }
        let parseRequest = try req.content
            .decode(ParseHookTriggerRequest<User>.self)

        req.logger.info("A ParseFile is being deleted: \(parseRequest)")
        return ParseHookResponse(success: true)
    }

    // A Parse Hook Trigger route for `ParseLiveQuery`.
    app.post("connect", "before",
             trigger: .beforeConnect) { req async throws -> ParseHookResponse<Bool> in
        // Note that `ParseHookResponse<Bool>` means a "successfull"
        // response will return a "Bool" type. Bool is the standard response with
        // a "true" response meaning everything is okay or continue.
        if let error: ParseHookResponse<Bool> = checkHeaders(req) {
            return error
        }
        let parseRequest = try req.content
            .decode(ParseHookTriggerRequest<User>.self)

        req.logger.info("A LiveQuery connection is being made: \(parseRequest)")
        return ParseHookResponse(success: true)
    }

    // Another Parse Hook Trigger route for `ParseLiveQuery`.
    app.post("score", "subscribe", "before",
             object: GameScore.self,
             trigger: .beforeSubscribe) { req async throws -> ParseHookResponse<Bool> in
        // Note that `ParseHookResponse<Bool>` means a "successfull"
        // response will return a "Bool" type. Bool is the standard response with
        // a "true" response meaning everything is okay or continue.
        if let error: ParseHookResponse<Bool> = checkHeaders(req) {
            return error
        }
        let parseRequest = try req.content
            .decode(ParseHookTriggerObjectRequest<User, GameScore>.self)

        req.logger.info("A LiveQuery subscription is being made: \(parseRequest)")
        return ParseHookResponse(success: true)
    }

    // Another Parse Hook Trigger route for `ParseLiveQuery`.
    app.post("score", "event", "after",
             object: GameScore.self,
             trigger: .afterEvent) { req async throws -> ParseHookResponse<Bool> in
        // Note that `ParseHookResponse<Bool>` means a "successfull"
        // response will return a "Bool" type. Bool is the standard response with
        // a "true" response meaning everything is okay or continue.
        if let error: ParseHookResponse<Bool> = checkHeaders(req) {
            return error
        }
        let parseRequest = try req.content
            .decode(ParseHookTriggerObjectRequest<User, GameScore>.self)

        req.logger.info("A LiveQuery event occured: \(parseRequest)")
        return ParseHookResponse(success: true)
    }
}
