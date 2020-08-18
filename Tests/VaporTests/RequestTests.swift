import XCTVapor

final class RequestTests: XCTestCase {
    
    func testCustomHostAdress() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.get("vapor", "is", "fun") {
            return $0.remoteAddress?.hostname ?? "n/a"
        }
        
        let ipV4Hostname = "127.0.0.1"
        try app.testable(method: .running(hostname: ipV4Hostname, port: 8080)).test(.GET, "vapor/is/fun") { res in
            XCTAssertEqual(res.body.string, ipV4Hostname)
        }
    }
    
    func testRequestRemoteAddress() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.get("remote") {
            $0.remoteAddress?.description ?? "n/a"
        }
        
        try app.testable(method: .running).test(.GET, "remote") { res in
            XCTAssertContains(res.body.string, "IP")
        }
    }

    func testURI() throws {
        do {
            var uri = URI(string: "http://vapor.codes/foo?bar=baz#qux")
            XCTAssertEqual(uri.scheme, "http")
            XCTAssertEqual(uri.host, "vapor.codes")
            XCTAssertEqual(uri.path, "/foo")
            XCTAssertEqual(uri.query, "bar=baz")
            XCTAssertEqual(uri.fragment, "qux")
            uri.query = "bar=baz&test=1"
            XCTAssertEqual(uri.string, "http://vapor.codes/foo?bar=baz&test=1#qux")
            uri.query = nil
            XCTAssertEqual(uri.string, "http://vapor.codes/foo#qux")
        }
        do {
            let uri = URI(string: "/foo/bar/baz")
            XCTAssertEqual(uri.path, "/foo/bar/baz")
        }
        do {
            let uri = URI(string: "ws://echo.websocket.org/")
            XCTAssertEqual(uri.scheme, "ws")
            XCTAssertEqual(uri.host, "echo.websocket.org")
            XCTAssertEqual(uri.path, "/")
        }
        do {
            let uri = URI(string: "http://foo")
            XCTAssertEqual(uri.scheme, "http")
            XCTAssertEqual(uri.host, "foo")
            XCTAssertEqual(uri.path, "")
        }
        do {
            let uri = URI(string: "foo")
            XCTAssertEqual(uri.scheme, "foo")
            XCTAssertEqual(uri.host, nil)
            XCTAssertEqual(uri.path, "")
        }
        do {
            let uri: URI = "/foo/bar/baz"
            XCTAssertEqual(uri.path, "/foo/bar/baz")
        }
        do {
            let foo = "foo"
            let uri: URI = "/\(foo)/bar/baz"
            XCTAssertEqual(uri.path, "/foo/bar/baz")
        }
    }
}
