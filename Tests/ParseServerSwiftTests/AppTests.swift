@testable import ParseServerSwift
@testable import ParseSwift
import XCTVapor

final class AppTests: XCTestCase {
    
    struct DummyRequest: Codable {
        var installationId: String?
        var params: FooParameters
    }

    func setupAppForTesting(hookKey: String? = nil) throws -> Application {
        let app = Application(.testing)
        try configure(app, testing: true)
        webhookKey = hookKey
        Parse.configuration.isTestingSDK = true
        return app
    }
    
    func testFooBar() throws {
        let app = try setupAppForTesting()
        defer { app.shutdown() }

        try app.test(.GET, "foo", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "foo bar")
        })
    }

    func testCheckServerHealth() async throws {
        let app = try setupAppForTesting()
        defer { app.shutdown() }

        XCTAssertGreaterThan(parseServerURLStrings.count, 0)
        do {
            try await checkServerHealth(app)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Unable to connect"))
        }
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
        let app = try setupAppForTesting()
        defer { app.shutdown() }

        let urlString = "https://parse.com/parse"
        guard let url = URL(string: urlString) else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertGreaterThan(parseServerURLStrings.count, 0)

        let function = HookFunction(name: "hello", url: url)
        let trigger = try HookTrigger(triggerName: .afterSave, url: url)

        await hooks.updateFunctions([ urlString: function ])
        await hooks.updateTriggers([ urlString: trigger ])

        let currentFunctions = await hooks.getFunctions()
        let currentTriggers = await hooks.getTriggers()
        XCTAssertGreaterThan(currentFunctions.count, 0)
        XCTAssertGreaterThan(currentTriggers.count, 0)

        await deleteHooks(app)

        let currentFunctions2 = await hooks.getFunctions()
        let currentTriggers2 = await hooks.getTriggers()
        XCTAssertEqual(currentFunctions2.count, 0)
        XCTAssertEqual(currentTriggers2.count, 0)
    }

    func testFunctionWebhookKeyNotEqual() throws {
        let app = try setupAppForTesting(hookKey: "wow")
        defer { app.shutdown() }
        
        try app.test(.POST, "hello", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertTrue(res.body.string.contains("Webhook keys"))
        })
    }

    func testTriggerWebhookKeyNotEqual() throws {
        let app = try setupAppForTesting(hookKey: "wow")
        defer { app.shutdown() }
        
        try app.test(.POST, "score/save/before", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertTrue(res.body.string.contains("Webhook keys"))
        })
    }

    func testMatchServerURLString() async throws {
        let app = try setupAppForTesting()
        defer { app.shutdown() }
        let urlString = "https://parse.com/parse"
        let uri = URI(stringLiteral: urlString)
        let serverString = try serverURLString(uri, parseServerURLStrings: [urlString])
        XCTAssertEqual(serverString, urlString)
        
        let urlString2 = urlString + "/helloWorld"
        let uri2 = URI(stringLiteral: urlString2)
        let serverString2 = try serverURLString(uri2, parseServerURLStrings: [urlString])
        XCTAssertEqual(serverString2, urlString)
        
        parseServerURLStrings = ["http://localhost:1337/parse"]
        let serverString3 = try serverURLString(uri,
                                                parseServerURLStrings: parseServerURLStrings)
        XCTAssertEqual(serverString3, parseServerURLStrings.first)
    }

    func testMatchServerURLStringThrowsError() async throws {
        let app = try setupAppForTesting()
        parseServerURLStrings.removeAll()
        defer { app.shutdown() }
        let urlString = "https://parse.com/parse"
        let uri = URI(stringLiteral: urlString)
        XCTAssertThrowsError(try serverURLString(uri,
                                                 parseServerURLStrings: parseServerURLStrings))
    }

    func testParseHookOptions() async throws {
        let app = try setupAppForTesting()
        defer { app.shutdown() }
        let installationId = "naw"
        let urlString = "https://parse.com/parse"
        parseServerURLStrings.append(urlString)
        let dummyHookRequest = DummyRequest(installationId: installationId, params: .init())
        let encoded = try ParseCoding.jsonEncoder().encode(dummyHookRequest)
        let hookRequest = try ParseCoding.jsonDecoder().decode(ParseHookFunctionRequest<User, FooParameters>.self,
                                                               from: encoded)

        let options = hookRequest.options()
        let installationOption = options.first(where: { $0 == .installationId("") })
        XCTAssertEqual(options.count, 1)
        XCTAssertTrue(installationOption.debugDescription.contains(installationId))

        let uri = URI(stringLiteral: urlString)
        let request = Request(application: app, url: uri, on: app.eventLoopGroup.any())
        let options2 = try hookRequest.options(request,
                                               parseServerURLStrings: parseServerURLStrings)
        let installationOption2 = options2.first(where: { $0 == .installationId("") })
        let serverURLOption = options2.first(where: { $0 == .serverURL("") })
        XCTAssertEqual(options2.count, 2)
        XCTAssertTrue(installationOption2.debugDescription.contains(installationId))
        XCTAssertTrue(serverURLOption.debugDescription.contains("\"\(urlString)\""))
    }

    func testHooksFunctions() async throws {
        let functions = await hooks.getFunctions()
        XCTAssertTrue(functions.isEmpty)
        
        let dummyHooks = ["yo": HookFunction(name: "hello", url: nil),
                          "no": HookFunction(name: "hello", url: nil)]
        await hooks.updateFunctions(dummyHooks)
        let functions2 = await hooks.getFunctions()
        XCTAssertEqual(functions2.count, 2)
        
        await hooks.removeFunctions(["yo"])
        let functions3 = await hooks.getFunctions()
        XCTAssertNil(functions3["yo"])
        XCTAssertNotNil(functions3["no"])

        await hooks.removeAllFunctions()
        let functions4 = await hooks.getFunctions()
        XCTAssertTrue(functions4.isEmpty)
    }

    func testHooksTriggers() async throws {
        let triggers = await hooks.getTriggers()
        XCTAssertTrue(triggers.isEmpty)
        
        guard let url = URL(string: "http://parse.com") else {
            XCTFail("Should have unwrapped")
            return
        }
        let dummyHooks = ["yo": HookTrigger(className: "hello", triggerName: .afterDelete, url: url),
                          "no": HookTrigger(className: "hello", triggerName: .afterEvent, url: url)]
        await hooks.updateTriggers(dummyHooks)
        let triggers2 = await hooks.getTriggers()
        XCTAssertEqual(triggers2.count, 2)
        
        await hooks.removeTriggers(["yo"])
        let triggers3 = await hooks.getTriggers()
        XCTAssertNil(triggers3["yo"])
        XCTAssertNotNil(triggers3["no"])

        await hooks.removeAllTriggers()
        let triggers4 = await hooks.getTriggers()
        XCTAssertTrue(triggers4.isEmpty)
    }
}
