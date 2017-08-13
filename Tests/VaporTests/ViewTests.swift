import XCTest
import Core
@testable import Vapor
import HTTP
import Session
import Node
import Service

class ViewTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic),
        ("testViewBytes", testViewBytes),
        ("testViewResponse", testViewResponse),
        ("testViewRequest", testViewRequest)
    ]

    func testBasic() throws {
        let r = TestRenderer(viewsDir: "ferret")
        r.views["foo"] = "42".makeBytes()

        let view = try r.make("foo")
        XCTAssertEqual(view.data.makeString(), "42")


        let view2 = try r.make("foo", "context")
        XCTAssertEqual(view2.data.makeString(), "42")
    }

    func testViewBytes() throws {
        let view = View(bytes: "42".makeBytes())
        XCTAssertEqual(view.makeBytes(), "42".makeBytes())
    }


    func testViewResponse() throws {
        let view = View(bytes: "42 🚀".makeBytes())
        let response = view.makeResponse()

        XCTAssertEqual(response.headers["content-type"], "text/html; charset=utf-8")
        XCTAssertEqual(try response.bodyString(), "42 🚀")
    }
    
    func testViewRequest() throws {
        final class TestRenderer: ViewRenderer {
            var shouldCache: Bool
            
            let viewsDir: String
            init(viewsDir: String) {
                self.viewsDir = viewsDir
                shouldCache = false
            }
            
            func make(_ path: String, _ context: Node) throws -> View {
                return View(data: "\(context)".makeBytes())
                
            }
        }
        
        var config = Config.default()
        try config.set("droplet", "view", to: "test")

        var services = Services.default()
        services.register(TestRenderer(viewsDir: ""), name: "test", supports: [ViewRenderer.self])
        
        let drop = try Droplet(config, services)
        
        let request = Request(method: .get, path: "/foopath")
        
        let session = Session(identifier: "abc")
        request.storage["session"] = session
        
        request.storage["test"] = "foobar"
        
        session.data = SessionData.dictionary([
            "name": .string("Vapor")
        ])
        

        
        let view = try drop.view().make("test-template", for: request)
        let string = view.data.makeString()
        
        XCTAssert(string.contains("Vapor"))
        XCTAssert(string.contains("foopath"))
        XCTAssert(string.contains("foobar"))
    }
}
