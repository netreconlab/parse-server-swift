# ``ParseServerSwift``

Write Parse Cloud Code in Swift!

## Overview

What is Cloud Code? For complex apps, sometimes you just need logic that isn’t running on a mobile device. Cloud Code makes this possible.
Cloud Code in `ParseServerSwift` is easy to use because it’s built using [Parse-Swift<sup>OG</sup>](https://github.com/netreconlab/Parse-Swift) 
and [Vapor](https://github.com/vapor/vapor). `ParseServerSwift` provides many additional benefits over the traditional [JS based Cloud Code](https://docs.parseplatform.org/cloudcode/guide/) that runs on the [Node.js parse-server](https://github.com/parse-community/parse-server):

* Write code with the [Parse-Swift SDK](https://github.com/netreconlab/Parse-Swift) vs the [Parse JS SDK](https://github.com/parse-community/Parse-SDK-JS) allowing you to take advantage of a modern SDK which is strongly typed
* Runs on a dedicated server/container, allowing the [Node.js parse-server](https://github.com/parse-community/parse-server) to focus on request reducing the burden by offloading intensive tasks and providing a true [microservice](https://microservices.io)
* All Cloud Code is in one place, but automatically connects supports the [Node.js parse-server](https://github.com/parse-community/parse-server) at scale. This circumvents the issues faced when using [JS based Cloud Code](https://docs.parseplatform.org/cloudcode/guide/) with [PM2](https://pm2.keymetrics.io)
* Leverage the capabilities of [server-side-swift](https://www.swift.org/server/) with [Vapor](https://github.com/vapor/vapor)

Technically, complete apps can be written with `ParseServerSwift`, the only difference is that this code runs in your `ParseServerSwift` rather than running on the user’s mobile device. When you update your Cloud Code, it becomes available to all mobile environments instantly. You don’t have to wait for a new release of your application. This lets you change app behavior on the fly and add new features faster.

## Additional Resources

For more information on using Parse Swift SDK:
- [Parse Swift API Documentation](https://swiftpackageindex.com/netreconlab/Parse-Swift/documentation)
- [Parse Swift Tutorials](https://netreconlab.github.io/Parse-Swift/release/tutorials/parseswift/)
- [Parse Swift Playgrounds](https://github.com/netreconlab/Parse-Swift/tree/main/ParseSwift.playground/Pages)

## Topics

### Getting Started
- <doc:configuring-parse-server-swift>
- <doc:adding-parseobjects>

### Cloud Code
- <doc:cloud-code-functions>
- <doc:cloud-code-triggers>
