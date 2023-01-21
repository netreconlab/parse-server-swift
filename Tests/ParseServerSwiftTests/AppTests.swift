@testable import ParseServerSwift
@testable import ParseSwift
import XCTVapor

final class AppTests: XCTestCase {
    
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
}
