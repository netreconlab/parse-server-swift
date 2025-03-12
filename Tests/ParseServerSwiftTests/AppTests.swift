@testable import ParseServerSwift
import ParseSwift
import XCTVapor

final class AppTests: XCTestCase {

    struct DummyRequest: Codable {
        var installationId: String?
        var params: FooParameters
    }

    func setupAppForTesting(hookKey: String? = nil) async throws -> Application {
        let app = try await Application.make(.testing)
        let configuration = try ParseServerConfiguration(
            app: app,
            hostName: "hostName",
            port: 8080,
            applicationId: "applicationId",
            maintenanceKey: "maintenanceKey",
            primaryKey: "primaryKey",
            webhookKey: hookKey,
            parseServerURLString: "http://localhost:1337/1"
        )
        try await ParseServerSwift.initialize(
            configuration,
            app: app,
            testing: true
        )
        guard let parseServerURL = URL(string: configuration.primaryParseServerURLString) else {
            let error = ParseError(
                code: .otherCause,
                message: "Could not make a URL from the Parse Server string"
            )
            throw error
        }
        try await ParseSwift.initialize(
            applicationId: configuration.applicationId,
            primaryKey: configuration.primaryKey,
            maintenanceKey: configuration.maintenanceKey,
            serverURL: parseServerURL,
            usingPostForQuery: true,
            requestCachePolicy: .reloadIgnoringLocalCacheData
        ) { _, completionHandler in
            // Setup to use default certificate pinning. See Parse-Swift docs for more info
            completionHandler(.performDefaultHandling, nil)
        }
        try exampleRoutes(app)
        return app
    }

    func testConfigRequiresKeys() async throws {
        let app = try await Application.make(.testing)
        XCTAssertThrowsError(try ParseServerConfiguration(app: app))
        try await app.asyncShutdown()
    }

    func testAllowInitConfigOnce() async throws {
        let app = try await Application.make(.testing)
        let configuration = try ParseServerConfiguration(
            app: app,
            hostName: "hostName",
            port: 8080,
            applicationId: "applicationId",
            maintenanceKey: "maintenanceKey",
            primaryKey: "primaryKey",
            parseServerURLString: "http://localhost:1337/1"
        )
        XCTAssertNoThrow(try setConfiguration(configuration))
        try await app.asyncShutdown()
    }

    func testDoNotInitConfigTwice() async throws {
        let app = try await setupAppForTesting()
        let configuration = try ParseServerConfiguration(
            app: app,
            hostName: "hostName",
            port: 8080,
            applicationId: "applicationId",
            maintenanceKey: "maintenanceKey",
            primaryKey: "primaryKey",
            parseServerURLString: "http://localhost:1337/1"
        )
        XCTAssertThrowsError(try setConfiguration(configuration))
        try await app.asyncShutdown()
    }

    func testFooBar() async throws {
        let app = try await setupAppForTesting()

        try await app.test(
            .GET,
            "foo"
        ) { res async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "foo bar")
        }

