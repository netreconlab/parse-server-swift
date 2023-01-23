# ParseServerSwift

[![Documentation](http://img.shields.io/badge/read-docs-2196f3.svg)](https://swiftpackageindex.com/netreconlab/parse-server-swift/documentation)
[![Tuturiol](http://img.shields.io/badge/read-tuturials-2196f3.svg)](https://netreconlab.github.io/parse-server-swift/release/tutorials/parseserverswift/)
[![Build Status CI](https://github.com/netreconlab/parse-server-swift/workflows/ci/badge.svg?branch=main)](https://github.com/netreconlab/parse-server-swift/actions?query=workflow%3Aci+branch%3Amain)
[![codecov](https://codecov.io/gh/netreconlab/parse-server-swift/branch/main/graph/badge.svg?token=RC3FLU6BGW)](https://codecov.io/gh/netreconlab/parse-server-swift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnetreconlab%2Fparse-server-swift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/netreconlab/parse-server-swift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnetreconlab%2Fparse-server-swift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/netreconlab/parse-server-swift)

---

Write Parse Cloud Code in Swift!

What is Cloud Code? For complex apps, sometimes you just need logic that isn’t running on a mobile device. Cloud Code makes this possible.
Cloud Code in `ParseServerSwift` is easy to use because it’s built using [Parse-Swift<sup>OG</sup>](https://github.com/netreconlab/Parse-Swift) 
and [Vapor](https://github.com/vapor/vapor). `ParseServerSwift` provides many additional benefits over the traditional [JS based Cloud Code](https://docs.parseplatform.org/cloudcode/guide/) that runs on the [Node.js parse-server](https://github.com/parse-community/parse-server):

* Write code with the [Parse-Swift<sup>OG</sup> SDK](https://github.com/netreconlab/Parse-Swift) vs the [Parse JS SDK](https://github.com/parse-community/Parse-SDK-JS) allowing you to take advantage of a modern SDK which is strongly typed
* Runs on a dedicated server/container, allowing the [Node.js parse-server](https://github.com/parse-community/parse-server) to focus on request reducing the burden by offloading intensive tasks and providing a true [microservice](https://microservices.io)
* All Cloud Code is in one place, but automatically connects supports the [Node.js parse-server](https://github.com/parse-community/parse-server) at scale. This circumvents the issues faced when using [JS based Cloud Code](https://docs.parseplatform.org/cloudcode/guide/) with [PM2](https://pm2.keymetrics.io)
* Leverage the capabilities of [server-side-swift](https://www.swift.org/server/) with [Vapor](https://github.com/vapor/vapor)

Technically, complete apps can be written with `ParseServerSwift`, the only difference is that this code runs in your `ParseServerSwift` rather than running on the user’s mobile device. When you update your Cloud Code, it becomes available to all mobile environments instantly. You don’t have to wait for a new release of your application. This lets you change app behavior on the fly and add new features faster.

## Configure ParseServerSwift to Connect to Your Parse Servers
### Environment Variables
The following enviroment variables are available and can be configured directly or through `.env`, `.env.production`, etc. See the [Vapor Docs for more details](https://docs.vapor.codes/basics/environment/).

```
PARSE_SWIFT_SERVER_HOST_NAME: cloud-code # The name of your host. If you are running in Docker it should be same name as the docker service
PARSE_SWIFT_SERVER_PORT: # This is the default port on the docker image
PARSE_SWIFT_SERVER_DEFAULT_MAX_BODY_SIZE: 500kb # Set the default size for bodies that are collected into memory before calling your handlers (See Vapor docs for more details)
PARSE_SWIFT_SERVER_URLS: http://parse:1337/parse # (Required) Specify one of your Parse Servers to connect to. Can connect to multiple by seperating URLs with commas
PARSE_SWIFT_SERVER_APPLICATION_ID: appId # (Required) The application id of your Parse Server
PARSE_SWIFT_SERVER_PRIMARY_KEY: primaryKey # (Required) The master key of your Parse Server 
PARSE_SWIFT_SERVER_WEBHOOK_KEY: webookKey # The webhookKey of your Parse Server
```

If you need to customize your configuration you will need to edit [ParseServerSwift/Sources/ParseServerSwift/configure.swift](https://github.com/netreconlab/ParseServerSwift/blob/main/Sources/ParseServerSwift/configure.swift) directly.

### WebhookKey
The `webhookKey` should match the [webhookKey on the Parse Server](https://github.com/parse-community/parse-server/blob/42c954318926823446326c95188b844e19954711/src/Options/Definitions.js#L491-L494).

### Parse-Swift<sup>OG</sup> SDK
The aforementioned environment variables automatically configure [Parse-Swift<sup>OG</sup> SDK](https://github.com/netreconlab/Parse-Swift). If you need a more custom configuration, see the [documentation](https://netreconlab.github.io/Parse-Swift/release/documentation/parseswift/).

## Starting the Server
`ParseServerSwift` is optimized to run in Docker containers. A sample [docker-compose.yml] demonstrates how to quickly spin up one (1) `ParseServerSwift` server with two (2) [parse-hipaa](https://github.com/netreconlab/parse-hipaa) servers and (1) [hipaa-postgres](https://github.com/netreconlab/hipaa-postgres) server.

### In Docker
1. Fork this repo
2. In your terminal, change directories into `ParseServerSwift` folder
3. Type `docker-compose up`

### On macOS
To start your server type, `swift run` in the terminal of the project root directory.

## Writing Cloud Code
### Creating `ParseObject`'s
It is recommended to add all of your `ParseObject`'s to [ParseServerSwift/Sources/ParseServerSwift/Models](https://github.com/netreconlab/ParseServerSwift/blob/main/Sources/ParseServerSwift/Models). An example `GameScore` model is provided:

```swift
import Foundation
import ParseSwift

/**
 An example `ParseObject`. This is for testing. You can
 remove when creating your application.
 */
struct GameScore: ParseObject {
    // These are required by ParseObject.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Your own properties.
    var points: Int?

    // Implement your own version of merge.
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points,
                                     original: object) {
            updated.points = object.points
        }
        return updated
    }
}
```

#### The `ParseUser` Model
Be sure to add all of the additional properties you have in your `_User` class to the `User` model which is located at [ParseServerSwift/Sources/ParseServerSwift/Models/User.swift](https://github.com/netreconlab/ParseServerSwift/blob/main/Sources/ParseServerSwift/Models/User.swift)

### Creating New Cloud Code Routes 
Adding routes for `ParseHooks` are as simple as adding [routes in Vapor](https://docs.vapor.codes/basics/routing/). `ParseServerSwift` provides some additional methods to routes to easily create and register [Hook Functions](https://parseplatform.org/Parse-Swift/release/documentation/parseswift/parsehookfunctionable) and [Hook Triggers](https://parseplatform.org/Parse-Swift/release/documentation/parseswift/parsehooktriggerable/). All routes should be added to [ParseServerSwift/Sources/ParseServerSwift/routes.swift](https://github.com/netreconlab/ParseServerSwift/blob/main/Sources/ParseServerSwift/routes.swift)

### Cloud Code Functions
Cloud Code Functions can also take parameters. It's recommended to place all paramters in 
[ParseServerSwift/Sources/ParseServerSwift/Models/Parameters](https://github.com/netreconlab/ParseServerSwift/blob/main/Sources/ParseServerSwift/Models/Parameters)

```swift
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
```

### Cloud Code Triggers
```swift
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
```
