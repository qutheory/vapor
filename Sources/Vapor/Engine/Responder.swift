/// Capable of responding to a request.
public protocol Responder {
    /// Returns a future response for the supplied request.
    func respond(to req: Request) throws -> Future<Response>
}

/// MARK: Route

/// A basic, closure-based responder.
public struct RouteResponder: Responder {
    /// Responder closure
    public typealias Closure = (Request) throws -> ResponseEncodable

    /// The stored responder closure.
    public let closure: Closure

    /// Create a new basic responder.
    public init(closure: @escaping Closure) {
        self.closure = closure
    }

    /// See: HTTP.Responder.respond
    public func respond(to req: Request) throws -> Future<Response> {
        let encodable = try closure(req)
        return try encodable.encode(for: req)
    }
}

/// A basic, closure-based responder.
public struct RequestDecodableResponder<C>: Responder
    where C: RequestDecodable
{
    /// Responder closure
    public typealias Closure = (Request, C) throws -> ResponseEncodable
    
    /// The stored responder closure.
    public let closure: Closure
    
    /// Create a new basic responder.
    public init(closure: @escaping Closure) {
        self.closure = closure
    }
    
    /// See: HTTP.Responder.respond
    public func respond(to req: Request) throws -> Future<Response> {
        return try C.decode(from: req).flatMap(to: Response.self) { content in
            let encodable = try self.closure(req, content)
            return try encodable.encode(for: req)
        }
    }
}

/// MARK: Router

/// Converts a router into a responder.
public struct RouterResponder: Responder {
    let router: Router

    /// Creates a new responder for a router
    public init(router: Router) {
        self.router = router
    }

    /// Responds to a request using the Router
    public func respond(to req: Request) throws -> Future<Response> {
        guard let responder = router.route(request: req) else {
            let res = req.makeResponse()
            res.http.status = .notFound
            return Future.map(on: req) { res }
        }

        return try responder.respond(to: req)
    }
}