        try await app.asyncShutdown()
    }

    func testCheckServerHealth() async throws {
        let app = try await setupAppForTesting()

        XCTAssertGreaterThan(configuration.parseServerURLStrings.count, 0)
        do {
            try await checkServerHealth()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Unable to connect"))
        }
        try await app.asyncShutdown()
    }

    func testGetParseServerURLs() async throws {
        let urls = try getParseServerURLs()
        XCTAssertEqual(urls.0, "http://localhost:1337/parse")
        XCTAssertEqual(urls.1.count, 0)
        let urlStrings = "http://parse2:1337/parse, http://parse:1337/parse"
        let urls2 = try getParseServerURLs(urlStrings)
        XCTAssertEqual(urls2.0, "http://parse:1337/parse")
        XCTAssertEqual(urls2.1.count, 1)
        XCTAssertEqual(urls2.1.first, "http://parse2:1337/parse")
        let urlStrings2 = "http://parse2:1337/parse,http://parse:1337/parse"
        let urls3 = try getParseServerURLs(urlStrings2)
        XCTAssertEqual(urls3.0, "http://parse:1337/parse")
        XCTAssertEqual(urls3.1.count, 1)
        XCTAssertEqual(urls3.1.first, "http://parse2:1337/parse")
    }

    func testDeleteHooks() async throws {
        let app = try await setupAppForTesting()

        let urlString = "https://parse.com/parse"
        guard let url = URL(string: urlString) else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertGreaterThan(configuration.parseServerURLStrings.count, 0)

        let function = ParseHookFunction(name: "hello", url: url)
        let trigger = try ParseHookTrigger(trigger: .afterSave, url: url)

        await configuration.hooks.updateFunctions([ urlString: function ])
        await configuration.hooks.updateTriggers([ urlString: trigger ])

        let currentFunctions = await configuration.hooks.getFunctions()
        let currentTriggers = await configuration.hooks.getTriggers()
        XCTAssertGreaterThan(currentFunctions.count, 0)
        XCTAssertGreaterThan(currentTriggers.count, 0)

        await deleteHooks(app)

        let currentFunctions2 = await configuration.hooks.getFunctions()
        let currentTriggers2 = await configuration.hooks.getTriggers()
        XCTAssertEqual(currentFunctions2.count, 0)
        XCTAssertEqual(currentTriggers2.count, 0)
        try await app.asyncShutdown()
    }

    func testFunctionWebhookKeyNotEqual() async throws {
        let app = try await setupAppForTesting(hookKey: "wow")

        try await app.test(
            .POST,
            "hello"
        ) { res async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssertTrue(res.body.string.contains("Webhook keys"))
        }

        try await app.asyncShutdown()
    }

    func testTriggerWebhookKeyNotEqual() async throws {
        let app = try await setupAppForTesting(hookKey: "wow")

        try await app.test(
            .POST,
            "score/save/before"
        ) { res async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssertTrue(res.body.string.contains("Webhook keys"))
        }

        try await app.asyncShutdown()
    }

    func testMatchServerURLString() async throws {
        let app = try await setupAppForTesting()
        let urlString = "https://parse.com/parse"
        let uri = URI(stringLiteral: urlString)
        let serverString = try serverURLString(uri, parseServerURLStrings: [urlString])
        XCTAssertEqual(serverString, urlString)

        let urlString2 = urlString + "/helloWorld"
        let uri2 = URI(stringLiteral: urlString2)
        let serverString2 = try serverURLString(uri2, parseServerURLStrings: [urlString])
        XCTAssertEqual(serverString2, urlString)

        Parse.configuration.parseServerURLStrings = ["http://localhost:1337/parse"]
        let serverString3 = try serverURLString(uri,
                                                parseServerURLStrings: configuration.parseServerURLStrings)
        XCTAssertEqual(serverString3, configuration.parseServerURLStrings.first)

        try await app.asyncShutdown()
    }

    func testMatchServerURLStringThrowsError() async throws {
        let app = try await setupAppForTesting()
        Parse.configuration.parseServerURLStrings.removeAll()
        let urlString = "https://parse.com/parse"
        let uri = URI(stringLiteral: urlString)
        XCTAssertThrowsError(try serverURLString(uri,
                                                 parseServerURLStrings: configuration.parseServerURLStrings))
        try await app.asyncShutdown()
    }

    func testParseHookOptions() async throws {
        let app = try await setupAppForTesting()
        let installationId = "naw"
        let urlString = "https://parse.com/parse"
        Parse.configuration.parseServerURLStrings.append(urlString)
        let dummyHookRequest = DummyRequest(installationId: installationId, params: .init())
        let encoded = try User.getJSONEncoder().encode(dummyHookRequest)
        let hookRequest = try User.getDecoder().decode(ParseHookFunctionRequest<User, FooParameters>.self,
                                                       from: encoded)

        let options = hookRequest.options()
        let installationOption = options.first(where: { $0 == .installationId(installationId) })
        XCTAssertEqual(options.count, 1)
        XCTAssertTrue(installationOption.debugDescription.contains(installationId))

        let uri = URI(stringLiteral: urlString)
        let request = Request(application: app, url: uri, on: app.eventLoopGroup.any())
        let options2 = try hookRequest.options(request,
                                               parseServerURLStrings: configuration.parseServerURLStrings)
        let installationOption2 = options2.first(where: { $0 == .installationId(installationId) })
        let serverURLOption = options2.first(where: { $0 == .serverURL(urlString) })
        XCTAssertEqual(options2.count, 2)
        XCTAssertTrue(installationOption2.debugDescription.contains(installationId))
        XCTAssertTrue(serverURLOption.debugDescription.contains("\"\(urlString)\""))
        try await app.asyncShutdown()
    }

    func testHooksFunctions() async throws {
        let functions = await configuration.hooks.getFunctions()
        XCTAssertTrue(functions.isEmpty)

        let dummyHooks = ["yo": ParseHookFunction(name: "hello", url: nil),
                          "no": ParseHookFunction(name: "hello", url: nil)]
        await configuration.hooks.updateFunctions(dummyHooks)
        let functions2 = await configuration.hooks.getFunctions()
        XCTAssertEqual(functions2.count, 2)

        await configuration.hooks.removeFunctions(["yo"])
        let functions3 = await configuration.hooks.getFunctions()
        XCTAssertNil(functions3["yo"])
        XCTAssertNotNil(functions3["no"])

        await configuration.hooks.removeAllFunctions()
        let functions4 = await configuration.hooks.getFunctions()
        XCTAssertTrue(functions4.isEmpty)
    }

    func testHooksTriggers() async throws {
        let triggers = await configuration.hooks.getTriggers()
        XCTAssertTrue(triggers.isEmpty)

        guard let url = URL(string: "http://parse.com") else {
            XCTFail("Should have unwrapped")
            return
        }
        let dummyHooks = ["yo": ParseHookTrigger(className: "hello",
                                                 trigger: .afterDelete,
                                                 url: url),
                          "no": ParseHookTrigger(className: "hello",
                                                 trigger: .afterEvent,
                                                 url: url)]
        await configuration.hooks.updateTriggers(dummyHooks)
        let triggers2 = await configuration.hooks.getTriggers()
        XCTAssertEqual(triggers2.count, 2)

        await configuration.hooks.removeTriggers(["yo"])
        let triggers3 = await configuration.hooks.getTriggers()
        XCTAssertNil(triggers3["yo"])
        XCTAssertNotNil(triggers3["no"])

        await configuration.hooks.removeAllTriggers()
        let triggers4 = await configuration.hooks.getTriggers()
        XCTAssertTrue(triggers4.isEmpty)
    }
}
