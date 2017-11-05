import Async
import Dispatch

/// Capable of responding to a request.
public protocol Responder {
    func respond(to req: Request) throws -> Future<Response>
}

extension Responder {
    /// Creates a stream from this responder capable of being
    /// added to a server or client stream.
    public func makeStream() -> ResponderStream {
        return ResponderStream(responder: self)
    }
}

/// A stream containing an HTTP responder.
public final class ResponderStream: Async.Stream {
    /// See InputStream.Input
    public typealias Input = Request

    /// See OutputStream.Output
    public typealias Notification = Response

    /// See BaseStream.errorNotification
    public let errorNotification = SingleNotification<Error>()

    // See BaseStream.outputStream
    public var outputStream: NotificationCallback?

    /// The responder
    let responder: Responder

    /// Create a new response stream.
    /// The responses will be awaited on the supplied queue.
    public init(responder: Responder) {
        self.responder = responder
    }

    /// Handle incoming requests.
    public func inputStream(_ input: Request) {
        do {
            // dispatches the incoming request to the responder.
            // the response is awaited on the responder stream's queue.
            try responder.respond(to: input).then { res in
                self.outputStream?(res)
            }.catch { error in
                self.errorNotification.notify(of: error)
            }
        } catch {
            self.errorNotification.notify(of: error)
        }
    }
}

