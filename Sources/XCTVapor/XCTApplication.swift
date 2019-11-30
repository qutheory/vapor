extension Application {
    public enum Method {
        case inMemory
        case running(port: Int)
        public static var running: Method {
            return .running(port: 8080)
        }
    }

    public func testable(method: Method = .inMemory) throws -> XCTApplicationTester {
        try self.boot()
        switch method {
        case .inMemory:
            return try InMemory(app: self)
        case .running(let port):
            return try Live(app: self, port: port)
        }
    }
    
    private struct Live: XCTApplicationTester {
        let app: Application
        let port: Int

        init(app: Application, port: Int) throws {
            self.app = app
            self.port = port
            
        }

        @discardableResult
        public func performTest(
            method: HTTPMethod,
            path: String,
            headers: HTTPHeaders,
            body: ByteBuffer?,
            file: StaticString,
            line: UInt,
            closure: (XCTHTTPResponse) throws -> ()
        ) throws -> XCTApplicationTester {
            let server = try app.server.start(hostname: "localhost", port: port)
            defer { server.shutdown() }
            let client = HTTPClient(eventLoopGroupProvider: .createNew)
            defer { try! client.syncShutdown() }
            var request = try HTTPClient.Request(
                url: "http://localhost:\(self.port)\(path)",
                method: method,
                headers: headers
            )
            if let body = body {
                request.body = .byteBuffer(body)
            }
            let response = try client.execute(request: request).wait()
            try closure(XCTHTTPResponse(
                status: response.status,
                headers: response.headers,
                body: response.body.flatMap { .init(buffer: $0) } ?? .init()
            ))
            return self
        }
    }

    private struct InMemory: XCTApplicationTester {
        let app: Application
        init(app: Application) throws {
            self.app = app
        }

        @discardableResult
        public func performTest(
            method: HTTPMethod,
            path: String,
            headers: HTTPHeaders,
            body: ByteBuffer?,
            file: StaticString,
            line: UInt,
            closure: (XCTHTTPResponse) throws -> ()
        ) throws -> XCTApplicationTester {
            var headers = headers
            if let body = body {
                headers.replaceOrAdd(name: .contentLength, value: body.readableBytes.description)
            }
            let path = path.hasPrefix("/") ? path : "/" + path
            let response: XCTHTTPResponse
            let request = Request(
                application: app,
                method: method,
                url: .init(string: path),
                headers: headers,
                collectedBody: body,
                remoteAddress: nil,
                on: self.app.eventLoopGroup.next()
            )
            do {
                let res = try self.app.responder.respond(to: request).wait()
                response = XCTHTTPResponse(status: res.status, headers: res.headers, body: res.body)
                try closure(response)
            } catch {
                XCTFail("\(error)", file: file, line: line)
            }
            return self
        }
    }
}

public protocol XCTApplicationTester {
    @discardableResult
    func performTest(
        method: HTTPMethod,
        path: String,
        headers: HTTPHeaders,
        body: ByteBuffer?,
        file: StaticString,
        line: UInt,
        closure: (XCTHTTPResponse) throws -> ()
    ) throws -> XCTApplicationTester
}

extension XCTApplicationTester {
    @discardableResult
    public func test(
        _ method: HTTPMethod,
        _ path: String,
        headers: HTTPHeaders = [:],
        body: ByteBuffer? = nil,
        file: StaticString = #file,
        line: UInt = #line,
        closure: (XCTHTTPResponse) throws -> () = { _ in }
    ) throws -> XCTApplicationTester {
        return try self.performTest(
            method: method,
            path: path,
            headers: headers,
            body: body,
            file: file,
            line: line,
            closure: closure
        )
    }

    @discardableResult
    public func test<Body>(
        _ method: HTTPMethod,
        _ path: String,
        headers: HTTPHeaders = [:],
        json: Body,
        file: StaticString = #file,
        line: UInt = #line,
        closure: (XCTHTTPResponse) throws -> () = { _ in }
    ) throws -> XCTApplicationTester
        where Body: Encodable
    {
        var body = ByteBufferAllocator().buffer(capacity: 0)
        try body.writeBytes(JSONEncoder().encode(json))
        var realHeaders = headers
        realHeaders.replaceOrAdd(name: .contentType, value: HTTPMediaType.json.serialize())
        return try self.test(method, path, headers: realHeaders, body: body, closure: closure)
    }
}
