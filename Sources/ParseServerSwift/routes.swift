import Vapor
import ParseSwift

func routes(_ app: Application) throws {

    // A typical route in Vapor.
    app.get { req in
        return req.view.render("index", ["title": "Hello Vapor!"])
    }

    // Another typical route in Vapor.
    app.get("foo") { req async throws -> String in
        return "foo bar"
    }

    // A Parse Hook Function route.
    app.post("hello",
             name: "hello") { req async throws -> ParseHookResponse<String> in
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
        // use the options() method from the parseRequest
        let options = try parseRequest.options(req)
        let scores = try await GameScore.query.findAll(options: options)
        req.logger.info("Scores this user can access: \(scores)")
        return ParseHookResponse(success: "Hello world!")
    }

    // A Parse Hook Trigger route.
    app.post("score", "save", "before",
             className: "GameScore",
             triggerName: .beforeSave) { req async throws -> ParseHookResponse<GameScore> in
        if let error: ParseHookResponse<GameScore> = checkHeaders(req) {
            return error
        }
        var parseRequest = try req.content
            .decode(ParseHookTriggerRequest<User, GameScore>.self)

        // If a User called the request, fetch the complete user.
        if parseRequest.user != nil {
            parseRequest = try await parseRequest.hydrateUser()
        }

        guard let object = parseRequest.object else {
            return ParseHookResponse(error: .init(code: .missingObjectId,
                                                  message: "Object not sent in request."))
        }
        // To query using the primaryKey pass the `usePrimaryKey` option
        // to ther query.
        let scores = try await GameScore.query.findAll(options: [.usePrimaryKey])
        req.logger.info("All scores: \(scores)")
        return ParseHookResponse(success: object)
    }

    // Another Parse Hook Trigger route.
    app.post("score", "find", "before",
             className: "GameScore",
             triggerName: .beforeFind) { req async throws -> ParseHookResponse<[GameScore]> in
        if let error: ParseHookResponse<[GameScore]> = checkHeaders(req) {
            return error
        }
        let parseRequest = try req.content
            .decode(ParseHookTriggerRequest<User, GameScore>.self)
        req.logger.info("A query is being made: \(parseRequest)")
        let score1 = GameScore(objectId: "yolo",
                               createdAt: Date(),
                               points: 50)
        let score2 = GameScore(objectId: "yolo",
                               createdAt: Date(),
                               points: 60)
        return ParseHookResponse(success: [score1, score2])
    }

    // Another Parse Hook Trigger route.
    app.post("user", "login", "after",
             className: "_User",
             triggerName: .afterLogin) { req async throws -> ParseHookResponse<Bool> in
        if let error: ParseHookResponse<Bool> = checkHeaders(req) {
            return error
        }
        let parseRequest = try req.content
            .decode(ParseHookTriggerRequest<User, GameScore>.self)

        req.logger.info("A user has logged in: \(parseRequest)")
        return ParseHookResponse(success: true)
    }

    // A Parse Hook Trigger route for `ParseFile` where the body will not be collected into a buffer.
    app.on("file", "save", "before",
           body: .stream,
           triggerName: .beforeSave) { req async throws -> ParseHookResponse<Bool> in
        if let error: ParseHookResponse<Bool> = checkHeaders(req) {
            return error
        }
        let parseRequest = try req.content
            .decode(ParseHookTriggerRequest<User, GameScore>.self)

        req.logger.info("A ParseFile is being saved: \(parseRequest)")
        return ParseHookResponse(success: true)
    }

    // Another Parse Hook Trigger route for `ParseFile`.
    app.post("file", "delete", "before",
             triggerName: .beforeDelete) { req async throws -> ParseHookResponse<Bool> in
        if let error: ParseHookResponse<Bool> = checkHeaders(req) {
            return error
        }
        let parseRequest = try req.content
            .decode(ParseHookTriggerRequest<User, GameScore>.self)

        req.logger.info("A ParseFile is being deleted: \(parseRequest)")
        return ParseHookResponse(success: true)
    }
    
    // A Parse Hook Trigger route for `ParseLiveQuery`.
    app.post("connect", "before",
             triggerName: .beforeConnect) { req async throws -> ParseHookResponse<Bool> in
        if let error: ParseHookResponse<Bool> = checkHeaders(req) {
            return error
        }
        let parseRequest = try req.content
            .decode(ParseHookTriggerRequest<User, GameScore>.self)

        req.logger.info("A LiveQuery connection is being made: \(parseRequest)")
        return ParseHookResponse(success: true)
    }

    // Another Parse Hook Trigger route for `ParseLiveQuery`.
    app.post("score", "subscribe", "before",
             className: "GameScore",
             triggerName: .beforeSubscribe) { req async throws -> ParseHookResponse<Bool> in
        if let error: ParseHookResponse<Bool> = checkHeaders(req) {
            return error
        }
        let parseRequest = try req.content
            .decode(ParseHookTriggerRequest<User, GameScore>.self)

        req.logger.info("A LiveQuery subscribe is being made: \(parseRequest)")
        return ParseHookResponse(success: true)
    }

    // Another Parse Hook Trigger route for `ParseLiveQuery`.
    app.post("score", "event", "after",
             className: "GameScore",
             triggerName: .afterEvent) { req async throws -> ParseHookResponse<Bool> in
        if let error: ParseHookResponse<Bool> = checkHeaders(req) {
            return error
        }
        let parseRequest = try req.content
            .decode(ParseHookTriggerRequest<User, GameScore>.self)

        req.logger.info("A LiveQuery event occured: \(parseRequest)")
        return ParseHookResponse(success: true)
    }
}
