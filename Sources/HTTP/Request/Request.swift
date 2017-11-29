import Async
import Foundation

/// An HTTP request.
///
/// Used to request a response from an HTTP server.
///
///     POST /foo HTTP/1.1
///     Content-Length: 5
///
///     hello
///
/// The HTTP server will stream incoming requests from clients.
/// You must handle these requests and generate responses.
///
/// When you want to request data from another server, such as
/// calling another API from your application, you will create
/// a request and use the HTTP client to prompt a response
/// from the remote server.
///
///     let req = Request(method: .post, body: "hello")
///
/// [Learn More →](https://docs.vapor.codes/3.0/http/request/)
public final class Request: Message {
    /// See EphemeralWorker.onInit
    public static var onInit: LifecycleHook?

    /// See EphemeralWorker.onDeinit
    public static var onDeinit: LifecycleHook?

    /// HTTP requests have a method, like GET or POST
    ///
    /// [Learn More →](https://docs.vapor.codes/3.0/http/method/)
    public var method: Method

    /// This is usually just a path like `/foo` but
    /// may be a full URI in the case of a proxy
    ///
    /// [Learn More →](https://docs.vapor.codes/3.0/http/uri/)
    public var uri: URI

    /// See `Message.version`
    public var version: Version

    /// See `Message.headers`
    ///
    /// [Learn More →](https://docs.vapor.codes/3.0/http/headers/)
    public var headers: Headers

    /// See `Message.body`
    ///
    /// [Learn More →](https://docs.vapor.codes/3.0/http/body/)
    public var body: Body
    
    /// See `Extendable.extend`
    public var extend: Extend
    
    /// See `Message.eventLoop`
    public let eventLoop: EventLoop

    /// Create a new HTTP request.
    public init(
        method: Method = .get,
        uri: URI = URI(),
        version: Version = Version(major: 1, minor: 1),
        headers: Headers = Headers(),
        body: Body = Body(),
        worker: Worker
    ) {
        self.method = method
        self.uri = uri
        self.version = version
        self.headers = headers
        self.body = body
        self.extend = Extend()
        self.eventLoop = worker.eventLoop
        
        Request.onInit?(self)
    }

    /// Called when request is deinitializing
    deinit {
        Request.onDeinit?(self)
        // print("Request.deinit")
    }
}

// MARK: Convenience

extension Request {
    /// Create a new HTTP request using something BodyRepresentable.
    public convenience init(
        method: Method = .get,
        uri: URI = URI(),
        version: Version = Version(major: 1, minor: 1),
        headers: Headers = Headers(),
        body: BodyRepresentable,
        worker: Worker
    ) throws {
        try self.init(method: method, uri: uri, version: version, headers: headers, body: body.makeBody(), worker: worker)
    }
}

/// Can be converted from a request.
public protocol RequestDecodable {
    static func decode(from req: Request) throws -> Future<Self>
}

/// Can be converted to a request
public protocol RequestEncodable {
    func encode(to req: inout Request) throws -> Future<Void>
}

/// Can be converted from and to a request
public typealias RequestCodable = RequestDecodable & RequestEncodable

// MARK: Request Conformance

extension Request: RequestEncodable {
    public func encode(to req: inout Request) throws -> Future<Void> {
        req = self
        return .done
    }
}

extension Request: RequestDecodable {
    /// See RequestInitializable.decode
    public static func decode(from request: Request) throws -> Future<Request> {
        return Future(request)
    }
}

