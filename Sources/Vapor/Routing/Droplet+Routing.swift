import HTTP
import Routing

@_exported import HTTPRouting
@_exported import TypeSafeRouting

extension Droplet: RouteBuilder {
    public typealias Value = Responder

    public func add(
        path: [String],
        value: Value
    ) {
        router.add(path: path, value: value)
    }
}

extension RouteBuilder where Value == Responder {
    public func group(_ middleware: Middleware ..., closure: (RouteGroup<Value, Self>) ->()) {
        group(prefix: [nil, nil], path: [], map: { handler in
            return Request.Handler { request in
                return try middleware.chain(to: handler).respond(to: request)
            }
        }, closure: closure)
    }

    public func grouped(_ middleware: Middleware ...) -> RouteGroup<Value, Self> {
        return grouped(prefix: [nil, nil], path: [], map: { handler in
            return Request.Handler { request in
                return try middleware.chain(to: handler).respond(to: request)
            }
        })
    }
    
    public func group(_ middlewares: [Middleware], closure: (RouteGroup<Value, Self>) ->()) {
        group(prefix: [nil, nil], path: [], map: { handler in
            return Request.Handler { request in
                return try middlewares.chain(to: handler).respond(to: request)
            }
        }, closure: closure)
    }
    
    public func grouped(_ middlewares: [Middleware]) -> RouteGroup<Value, Self> {
        return grouped(prefix: [nil, nil], path: [], map: { handler in
            return Request.Handler { request in
                return try middlewares.chain(to: handler).respond(to: request)
            }
        })
    }
}

extension RouteBuilder {
    public func collection<
        C: RouteCollection>(_ collectionType: C.Type)
        where C.Wrapped == Value,
        C: EmptyInitializable
    {
        let collection = collectionType.init()
        self.collection(collection)
    }
}
