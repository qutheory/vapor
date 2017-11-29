import Async
import Bits
import HTTP
import Routing
import Vapor
import TCP
import XCTest

class ApplicationTests: XCTestCase {
    func testCORSMiddleware() throws {
        let app = try Application()
        let cors = CORSMiddleware()
        
        let router = try app.make(Router.self).grouped(cors)
        
        router.post("good") { req in
            return try Response(
                status: .ok,
                body: "hello"
            )
        }
        
        var request = Request(
            method: .options,
            uri: "/good",
            headers: [
                .origin: "http://localhost:8090",
                .accessControlRequestMethod: "POST",
            ]
        )
        
        let trieRouter = try app.make(TrieRouter.self)
        
        if let responder = trieRouter.fallbackResponder {
            trieRouter.fallbackResponder = cors.makeResponder(chainedTo: responder)
        }
        
        var response = try router.route(request: request)?.respond(to: request).blockingAwait()
        
//        XCTAssertEqual(response?.status, 200)
        
        try response?.body.withUnsafeBytes { pointer in
            let data = Array(ByteBuffer(start: pointer, count: response!.body.count ?? 0))
            XCTAssertNotEqual(data, Array("hello".utf8))
        }
        
        request = Request(method: .get, uri: "/good")
        response = try router.route(request: request)?.respond(to: request).blockingAwait()
        
        XCTAssertNotEqual(response?.status, 200)
        try response?.body.withUnsafeBytes { pointer in
            let data = Data(ByteBuffer(start: pointer, count: response!.body.count ?? 0))
            XCTAssertNotEqual(data, Data("hello".utf8))
        }
        
        request = Request(method: .post, uri: "/good")
        response = try router.route(request: request)?.respond(to: request).blockingAwait()
        
        XCTAssertEqual(response?.status, 200)
        try response?.body.withUnsafeBytes { pointer in
            let data = Data(ByteBuffer(start: pointer, count: response!.body.count ?? 0))
            XCTAssertEqual(data, Data("hello".utf8))
        }
    }

    static let allTests = [
        ("testCORSMiddleware", testCORSMiddleware),
    ]
}
