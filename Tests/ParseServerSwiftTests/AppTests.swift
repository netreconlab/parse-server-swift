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
        webhookKey = hookKey
        try configure(app, testing: true)
        Parse.configuration.isTestingSDK = true
        return app
    }
    
    func testHelloWorld() throws {
        let app = try setupAppForTesting()
        defer { app.shutdown() }

        try app.test(.GET, "hello", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "Hello, world!")
        })
    }

    func testFunctionWebhookKeyNotEqual() throws {
        let app = try setupAppForTesting(hookKey: "wow")
        defer { app.shutdown() }
        
        try app.test(.POST, "foo", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertTrue(res.body.string.contains("Webhook keys"))
        })
    }

    func testTriggerWebhookKeyNotEqual() throws {
        let app = try setupAppForTesting(hookKey: "wow")
        defer { app.shutdown() }
        
        try app.test(.POST, "bar", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertTrue(res.body.string.contains("Webhook keys"))
        })
    }

    func testMatchServerURLString() async throws {
        let app = try setupAppForTesting()
        defer { app.shutdown() }
        let urlString = "https://parse.com/1"
        let uri = URI(stringLiteral: urlString)
        let serverString = try serverURLString(uri, parseServerURLStrings: [urlString])
        XCTAssertEqual(serverString, urlString)
        
        let urlString2 = urlString + "/helloWorld"
        let uri2 = URI(stringLiteral: urlString2)
        let serverString2 = try serverURLString(uri2, parseServerURLStrings: [urlString])
        XCTAssertEqual(serverString2, urlString)
        
        parseServerURLStrings = ["http://localhost:1337/1"]
        let serverString3 = try serverURLString(uri)
        XCTAssertEqual(serverString3, parseServerURLStrings.first)
    }

    func testMatchServerURLStringThrowsError() async throws {
        let app = try setupAppForTesting()
        parseServerURLStrings.removeAll()
        defer { app.shutdown() }
        let urlString = "https://parse.com/1"
        let uri = URI(stringLiteral: urlString)
        XCTAssertThrowsError(try serverURLString(uri))
    }

    func testParseHookOptions() async throws {
        let app = try setupAppForTesting()
        defer { app.shutdown() }
        let installationId = "naw"
        let urlString = "https://parse.com/1"
        parseServerURLStrings.append(urlString)
        let dummyHookRequest = DummyRequest(installationId: installationId, params: .init())
        let encoded = try ParseCoding.jsonEncoder().encode(dummyHookRequest)
        let hookRequest = try ParseCoding.jsonDecoder().decode(ParseHookFunctionRequest<User, FooParameters>.self,
                                                               from: encoded)

        let options = hookRequest.options()
        XCTAssertEqual(options, API.Options([.installationId(installationId)]))
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
