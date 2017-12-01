import Async

/// Capable of transforming requests and responses.
///
/// [Learn More →](https://docs.vapor.codes/3.0/http/middleware/)
public protocol Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response>
}

// MARK: Responder

/// A wrapper that applies the supplied middleware to a responder.
///
/// Note: internal since it is exposed through `makeResponder` extensions.
internal final class MiddlewareResponder: Responder {
    /// The middleware to apply.
    let middleware: Middleware

    /// The actual responder.
    let chained: Responder

    /// Creates a new middleware responder.
    init(middleware: Middleware, chained: Responder) {
        self.middleware = middleware
        self.chained = chained
    }

    /// Responder conformance.
    func respond(to req: Request) throws -> Future<Response> {
        return try middleware.respond(to: req, chainingTo: chained)
    }
}


// MARK: Convenience

extension Middleware {
    /// Converts a middleware into a responder by chaining it to an actual responder.
    public func makeResponder(chainedTo responder: Responder) -> Responder {
        return MiddlewareResponder(middleware: self, chained: responder)
    }
}

/// Extension on [Middleware]
extension Array where Element == Middleware {
    /// Converts an array of middleware into a responder by
    /// chaining them to an actual responder.
    public func makeResponder(chainedto responder: Responder) -> Responder {
        var responder = responder
        for middleware in self {
            responder = middleware.makeResponder(chainedTo: responder)
        }
        return responder
    }
}

/// Extension on [ConcreteMiddleware]
extension Array where Element: Middleware {
    /// Converts an array of middleware into a responder by
    /// chaining them to an actual responder.
    public func makeResponder(chainedto responder: Responder) -> Responder {
        var responder = responder
        for middleware in self {
            responder = middleware.makeResponder(chainedTo: responder)
        }
        return responder
    }
}
