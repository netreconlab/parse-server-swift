# ParseServerSwift

Write Cloud Code in Swift!

What is Cloud Code? For complex apps, sometimes you just need logic that isn’t running on a mobile device. Cloud Code makes this possible.
Cloud Code in ParseServerSwift is easy to use because it’s built using [Parse-Swift](https://github.com/parse-community/Parse-Swift) 
and [Vapor](https://github.com/vapor/vapor). The only difference is that this code runs in your ParseServerSwift rather than running on the user’s mobile device. When you update your Cloud Code, 
it becomes available to all mobile environments instantly. You don’t have to wait for a new release of your application. 
This lets you change app behavior on the fly and add new features faster.

## Configure ParseServerSwift
To configure, you should edit [ParseServerSwift/Sources/App/configure.swift](https://github.com/netreconlab/ParseServerSwift/blob/main/Sources/App/configure.swift)

### WebhookKey
The `webhookKey` should match the [webhookKey on the Parse Server](https://github.com/parse-community/parse-server/blob/42c954318926823446326c95188b844e19954711/src/Options/Definitions.js#L491-L494). If you decide not the a `webhookKey`, set the value to `nil` in your ParseServerSwift.

### Hostname and Port
By default, the hostname is `127.0.0.1` and the port is `8081`. These values can easily be changed:

```swift
app.http.server.configuration.hostname = "your.hostname.com"
app.http.server.configuration.port = 8081
app.http.server.configuration.tlsConfiguration = .none
```