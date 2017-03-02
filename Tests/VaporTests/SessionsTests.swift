import XCTest
@testable import Sessions
import Vapor
import HTTP
import Core

class SessionsTests: XCTestCase {
    static let allTests = [
        ("testExample", testExample),
    ]

    func testExample() throws {
        let drop = try Droplet()

        let s = MemorySessions()
        let m = SessionsMiddleware(sessions: s)
        drop.middleware = [m]

        drop.get("set") { req in
            try req.session().data["foo"] = "bar"
            try req.session().data["bar"] = "baz"
            return "set"
        }

        drop.get("get") { req in
            return try req.session().data["foo"]?.string ?? "fail"
        }

        let req = Request(method: .get, path: "set")
        let res = try drop.respond(to: req)

        guard let c = res.cookies["vapor-sessions"] else {
            XCTFail("No cookie")
            return
        }

        for s in s.sessions {
            print(s.key)
            print(s.value.data)
        }
        
        XCTAssertEqual(s.sessions[c]?.data, Node([
            "foo": "bar",
            "bar": "baz"
        ]))

        let req2 = Request(method: .get, path: "get")
        req2.cookies["vapor-sessions"] = c
        let res2 = try drop.respond(to: req2)

        XCTAssertEqual(res2.body.bytes?.string, "bar")
    }
    
}
