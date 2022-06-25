# ParseServerSwift
<h3 align="left">Platforms: macOS · Linux · Windows</h3>

---

[![Build Status CI](https://github.com/netreconlab/parse-server-swift/workflows/ci/badge.svg?branch=main)](https://github.com/netreconlab/parse-server-swift/actions?query=workflow%3Aci+branch%3Amain)
[![codecov](https://codecov.io/gh/netreconlab/parse-server-swift/branch/main/graph/badge.svg?token=RC3FLU6BGW)](https://codecov.io/gh/netreconlab/parse-server-swift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnetreconlab%2Fparse-server-swift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/netreconlab/parse-server-swift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnetreconlab%2Fparse-server-swift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/netreconlab/parse-server-swift)

Write Cloud Code in Swift!

What is Cloud Code? For complex apps, sometimes you just need logic that isn’t running on a mobile device. Cloud Code makes this possible.
Cloud Code in ParseServerSwift is easy to use because it’s built using [Parse-Swift](https://github.com/parse-community/Parse-Swift) 
and [Vapor](https://github.com/vapor/vapor). The only difference is that this code runs in your ParseServerSwift rather than running on the user’s mobile device. When you update your Cloud Code, 
it becomes available to all mobile environments instantly. You don’t have to wait for a new release of your application. 
This lets you change app behavior on the fly and add new features faster.

## Configure ParseServerSwift
To configure, you should edit [ParseServerSwift/Sources/ParseServerSwift/configure.swift](https://github.com/netreconlab/ParseServerSwift/blob/main/Sources/App/configure.swift)

### WebhookKey
The `webhookKey` should match the [webhookKey on the Parse Server](https://github.com/parse-community/parse-server/blob/42c954318926823446326c95188b844e19954711/src/Options/Definitions.js#L491-L494). If you decide not the a `webhookKey`, set the value to `nil` in your ParseServerSwift.

### Hostname, Port, and TLS
By default, the hostname is `127.0.0.1` and the port is `8081`. These values can easily be changed:

```swift
app.http.server.configuration.hostname = "your.hostname.com"
app.http.server.configuration.port = 8081
app.http.server.configuration.tlsConfiguration = .none
```

### Parse Swift SDK
Configure the SDK as described in the [documentation](https://parseplatform.org/Parse-Swift/release/documentation/parseswift/parseswift/initialize(applicationid:clientkey:masterkey:serverurl:livequeryserverurl:allowingcustomobjectids:usingtransactions:usingequalqueryconstraint:keyvaluestore:requestcachepolicy:cachememorycapacity:cachediskcapacity:migratingfromobjcsdk:deleti-97083)).

```swift
// Required: Change to your Parse Server serverURL.
guard let parseServerUrl = URL(string: "http://localhost:1337/1") else {
    throw ParseError(code: .unknownError,
                     message: "Could not make Parse Server URL")
}

// Initialize the Parse-Swift SDK
ParseSwift.initialize(applicationId: "applicationId", // Required: Change to your applicationId.
                        clientKey: "clientKey", // Required: Change to your clientKey.
                        masterKey: "masterKey", // Required: Change to your masterKey.
                        serverURL: parseServerUrl) { _, completionHandler in
    completionHandler(.performDefaultHandling, nil)
}
```

## Adding `ParseObject`'s
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

### The `ParseUser` Model
Be sure to add all of the additional properties you have in your `_User` class to the `User` model which is located at [ParseServerSwift/Sources/ParseServerSwift/Models/User.swift](https://github.com/netreconlab/ParseServerSwift/blob/main/Sources/ParseServerSwift/Models/User.swift)

## Parse Cloud Code Hook Routes
Adding routes for ParseHooks are as simple as adding [routes in Vapor](https://docs.vapor.codes/basics/routing/). `ParseServerSwift` adds some additional methods to routes to easily create and register [Hook Functions](https://parseplatform.org/Parse-Swift/release/documentation/parseswift/parsehookfunctionable) and [Hook Triggers](https://parseplatform.org/Parse-Swift/release/documentation/parseswift/parsehooktriggerable/). All routes should be added to [ParseServerSwift/Sources/ParseServerSwift/routes.swift](https://github.com/netreconlab/ParseServerSwift/blob/main/Sources/ParseServerSwift/routes.swift)

### Cloud Code Functions
Cloud Code Functions can also take parameters. It's recommended to place all paramters in 
[ParseServerSwift/Sources/ParseServerSwift/Models/Parameters](https://github.com/netreconlab/ParseServerSwift/blob/main/Sources/ParseServerSwift/Models/Parameters)

```swift
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
```

### Cloud Code Triggers
```swift
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
```
