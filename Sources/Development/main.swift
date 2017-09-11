import Async
import Dispatch
import HTTP
import Leaf
import Routing
import Service
import Vapor

extension View: ContentEncodable, ResponseRepresentable {
    public func encodeContent(to message: Message) throws {
        message.mediaType = .html
        message.body = Body(data)
    }
}


var services = Services.default()
try services.register(Leaf.Provider())

services.register { container in
    MiddlewareConfig([
        ErrorMiddleware.self
    ])
}

let app = Application(services: services)

let async = try app.make(AsyncRouter.self)
let sync = try app.make(SyncRouter.self)

let user = User(name: "Vapor", age: 3);
async.on(.get, to: "hello") { req in
    return Future<User>(user)
}

let hello = try Response(body: "Hello, world!")
sync.on(.get, to: "plaintext") { req in
    return hello
}

let view = try app.make(ViewRenderer.self)
async.on(.get, to: "leaf") { req -> Future<View> in
    user.child = User(name: "Leaf", age: 1)
    let promise = Promise(User.self)
    user.futureChild = promise.future

    try req.requireQueue().asyncAfter(deadline: .now() + 2) {
        let user = User(name: "unborn", age: -1)
        promise.complete(user)
    }
    
    return try view.make("/Users/tanner/Desktop/hello", context: user, for: req)
}

extension String: ResponseRepresentable {
    public func makeResponse() throws -> Response {
        return try Response(body: self)
    }
}

async.on(.post, to: "test") { (req: Request) throws -> Future<String> in
    let req = try MultipartParser.parse(request: req)
    
    print(req)
    
    return Future("test")
}

print("Starting server...")
try app.run()

